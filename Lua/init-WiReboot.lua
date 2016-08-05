
local c = require("config")

if file.open("t.lua", "r") then
    file.close()
    local t = require("t")
else
    if rboot.rom()==1 then  -- after firmware update, read token, config from RTC and save
        dofile("ota-token.lua")
    else
        dofile("dualSetup.lua")
        return
    end
end

local v = adc.read(0)
-- majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
-- print(majorVer.."."..minorVer.."."..devVer)

gpio.mode(6, gpio.INPUT)

i = 0
j = 0

-- local DuringReboot = false
function PowerCycle()
    print("Power Off")
    tmr.stop(1)
    gpio.mode(2, gpio.OUTPUT, gpio.PULLUP)
    gpio.write(2, gpio.LOW)
    tmr.alarm(5,rebootInterval,0,function() gpio.write(2, gpio.HIGH) print("Power ON") node.dsleep(waitAfterReboot) end)
end

gpio.mode(4, gpio.INPUT)    -- gpio2 = 4

gpio.mode(1, gpio.OUTPUT, gpio.PULLUP)    -- gpio5 = 1 , connect to LED
gpio.write(1, gpio.LOW)

gpio.mode(3, gpio.OUTPUT, gpio.PULLDOWN)
gpio.write(3, gpio.LOW)
-- gpio0=3, gpio2=4

tmr.delay(10)

if rboot.rom()==1 and token==nil then   -- token was in RTC mem before OTA
    dofile("ota-token.lua")
end

if gpio.read(4)==0 then     -- gpio0 connect to gpio2, user want to run WiFi setup again
    print("WiFi setup")
    dofile("dualSetup.lua") -- dofile("setup.lua")
else
    -- check boot reason, print(node.bootreason()), if power on first time, sleep and wait a few minutes to test WiFi connection, prevent over-heating
    boot_code, reset_reason = node.bootreason()
    if reset_reason==6 or reset_reason==0 then
    -- if reset_reason!=4 then
        print("wait...")
        tmr.alarm(0,waitFirstPowerOn,0,function() node.restart() end)
    else
        print("test WiFi:")  -- check internet, then go to sleep
    
        tmr.alarm(1,testWiFiInterval,1,function()
            if(wifi.sta.status()~=5) then
                i = i + 1
                print("Offline") -- trying to connect to router
                --if token==nil then     -- Token is nil, never connect to server -- move token check to top
                if gpio.read(6)==0 and i>3 then  -- User want to run setup again
                    tmr.stop(1)
                    dofile("dualSetup.lua") -- dofile("setup.lua")
                end
                -- if i>retryTimesLocal and DuringReboot==false then
                if i>retryTimesLocal then
                    --DuringReboot = true
                    PowerCycle()
                    --i = 0
                end
            else
                -- test https (and post sensors data if module is connected
                j = j + 1
                -- if j>retryTimesHTTPS and DuringReboot==false then
                if j>retryTimesHTTPS then
                    --DuringReboot = true
                    PowerCycle()
                    --j = 0
                end
                local ip = wifi.sta.getip()
                local m = node.heap()
                local mac = wifi.sta.getmac()
             
                local sPostData = string.format([[a=run&ip=%s&m=%s&mac=%s&at=%s&v=%s]],ip,m,mac,token,v)
                print(sPostData)
                http.post(url, nil, sPostData, function(code, res)
                    print(code)
--                    if (code < 0) then
--                      print("Post failed")
--                    else
                    if (code ==200) then
                      j = 0
                      pos=string.find(res, "node:")
                      strNode=string.sub(res,pos+5)
                      print(strNode)
                      -- tmr.alarm(0,500,0,function() pcall(loadstring(strNode)) end)
                      pcall(loadstring(strNode))
                    else
                      node.dsleep(defaultSleepTime)
                    end
                end)
                
            end
            collectgarbage()
        end)
    end
end
