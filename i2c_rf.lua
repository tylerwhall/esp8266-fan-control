gpio_scl = 3 --0
gpio_sda = 4 --2

--gpio.mode(gpio_scl, gpio.INPUT)
--gpio.mode(gpio_sda, gpio.INPUT)
--gpio.write(gpio_scl, gpio.LOW)

local bus = 0
local address = 0x46

-- 12-bit fan commands
local FAN12_LIGHT   = 0x01
local FAN12_FANHIGH = 0x20
local FAN12_FANMED  = 0x10
local FAN12_FANLOW  = 0x08
local FAN12_FANOFF  = 0x02

-- 21-bit fan commands
local FAN21_FANHIGH   = 0x2
local FAN21_FANMED    = 0x1
local FAN21_FANLOW    = 0x0
local FAN21_FANOFF    = 0x3
local FAN21_INTENSITY_MAX = 0x3e
local FAN21_LIGHT_OFF     = 0x3f

FAN_OFF     = 0
FAN_HIGH    = 3
FAN_MED     = 2
FAN_LOW     = 1

local LIVINGROOM_FAN_ADDR = 0x9
local BEDROOM_FAN_ADDR = 0xe

local _i2c_tx = function(bits1221, count, data0, data1)    
    i2c.start(bus)
    if not i2c.address(bus, address, i2c.TRANSMITTER) then
        print("i2c no address ack")
        return false
    end
    local len = i2c.write(bus, string.char(bits1221, count, data0, data1))
    if len ~= 4 then
        print("Bad write length", len)
        return false
    end
    return true
end

local i2c_tx = function(...)
    local ret = _i2c_tx(unpack(arg))
    i2c.stop(bus)
    return ret
end

local addr_reverse = function(addr)
    return bit.bor(
            bit.lshift(bit.band(addr, 1), 3),
            bit.lshift(bit.band(addr, 2), 1),
            bit.rshift(bit.band(addr, 4), 1),
            bit.rshift(bit.band(addr, 8), 3))
end

local fan_cmd12 = function(addr, count, cmd)
    addr = addr_reverse(bit.band(addr, 0xf))
    cmd = bit.band(cmd, 0x3f)
    local data0 = bit.bor(bit.lshift(1, 7), bit.lshift(addr, 3), bit.rshift(cmd, 4))
    local data1 = bit.band(cmd, 0xf)
    print(string.format("12bit 0x%x 0x%x", data0, data1))
    i2c_tx(0, count, data0, data1)
end

-- light is a float intensity between 0 and 1
local fan_cmd21 = function(addr, count, light, fan)
    local addr = addr_reverse(bit.band(addr, 0xf))
    print(light, FAN21_INTENSITY_MAX)
    if not light then
        light = FAN21_LIGHT_OFF
    else
        light = math.floor(light * FAN21_INTENSITY_MAX)
    end
    print(light, bit.lshift(light, 0), bit.lshift(light, 2))
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
    print(string.format("21bit 0x%x 0x%x", data0, data1))
    i2c_tx(1, count, data0, data1)
end


function livingroom_fan_cmd(cmd)
    fan_cmd12(LIVINGROOM_FAN_ADDR, 20, cmd)
end

function bedroom_fan_cmd(intensity, fan)
    if fan == FAN_HIGH then
        fan = FAN21_FANHIGH
    elseif fan == FAN_MED then
        fan = FAN21_FANMED
    elseif fan == FAN_LOW then
        fan = FAN21_FANLOW
    else
        fan = FAN21_FANOFF
    end
    fan_cmd21(BEDROOM_FAN_ADDR, 60, intensity, fan)
end

local function fan_cmd2()
    bedroom_fan_cmd(.5, FAN_LOW)
    tmr.alarm(1, 2500, 0, function() fan_cmd() end)
end

fan_cmd = function()
    livingroom_fan_cmd(FAN12_LIGHT)
    tmr.alarm(1, 2500, 0, fan_cmd2)
end

i2c.setup(bus, gpio_sda, gpio_scl, i2c.SLOW)

fan_cmd()