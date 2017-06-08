
function sendFile(conn, filename)
  local f
  local buf
  local head = "HTTP/1.1 200 OK\r\n"

  if filename ~= nil then
    f = file.open(filename, "r")
  else
    f = nil
  end

  if f == nil then
    f = file.open("404.html", "r")
    head = "HTTP/1.1 404 Not Found\r\n"
  end

--  head = head.."Content-Type: text/html\r\n\r\n"
  head = head.."\r\n\r\n"

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
  conn:send(head)

end


function sendString(conn, str, status)
  status = status or "200 OK"
  str = "HTTP/1.1 "..status.."\r\nContent-Type: text/plain\r\n\r\n"..str

  conn:send(str, function(sent)
    conn:close()
  end)
end

function sendString400(conn, str)
  sendString(conn, str, "400 Bad Request")
end

function sendString503(conn, str)
  sendString(conn, str, "503 Service Temporarily Unavailable")
end

srv=net.createServer(net.TCP)
srv:listen(80, function(conn)
  conn:on("disconnection", function(conn)
    node.output()
  end)
  conn:on("receive", function(conn, payload)
    local buf
    local reqfile
    
    if string.sub(payload, 1, 3) == "GET" then

      reqfile = string.sub(payload, string.find(payload,"GET /")+5, string.find(payload,"HTTP/")-2)

      if reqfile == "" then reqfile = "index.html" end

      sendFile(conn, reqfile)

    elseif string.sub(payload, 1, 4) == "POST" then

      reqfile = string.sub(payload, string.find(payload,"POST /")+5, string.find(payload,"HTTP/")-2)

      local bodyStart = string.find(payload,"\r\n\r\n")
      if bodyStart == nil then
        sendString(conn, "POST body is missing")
        return
      end

      bodyStart = bodyStart + 4

      local body = string.sub(payload, bodyStart, string.len(payload))

      local argStart = string.find(body, "arg=")

      if argStart == nil then
        sendString400(conn, "POST body has no arg parameter")
        return  
      end

      argStart = argStart + 4

      local arg = string.sub(body, argStart, string.len(body))

      if not arg or string.len(arg) < 1 then
        sendString400(conn, "POST body has empty arg parameter")
        return
      end


      if reqfile == "/transmit" then

        if string.len(arg) > 512 then
          sendString400(conn, "Attempted to transmit more than 256 bytes (max packet size)")
          return
        end

        if loraQueueTransmission(arg) then
          sendString(conn, "Successfully queued packet for transmission")
        else
          sendString503(conn, "Could not queue packet. Transmission queue is full.")
        end

      elseif reqfile == "/chat" then

      elseif reqfile == "/console" then

        -- redirect lua interpreter output
        node.output(function(str)
          conn:send(str, function(sent)
            node.output(nil)
            conn:close()
          end)
        end, 1)
 
        -- submit command to lua interpreter
        node.input(arg)

      else
        sendFile(conn, nil) -- send 404
      end

    else 

    end
  end)
end)
