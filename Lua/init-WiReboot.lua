i=0
local j=0
local k=0
local t=0

local c=require("config")

if file.exists("t.lua") then
    local t = require("t")
else
    if rboot.rom()==1 then  -- after firmware update, read token, config from RTC and save
        dofile("ota-token.lua")
    else
        dofile("dualSetup.lua")
        return
    end
end

URLs={'live.com', 'amazon.com', 'yahoo.com'} --'httpbin.org/ip'

majorVer, minorVer, devVer=node.info()
local fv=majorVer.."."..minorVer.."."..devVer
--print(fv)
majorVer,minorVer,devVer=nil,nil,nil

local v=adc.read(0)
local sm=require("sm")
local sd=sm.sData()
package.loaded["sm"]=nil
sm=nil
if sd==nil then sd='' end

gpio.mode(6,gpio.INT)
local function touchcb(level)
    t=t+1
    if t==4 then uart.alt(0) end
    if token~=nil then
        if (t==10 and wifi.sta.status()==5) or (t==6 and wifi.sta.status()~=5) then
            file.remove("t.lua")
            node.restart()
        end
    end
end
gpio.trig(6,"both",touchcb)

function PowerCycle()
    print("Power Off")
    tmr.stop(1)
    gpio.mode(2, gpio.OUTPUT, gpio.PULLUP)
    gpio.write(2, gpio.LOW)
    tmr.alarm(5,rebootInterval,0,function() gpio.write(2, gpio.HIGH) print("Power ON") node.dsleep(waitAfterReboot) end)
end

connected=false
function testNet()
    connected=false
    -- test amazon, bing, yahoo, if able to access any of them, reset j=0
    for u = 1, #URLs do
        -- print(URLs[u])
        if connected==true then break end
        http.get('http://'..URLs[u], nil, function(code, data)
            print(code)
            if (code > 0) then
              -- print(code, data)
              k=k+1
              j=0
              connected=true
            end
          end)        
    end
end

function postData() -- ToDO: when to sleep if Google is blocked?
    local ip = wifi.sta.getip()
    local m = node.heap()
    local mac = wifi.sta.getmac()
    local sPostData

    sPostData = string.format([[a=wr&ip=%s&m=%s&mac=%s&at=%s&v=%s&fv=%s]],ip,m,mac,token,v,fv)..sd
    print(sPostData)
    http.post(url, nil, sPostData, function(code, res)
        print(code)
        if (code<0) then return end -- if code==-1, sleep?
        if (code ==200) then
          j = 0
          pos=string.find(res, "node:")
          strNode=string.sub(res,pos+5)
          print(strNode)
          pcall(loadstring(strNode))
        else
          node.dsleep(defaultSleepTime)
        end
    end)
end

gpio.mode(1, gpio.OUTPUT, gpio.PULLUP)    -- gpio5 = 1 , RED LED
gpio.write(1, gpio.LOW)

if rboot.rom()==1 and token==nil then   -- token was in RTC mem before OTA
    dofile("ota-token.lua")
end

-- check boot reason, if power on, sleep and wait modem/router few minutes before test WiFi
boot_code, reset_reason = node.bootreason()
if reset_reason==6 or reset_reason==0 then
    print("wait...")
    tmr.alarm(0,waitFirstPowerOn,0,function() node.restart() end)
    -- if can not find Wi-Fi ssid, restart Wi-Fi setup after 10 minutes
--    tmr.alarm(1,600000,0,function() 
--        tmr.stop(0)
--        dofile("dualSetup.lua")
--    end)
else
    print("test WiFi:")  -- check internet, then sleep

    tmr.alarm(1,testWiFiInterval,1,function()
        if(wifi.sta.status()~=5) then
            i = i + 1
            print("Offline") -- trying to connect to router
            if i>retryTimesLocal then
                PowerCycle()
            end
        else
            -- test https (and post sensors data if module is connected
            j = j + 1

            if token==nil then  -- if token is not nil, it means able to access google server
                testNet()
            end
            
            if j>retryTimesHTTPS then
                PowerCycle()
            else
                postData()
            end
--                print(k)
            if k>1 then node.dsleep(defaultSleepTime) end
        end
        collectgarbage()
    end)
end
