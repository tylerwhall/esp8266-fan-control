gpio_r = 8 --15
gpio_g = 6 --12
gpio_b = 7 --13

local led_r = 0
local led_g = 0
local led_b = 0

pwm.setup(gpio_r, 100, 0)
pwm.setup(gpio_g, 100, 0)
pwm.setup(gpio_b, 100, 0)
pwm.start(gpio_r)
pwm.start(gpio_g)
pwm.start(gpio_b)

function led_update()
    pwm.setduty(gpio_r, 1023*led_r)
    pwm.setduty(gpio_g, 1023*led_g)
    pwm.setduty(gpio_b, 1023*led_b)
end

function led_color(r, g, b)
    led_r = r
    led_g = g*.1
    led_b = b*.1
    led_update()
end