local gpio_scl = 3 --0
local gpio_sda = 4 --2

local bus = 0
local address = 0x46

FAN_OFF     = 0
FAN_HIGH    = 3
FAN_MED     = 2
FAN_LOW     = 1
FAN_LIGHT   = 4

local function _i2c_tx(bits1221, count, data0, data1)    
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

function i2c_tx(...)
    local ret = _i2c_tx(unpack(arg))
    i2c.stop(bus)
    return ret
end

function addr_reverse(addr)
    return bit.bor(
            bit.lshift(bit.band(addr, 1), 3),
            bit.lshift(bit.band(addr, 2), 1),
            bit.rshift(bit.band(addr, 4), 1),
            bit.rshift(bit.band(addr, 8), 3))
end

i2c.setup(bus, gpio_sda, gpio_scl, i2c.SLOW)