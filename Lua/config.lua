-- local gpio4 = 2
url = "https://wirebootapp.appspot.com"   -- Need a way to change that using phone App, some country block Google App Engine

defaultSleepTime = 60000000
LEDBlinkInterval = 500    -- 500ms, how fast LED blinks in WiFi setup
LEDOnTime = 1500
testWiFiInterval = 10000   -- 10 seconds, timers between retry connection test
retryTimesLocal = 5       -- how many times to try local before reboot
retryTimesHTTPS = 5       -- how many times to try https access before reboot
rebootInterval = 10000     -- 10 seconds, time between power off and power on
-- waitAfterReboot = 600000000   -- After power cycle, wait 10 mins to test again
-- waitFirstPowerOn = 600000     -- 10 minutes
waitAfterReboot = 1800000000   -- After power cycle, wait 30 mins to test again
waitFirstPowerOn = 900000     -- 15 minutes
