MqttFan = { speed = FAN_OFF }

local function speed_map(speed)
    if speed == FAN_HIGH then return "High"
    elseif speed == FAN_MED then return "Medium"
    elseif speed == FAN_LOW then return "Low"
    else return "Off"
    end
end

function MqttFan:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.speed_topic = o.topic .. "/speed"
    o.command_topic = o.topic .. "/command"
    return o
end

function MqttFan:publish(m)
    m:publish(self.speed_topic, speed_map(self.speed), 0, 0, nil)
end

function MqttFan:mqtt_command(m, data)
    print(self.topic, "command", data)
    if not type(data) == "string" then
        return
    end
    data = data:upper()
    if data == "HIGH" then
        self.speed = FAN_HIGH
    elseif data == "MED" or data == "MEDIUM" then
        self.speed = FAN_MED
    elseif data == "LOW" then
        self.speed = FAN_LOW
    elseif data == "OFF" then
        self.speed = FAN_OFF
    else
        return
    end

    self:publish(m)
    self.set_speed(self.speed)
end

function MqttFan:mqtt_dispatch(m, topic, data)
    if topic == self.command_topic then
        self:mqtt_command(m, data)
        return true
    end
end

function MqttFan:mqtt_subscribe(m)
    m:subscribe(self.command_topic, 0, function(con) print("Subscribed") end)
end