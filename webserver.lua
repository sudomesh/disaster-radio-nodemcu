
function sendFile(sck, filename)
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

  local function send(c)
    buf = f:read(1024)
    if buf then
      c:send(buf)
    else
      c:close()
      f:close()
    end
    buf = nil

  end
  
  sck:on("sent", send)

  send(sck)

end


function sendString(sck, str, status)
  status = status or "200 OK"

  local response = {}
  response[#response + 1] = "HTTP/1.1 "..status.."\r\nContent-Type: text/plain\r\n\r\n"..str

  local function send(c)
    if #response > 0 then
      c:send(table.remove(response, 1))
    else
      collectgarbage()
      response = nil
      c:close()
    end
  end

  sck:on("sent", send)
  send(sck)

end

function sendString400(conn, str)
  sendString(conn, str, "400 Bad Request")
end

function sendString503(conn, str)
  sendString(conn, str, "502 Service Temporarily Unavailable")
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

      elseif reqfile == "/receive" then

        sendString(conn, loraGetReceived())

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
