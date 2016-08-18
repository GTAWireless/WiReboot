gpio.mode(2, gpio.OUTPUT, gpio.PULLUP)
gpio.write(2, gpio.LOW)

tmr.alarm(5,10000,0,function() gpio.write(2, gpio.HIGH)  node.dsleep(1800000000) end)

