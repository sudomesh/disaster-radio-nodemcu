
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
    if (expectLines > 0) and (lineCount >= expectLines) then
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

-- like loraCmd but times out after 200 ms
-- if no response is received from lora chip
function loraCmdT(cmd, cb, expectLines)
  local t = tmr.create()
  local timedOut = false
  t:alarm(200, function()
    timedOut = true
    cb("error: no response from lora chip")
  end)
  loraCmd(cmd, function(data)
    if timedOut then
      return nil
    end
    t:unregister()
    cb(data)
  end), expectLines)
end


-- check if we can talk to RN2903 LoRa device
-- via serial
function loraCheckConnection(cb)
  loraCmdT("sys get ver", function(data)
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
    if resp ~= "radio_tx_ok" then
      return cb("Radio transmit failed: "..resp)
    end
    cb()
  end, 2) 
end

-- calls back with cb(err, [data])
-- where data is a string of two-characte per byte hex numbers
-- same as described for loraTransmit
function loraReceive(rxWindowSize, cb)
  loraCmd("radio rx "..rxWindowSize, function(resp)
    if string.sub(resp, 1, 8) ~= "radio_rx" then
      return cb("Radio receive failed: "..resp)
    end
    cb(nil, string.sub(resp, 8))
  end, 2) 
end


function loraInit()
  loraCheckConnection(function(success)
    if not success then
      local t = tmr.create()
      t:alarm(200, function()
        loraInit() -- retry
      end)
      return
    end

    loraSetup(function(err)
      if err then
        local t = tmr.create()
        t:alarm(1000, function()
          loraInit() -- retry
        end)
        return        
      end

      loraTransceiveLoop()
    end)
  end)

end


-- TODO turn this into an actual queue
loraTransmitQueue = nil

-- interval is specified in "receive windows size" not ms
-- see RN2903 protocol datasheet for "radio rx"
function loraTransceiveLoop(interval)
  interval = interval or 500

  loraReceive(interval, function(err, data)
    if not err then
      handleReceived(data)
    end
    -- if there is something to transmit, then transmit it
    if loraTransmitQueue then
      loraTransmit(loraTransmitQueue, function(err)
        if not err then
          loraTransmitQueue = nil
        end
        loraTransceiveLoop(interval) 
      end)
    else
      loraTransceiveLoop(interval)
    end
  end)
end

function loraQueueTransmission(data)
  if loraTransmitQueue then
    return false
  end
  loraTransmitQueue = data
  return true
end

function handleReceived(data)
  -- TODO actually handle incoming data
end