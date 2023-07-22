local JSON = require('deps.json')

return function(EVENTJSON)
	local Event = JSON.decode(EVENTJSON) or {}

	local Request = {
		query = Event.queryStringParameters,
        method = Event.requestContext.http.method,
        path = Event.requestContext.http.path,
        userAgent = Event.requestContext.http.userAgent,
        sourceIp = Event.requestContext.http.sourceIp,
		body = Event.body,
        headers = { },
		cookies = { }
    }
	
    for name, value in pairs(Event.headers or {}) do
        if name:find('x-amzn') then goto continue end
        if name == 'x-forwarded-for' then goto continue end
        if name == 'host' then goto continue end

        Request.headers[name] = value

        ::continue::
    end
end