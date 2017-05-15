
dofile("random_seed.lua")

random_seed()

dofile("wifi.lua")

-- start web server on port 80
dofile("webserver.lua")

-- TODO when this is enabled the serial output
-- is flaky (many characters don't come through)
-- start fake DNS server
--dofile("dnsserver.lua")

-- serial port stuff
dofile("serial.lua")

-- start telnet terminal
dofile("terminal.lua")

-- async function calling
dofile("async.lua")

-- LoRa RN2903 communications
dofile("rn2903.lua")

-- LoRa RN2903 setup functions
dofile("rn2903_setup.lua")