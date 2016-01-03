local BEDROOM_FAN_ADDR = 0xe

-- 21-bit fan commands
local FAN21_FANHIGH   = 0x2
local FAN21_FANMED    = 0x1
local FAN21_FANLOW    = 0x0
local FAN21_FANOFF    = 0x3
local FAN21_INTENSITY_MAX = 0x3e
local FAN21_INTENSITY_MIN = FAN21_INTENSITY_MAX * 0.3
local FAN21_LIGHT_OFF     = 0x3f

-- light is a float intensity between 0 and 1
local fan_cmd21 = function(addr, count, light, fan)
    local addr = addr_reverse(bit.band(addr, 0xf))
    if light == 0 then
        light = FAN21_LIGHT_OFF
    else
        -- Fan seems to reject commands with intensity less than slightly under 30%
        light = math.floor(light * (FAN21_INTENSITY_MAX - FAN21_INTENSITY_MIN)) + FAN21_INTENSITY_MIN
    end
    -- Command is 8 bits
    local cmd = bit.bor(
            bit.lshift(light, 2),
            bit.band(fan, 0x3))

    -- Data 0 is address and some ones
    local data0 = bit.bor(
            bit.lshift(0x7, 5),
            bit.lshift(addr, 1),
            1)
    -- Data 1 is command
    local data1 = cmd
    --print(string.format("21bit 0x%x 0x%x", data0, data1))
    return i2c_tx(1, count, data0, data1)
end

local function _bedroom_fan_cmd(intensity, fan)
    print("Bedroom fan cmd", intensity, fan)
    if fan == FAN_HIGH then
        fan = FAN21_FANHIGH
    elseif fan == FAN_MED then
        fan = FAN21_FANMED
    elseif fan == FAN_LOW then
        fan = FAN21_FANLOW
    else
        fan = FAN21_FANOFF
    end
    return fan_cmd21(BEDROOM_FAN_ADDR, 30, intensity, fan)
end

function bedroom_fan_cmd(intensity, fan)
    return assert(loadfile("fan21.lua"))(intensity, fan)
end

local arg={...}
if #arg == 2 then
    return _bedroom_fan_cmd(arg[1], arg[2])
end