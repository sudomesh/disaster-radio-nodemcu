
dofile("interpret.lua")

srv=net.createServer(net.TCP)
srv:listen(23, function(conn)

  local ret
  local out
  local cmd = ""
  
  conn:send("\n~ DisasterRadio debug console ~\n\n> ")

  -- redirect lua interpreter output
--  node.output(function(str)
--    conn:send(str)
--  end, 1)

  conn:on("disconnection", function(conn)
--    node.output()
  end)

  conn:on("receive", function(conn, payload)

    -- submit command to lua interpreter
--    node.input(payload)

    ret = string.find(payload, "\n")
    if ret ~= nil then
      cmd = cmd..string.sub(payload, 1, ret-1)

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

