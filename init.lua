

-- highest transmit power only available in 802.11b mode
wifi.setphymode(wifi.PHYMODE_B)

-- use only AP for now since STATIONAP wasn't working
wifi.setmode(wifi.SOFTAP)
ap_cfg = {
  ssid = "peoples-disaster-radio",
  channel = 1,
  beacon = 1000
}

--[[
wifi.ap.config(ap_cfg)
sta_cfg = {
  ssid = "peoplesopen.net",
  auto = true
}
wifi.sta.config(sta_cfg)
--]]

ip_cfg = {
  ip = "100.127.0.1",
  netmask = "255.192.0.0",
  gateway = "100.127.0.1"
}
wifi.ap.setip(ip_cfg)

-- Since the maximum number of connected clients is 4
-- the end of the DHCP range will be start + 4
dhcp_config = {
  start = "100.127.0.2"
}
wifi.ap.dhcp.config(dhcp_config)
wifi.ap.dhcp.start()

-- start web server on port 80
dofile("webserver.lua")

-- start fake DNS server
dofile("dnsserver.lua")

-- serial port stuff
dofile("serial.lua")

-- start telnet terminal
dofile("terminal.lua")