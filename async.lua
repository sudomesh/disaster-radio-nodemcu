
-- from https://github.com/tuanpmt/lua-async
function each(tasks, cb)
	local nextArg = {}
	for i, v in pairs(tasks) do
		local error = false
    sdebug("running")
		v(function(err, ...)
			local arg = {...}
		    nextArg = arg;
		    if err then
				error = true
			end
		end, unpack(nextArg))
		if error then return cb("error") end
	end
	cb(nil, unpack(nextArg))
end

function eachSerial(funcs, cb)
  local i = 1
        
  function runNext(err)
    if err then
      return cb(err)
    end
    i = i + 1
    if not funcs[i] then
      return cb()
    end
    funcs[i](runNext)
  end

  funcs[i](runNext)
end