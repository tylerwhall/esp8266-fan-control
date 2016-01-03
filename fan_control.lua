local bedroom_fan_intensity = 0
local bedroom_fan_speed = FAN_OFF
local bedroom_fan_needs_update = false
local i2c_tries = 0

local function fan_update()
    if bedroom_fan_needs_update then
        if bedroom_fan_cmd(bedroom_fan_intensity, bedroom_fan_speed) then
            bedroom_fan_needs_update = false
        else
            i2c_tries = i2c_tries + 1
        end
    end

    if bedroom_fan_needs_update then
        if i2c_tries <= 10 then
            tmr.alarm(I2C_RETRY_TIMER, 500, 0, fan_update)
        else
            print("I2C Timed Out")
        end
    end
end

function bedroom_fan_set(intensity, speed)
    bedroom_fan_intensity = intensity
    bedroom_fan_speed = speed
    bedroom_fan_needs_update = true
    i2c_tries = 0
    fan_update()
end