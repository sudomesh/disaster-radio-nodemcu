
dofile("interpret.lua")

debugSocket = nil

function sdebug(data)
  if debugSocket then
    debugSocket:send("[serial-receive] "..data.."\n")
  end
end

srv=net.createServer(net.TCP)
srv:listen(23, function(conn)

  local ret
  local out
  local cmd = ""

  debugSocket = conn
  switchSerial(nil)

--  switchSerial(function(data)
--    conn:send("[serial-receive] "..data.."\n")
--  end)

  conn:send("\n~ DisasterRadio debug console ~\n\n> ")

  conn:on("disconnection", function(conn)
    debugSocket = nil
--    node.output()
  end)

  conn:on("receive", function(conn, payload)

    -- submit command to lua interpreter
--    node.input(payload)

    ret = string.find(payload, "\n")
    if ret ~= nil then
      cmd = cmd..string.sub(payload, 1, ret-1)

      -- the telnet protocol sends two-byte control sequences
      -- where the first byte is always 0xff
      -- so remove all two-byte sequeces starting with 0xff
      -- TODO support 247 "erase character" and 248 "erase line"
      cmd = cmd:gsub(string.char(0xff)..'.', '')

      out = run(cmd)
      conn:send(out.."\n> ")
      if string.len(payload) > ret then
        cmd = string.sub(payload, ret+1, string.len(payload))
      else
        cmd = ""
      end
    else
      cmd = cmd..payload
    end

  end)
end)

