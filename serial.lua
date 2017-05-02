
-- switches the serial from being a debugging interface 
-- to talking to the RN2903

function switchSerial(receive)

  print("Connecting serial port to RN2903")
  print("Your serial debug console will be disabled until next reboot")

  -- disable lua interpreter serial output
  node.output(function(str)
    -- throwing away the output
  end, 0)


  -- switch the serial to talking to RN2903
  uart.alt(1)
  -- 115200, 8N1, no echo
  uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)


  uart.on("data", "\r", function(data)
    receive(data)
  end, 0)
end