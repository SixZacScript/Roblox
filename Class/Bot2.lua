-- Services
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- References
local CollectiblesFolder = Workspace:WaitForChild("Collectibles")

-- Bot Module
local Bot = {}
Bot.__index = Bot

-- Constructor
function Bot.new()
	local self = setmetatable({}, Bot)
	self.autoFarm = false
	self.converting = false
	self.sessionId = 0
	self.itemQueue = {}
	self._connections = {}

	self:_initItemTracking()
	return self
end

-- Private Methods
function Bot:_initItemTracking()
	CollectiblesFolder.ChildAdded:Connect(function(item)
		local field = shared.main.currentField
		if item:IsA("BasePart") and not item:GetAttribute("Collected") then
			local inField = (item.Position - field.Position).Magnitude <= field.Size.Magnitude / 2
			if inField then
                local touchedConn
				touchedConn = item.Touched:Connect(function(hit)
					if hit:IsDescendantOf(shared.character.character) and not item:GetAttribute("Collected") then
						item:SetAttribute("Collected", true)
						self:_removeItemFromQueue(item)
						touchedConn:Disconnect()
					end
				end)
				table.insert(self.itemQueue, { item = item, conn = touchedConn })
				self:_sortItemQueue()
			end
		end
	end)

	CollectiblesFolder.ChildRemoved:Connect(function(item)
		self:_removeItemFromQueue(item)
	end)
end

function Bot:_sortItemQueue()
	table.sort(self.itemQueue, function(a, b)
		local pos = shared.character.rootPart.Position
		return (a.item.Position - pos).Magnitude < (b.item.Position - pos).Magnitude
	end)
end

function Bot:_removeItemFromQueue(item)
	for i, v in ipairs(self.itemQueue) do
		if v.item == item then
			if v.conn then v.conn:Disconnect() end
			table.remove(self.itemQueue, i)
			break
		end
	end
end

-- Connection Management
function Bot:addConnection(name, callback)
	self:removeConnection(name)
	self._connections[name] = RunService.Heartbeat:Connect(callback)
	return self._connections[name]
end

function Bot:removeConnection(name)
	if self._connections[name] then
		self._connections[name]:Disconnect()
		self._connections[name] = nil
	end
end

function Bot:removeAllConnections()
	for _, conn in pairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}
end

-- Utility
function Bot:getRandomPositionInField()
	local field = shared.main.currentField
	local size, center = field.Size, field.Position
	local x = center.X + math.random(-size.X / 2 + 5, size.X / 2 - 5)
	local z = center.Z + math.random(-size.Z / 2 + 5, size.Z / 2 - 5)
	return Vector3.new(x, shared.character.rootPart.Position.Y, z)
end

function Bot:getFirstItem()
	return self.itemQueue[1]
end

-- Core Methods
function Bot:start()
	if self.autoFarm then return end
	self.autoFarm = true
	self.sessionId += 1

	if shared.hiveHelper:isPollenFull() then
		self:checkPollenAndConvert(self.sessionId)
	else
		self:returnToField()
	end
end

function Bot:stop()
	if not self.autoFarm then return end
	self.autoFarm = false
	self.converting = false
	self.itemQueue = {}
	shared.character:moveTo(shared.character.rootPart.Position)
	self:removeAllConnections()
end

function Bot:checkPollenAndConvert(sessionId)
	if not shared.hiveHelper:isPollenFull() then return false end
	self.converting = true

	shared.hiveHelper:gotoHive(function()
		task.wait(1)
		ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
		while shared.hiveHelper.PollenValue > 0 and self.autoFarm and self.converting do
			task.wait(0.1)
		end
		task.wait(5)
		self.converting = false
		if self.autoFarm and self.sessionId == sessionId then
			self:returnToField()
		end
	end)
	return true
end

function Bot:returnToField()
	if not self.autoFarm then return end
	local field = shared.main.currentField
	local pos, radius = field.Position, field.Size.X / 2
	local isOutside = shared.character:getDistance(pos) > radius

	local gotoFarm = function() self:farmLoop() end
	if isOutside then
		shared.character:tweenTo(pos + Vector3.new(0, 3, 0), gotoFarm)
	else
		gotoFarm()
	end
end

function Bot:moveToItem()
	local data = self:getFirstItem()
	if not data then return end
	local item = data.item
	local pos = Vector3.new(item.Position.X, shared.character.rootPart.Position.Y, item.Position.Z)
	shared.character:moveTo(pos, not (self.autoFarm and not self.converting),function()
        self:_sortItemQueue()
    end)
end

function Bot:farmLoop()
	while self.autoFarm do
		if self:checkPollenAndConvert(self.sessionId) then break end
		local isReady = self.autoFarm and not self.converting and shared.character:isValid()
		local item = self:getFirstItem()

		if item then
			self:moveToItem()
		elseif isReady then
			local breakMove = false
			local target = self:getRandomPositionInField()
			local moveConn = self:addConnection("move", function()
				breakMove = self:getFirstItem() ~= nil or shared.hiveHelper:isPollenFull()
			end)
			shared.character:moveTo(target, breakMove, function()
				if moveConn then moveConn:Disconnect() end
			end)
		end

		task.wait()
	end
end

return Bot