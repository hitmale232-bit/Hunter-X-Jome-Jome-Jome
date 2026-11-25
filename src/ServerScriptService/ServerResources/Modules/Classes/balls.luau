local class = {}

function class.new(param)
	local self = setmetatable({}, {__index = class}) -- this is an object
	
	return self
end

function class:Method()
	
end

return class