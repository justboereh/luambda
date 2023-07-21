local FILENAME_OUT = "/tmp/lua_result.log"
local FILENAME_ERR = "/tmp/lua_result_err.log"
local EVENTJSON = io.open("/tmp/invocation_event.log", "r"):read('a')
local ROOT = io.open("/tmp/invocation_root.log", "r"):read('a')

package.path = ROOT .. '/?.lua;/opt/runtime/?.lua;/opt/runtime/?.out;' .. package.path

local JSON = require('deps/json')

local function WriteFile(filename, contents)
    local file = io.open(filename, "w")

    if (not file) then return end

    file:write(contents)
    file:close()
end

local function RunTask()
    local module = require('function')
    if (not module or type(module) ~= "function") then error('invalid lua code') end

    local Event = JSON.decode(EVENTJSON) or {}

	local Request = {
		query = Event.queryStringParameters,
        method = Event.requestContext.http.method,
        path = Event.requestContext.http.path,
        userAgent = Event.requestContext.http.userAgent,
        sourceIp = Event.requestContext.http.sourceIp,
		body = Event.body,
		headers = { }
    }
	
	for name, value in pairs(Event.headers or {}) do
		if name:find('x-amzn') then goto continue end
		if name == 'x-forwarded-for' then goto continue end
		if name == 'host' then goto continue end

		Request.headers[name] = value

		::continue::
	end

	return module(Request)
end

local function Run()
    local success, result = pcall(RunTask)

	if (success) then
        WriteFile(FILENAME_OUT, JSON.encode(result))

		return
	end

	local resultErr = JSON.encode({
		errorMessage = (result and tostring(result)),
		errorType = "LuaError"
	})

	WriteFile(FILENAME_ERR, resultErr)
end

Run()