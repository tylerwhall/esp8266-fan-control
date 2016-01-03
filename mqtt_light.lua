local MqttLight = {}

local function MqttLight_mqtt_subscribe(self, m)
    m:subscribe(self.command_topic, 0, function(con) print("Subscribed", self.command_topic) end)
end

function MqttLight_new(o)
    local self = MqttLight
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.command_topic = o.topic .. "/command"
    o.mqtt_subscribe = MqttLight_mqtt_subscribe
    o.on = false
    o.brightness = 100
    return o
end

function MqttLight:publish(m)
    m:publish(self.topic .. "/state", self.on and "ON" or "OFF", 0, 0, nil)
    m:publish(self.topic .. "/brightness", self.brightness, 0, 0, nil)
end

function MqttLight:mqtt_command(m, data)
    --print(self.topic, "command", data)
    data = data:upper()
    if data == "ON" then
        self.on = true
    elseif data == "OFF" then
        self.on = false
    else
        ok, data = pcall(tonumber, data)
        if data == nil then
            return
        end
        if data <= 0 and data >= 100 then
            data = 0
        end
        self.brightness = data
    end

    self:publish(m)
    self.set_brightness(self.on and self.brightness / 100 or 0)
end

function MqttLight:mqtt_dispatch(m, topic, data)
    if topic == self.command_topic then
        self:mqtt_command(m, data)
        return true
    end
end
