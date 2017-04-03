
srv=net.createServer(net.TCP)
srv:listen(80, function(conn)
  conn:on("receive", function(conn, payload)
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

    conn:send(buf, function(sent) 
      f:close()
      conn:close()
      f = nil
      reqfile = nil
    end)

  end)
end)
