
-- from https://github.com/tuanpmt/lua-async
function async(tasks, cb)
	local nextArg = {}
	for i, v in pairs(tasks) do
		local error = false
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