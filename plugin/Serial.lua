local SandboxEnv = require(script.Parent.SandboxEnv)

local Serial = {}

function Serial.SerializeValue(data, depth)
	local ty = typeof(data)
	local indent = ("  "):rep(depth)

	local str
	if ty == 'number' or ty == 'boolean' then
		str = tostring(data)
	elseif ty == 'string' then
		str = string.format("%q", data)
	elseif ty == 'table' and #data > 0 then
		-- array
		str = { "{" }

		for i = 1, #data do
			str[#str+1] = string.format("%s  %s,", indent, Serial.SerializeValue(data[i], depth + 1))
		end

		str[#str+1] = indent.."}"
	elseif ty == 'table' then
		-- dict
		str = { "{" }

		local ident = "^([%a_][%w_]*)$"
		local keys = {}
		for key, value in pairs(data) do
			keys[#keys+1] = key
		end
		table.sort(keys)
		for i = 1, #keys do
			local key = keys[i]
			local value = data[key]
			local safeKey
			if typeof(key) == 'string' and key:match(ident) then
				safeKey = key
			else
				safeKey = Serial.SerializeValue(key, depth + 1)
			end
			str[#str+1] = string.format("%s  %s = %s,", indent, safeKey, Serial.SerializeValue(value, depth + 1))
		end

		str[#str+1] = indent.."}"
	else
		error("Unexpected type: "..ty)
	end

	if typeof(str) == 'table' then
		str = table.concat(str, '\n')
	end
	return str
end

function Serial.Serialize(data)
	return "return ".. Serial.SerializeValue(data, 0)
end

function Serial.Deserialize(string)
	local func = loadstring(string)
	setfenv(func, SandboxEnv.lson())
	return func()
end

return Serial
