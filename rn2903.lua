
loraConnected = false

function loraCmd(cmd, cb)

  uart.write(0, cmd.."\r\n")

  uart.on("data", "\n", function(data)
    uart.on("data", "\n", nil, 0)

    -- strip trailing \r\n
    data = string.sub(data, 1, -3)
    if cb then
      cb(data)
    end
    sdebug(data)
  end, 0)
end


function loraInit(cb)
  loraCmd("sys get ver", function(data)
    if string.sub(data, 1, 6) == "RN2903" then
      sdebug("RN2903 chip is connected")
      loraConnected = true
      if cb then
        cb(true)
      end
    else
      sdebug("RN2903 chip sent garbage response")
      if cb then
        cb(false)
      end
    end
  end)
end
