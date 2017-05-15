
-- Use the MAC address to seed the math.random() function.
-- This is pretty terrible but it's an improvement on the default
-- where all the boards will use the same seed.
-- Now at least each board will have its own random seed
-- but it will be the same on each boot. 
-- We should _not_ use math.random for anything security related
-- until this is solved. Apparently ESP8266 has a hardware RNG
-- but nodemcu does not have an API for it.

function random_seed()
  mac = wifi.sta.getmac()
  mac = mac:gsub(":", "")
   -- only use last 7 chars so we don't overflow the int
  mac = "0x"..mac:sub(6)
  mac = tonumber(mac)
  math.randomseed(mac)
end