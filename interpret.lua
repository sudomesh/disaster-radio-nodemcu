
-- an attempt at something better than node.input() / node.output()
-- since node.output still doesn't redirect errors
-- which makes it pretty useless for debugging

function run(cmd)

  local func
  local err
  local status

  -- turn string into function
  -- err will contain any parser errors
  func, err = loadstring(cmd)

  if err then
    return err
  end

  -- intercept print function calls
  -- TODO also deal with IO:write and IO.stdout
  local oldprint = print
  local out = ""
  print = function(...)
    for i,v in ipairs(arg) do
      out = out.." "..tostring(v)
    end
  end

  -- call function and catch error
  status, err = pcall(func)
  print = oldprint -- restore print function

  if not status then
    out = out..err
  end
 
  return out
end
