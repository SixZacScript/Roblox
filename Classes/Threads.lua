local threads = {}

local self = {}

function self:Spawn(func, ...)
	task.spawn(table.remove(threads) or Thread,func, ...)
end

function self:Defer(func, ...)
	task.defer(table.remove(threads) or Thread,func, ...)
end

function Thread(func, ...)
	func(...)
	while true do table.insert(threads, coroutine.running()) Call(coroutine.yield()) end
end

function Call(func, ...)
	func(...)
end

return self