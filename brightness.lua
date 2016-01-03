local lastBrightness = 0
local scheduleBrightness

function publishBrightness()
    brightness = adc.read(0) / 1024 * 100
    if math.abs(lastBrightness - brightness) > 1 then
        --print("Sending brightness update ", brightness)
        lastBrightness = brightness
        m:publish("home/livingroom/brightness", brightness, 0, 0, scheduleBrightness)
    else
        --print("Brightness", brightness, "similar to", lastBrightness, "No update")
        scheduleBrightness(nil)
    end
end

scheduleBrightness = function(conn)
    tmr.alarm(0, 500, 0, publishBrightness)
end
