local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local WP  = game:GetService("Workspace")
local CollectiblesFolder = WP:WaitForChild("Collectibles")

local Bot = {}
Bot.__index = Bot

function Bot.new(character, manageRef)
	local self = setmetatable({}, Bot)
	self.character = character
    self.manageRef = manageRef 
    self:initVariable()

    local player = Players:GetPlayerFromCharacter(character)
    if player then
        player.CharacterAdded:Connect(function(newChar)
            if shared.main.startFarming then
                self.character = newChar
                self:initVariable()
                task.wait(3)
                self:startFarming()
            end
        end)
    end

	return self
end
function Bot:initVariable()
    self.taskQueue = {}
    self.items = {}
	self.isRunning = false
    self.farming = false
    self.currentTarget = nil
end


function Bot:addTask(task)
	table.insert(self.taskQueue, task)
	if not self.isRunning then
		self:runTasks()
	end
end

function Bot:runTasks()
	self.isRunning = true
	task.spawn(function()
		while #self.taskQueue > 0 do
			local taskData = table.remove(self.taskQueue, 1)
			self:executeTask(taskData)
			task.wait(0.1)
		end
		self.isRunning = false
	end)
end

function Bot:executeTask(taskData)
	if taskData.type == "walk" then
		self:walkTo(taskData.position, taskData.onComplete)
	elseif taskData.type == "farm" then
		self:farmAt(taskData.onComplete)
	elseif taskData.type == "fly" then
		self:flyTo(taskData.position, taskData.onComplete)
    elseif taskData.type == "start" then
        self:startFarming()
    elseif taskData.type == "stop" then
        self:stopFarming()
    elseif taskData.type == "convert" then
        self:convertPollen(taskData.onComplete)
	end
end


function Bot:flyTo(position, onComplete)
	local rootPart = self.character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local duration = shared.main.tweenSpeed or 0.6
	local tween = TweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(position)
	})
	tween:Play()
	tween.Completed:Connect(function()
		if onComplete then onComplete() end
	end)
end
function Bot:walkTo(position, onComplete)
    local humanoid = self.character:FindFirstChildOfClass("Humanoid")
    local rootPart = self.character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    humanoid:MoveTo(position)
    self.currentTarget = position

    self.moving = true
    task.spawn(function()
        while self.moving and rootPart do
            if rootPart then

            end
            task.wait()
        end
    end)

 return  humanoid.MoveToFinished:Connect(function(reached)
        self.moving = false

        if onComplete then onComplete() end
    end)
end


function  Bot:stopFarming()
    self:stopCollecting()
    self:initVariable()
end;
function Bot:startFarming()
    local field = shared.main.currentField
    if self.farming and self.currentField == field then return end
    self:checkPollen(function()
        self:getUnclaimHive()
        self:stopFarming()
        self.farming = true
        self.currentField = field
        print("Starting farming at field:", field.Name)
        self:startCollecting()
        self:addTask({type = "farm"})
    end)
end
function Bot:farmAt(onComplete)
    local Field = shared.main.currentField
    local FieldPosition = Field.Position + Vector3.new(0, 3, 0)

    local function isInField()
        local root = self.character and self.character:FindFirstChild("HumanoidRootPart")
        if not root then return false end

        local pos = root.Position
        local size = Field.Size
        local minX = Field.Position.X - size.X / 2
        local maxX = Field.Position.X + size.X / 2
        local minZ = Field.Position.Z - size.Z / 2
        local maxZ = Field.Position.Z + size.Z / 2

        return pos.X >= minX and pos.X <= maxX and pos.Z >= minZ and pos.Z <= maxZ
    end

    local function getRandomPositionInField()
        local size = Field.Size
        local margin = 15
        local minX = Field.Position.X - size.X / 2 + margin
        local maxX = Field.Position.X + size.X / 2 - margin
        local minZ = Field.Position.Z - size.Z / 2 + margin
        local maxZ = Field.Position.Z + size.Z / 2 - margin

        local x = math.random(minX, maxX)
        local z = math.random(minZ, maxZ)

        return Vector3.new(x, Field.Position.Y + 3, z)
    end

    -- New function to check for nearby items
    local function checkForNearbyItems()
        local root = self.character and self.character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end

        local collectRadius = shared.main.tokenRadius 
        local closestItem = nil
        local closestDistance = collectRadius

        for _, item in pairs(CollectiblesFolder:GetChildren()) do
            if item and item.Parent and item:IsA("BasePart") then
                local distance = (root.Position - item.Position).Magnitude
                if distance <= closestDistance then
                    closestDistance = distance
                    closestItem = item
                end
            end
        end

        return closestItem
    end
    local function startLoop()
        local isMoving = false
        while shared.main.startFarming and not shared.main.convertPollen do
            if not isMoving then
                local nextPos = getRandomPositionInField()
                local nearbyItem = checkForNearbyItems()
                isMoving = true

                if nearbyItem and not nearbyItem:GetAttribute("Collect") then
                    self:walkTo(nearbyItem.Position, function()
                        isMoving = false
                        nearbyItem:SetAttribute("Collect", true)
                    end)
                else
                    local moveConn

                    local function monitorNearbyItems()
                        while isMoving and shared.main.startFarming do
                            local item = checkForNearbyItems()
                            if item and not item:GetAttribute("Collect") then
                                if moveConn then moveConn:Disconnect() end
                                self:walkTo(item.Position, function()
                                    isMoving = false
                                    item:SetAttribute("Collect", true)
                                end)
                                break
                            end
                            task.wait()
                        end
                    end

                    task.spawn(monitorNearbyItems)

                    moveConn = self:walkTo(nextPos, function()
                        isMoving = false
                        if moveConn then moveConn:Disconnect() end
                    end)
                end
            end

            task.wait()
        end
    end


    if not isInField() then
        self:addTask({
            type = "fly",
            position = FieldPosition,
            onComplete = function()
                startLoop()
            end
        })
    else
        startLoop()
    end
end


function Bot:checkPollen(onComplete)
    if shared.main.Pollen == shared.main.Capacity then
        shared.main.convertPollen = true
        self:stopFarming()
        self:addTask({
            type = "convert",
            onComplete = function()
                if onComplete then onComplete() end
                shared.main.convertPollen = false
                if shared.main.startFarming then
                    self:addTask({type = "start", field = shared.main.currentField})
                end
            end
        })
    else
        if onComplete then onComplete() end
    end
end

function Bot:gotoHive(onComplete)
    local Hive = self.manageRef.Hive
    local patharrow = Hive and Hive:FindFirstChild("patharrow")
    local Base = patharrow and patharrow:FindFirstChild("Base")
    if not Base then
        warn("Base not found in patharrow")
        Hive = self:getUnclaimHive()
        self:gotoHive(onComplete)
        return
    end
    self:flyTo(Base.Position, function()
        if onComplete then onComplete() end
    end)
end
function Bot:getUnclaimHive()
   if self.manageRef.Hive then return self.manageRef.Hive end
   
   local LocalPlayer = game.Players.LocalPlayer
   local unclaimed
   
   for i, hive in pairs(workspace.Honeycombs:GetChildren()) do
       local owner = hive:FindFirstChild("Owner")
       if owner then
           if owner.Value == LocalPlayer then
               self.manageRef.Hive = hive
               return hive
           elseif not owner.Value and not unclaimed then
               unclaimed = {hive, i}
           end
       end
   end
   
   if unclaimed then
       game:GetService("ReplicatedStorage").Events.ClaimHive:FireServer(unclaimed[2])
       self.manageRef.Hive = unclaimed[1]
       return unclaimed[1]
   end
end

function Bot:convertPollen(onComplete)
    local Pollen = shared.main.Pollen
    print("Converting pollen...")
    self:gotoHive(function()
        task.wait(1) 
        local Event = game:GetService("ReplicatedStorage").Events.PlayerHiveCommand
        Event:FireServer("ToggleHoneyMaking")

        repeat
            Pollen = shared.main.Pollen
            task.wait(5)
        until Pollen <= 0

        self.farming = false
        print("Completed Convert pollen...")
        if onComplete then onComplete() end
    end)

end

function Bot:isInField(position)
    local currentField = shared.main.currentField
    local size = currentField.Size
    local center = currentField.Position
    local halfSize = size * 0.5

    local minX = center.X - halfSize.X
    local maxX = center.X + halfSize.X
    local minZ = center.Z - halfSize.Z
    local maxZ = center.Z + halfSize.Z

    return position.X >= minX and position.X <= maxX and position.Z >= minZ and position.Z <= maxZ
end

function Bot:startCollecting()
    if self.collectingConnection then return end 
    
    self.collectingConnection = CollectiblesFolder.ChildAdded:Connect(function(item)
        if self.farming then 
            self:collectItem(item)
        end
    end)
end

function Bot:stopCollecting()
    if self.collectingConnection then
        self.collectingConnection:Disconnect()
        self.collectingConnection = nil
    end
end

function Bot:collectItem(item)
    if not item or not item.Parent then return end
    
    local rootPart = self.character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Check if item is within reasonable distance (optional)
    local distance = (rootPart.Position - item.Position).Magnitude
    if distance > 100 then return end -- Skip items too far away
    
    -- Add collection task with high priority
    table.insert(self.taskQueue, 1, {
        type = "collect",
        item = item,
        position = item.Position
    })
    
    if not self.isRunning then
        self:runTasks()
    end
end



return Bot