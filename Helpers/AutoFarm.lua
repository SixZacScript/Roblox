local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


local AutoFarm = {}
AutoFarm.__index = AutoFarm

function AutoFarm.new(manageRef)
	local self = setmetatable({}, AutoFarm)
	self.player = Players.LocalPlayer
	self.character = self.player.Character or self.player.CharacterAdded:Wait()
	self.rootPart = self.character:WaitForChild("HumanoidRootPart")
	self.humanoid = self.character:WaitForChild("Humanoid")
	self.autoFarm = false
	self.converting = false
	self.currentField = shared.main.currentField
	self.tokenList = {}
	self.collectiblesFolder = workspace:WaitForChild("Collectibles")
	self.hivePosition = Vector3.new(0, 3, 0)
	self.Pollen = shared.main.Pollen
	self.Capacity = shared.main.Capacity
	self.itemQueue = {}
    self.manageRef = manageRef

	self.collectiblesFolder.ChildAdded:Connect(function(item)
        local currentField = shared.main.currentField
        local inField = (item.Position - currentField.Position).Magnitude <= currentField.Size.Magnitude / 2
        local decal = item:FindFirstChild("FrontDecal")
        local assetId = decal and decal.Texture or nil 
        local isCollectible = assetId and shared.main.tokenList[assetId] or false
        if item:IsA("BasePart") and not item:GetAttribute("Collected") and inField and isCollectible then
            table.insert(self.itemQueue, item)
            self:sortItemQueue()
        end
    end)

	self.collectiblesFolder.ChildRemoved:Connect(function(item)
		for i, v in ipairs(self.itemQueue) do
			if v == item then
				table.remove(self.itemQueue, i)
				break
			end
		end
	end)
    self.humanoid.Died:Connect(function()
        self:stop()
    end)
    self.player.CharacterAdded:Connect(function(character)
        self.character = character
        self.rootPart = character:WaitForChild("HumanoidRootPart")
        self.humanoid = character:WaitForChild("Humanoid")
        task.wait(5)
        self:start()
    end)
   UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.E and self.converting then
            self.converting = false
        end

        local movementKeys = {
            [Enum.KeyCode.W] = true,
            [Enum.KeyCode.A] = true,
            [Enum.KeyCode.S] = true,
            [Enum.KeyCode.D] = true,
            [Enum.KeyCode.Space] = true,
        }

        if movementKeys[input.KeyCode] and self.autoFarm then
            self:stop()
            -- shared.Rayfield:Notify({
            --     Title = "AutoFarm Stopped",
            --     Content = "You have stopped the AutoFarm.",
            --     Duration = 5,
            -- })
        end
    end)
	return self
end

function AutoFarm:sortItemQueue()
	table.sort(self.itemQueue, function(a, b)
		local distA = (a.Position - self.rootPart.Position).Magnitude
		local distB = (b.Position - self.rootPart.Position).Magnitude
		return distA < distB
	end)
end

function AutoFarm:filterInvalidItems()
	for i = #self.itemQueue, 1, -1 do
		local item = self.itemQueue[i]
		if item:IsA("BasePart") and item.Rotation.Z == 90 then
			table.remove(self.itemQueue, i)
		end
	end
end

function AutoFarm:getFirstItem()
	self:filterInvalidItems()
	return self.itemQueue[1]
end




function AutoFarm:tweenTo(targetPos, callback)
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(self.rootPart, tweenInfo, {CFrame = CFrame.new(targetPos)})
	tween:Play()
	tween.Completed:Connect(function()
		if callback then callback() end
	end)
end

function AutoFarm:getRandomPositionInField()
    local currentField = shared.main.currentField
	local size = currentField.Size
	local halfSizeX, halfSizeZ = size.X / 2, size.Z / 2
	local center = currentField.Position
	local randomX = center.X + math.random(-halfSizeX + 5, halfSizeX - 5)
	local randomZ = center.Z + math.random(-halfSizeZ + 5, halfSizeZ - 5)
	return Vector3.new(randomX, center.Y + 3, randomZ)
end

function AutoFarm:moveToItem()
	local item = self:getFirstItem()
	if not item then return end

	local touchedConn
	local reached = false
    local function getOffsetPosition(fromPos, toPos, offset)
        local direction = (toPos - fromPos).Unit
        return toPos + direction * offset
    end
	touchedConn = item.Touched:Connect(function(hit)
		if hit and hit:IsDescendantOf(self.character) then
			if not item:GetAttribute("Collected") then
				item:SetAttribute("Collected", true)
				for i, v in ipairs(self.itemQueue) do
					if v == item then
						table.remove(self.itemQueue, i)
						break
					end
				end
				if touchedConn then
					touchedConn:Disconnect()
				end
                self:filterInvalidItems()
				reached = true
			end
		end
	end)

    local offsetPos = getOffsetPosition(self.rootPart.Position, item.Position, 3)
	self.humanoid:MoveTo(offsetPos)

	local timeout = 5
	local startTime = tick()
    local isAvailable =  self.autoFarm and not self.converting
	while tick() - startTime < timeout and isAvailable do
		if reached or not item or (item and (item.Rotation.Z == 90 or item.Transparency == 1)) then break end
		RunService.Heartbeat:Wait()
	end

	if touchedConn and touchedConn.Connected then
		touchedConn:Disconnect()
	end
end

function AutoFarm:moveTo(pos)
	self.humanoid:MoveTo(pos)
	local timeout = 5
	local startTime = tick()
    local isAvailable =  self.autoFarm and not self.converting
	while (self.rootPart.Position - pos).Magnitude > 5 and tick() - startTime < timeout and isAvailable do
		local item = self:getFirstItem()
		if item then
			self:moveToItem()
			return
		end
		RunService.Heartbeat:Wait()
	end
end
function AutoFarm:convertPollen(onComplete)
    if (shared.main.Pollen <= 0) then return onComplete and onComplete() end
    self.converting = true
    shared.hiveHelper:gotoHive(function()
        task.wait(1)
        game:GetService("ReplicatedStorage").Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
        while shared.main.Pollen > 0 and self.autoFarm and self.converting do
            task.wait(0.1)
        end  
        task.wait(5)
        self.converting = false
        if onComplete then onComplete() end
   end)
end
function AutoFarm:runFarmLoop()
	while self.autoFarm do
        if not self.converting then
            local item = self:getFirstItem()
            if item then
                self:moveToItem()
            else
                local target = self:getRandomPositionInField()
                self:moveTo(target)
            end
        end
		RunService.Heartbeat:Wait()
	end
end
function AutoFarm:addConnection(name, callback)
    self._connections = self._connections or {}
    if self._connections[name] then
        self._connections[name]:Disconnect()
    end
    self._connections[name] = RunService.Heartbeat:Connect(callback)
end

function AutoFarm:setupHeartbeatConnection()
    self:addConnection("HeartbeatLogic", function()
        if self.autoFarm and not self.converting then
            local item = self:getFirstItem()
            if item then
                self:moveToItem()
            end
        end
    end)
end
function AutoFarm:removeConnection(name)
    if self._connections and self._connections[name] then
        self._connections[name]:Disconnect()
        self._connections[name] = nil
    end
end

function AutoFarm:stop()
    self.itemQueue = {}
    self.autoFarm = false
    self.converting = false
    self:removeConnection("Heartbeat")
    self:moveTo(self.rootPart.Position)
    -- self.manageRef.farmTab.farmToggle:Set(false)
end

function AutoFarm:start()
    self.Hive = shared.hiveHelper.Hive
    self.autoFarm = true
    local targetPos = shared.main.currentField.Position + Vector3.new(0, 3, 0)

    self:removeConnection("Heartbeat")
    self:addConnection("Heartbeat", function()
        if shared.main.Pollen >= shared.main.Capacity and not self.converting then
            self:convertPollen(function()
                if self.autoFarm then
                    self:tweenTo(targetPos)
                end
            end)
        end
    end)

    self:tweenTo(targetPos, function()
        self:runFarmLoop()
    end)
end


return AutoFarm
