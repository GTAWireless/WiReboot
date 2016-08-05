token = string.char(rtcmem.read32(1,32))
--print(token)  -- print(rtcmem.read32(1,80))

file.open("t.lua","w")
file.write([[token="]]..token..[[" ]])
file.close()

-- read varibles from rtcmem and write to config.lua
defaultSleepTime,LEDBlinkInterval,LEDOnTime,testWiFiInterval,retryTimesLocal,retryTimesHTTPS,rebootInterval,waitAfterReboot,waitFirstPowerOn = rtcmem.read32(33,9)
url = string.char(rtcmem.read32(44,rtcmem.read32(43)))

file.open("config.lua","w")
file.write([[defaultSleepTime=]]..defaultSleepTime..[[;]])
file.write([[LEDBlinkInterval=]]..LEDBlinkInterval..[[;]])
file.write([[LEDOnTime=]]..LEDOnTime..[[;]])
file.write([[testWiFiInterval=]]..testWiFiInterval..[[;]])
file.write([[retryTimesLocal=]]..retryTimesLocal..[[;]])
file.write([[retryTimesHTTPS=]]..retryTimesHTTPS..[[;]])
file.write([[rebootInterval=]]..rebootInterval..[[;]])
file.write([[waitAfterReboot=]]..waitAfterReboot..[[;]])
file.write([[waitFirstPowerOn=]]..waitFirstPowerOn..[[;]])
file.write([[url="]]..url..[["; ]])
file.close()

-- print(waitFirstPowerOn) print(url)
node.restart()
