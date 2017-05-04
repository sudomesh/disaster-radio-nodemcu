
-- switches the serial from being a debugging interface 
-- to talking to the RN2903

function switchSerial(receive)

--  print("Connecting serial port to RN2903")
--  print("Your serial debug console will be disabled until next reboot")

  -- disable lua interpreter serial output
  node.output(function(str)
    -- throwing away the output
  end, 0)

  -- switch the serial to talking to RN2903
  uart.alt(1)
  -- RN2903 default settings are: 57600, 8N1, no echo
  uart.setup(0, 57600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)

  if receive then
    uart.on("data", "\n", receive, 0)
  else
    uart.on("data", "\n", nil, 0)
  end
end