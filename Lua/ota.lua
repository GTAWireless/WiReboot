local pos = 1

-- print(rtcmem.read32(1,32))  print(rtcmem.read32(33,9)) print(rtcmem.read32(43))  print(string.char(rtcmem.read32(44,rtcmem.read32(43))))

local t = require("t")
-- save token to RTC mem

-- rtcmem.write32(0, 12345)
if token~=nil then
    for i = 1, #token do
        local c = token:sub(i,i)
        -- do something with c
        rtcmem.write32(i,string.byte(c))
    end
end

-- write varibles to rtcmem, new firmware will read from rtcmem and write to config.lua
local c = require("config")
pos = pos + 31

rtcmem.write32(pos+1,defaultSleepTime)
rtcmem.write32(pos+2,LEDBlinkInterval)
rtcmem.write32(pos+3,LEDOnTime)
rtcmem.write32(pos+4,testWiFiInterval)
rtcmem.write32(pos+5,retryTimesLocal)
rtcmem.write32(pos+6,retryTimesHTTPS)
rtcmem.write32(pos+7,rebootInterval)
rtcmem.write32(pos+8,waitAfterReboot)
rtcmem.write32(pos+9,waitFirstPowerOn)

rtcmem.write32(pos+10,#url)

-- print(pos)
-- write url
for i = 1, #url do
    local c = url:sub(i,i)
    -- do something with c
    rtcmem.write32(pos+11+i,string.byte(c))
end


-- print(rboot.rom()) 
-- rboot.swap()
-- if (wifi.sta.status()~=5) then   -- print(wifi.sta.status())

if rboot.rom()==0 then rboot.otafs() end
rboot.ota()
