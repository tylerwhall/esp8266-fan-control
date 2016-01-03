local LIVINGROOM_FAN_ADDR = 0x9

-- 12-bit fan commands
local FAN12_LIGHT   = 0x01
local FAN12_FANHIGH = 0x20
local FAN12_FANMED  = 0x10
local FAN12_FANLOW  = 0x08
local FAN12_FANOFF  = 0x02

local function fan_cmd12(addr, count, cmd)
    addr = addr_reverse(bit.band(addr, 0xf))
    cmd = bit.band(cmd, 0x3f)
    local data0 = bit.bor(bit.lshift(1, 7), bit.lshift(addr, 3), bit.rshift(cmd, 4))
    local data1 = bit.band(cmd, 0xf)
    --print(string.format("12bit 0x%x 0x%x", data0, data1))
    return i2c_tx(0, count, data0, data1)
end

local function _livingroom_fan_cmd(cmd)
    print("Livingroom fan cmd", cmd)
    if cmd == FAN_HIGH then
        cmd = FAN12_FANHIGH
    elseif cmd == FAN_MED then
        cmd = FAN12_FANMED
    elseif cmd == FAN_LOW then
        cmd = FAN12_FANLOW
    elseif cmd == FAN_OFF then
        cmd = FAN12_FANOFF
    else
        cmd = FAN12_LIGHT
    end
    return fan_cmd12(LIVINGROOM_FAN_ADDR, 20, cmd)
end

function livingroom_fan_cmd(cmd)
    print(cmd)
    return assert(loadfile("fan12.lua"))(cmd)
end

local arg={...}
print(#arg)
if #arg == 1 then
    return _livingroom_fan_cmd(arg[1])
end