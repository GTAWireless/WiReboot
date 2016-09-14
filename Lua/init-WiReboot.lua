i=0
local j=0
local k=0
local t=0

local c=require("config")

if file.exists("t.lua") then
    local t = require("t")
else
    if rboot.rom()==1 then  -- after OTA, read token/config from RTC and save
        dofile("ota-token.lua")
    else
        dofile("dualSetup.lua")
        return
    end
end

URLs={'live.com', 'amazon.com', 'yahoo.com'} --'httpbin.org/ip'

majorVer, minorVer, devVer=node.info()
local fv=majorVer.."."..minorVer.."."..devVer
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
    tmr.alarm(5,rebootInterval,0,function() gpio.write(2, gpio.HIGH) print("Power ON") rtctime.dsleep(waitAfterReboot) end)
end

local u=0
function testNet()
    if k>0 then rtctime.dsleep(defaultSleepTime) end
    -- test amazon, bing, yahoo
    u=u+1
    print(URLs[u])
    if u>#URLs then u=1 end
    http.get('http://'..URLs[u], nil, function(code, data)
        if (code > 0) then
          k=k+1
          --j=0
        end
      end)
end

local mac = wifi.sta.getmac()
function postData()
    local ip = wifi.sta.getip()
    local m = node.heap()
    local sPostData

    sPostData = string.format([[a=wr&ip=%s&m=%s&mac=%s&at=%s&v=%s&fv=%s]],ip,m,mac,token,v,fv)..sd
    print(sPostData)
    http.post(url, nil, sPostData, function(code, res)
        print(code)
        if (code<0) then if(j>2) then testNet() end return end -- if code==-1 and tried Google 2+ times, test other sites
        if (code ==200) then
          j = 0
          pos=string.find(res, "node:")
          strNode=string.sub(res,pos+5)
          --print(strNode)
          pcall(loadstring(strNode))
        else
          rtctime.dsleep(defaultSleepTime)
        end
    end)
end

gpio.mode(1, gpio.OUTPUT, gpio.PULLUP)    -- gpio5 = 1 , RED LED
--gpio.write(1, gpio.LOW)

if rboot.rom()==1 and token==nil then   -- token was in RTC mem before OTA
    dofile("ota-token.lua")
end

if v>280 then uart.alt(0) end

-- check boot reason, if power on, sleep and wait modem/router few minutes before test WiFi
boot_code, reset_reason = node.bootreason()
if reset_reason==6 or reset_reason==0 then
    print("wait...")
    tmr.alarm(0,waitFirstPowerOn,0,function() node.restart() end)
else
    print("test WiFi:")

    tmr.alarm(1,testWiFiInterval,1,function()
        if(wifi.sta.status()~=5) then
            i = i + 1
            print("Offline") -- connecting
            if i>retryTimesLocal then
                PowerCycle()
            end
        else
            -- test https (and post sensors data if module is connected
            -- if j==0 then sntp.sync(nil, function(sec,usec,server) k=1 end, nil)
            if j==0 then sntp.sync() end
            
            j = j + 1

            if token==nil then  
                testNet()
            else
                postData() -- token is not nil, able to access google server
            end
            
            if j>retryTimesHTTPS then
                PowerCycle()
            end
        end
        collectgarbage()
    end)
end
