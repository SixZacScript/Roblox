local eventClass, connectionClass = {}, {}
eventClass.__index, connectionClass.__index = eventClass, connectionClass

function eventClass.new()
	local self = setmetatable({}, eventClass)
	self.Next = self
	self.Previous = self
	
	return self
end

function eventClass:Connect(func, parameter)
	local connection = {}
	connection.Function = func
	connection.Parameter = parameter
	connection.Next = self
	connection.Previous = self.Previous
	self.Previous.Next = connection
	self.Previous = connection
	return setmetatable(connection, connectionClass)
end

function eventClass:Fire(...)
	local connection = self.Previous
	while connection ~= self do
		shared.Threads:Spawn(connection.Function, connection.Parameter, ...)
		connection = connection.Previous
	end
end

function connectionClass:Disconnect()
	self.Previous.Next = self.Next
	self.Next.Previous = self.Previous
end



return eventClass