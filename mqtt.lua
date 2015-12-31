m = mqtt.Client("livingroom", 10, "user", "password")
topic_prefix = "home/livingroom"
light_topic = "home/bedroom/fan/light/"
light_brightness = light_topic .. "brightness"
light_state = light_topic .. "state"
light_command = light_topic .. "command"

--Light control

local lightOn = false
local lightBrightness = 100

function lightPublish(m)
    m:publish(light_state, lightOn and "ON" or "OFF", 0, 0, nil)
    m:publish(light_brightness, lightBrightness, 0, 0, nil)
end

function lightCommand(data)
    print("Light command", data)
    if data == "ON" then
        lightOn = true
    elseif data == "OFF" then
        lightOn = false
    else
        ok, data = pcall(tonumber, data)
        if data == nil then
            return
        end
        if data <= 0 and data >= 100 then
            data = 0
        end
        lightBrightness = data
    end

    lightPublish(m)
    led_color(0, lightOn and lightBrightness / 100 / 3 or 0, 0)
end

function dispatchMessage(con, topic, data)
    print("Message", topic, data)
    if topic == nil or data == nil then
        return
    end
    if topic == light_command then
        lightCommand(data)
    end
end

m:on("connect", function(con) print("mqtt connected") end)
m:on("offline", function(con) print("mqtt offline") end)
m:on("message", dispatchMessage)
m:lwt(topic_prefix .. "/status", "offline", 0, 0)

function getBrightness()
    return adc.read(0) / 1024 * 100
end

local lastBrightness = 0
local scheduleBrightness
local publishBrightness = function(m)
    brightness = getBrightness()
    if math.abs(lastBrightness - brightness) > 1 then
        --print("Sending brightness update ", brightness)
        lastBrightness = brightness
        m:publish(topic_prefix .. "/brightness", brightness, 0, 0, function(conn)
            scheduleBrightness(m)
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
            m:subscribe(light_command, 0, function(con) print("Subscribed", light_command) end)
            publishBrightness(m)
        end)
    else
        print("Waiting for WIFI")
    end
end)