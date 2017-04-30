
function sendFileOld(conn, filename)
  local f

  if filename ~= nil then
    f = file.open(filename, "r")
  else
    f = nil
  end

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
  end)
end

function sendLines(conn, f)



end

function sendFile(conn, filename)
  local f
  local buf

  if filename ~= nil then
    f = file.open(filename, "r")
  else
    f = nil
  end

  if f == nil then
    f = file.open("404.html", "r")
  end

  if f == nil then
    print("FAIL")
  end  

  local function sender()

    buf = f:read(1024)
    if buf then
      conn:send(buf)
    else
      conn:close()
      f:close()
    end
  end

  conn:on("sent", sender)

  sender()
end


function sendString(conn, str)
  conn:send(str, function(sent)
    conn:close()
  end)
end

srv=net.createServer(net.TCP)
srv:listen(80, function(conn)
  conn:on("receive", function(conn, payload)
    local buf
    local reqfile
    
    if string.sub(payload, 1, 3) == "GET" then

      reqfile = string.sub(payload, string.find(payload,"GET /")+5, string.find(payload,"HTTP/")-2)

      if reqfile == "" then reqfile = "index.html" end

      sendFile(conn, reqfile)

    elseif string.sub(payload, 1, 4) == "POST" then

      reqfile = string.sub(payload, string.find(payload,"POST /")+5, string.find(payload,"HTTP/")-2)

      if reqfile == "/serial" then

        local bodyStart = string.find(payload,"\r\n\r\n")
        if bodyStart == nil then
          sendString(conn, "POST body is missing")
          return
        end

        bodyStart = bodyStart + 4

        local body = string.sub(payload, bodyStart, string.len(payload))

        local cmdStart = string.find(body, "cmd=")

        if cmdStart == nil then
          sendString(conn, "POST body has no cmd parameter")
          return  
        end

        cmdStart = cmdStart + 4

        local cmd = string.sub(body, cmdStart, string.len(body))

        conn:send(cmd, function(sent) 
          conn:close()
        end)

      else
        sendFile(conn, nil) -- send 404
      end

    else 

    end
  end)
end)
