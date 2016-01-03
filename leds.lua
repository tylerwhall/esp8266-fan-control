local gpio_r = 8 --15
local gpio_g = 6 --12
local gpio_b = 7 --13

led_r = 0
led_g = 0
led_b = 0

local function init()
    pwm.setup(gpio_r, 100, 0)
    pwm.setup(gpio_g, 100, 0)
    pwm.setup(gpio_b, 100, 0)
    pwm.start(gpio_r)
    pwm.start(gpio_g)
    pwm.start(gpio_b)
end

local function led_update()
    pwm.setduty(gpio_r, 1023*led_r)
    pwm.setduty(gpio_g, 1023*led_g)
    pwm.setduty(gpio_b, 1023*led_b)
end

local function _led_color(r, g, b)
    led_r = r
    led_g = g*.1
    led_b = b*.1
    led_update()
end

local arg={...}
if #arg == 0 then
    init()
    _led_color(0, 0, 1)
else
    _led_color(unpack(arg))
end

function led_color(r, g, b)
    assert(loadfile("leds.lua"))(r, g, b)
end