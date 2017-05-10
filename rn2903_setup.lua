


-- configure RN2903 for radio communication
function loraSetup1(cb)
  -- disable layer 2
  loraCmd("mac pause", function(maxPauseTime)
    -- set LoRa modulation mode
    loraCmd("radio set mod lora", function(resp)
      if resp ~= "ok" then
        return cb("Could not switch radio into LoRa modulation mode: "..resp)
      end
      -- set frequency
      loraCmd("radio set freq 902000000", function(resp)
        if resp ~= "ok" then
          return cb("Could not set radio frequency: "..resp)
        end
        -- setting power to 20 equates to setting 18.5 dBm output power
        -- See page 7 http://ww1.microchip.com/downloads/en/DeviceDoc/50002390B.pdf
        loraCmd("radio set pwr 20", function(resp)
          if resp ~= "ok" then
            return cb("Could not set radio output power: "..resp)
          end
          return cb(false)
        end)
      end)
    end)
  end)
end



function loraSetup2(cb)
  -- set largest spreading factor (slowest, longest range)
  loraCmd("radio set sf sf12", function(resp)
    if resp ~= "ok" then
      return cb("Could not set LoRa spreading factor: "..resp)
    end
    -- disable CRC header
    loraCmd("radio set crc off", function(resp)
      if resp ~= "ok" then
        return cb("Could not disable radio CRC header: "..resp)
      end
      -- set the coding rate to 4/8
      -- it is the ratio between actual data and error correction data
      -- the ratio is <bits-of-actual-data>/<total-bits-sent>
      loraCmd("radio set cr 4/8", function(resp)
        if resp ~= "ok" then
          return cb("Could not set radio coding rate: "..resp)
        end
        -- set the Sync word to 0x42
        loraCmd("radio set sync 42", function(resp)
          if resp ~= "ok" then
            return cb("Could not set sync word: "..resp)
          end
          -- set bandwidth to 500 kHz (maximum)
          loraCmd("radio set bw 500", function(resp)
            if resp ~= "ok" then
              return cb("Could not set radio bandwidth: "..resp)
            end
            return cb(false)
          end)
        end)
      end)
    end)
  end)
end

function loraSetup(cb)
  loraSetup1(function(ret)
    if not ret then
      return cb(ret)
    end
    loraSetup2(cb)
  end)
end
