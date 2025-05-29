local TweenService = game:GetService("TweenService")
local WP  = game:GetService("Workspace")
local CollectiblesFolder = WP:WaitForChild("Collectibles")

local Bot = {}
Bot.__index = Bot

function Bot.new(character, manageRef)
	local self = setmetatable({}, Bot)
	self.character = character
    self.manageRef = manageRef 
	self.taskQueue = {}
    self.items = {}
	self.isRunning = false
    self.farming = false
    self.movingConnection = nil
    self.heartbeatConnection = nil
    self.currentTarget = nil

    CollectiblesFolder.ChildAdded:Connect(function(item)
        if item:IsA("BasePart") then
            table.insert(self.items, item)
        end
    end)
    CollectiblesFolder.ChildRemoved:Connect(function(item)
        for i, v in ipairs(self.items) do
            if v == item then
                table.remove(self.items, i)
                break
            end
        end
    end)

	return self
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
		self:farmAt(taskData.field, taskData.onComplete)
	elseif taskData.type == "fly" then
		self:flyTo(taskData.position, taskData.onComplete)
    elseif taskData.type == "start" then
        self:startFarming(taskData.field)
    elseif taskData.type == "stop" then
        self:stopFarming()

	end
end


function Bot:flyTo(position, onComplete)
	local rootPart = self.character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local duration = 0.6
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

	print("Moving to:", position)
	humanoid:MoveTo(position)
	self.currentTarget = position

	if self.movingConnection then
		self.movingConnection:Disconnect()
	end
	if self.heartbeatConnection then
		self.heartbeatConnection:Disconnect()
	end

    self.heartbeatConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if self.farming and #self.items > 0 then
            local item = self.items[1]
            if item and (not self.currentTarget or (self.currentTarget - item.Position).Magnitude > 1) then
                print("Go to item")
                if self.movingConnection then
                    self.movingConnection:Disconnect()
                    self.movingConnection = nil
                end
                if self.heartbeatConnection then
                    self.heartbeatConnection:Disconnect()
                    self.heartbeatConnection = nil
                end
                self:walkTo(item.Position, function()
                    table.remove(self.items, 1)
                    if onComplete then onComplete() end
                end)
            end
        end
    end)

	self.movingConnection = humanoid.MoveToFinished:Connect(function(reached)
		if self.movingConnection then
			self.movingConnection:Disconnect()
			self.movingConnection = nil
		end
		if self.heartbeatConnection then
			self.heartbeatConnection:Disconnect()
			self.heartbeatConnection = nil
		end
		if onComplete then onComplete() end
	end)
end

function  Bot:stopFarming()
    self.farming = false
end
function Bot:startFarming(field)
    if self.farming then return end
    self.farming = true
    self.currentField = field
    print("Starting farming at field:", field.Name)
    self:addTask({type = "farm",field = field})

end
function Bot:farmAt(Field, onComplete)
    local FieldPosition = Field.Position + Vector3.new(0,3,0)
    local lastPosition = Field.Position

    local function getRandomPositionInFieldNear(origin)
        local size = Field.Size
        local margin = 10
        local tries = 10

        local minX = Field.Position.X - size.X/2 + margin
        local maxX = Field.Position.X + size.X/2 - margin
        local minZ = Field.Position.Z - size.Z/2 + margin
        local maxZ = Field.Position.Z + size.Z/2 - margin

        for i = 1, tries do
            local x = math.clamp(origin.X + math.random(-10, 10), minX, maxX)
            local z = math.clamp(origin.Z + math.random(-10, 10), minZ, maxZ)
            return Vector3.new(x, Field.Position.Y + 3, z)
        end

        return Vector3.new(
            math.clamp(origin.X, minX, maxX),
            Field.Position.Y + 3,
            math.clamp(origin.Z, minZ, maxZ)
        )
    end


    local function moveNext()
        if not self.farming then return end
        local nextPos = getRandomPositionInFieldNear(lastPosition)
        lastPosition = nextPos
        self:walkTo(nextPos, function()
            moveNext()
        end)
    end

    self:addTask({
        type = "fly",
        position = FieldPosition,
        onComplete = function()
            lastPosition = FieldPosition
            moveNext()
        end
    })
end
return Bot