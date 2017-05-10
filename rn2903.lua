
loraConnected = false

-- If expectLines is set and is higher than 1
-- then this function will expect a response of that number of lines
-- from the RN2903 chip, but will return only a single line if
-- the first line from the RN2903 isn't "ok\r\n"
-- This is used for the "radio tx" and "radio rx" commands
function loraCmd(cmd, cb, expectLines)
  if not expectLines then
    expectLines = 1
  end

  lines = {}
  lineCount = 1

  uart.write(0, cmd.."\r\n")

  uart.on("data", "\n", function(data)
    if (lineCount + 1) >= expectLines then
      uart.on("data", "\n", nil, 0)
    end

    -- strip trailing \r\n
    data = string.sub(data, 1, -3)

    sdebug(data)

    if cb then
      if expectLines <= 1 then
        return cb(data)
      end
      lines[lineCount] = data

      if lineCount == 1 and data ~= "ok" then
        return cb(data)
      end      

      lineCount = lineCount + 1

      if lineCount >= expectLines then
        return cb(data)
      end
    end
  end, 0)
end


-- check if we can talk to RN2903 LoRa device
-- via serial
function loraCheckConnection(cb)
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


-- Expects a hex string
-- e.g. "baz" consists of 0x62, 0x61 and 0x7a
-- and should be sent to this function as "62617a"
-- If a hex value is less than 10 then it must be padded with a zero e.g. "09"
function loraTransmit(data, cb)
  if string.len(data) < 2 or string.len(data) > 510 then
    return cb("data must be a string of 1 to 255 two-character hex values")
  end
  loraCmd("radio tx "..data, function(resp)
    if table.getn(resp) < 2 then
      return cb("Radio transmit failed: "..resp[1])
    end
    if resp[2] ~= "radio_tx_ok" then
      return cb("Radio transmit failed: "..resp[2])
    end
    cb(nil)
  end) 
end

-- calls back with cb(err, [data])
-- where data is a string of two-characte per byte hex numbers
-- same as described for loraTransmit
function loraReceive(rxWindowSize, cb)
  loraCmd("radio rx "..rxWindowSize, function(resp)
    if table.getn(resp) < 2 then
      return cb("Radio receive failed: "..resp[1])
    end
    if string.sub(resp[2], 1, 8) ~= "radio_rx" then
      return cb("Radio receive failed: "..resp[2])
    end
    cb(nil, string.sub(resp[2], 8))
  end) 
end

