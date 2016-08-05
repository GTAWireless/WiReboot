local LEDBlinkInterval = 1500    -- 500ms, how fast LED blinks in WiFi setup
local LEDOnTime = 1500

local gpio12 = 6
gpio.mode(gpio12,gpio.INT)

urlToken = 'https://wirebootapp.appspot.com/nt'
keyToken = 'xxxxxxxxx'
i = 0

started = false

local function startSmart()
    print("SmartConfig")
    LEDBlinkInterval = 1500
    tmr.stop(1)
    tmr.alarm(1,LEDBlinkInterval,1,function() gpio.write(1, gpio.HIGH) tmr.delay(LEDOnTime) gpio.write(1, gpio.LOW) end)
    -- tmr.alarm(1,LEDBlinkInterval,1,function() print("S") end)
    
    wifi.setmode(wifi.STATION)
    wifi.startsmart(0,
        function(ssid, password)
            print(string.format("Success. SSID:%s", ssid))
            -- write token, then reboot
            -- tmr.alarm(2, 10000, 0, function() node.restart() end)   -- wait 10 seconds do App can confirm
            -- tmr.alarm(2,testWiFiInterval,1,function()
            tmr.alarm(2,5000,1,function()
                if(wifi.sta.status()==5) then
                    i = 0
                    -- print(wifi.sta.getip()) , now App know the IP, switch to stationap mode, we can not do it early because do not know if the password is correct
                    wifi.setmode(wifi.STATIONAP)
                    -- dofile("i.lua") -- now App can update url and token if needed
                    if started==false then
                        dofile("i.lua")
                        started = true
                    end
                    local mac = wifi.sta.getmac()
                    -- local sPostData = string.format([[mac=%s&k=%s&c=%s]],mac,keyToken,"json")
                    -- local sPostData = string.format([[mac=%s&k=%s&c=%s]],mac,keyToken,"node")
                    local sPostData = string.format([[mac=%s&k=%s]],mac,keyToken)
                    -- print(sPostData)
                    http.post(urlToken, nil, sPostData, function(code, res)
                        print(code)
                        if (code ==200) then
                            -- print(res) -- {"token": "xxx", "server_url": "xxx"}
                            o = cjson.decode(res)
                            file.open("t.lua","w"); file.write([[token=']]..o['token']..[['; ]]); file.close();
                            -- tmr.alarm(3, 3000, 0, function() node.restart() end)   -- wait 3 seconds do App can confirm
                            -- user able to access google server, so wait few minutes to wait App, if no command from App, reboot
                            tmr.alarm(3, 300000, 0, function() node.restart() end)
                            
                            -- can not do here because user may not able to access google server: now switch to stationap mode so App can change url and other varibles
                            tmr.stop(2)
                        else
                          -- node.dsleep(defaultSleepTime)
                        end
                    end)
                else
                    i = i + 1
                    print(i)
                end
                if i>15 then
                    node.restart()
                end
            end)
        end
    )
end

local function startWWW()
    print("WebConfig")
    LEDBlinkInterval = 500
    tmr.stop(1)
    tmr.alarm(1,LEDBlinkInterval,1,function() gpio.write(1, gpio.HIGH) tmr.delay(LEDOnTime) gpio.write(1, gpio.LOW) end)
    -- tmr.alarm(1,LEDBlinkInterval,1,function() print("W") end)

    wifi.setmode(wifi.STATIONAP)
    aplist = nil
    function listap(t)
      aplist = t
    end
    
    local cfg={}
    cfg.ssid = "WiReboot-"..node.chipid()
    wifi.ap.config(cfg)
    
    tmr.alarm(5, 1000, 0, function() wifi.sta.getap(listap) end)
    tmr.alarm(0, 2000, 0, function()
      -- dofile("i.lc")
      dofile("i.lua")
    end)
end

local function touchcb(level)
    if level==1 then
        startSmart()
    else
        startWWW()
    end
end

gpio.trig(gpio12, "both", touchcb)

net.dns.setdnsserver('8.8.8.8',0)
net.dns.setdnsserver('8.8.4.4',1)

startSmart()
