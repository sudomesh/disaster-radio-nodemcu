

function loraSetup(cb) 
  if not cb then
    cb = function(err) end
  end
  eachSerial({
    loraDisableMAC,
    loraSetModulation,
    loraSetFrequency,
    loraSetTXPower,
    loraSetSpreadingFactor,
    loraSetCRC,
    loraSetCodingRate,
    loraSetSyncWord,
    loraSetBandwidth
  }, cb)
end

function loraDisableMAC(cb)
  loraCmd("mac pause", function(maxPauseTime)
    if maxPauseTime == "0" then
      return cb("Could not pause MAC")
    end
    cb(nil)
  end)
end

-- set LoRa modulation mode to LoRa
function loraSetModulation(cb)
  loraCmd("radio set mod lora", function(resp)
    if resp ~= "ok" then
      return cb("Could not switch radio into LoRa modulation mode: "..resp)
    end
    cb(nil)
  end)
end

-- set radio frequency
function loraSetFrequency(cb)
  loraCmd("radio set freq 902000000", function(resp)
    if resp ~= "ok" then
      return cb("Could not set radio frequency: "..resp)
    end
    cb(nil)
  end)
end

-- set power to 20 equates to setting 18.5 dBm output power
function loraSetTXPower(cb)
  -- See page 7 http://ww1.microchip.com/downloads/en/DeviceDoc/50002390B.pdf
  loraCmd("radio set pwr 20", function(resp)
    if resp ~= "ok" then
      return cb("Could not set radio output power: "..resp)
    end
    cb(nil)
  end)
end


-- set largest spreading factor (slowest, longest range)
function loraSetSpreadingFactor(cb)
  loraCmd("radio set sf sf12", function(resp)
    if resp ~= "ok" then
      return cb("Could not set LoRa spreading factor: "..resp)
    end
    cb(nil)
  end)
end


-- disable CRC header
function loraSetCRC(cb)
  loraCmd("radio set crc off", function(resp)
    if resp ~= "ok" then
      return cb("Could not disable radio CRC header: "..resp)
    end
    cb(nil)
  end)
end

-- set the coding rate to 4/8
-- it is the ratio between actual data and error correction data
-- the ratio is <bits-of-actual-data>/<total-bits-sent>
function loraSetCodingRate(cb)
  loraCmd("radio set cr 4/8", function(resp)
    if resp ~= "ok" then
      return cb("Could not set radio coding rate: "..resp)
    end
    cb(nil)
  end)
end

-- set the Sync word to 0x42
function loraSetSyncWord(cb)
  loraCmd("radio set sync 42", function(resp)
    if resp ~= "ok" then
      return cb("Could not set sync word: "..resp)
    end
    cb(nil)
  end)
end

-- set bandwidth to 500 kHz (maximum)
function loraSetBandwidth(cb)
  loraCmd("radio set bw 500", function(resp)
    if resp ~= "ok" then
      return cb("Could not set radio bandwidth: "..resp)
    end
    cb(nil)
  end)
end
