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
function Bot:initVariable()
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
		self:walkTo(taskData.position, taskData.onComplete, taskData.onMove)
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

    local completed = false

    tween:Play()

    local timeoutThread = task.delay(duration + 1, function()
        if not completed then
            tween:Cancel()
            rootPart.CFrame = CFrame.new(position)
            if onComplete then onComplete() end
        end
    end)

    tween.Completed:Connect(function()
        if not completed then
            completed = true
            if onComplete then onComplete() end
        end
    end)
end



function Bot:initItemListener()
    self.itemQueue = {}
    local LocalPlayer = game.Players.LocalPlayer
    local function  removeQ(item)
        for i, v in ipairs(self.itemQueue) do
            if v == item then
                table.remove(self.itemQueue, i)
                break
            end
        end
        
    end
    local function sortItemsByDistance()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Pre-calculate distances
        local distances = {}
        for i, item in ipairs(self.itemQueue) do
            distances[item] = (item.Position - root.Position).Magnitude
        end
        
        table.sort(self.itemQueue, function(a, b)
            return distances[a] < distances[b]
        end)
    end

    CollectiblesFolder.ChildAdded:Connect(function(item)
        local currentField = shared.main.currentField
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local yDiff = math.abs(item.Position.Y - root.Position.Y)
        if yDiff > 4 then return end
        local inField = (item.Position - currentField.Position).Magnitude <= currentField.Size.Magnitude / 2
        if item:IsA("BasePart") and not item:GetAttribute("Collected") and inField then
            local decal = item:FindFirstChildOfClass("Decal")
            local texture = decal and decal.Texture or ""
            local assetID = tonumber(texture:match("(%d+)$"))
            if assetID and not shared.main.tokenList[assetID] then return end

            table.insert(self.itemQueue, item)
            sortItemsByDistance()

            local connection
            connection = item.Touched:Connect(function(hit)
                if hit and hit:IsDescendantOf(LocalPlayer.Character) then
                    if not item:GetAttribute("Collected") then
                        item:SetAttribute("Collected", true)
                        item.Color = Color3.fromRGB(0, 255, 55)
                        if connection and connection.Connected then
                            removeQ(item)
                            connection:Disconnect()
                        end
                    end
                end
            end)
        end
    end)

    CollectiblesFolder.ChildRemoved:Connect(function(item)
        removeQ(item)
    end)
end

function Bot:getNextItem()
    local root = self.character:FindFirstChild("HumanoidRootPart")
    local currentField = shared.main.currentField
    if not root or not currentField then return nil end

    return self.itemQueue[1] or nil
end



function Bot:walkTo(position, onComplete, onMove)
    local humanoid = self.character:FindFirstChildOfClass("Humanoid")
    local root = self.character:FindFirstChild("HumanoidRootPart")
    local finished = false
    if not humanoid or not root then return end

    local function safeDisconnect(conn)
        if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        end
    end

    local lastPosition = root.Position
    local moveConn
    local moveToConn
    local timeoutStart = tick()

    local function handleDisconnect()
        safeDisconnect(moveConn)
        safeDisconnect(moveToConn)
    end

    humanoid:MoveTo(position)

    moveConn = game:GetService("RunService").Heartbeat:Connect(function()
        if (tick() - timeoutStart) >= 5 and not finished then
            finished = true
            handleDisconnect()
            warn("WalkTo timeout, cancelling task.")
            if onComplete then onComplete() end
        elseif onMove and (root.Position - lastPosition).Magnitude > 0.01 then
            onMove(moveToConn, handleDisconnect)
            lastPosition = root.Position
        end
    end)

    moveToConn = humanoid.MoveToFinished:Connect(function(reached)
        if not finished then
            finished = true
            handleDisconnect()
            if onComplete then onComplete() end
        end
    end)
end

function Bot:farmAt()
    local Field = shared.main.currentField
    local FieldPosition = Field.Position + Vector3.new(0, 3, 0)

    local function isInField(root)
        if not root then return false end
        local pos, size = root.Position, Field.Size
        return pos.X >= Field.Position.X - size.X/2 and pos.X <= Field.Position.X + size.X/2
            and pos.Z >= Field.Position.Z - size.Z/2 and pos.Z <= Field.Position.Z + size.Z/2
    end

    local function getRandomPositionInField(maxRadius)
        local center = Vector3.new(Field.Position.X, Field.Position.Y + 3, Field.Position.Z)
        local radius = math.random() * maxRadius
        local angle = math.random() * math.pi * 2

        local offsetX = math.cos(angle) * radius
        local offsetZ = math.sin(angle) * radius

        return center + Vector3.new(offsetX, 0, offsetZ)
    end



    local function startPatrolling()
        local maxRadius = math.min(Field.Size.X, Field.Size.Z) / 2 - 5
        local patrolPoints = getRandomPositionInField(maxRadius)
        local patrolIndex = 1
        local isMoving = false
        local currentItem = nil
        local root = self.character and self.character:FindFirstChild("HumanoidRootPart")

        while shared.main.autoFarm and not shared.main.convertPollen do
            if not isMoving and #patrolPoints > 0 then
                isMoving = true
                local targetPos = patrolPoints[patrolIndex]
                patrolIndex = patrolIndex % #patrolPoints + 1

                self:addTask({
                    type = "walk",
                    position = targetPos,
                    onComplete = function()
                        isMoving = false
                        if Field ~= shared.main.currentField then
                            return self:farmAt()
                        end
                    end,
                    onMove = function(_, handleDisconnect)
                        if currentItem then return end
                        local newItem = self:getNextItem()
                        if newItem then
                            currentItem = newItem
                            handleDisconnect()

                            local itemPos = Vector3.new(currentItem.Position.X, root.Position.Y, currentItem.Position.Z)
                            self:cancelCurrentTask()
                            self:addTask({
                                type = "walk",
                                position = itemPos,
                                onComplete = function()
                                    isMoving = false
                                    currentItem = nil
                                end
                            })
                        end
                    end
                })
            end
            task.wait()
        end
    end

    local root = self.character and self.character:FindFirstChild("HumanoidRootPart")
    if not isInField(root) then
        self:addTask({
            type = "fly",
            position = FieldPosition,
            onComplete = function()
                task.wait(1)
                startPatrolling()
            end
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
