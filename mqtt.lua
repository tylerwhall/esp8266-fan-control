m = mqtt.Client("livingroom", 10, "user", "password")
topic_prefix = "home/livingroom"

m:on("connect", function(con) print("mqtt connected") end)
m:on("offline", function(con) print("mqtt offline") end)
m:lwt(topic_prefix .. "/status", "offline", 0, 0)
m:on("message", function(conn, topic, data)
    print(topic .. ":")
    if data ~= nil then
        print(data)
    end
end)

function getBrightness()
    return adc.read(0) / 1024
end

local lastBrightness = 0
local scheduleBrightness
local publishBrightness = function(m)
    brightness = getBrightness()
    if math.abs(lastBrightness - brightness) > 0.01 then
        --print("Sending brightness update ", brightness)
        led_color(0, 0, 1)
        lastBrightness = brightness
        m:publish(topic_prefix .. "/brightness", brightness, 0, 0, function(conn)
            scheduleBrightness(m)
            led_color(0, 0, 0)
        end)
    else
        --print("Brightness", brightness, "similar to", lastBrightness, "No update")
        scheduleBrightness(m)
    end
end

scheduleBrightness = function(m)
    tmr.alarm(0, 500, 0, function() publishBrightness(m) end) 
end

-- Wait for wifi connection
led_color(1, 0, 0)
tmr.alarm(0, 500, 1, function()
    if wifi.sta.getip() ~= nil then
        print("WIFI connected")
        led_color(0, 0, 0)
        tmr.stop(0)
        m:connect("192.168.1.21", 1883, 0, function(con)
            print("connected")
            m:publish(topic_prefix .. "/status", "online", 0, 0, nil)
            publishBrightness(m)
        end)
    else
        print("Waiting for WIFI")
    end
end)