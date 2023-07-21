local JSON = require('deps/json')

local response = {
    headers = {
		['Content-Type'] = '*/*'
	},
    __response = '',
	__status = 500,
}

function response.send(data, status)
    for _, t in pairs({ 'function', 'thread', 'userdata' }) do
        if type(data) == t then
            return error('Invalid data type')
        end
    end

    if (type(data) == 'table') then
        data = JSON.stringify(data)

        response.headers['Content-Type'] = 'application/json'
    end

    response.__response = data

    if not status or not type(status) == 'number' then return end
    response.__status = status
end

function response.header(name, value)
    if not name then return error('Header name required') end
    if not value then return error('Invalid header value') end

    response.headers[name] = value
end

function response.status(status)
	if not status then return error('Status required') end
    if type(status) ~= 'number' then return error('Invalid status value') end
	
	 response.__status = status
end

return response