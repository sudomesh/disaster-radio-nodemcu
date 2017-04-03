
-- wifi.setmode(wifi.STATIONAP)
-- use only AP for now since STATIONAP wasn't working
-- wifi.setmode(wifi.SOFTAP)
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

srv=net.createServer(net.TCP)
srv:listen(80, function(conn)
  conn:on("receive", function(conn, payload)
    print(payload)
    local reqfile = string.sub(payload, string.find(payload,"GET /")+5, string.find(payload,"HTTP/")-2)
    if reqfile == "" then reqfile = "index.html" end

    local f = file.open(reqfile, "r")

    if f == nil then
      f = file.open("404.html", "r")
		end

    local buf = ""
    local line
    repeat
      line = f:read()
      if line then
        buf = buf..line
      end
    until line == nil

    print(buf)
    conn:send(buf, function(sent) 
      f:close()
      conn:close()
      f = nil
      reqfile = nil
    end)

  end)
end)
