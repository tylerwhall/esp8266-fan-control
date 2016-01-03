local m = mqtt.Client("livingroom", 10, "user", "password")
local topic_prefix = "home/livingroom"

local bedroom_fan = MqttFan_new {
    topic = "home/bedroom/fan",
    set_speed = bedroom_fan_set_speed
}

local bedroom_light = MqttLight_new {
    topic = "home/livingroom/fancontroller/led",
    set_brightness = function(brightness)
        led_color(0, brightness, 0)
    end
}

local led = MqttLight_new {
    topic = "home/bedroom/fan/light",
    set_brightness = function(brightness)
        print("Fan set brightness", brightness)
        bedroom_fan_set_brightness(brightness)
    end
}

local livingroom_fan = MqttFan_new {
    topic = "home/livingroom/fan",
    set_speed = livingroom_fan_set_speed
}

local livingroom_light = MqttLight_new {
    topic = "home/livingroom/fan/light",
    set_brightness = function(brightness)
        print("Livingroom fan set brightness (toggle)", brightness)
        livingroom_fan_light_toggle()
    end,
    -- No status updates - only toggle capability
    publish = function() end
}

MqttFan_new = nil
MqttLight_new = nil

local mqtt_nodes = {
    bedroom_fan,
    bedroom_light,
    led,
    livingroom_fan,
    livingroom_light,
}

local function dispatchMessage(con, topic, data)
    print("Message", topic, data)
    if topic == nil or data == nil then
        return
    end
    for k, v in pairs(mqtt_nodes) do
        if v:mqtt_dispatch(m, topic, data) then
            return
        end
    end
end

m:on("connect", function(con) print("mqtt connected") end)
m:on("offline", function(con) print("mqtt offline") end)
m:on("message", dispatchMessage)
m:lwt(topic_prefix .. "/status", "offline", 0, 0)


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
            for k, v in pairs(mqtt_nodes) do
                v:mqtt_subscribe(m)
            end
            for k, v in pairs(mqtt_nodes) do
                v.mqtt_subscribe = nil
            end
            --publishBrightness(m)
        end)
    else
        print("Waiting for WIFI")
    end
end)
