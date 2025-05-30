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
    self:initItemListener() 

    local player = Players:GetPlayerFromCharacter(character)
    if player then
        player.CharacterAdded:Connect(function(newChar)
            if shared.main.autoFarm then
                self.character = newChar
                self:initVariable()
                self:initItemListener() 
                task.wait(3)
                self:startFarming()
            end
        end)
    end

	return self
end

function Bot:initVariable()
    self.taskQueue = {}
    self.currentTask = nil
	self.isRunning = false
    shared.main.convertPollen = false
end

function Bot:addTask(task)
    self:cancelCurrentTask()
    self.currentTask = task
	if not self.isRunning then
		self:runTasks()
	end
end

function Bot:cancelCurrentTask()
    self.taskQueue = {}
    self.currentTask = nil
    self.isRunning = false
    self:walkTo(self.character.PrimaryPart.Position)
end

function Bot:runTasks()
	self.isRunning = true
	task.spawn(function()
		while self.currentTask do
			self:executeTask(self.currentTask)
			self.currentTask = nil
			task.wait(0.1)
		end
		self.isRunning = false
	end)
end

function Bot:executeTask(taskData)
	if taskData.type == "walk" then
		self:walkTo(taskData.position, taskData.onComplete)
	elseif taskData.type == "fly" then
		self:flyTo(taskData.position, taskData.onComplete)
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
function Bot:initItemListener()
    self.itemQueue = {}

    -- for _, item in ipairs(CollectiblesFolder:GetChildren()) do
    --     if item:IsA("BasePart") and not item:GetAttribute("Collected") then
    --         table.insert(self.itemQueue, item)
    --     end
    -- end

    CollectiblesFolder.ChildAdded:Connect(function(item)
        if item:IsA("BasePart") and not item:GetAttribute("Collected") then
            table.insert(self.itemQueue, item)
        end
    end)

    CollectiblesFolder.ChildRemoved:Connect(function(item)
        for i, v in ipairs(self.itemQueue) do
            if v == item then
                table.remove(self.itemQueue, i)
                break
            end
        end
    end)
end

function Bot:getNextItem()
    local root = self.character:FindFirstChild("HumanoidRootPart")
    local currentField = shared.main.currentField
    if not root or not currentField then return nil end

    for i, item in ipairs(self.itemQueue) do
        local inField = (item.Position - currentField.Position).Magnitude <= currentField.Size.Magnitude / 2
        if item:IsA("BasePart")and not item:GetAttribute("Collected") and inField then
            local decal = item:FindFirstChildOfClass("Decal")
            local texture = decal and decal.Texture or ""
            local assetID = tonumber(texture:match("(%d+)$"))
            if assetID and not shared.main.tokenList[assetID] then continue end
            table.remove(self.itemQueue, i)
            return item
        end
    end
    return nil
end

function Bot:walkTo(position, onComplete)
    local humanoid = self.character:FindFirstChildOfClass("Humanoid")
    local root = self.character:FindFirstChild("HumanoidRootPart")
    local finished = false
    if not humanoid or not root then return end

    -- Timeout ถ้าเดินไม่ถึงภายใน 5 วินาที
    task.delay(5, function()
        if not finished then
            finished = true
            shared.Rayfield:Notify({
                Title = "Failed to walk",
                Content = "Timeout: Failed to reach position within 5 seconds",
                Duration = 6.5,
                Image = 4483362458,
            })
            if onComplete then onComplete() end
        end
    end)


    humanoid:MoveTo(position)
    humanoid.MoveToFinished:Once(function(reached)
        finished = true
        if onComplete then onComplete() end
    end)
end


function Bot:stopFarming()
    self:cancelCurrentTask()
    print("Farming stopped.")
end

function Bot:startFarming()
    self:initVariable()
    self:getUnclaimHive()
    self:cancelCurrentTask()
    self:checkPollen(function()
        print(shared.main.Pollen, shared.main.Capacity)
        print("you are ready to farming...","currenthive:", self.manageRef.Hive.Name)
        self:farmAt()
    end)
end

function Bot:farmAt()
    local Field = shared.main.currentField
    local FieldPosition = Field.Position + Vector3.new(0, 3, 0)
    local root = self.character and self.character:FindFirstChild("HumanoidRootPart")
    local function isInField()
        local root = self.character and self.character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local pos, size = root.Position, Field.Size
        return pos.X >= Field.Position.X - size.X/2 and pos.X <= Field.Position.X + size.X/2
            and pos.Z >= Field.Position.Z - size.Z/2 and pos.Z <= Field.Position.Z + size.Z/2
    end


    local function getRandomPositionInField()
        local randomX = Field.Position.X + math.random(-Field.Size.X/2 + 5, Field.Size.X/2 - 5)
        local randomZ = Field.Position.Z + math.random(-Field.Size.Z/2 + 5, Field.Size.Z/2 - 5)
        return Vector3.new(randomX, Field.Position.Y + 3, randomZ)
    end
    
    local function startPatrolling()
        local isMoving = false
        local currentItem = nil
        while shared.main.autoFarm and not shared.main.convertPollen do 
            if not isMoving then 
                isMoving = true
                local randomPosition = getRandomPositionInField()
                self:addTask({
                    type = "walk",
                    position = randomPosition,
                    onComplete = function()
                         isMoving = false
                        if Field ~= shared.main.currentField then
                            return self:farmAt()
                        end
                    end
                })
                while isMoving do
                    if shared.main.autoFarm and not shared.main.convertPollen and not currentItem then
                        currentItem = self:getNextItem()
                         if currentItem then
                            local itemPos = Vector3.new(currentItem.Position.X, root.Position.Y, currentItem.Position.Z)
                            self:cancelCurrentTask()
                            self:addTask({
                                type = "walk",
                                position = itemPos,
                                onComplete = function()
                                    currentItem:SetAttribute("Collected", true)
                                    isMoving = false
                                    currentItem = nil
                                end
                            })
                        end
                    end
                    task.wait()
                end
            end
            task.wait()
        end
    end
    
    if not isInField() then
        self:addTask({ 
            type = "fly", 
            position = FieldPosition,
            onComplete = startPatrolling
        })
    else
        startPatrolling()
    end
end

function Bot:checkPollen(onComplete)
    if shared.main.Pollen >= shared.main.Capacity and not shared.main.convertPollen  then
        shared.main.convertPollen = true
        self:addTask({
            type = "convert",
            onComplete = function()
                if onComplete then onComplete() end
            end
        })
    else
        if onComplete then onComplete() end
    end
end

function Bot:gotoHive(onComplete)
    local Hive = self.manageRef.Hive 
    local Base = Hive and Hive:FindFirstChild("patharrow") and Hive.patharrow:FindFirstChild("Base")
    if not Base then
        warn("Base not found in patharrow")
        return self:gotoHive(onComplete)
    end
    self:flyTo(Base.Position, onComplete)
end

function Bot:getUnclaimHive()
    if self.manageRef.Hive then return self.manageRef.Hive end

    local LocalPlayer = Players.LocalPlayer

    -- First: check if the player already owns a hive
    for _, hive in ipairs(workspace.Honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and owner.Value == LocalPlayer then
            self.manageRef.Hive = hive
            return hive
        end
    end

    -- Second: find the first unclaimed hive and claim it
    for i, hive in ipairs(workspace.Honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and not owner.Value then
            game:GetService("ReplicatedStorage").Events.ClaimHive:FireServer(i)
            self.manageRef.Hive = hive
            return hive
        end
    end
end


function Bot:convertPollen(onComplete)
   print("Converting pollen...")
   if shared.main.Pollen <= 0 then return onComplete and onComplete() end
   
   local wasAutoFarming = shared.main.autoFarm
   if wasAutoFarming then self:stopFarming() end
   
   self:gotoHive(function()
       task.wait(1)
       game:GetService("ReplicatedStorage").Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
       
       while shared.main.Pollen > 0 do
           task.wait(0.1)
       end
       
       print("Completed Convert pollen...")
       task.wait(5)
       shared.main.convertPollen = false
       if wasAutoFarming then self:startFarming() end
       if onComplete then onComplete() end
   end)
end


return Bot
