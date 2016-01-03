local bedroom_fan_intensity = 0
local bedroom_fan_speed = FAN_OFF
local bedroom_fan_needs_update = false
local lvgroom_fan_speed = FAN_OFF
local lvgroom_fan_needs_toggle = false
local lvgroom_fan_needs_update = false
local i2c_tries = 0

local function fan_update_try()
    if lvgroom_fan_needs_toggle then
        if livingroom_fan_cmd(FAN_LIGHT) then
            lvgroom_fan_needs_toggle = false
        else
            return false
        end
    end
    if lvgroom_fan_needs_update then
        if livingroom_fan_cmd(lvgroom_fan_speed) then
            lvgroom_fan_needs_update = false
        else
            return false
        end
    end
    if bedroom_fan_needs_update then
        if bedroom_fan_cmd(bedroom_fan_intensity, bedroom_fan_speed) then
            bedroom_fan_needs_update = false
        else
            return false
        end
    end
    return true
end

local function fan_update()
    if not fan_update_try() then
        i2c_tries = i2c_tries + 1
        if i2c_tries <= 10 then
            tmr.alarm(I2C_RETRY_TIMER, 500, 0, fan_update)
        else
            print("I2C Timed Out")
        end
    end
end

local function fan_change()
    i2c_tries = 0
    fan_update()
end

function bedroom_fan_set_brightness(brightness)
    bedroom_fan_intensity = brightness
    bedroom_fan_needs_update = true
    fan_change()
end

function bedroom_fan_set_speed(speed)
    bedroom_fan_speed = speed
    bedroom_fan_needs_update = true
    fan_change()
end

function livingroom_fan_set_speed(speed)
    lvgroom_fan_needs_update = true
    lvgroom_fan_speed = speed
    fan_change()
end

function livingroom_fan_light_toggle()
    lvgroom_fan_needs_toggle = true
    fan_change()
end