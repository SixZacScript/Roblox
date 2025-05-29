local TweenService = game:GetService("TweenService")

local Bot = {}
Bot.__index = Bot

function Bot.new(character)
    print("Bot initialized for character:", character.Name)
	local self = setmetatable({}, Bot)
	self.character = character
	self.taskQueue = {}
	self.isRunning = false
    self.farming = false
	return self
end

function Bot:addTask(task)
    print("Adding task:", task.type)
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
	if taskData.type == "move" then
		self:moveTo(taskData.position, taskData.onComplete)
	elseif taskData.type == "farm" then
		self:farmAt(taskData.field, taskData.onComplete)
	elseif taskData.type == "walk" then
		self:walkTo(taskData.position, taskData.onComplete)
	elseif taskData.type == "fly" then
		self:flyTo(taskData.position, taskData.onComplete)
    elseif taskData.type == "fly" then
        self:startFarming(taskData.field)
    elseif taskData.type == "stop" then
        self:stopFarming()

	end
end

function Bot:moveTo(position, onComplete)
	self:flyTo(position, onComplete) 
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
	if not humanoid then return end

	humanoid:MoveTo(position)
	local conn
	conn = humanoid.MoveToFinished:Connect(function(reached)
		if conn then conn:Disconnect() end
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
    self:addTask({type = "farm",field = field})

end
function Bot:farmAt(Field, onComplete)

    self:flyTo(Field.Position, function()
        
    end)
	print("Farming at", Field.Name)

end

return Bot