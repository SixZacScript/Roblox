-- Config Module - External configuration for easy maintenance
local Config = {
    FIELD_PADDING = 5,
    MOVEMENT_TWEEN_TIME = 1,
    CONVERSION_DELAY = 5,
    PRIORITY_CHECK_INTERVAL = 0.08,
    REGULAR_CHECK_INTERVAL = 0.2,
    MONSTER_JUMP_INTERVAL = 1.5,
    MONSTER_DETECTION_RADIUS = 40,
    MAX_NEARBY_COLLECTIBLES = 10,
    MOVEMENT_TIMEOUT_BUFFER = 2,
    COLLECTIBLE_Y_TOLERANCE = 3,
    PRIORITY_MULTIPLIER = 5
}

-- Services Cache
local Services = {
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage")
}

-- Folder References
local Folders = {
    Collectibles = Services.Workspace:WaitForChild("Collectibles"),
    Monsters = Services.Workspace:WaitForChild("Monsters"),
    Particles = Services.Workspace:WaitForChild("Particles")
}

-- State Manager - Centralized state management
local StateManager = {}
StateManager.__index = StateManager

function StateManager.new()
    return setmetatable({
        autoFarm = false,
        converting = false,
        killingMonster = false,
        isMoving = false,
        movingToCollectible = false,
        lastField = nil,
        lastPriorityCheck = 0,
        lastRegularCheck = 0
    }, StateManager)
end

function StateManager:reset()
    self.converting = false
    self.killingMonster = false
    self.isMoving = false
    self.movingToCollectible = false
end

-- Movement Manager - Handles all movement operations
local MovementManager = {}
MovementManager.__index = MovementManager

function MovementManager.new(state)
    return setmetatable({
        state = state,
        currentConnection = nil,
        visualPart = nil
    }, MovementManager)
end

function MovementManager:cancel()
    if self.currentConnection then
        self.currentConnection:Disconnect()
        self.currentConnection = nil
    end
    shared.character.humanoid:MoveTo(shared.character.rootPart.Position)
    self.state.isMoving = false
    self.state.movingToCollectible = false
    self:clearVisual()
end

function MovementManager:clearVisual()
    if self.visualPart then
        self.visualPart:Destroy()
        self.visualPart = nil
    end
end

function MovementManager:moveToAsync(position, isCollectible, item)
    self:clearVisual()
    if not self.state.autoFarm then return end

    self.visualPart = shared.character:createBillboard(position, item and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
    self.state.isMoving = true
    self.state.movingToCollectible = isCollectible or false
    
    shared.character.humanoid:MoveTo(position)
    local timeout = (shared.character:getDistance(position) / math.max(shared.character.humanoid.WalkSpeed, 16)) + Config.MOVEMENT_TIMEOUT_BUFFER
    local startTime = tick()
    
    self.currentConnection = shared.character.humanoid.MoveToFinished:Connect(function()
        self:cancel()
    end)
    
    while self.state.isMoving and self.state.autoFarm and not self.state.converting and shared.character:isValid() do
        if tick() - startTime > timeout then
            warn("Movement timed out")
            self:cancel()
            break
        end
        task.wait()
    end
    
    if item then item:SetAttribute("Collected", true) end
    self:clearVisual()
end

function MovementManager:tweenTo(position, onComplete, time)
    local tween = Services.TweenService:Create(
        shared.character.rootPart,
        TweenInfo.new(time or Config.MOVEMENT_TWEEN_TIME, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position)}
    )
    tween:Play()
    tween.Completed:Wait()
    if onComplete then onComplete() end
end

-- Collectible Manager - Handles collectible detection and management
local CollectibleManager = {}
CollectibleManager.__index = CollectibleManager

function CollectibleManager.new()
    return setmetatable({
        collectibles = {},
        nearbyCollectibles = {},
        touchedConnections = {}
    }, CollectibleManager)
end

function CollectibleManager:clear()
    self.collectibles = {}
    self.nearbyCollectibles = {}
    -- Disconnect all touched connections
    for child, connection in pairs(self.touchedConnections) do
        connection:Disconnect()
    end
    self.touchedConnections = {}
end

function CollectibleManager:shouldTrack(child)
    local shouldFarmBubble = shared.main.farmBubble ~= false
    return ((child.Name == "Bubble" and shouldFarmBubble) or child.Name == "C") 
           and not child:GetAttribute("Collected")
end

function CollectibleManager:isValidCollectible(child)
    local field = shared.main.currentField
    if not field then return false end
    
    local distance = (child.Position - field.Position).Magnitude
    local yDifference = math.abs(child.Position.Y - shared.character.rootPart.Position.Y)
    
    return distance <= field.Size.Magnitude / 2 and yDifference <= Config.COLLECTIBLE_Y_TOLERANCE
end

function CollectibleManager:getTokenData(child)
    if child.Name == "C" then
        local decal = child:FindFirstChild("FrontDecal")
        if decal and decal:IsA("Decal") then
            local id = tonumber(decal.Texture:match("rbxassetid://(%d+)"))
            return shared.Tokens:getTokenById(id)
        end
    end
    return child.Name, { id = -1, isSkill = false, priority = 1 }
end

function CollectibleManager:addCollectible(child)
    local _, data = self:getTokenData(child)
    table.insert(self.collectibles, {
        part = child,
        priority = data and data.priority or 10
    })
end

function CollectibleManager:removeCollectible(collectible)
    for _, list in ipairs({self.collectibles, self.nearbyCollectibles}) do
        for i = #list, 1, -1 do
            if list[i].part == collectible then
                table.remove(list, i)
            end
        end
    end
end

function CollectibleManager:cleanup()
    -- Clean collectibles
    for i = #self.collectibles, 1, -1 do
        local item = self.collectibles[i]
        if not item.part or not item.part.Parent or item.part:GetAttribute("Collected") then
            table.remove(self.collectibles, i)
        end
    end
    
    -- Clean nearby collectibles
    for i = #self.nearbyCollectibles, 1, -1 do
        local item = self.nearbyCollectibles[i]
        if not item.part or not item.part.Parent then
            table.remove(self.nearbyCollectibles, i)
        end
    end
end

function CollectibleManager:getBestNearby()
    self:cleanup()
    local best, bestScore = nil, math.huge
    local maxCheck = math.min(#self.nearbyCollectibles, Config.MAX_NEARBY_COLLECTIBLES)
    
    for i = 1, maxCheck do
        local item = self.nearbyCollectibles[i]
        local score = item.distance - (item.priority * Config.PRIORITY_MULTIPLIER)
        if score < bestScore then
            bestScore = score
            best = item.part
        end
    end
    return best
end

function CollectibleManager:getNearest()
    self:cleanup()
    
    -- Sort by priority and distance
    table.sort(self.collectibles, function(a, b)
        if a.priority == b.priority then
            return self:getDistance(a.part) < self:getDistance(b.part)
        else
            return a.priority > b.priority
        end
    end)
    
    for _, item in ipairs(self.collectibles) do
        if item.part and item.part.Parent then
            return item.part
        end
    end
    return nil
end

function CollectibleManager:getDistance(collectible)
    local pos = collectible:IsA("Model") and collectible:GetPivot().Position or collectible.Position
    return (shared.character.rootPart.Position - pos).Magnitude
end

function CollectibleManager:getPosition(collectible)
    return collectible:IsA("Model") and collectible:GetPivot().Position or collectible.Position
end

local MonsterManager = {}
MonsterManager.__index = MonsterManager

function MonsterManager.new(state)
    return setmetatable({
        state = state,
        monsters = {},
        jumpConnection = nil
    }, MonsterManager)
end

function MonsterManager:setup()
    -- Monster tracking
    Folders.Monsters.ChildAdded:Connect(function(monsterModel)
        if not monsterModel:IsA("Model") then return end
        
        task.delay(0.1, function()
            local humanoid = monsterModel:FindFirstChild("Humanoid")
            local target = monsterModel:FindFirstChild("Target")
            
            if humanoid and target and target:IsA("ObjectValue") and target.Value == shared.character.character then
                self.monsters[monsterModel] = humanoid
            end
        end)
    end)
    
    Folders.Monsters.ChildRemoved:Connect(function(monsterModel)
        self.monsters[monsterModel] = nil
    end)
    
    -- Monster combat loop
    self.jumpConnection = Services.RunService.Heartbeat:Connect(function()
        if self.state.autoFarm and not self.state.converting and not self.state.killingMonster then
            local monster = self:getClosest(Config.MONSTER_DETECTION_RADIUS)
            if monster then
                self:startCombat(monster)
            end
        end
    end)
end

function MonsterManager:getClosest(maxRadius)
    local closest, shortestDistance = nil, math.huge
    local myPosition = shared.character.rootPart.Position
    
    for monsterModel, humanoid in pairs(self.monsters) do
        if humanoid and humanoid.Health > 0 and monsterModel.PrimaryPart then
            local distance = (monsterModel.PrimaryPart.Position - myPosition).Magnitude
            if distance < shortestDistance and distance <= maxRadius then
                shortestDistance = distance
                closest = monsterModel
            end
        end
    end
    return closest
end

function MonsterManager:isAlive(monsterModel)
    local humanoid = self.monsters[monsterModel]
    return humanoid and humanoid.Health > 0
end

function MonsterManager:startCombat(monster)
    self.state.killingMonster = true
    
    task.spawn(function()
        local humanoid = shared.character.humanoid
        humanoid.JumpPower = 50
        local lastJump = tick()
        while self.state.autoFarm and self:isAlive(monster) and not self.state.converting do
            if tick() - lastJump >= Config.MONSTER_JUMP_INTERVAL then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                lastJump = tick()
            end
            task.wait(0.1)
        end
        
        self.state.killingMonster = false
        humanoid.JumpPower = shared.main.defaultJumpPower
    end)
end

function MonsterManager:destroy()
    if self.jumpConnection then
        self.jumpConnection:Disconnect()
        self.jumpConnection = nil
    end
end

local Bot = {}
Bot.__index = Bot

function Bot.new()
    local self = setmetatable({}, Bot)
    
    -- Initialize managers
    self.state = StateManager.new()
    self.movement = MovementManager.new(self.state)
    self.collectibles = CollectibleManager.new()
    self.monsters = MonsterManager.new(self.state)
    
    -- Initialize connections
    self.connections = {}
    self.farmThread = nil
    
    self:setup()
    return self
end

function Bot:setup()
    self.monsters:setup()
    self:setupCollectibles()
    self:setupRealtimeCheck()
end

function Bot:setupCollectibles()
    local folders = {Folders.Collectibles, Folders.Particles}
    
    for _, folder in ipairs(folders) do
        -- Process existing children
        for _, child in ipairs(folder:GetChildren()) do
            if self.collectibles:shouldTrack(child) and self.collectibles:isValidCollectible(child) then
                self.collectibles:addCollectible(child)
            end
        end
        
        -- Setup event connections
        self.connections[#self.connections + 1] = folder.ChildAdded:Connect(function(child)
            if not self.collectibles:shouldTrack(child) then return end
            
            if self.collectibles:isValidCollectible(child) then
                self.collectibles:addCollectible(child)
                
                if child:IsA("BasePart") then
                    self.collectibles.touchedConnections[child] = child.Touched:Connect(function(hit)
                        if hit and hit:IsDescendantOf(shared.character.character) and not child:GetAttribute("Collected") then
                            child:SetAttribute("Collected", true)
                            self.collectibles:removeCollectible(child)
                        end
                    end)
                end
            end
        end)
        
        self.connections[#self.connections + 1] = folder.ChildRemoved:Connect(function(child)
            self.collectibles:removeCollectible(child)
            if self.collectibles.touchedConnections[child] then
                self.collectibles.touchedConnections[child]:Disconnect()
                self.collectibles.touchedConnections[child] = nil
            end
        end)
    end
end

function Bot:setupRealtimeCheck()
    self.state.lastField = shared.main.currentField
    
    self.connections[#self.connections + 1] = Services.RunService.Heartbeat:Connect(function()
        if not self.state.autoFarm or self.state.converting then return end
        
        local currentTime = tick()
        
        -- Priority checks (nearby collectibles)
        if currentTime - self.state.lastPriorityCheck >= Config.PRIORITY_CHECK_INTERVAL then
            self.state.lastPriorityCheck = currentTime
            
            if #self.collectibles.nearbyCollectibles > 0 and not self.state.movingToCollectible then
                local best = self.collectibles:getBestNearby()
                if best then
                    self:collectItem(best)
                    return
                end
            end
        end
        
        -- Regular checks
        if currentTime - self.state.lastRegularCheck >= Config.REGULAR_CHECK_INTERVAL then
            self.state.lastRegularCheck = currentTime
            
            -- Field change detection
            if shared.main.currentField ~= self.state.lastField then
                self.state.lastField = shared.main.currentField
                self:handleFieldChange()
                return
            end
            
            -- Pollen conversion check
            if shared.hiveHelper and shared.hiveHelper:isPollenFull() then
                self:convertPollen()
                return
            end
            
            -- Movement optimization
            if self.state.isMoving and not self.state.movingToCollectible and #self.collectibles.nearbyCollectibles == 0 then
                local nearest = self.collectibles:getNearest()
                if nearest then
                    self:collectItem(nearest)
                end
            end
        end
    end)
end

function Bot:handleFieldChange()
    self.movement:cancel()
    self.collectibles:clear()
    self:setupCollectibles()
    self:returnToField()
end

function Bot:collectItem(collectible)
    if not collectible or not collectible.Parent then return end
    
    self.movement:cancel()
    local pos = self.collectibles:getPosition(collectible)
    self.movement:moveToAsync(pos, true, collectible)
end

function Bot:convertPollen()
    if self.state.converting then return end
    
    self.state.converting = true
    self.movement:cancel()
    
    task.spawn(function()
        shared.hiveHelper:gotoHive(function()
            task.wait(1)
            Services.ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
            
            local startTime = tick()
            local timeoutDuration = 180 
            
            while shared.hiveHelper.PollenValue > 0 and self.state.autoFarm and self.state.converting do
                task.wait(0.2)

                if tick() - startTime >= timeoutDuration then
                    break
                end
            end
            
            task.wait(Config.CONVERSION_DELAY)
            self.state.converting = false
            
            if self.state.autoFarm then
                self:returnToField()
            end
        end)
    end)
end

function Bot:returnToField(onComplete)
    if not self.state.autoFarm then return end
    
    if not shared.character:isPlayerInField() and shared.main.currentField then
        local fieldPos = shared.main.currentField.Position + Vector3.new(0, 3, 0)
        pcall(function()
            self.movement:tweenTo(fieldPos, onComplete)
        end)
    elseif onComplete then
        onComplete()
    end
end

function Bot:getRandomFieldPosition()
    local field = shared.main.currentField
    if not field then return shared.character.rootPart.Position end
    
    local size, center = field.Size, field.Position
    local padding = Config.FIELD_PADDING + 10
    local y = shared.character.rootPart.Position.Y
    
    local x = center.X + math.random(-size.X / 2 + padding, size.X / 2 - padding)
    local z = center.Z + math.random(-size.Z / 2 + padding, size.Z / 2 - padding)
    
    return Vector3.new(x, y, z)
end

function Bot:farmLoop()
    while self.state.autoFarm do
        if shared.hiveHelper and shared.hiveHelper:isPollenFull() then
            self:convertPollen()
            while self.state.converting and self.state.autoFarm do
                task.wait(0.1)
            end
            if not self.state.autoFarm then break end
        end
        
        if shared.character:isPlayerInField(shared.main.currentField) and not self.state.killingMonster then
            local nearest = self.collectibles:getNearest()
            if nearest then
                self:collectItem(nearest)
            else
                self.movement:moveToAsync(self:getRandomFieldPosition(), false)
            end
        end
        
        task.wait()
    end
end

function Bot:start()
    if self.state.autoFarm then return end
    
    self.state.autoFarm = true
    
    self.farmThread = task.spawn(function()
        shared.Rayfield:Notify({
            Title = "Notification",
            Content = "Auto Farm has been started.",
            Duration = 3
        })
        
        if shared.hiveHelper and shared.hiveHelper:isPollenFull() then
            self:convertPollen()
            while self.state.converting and self.state.autoFarm do
                task.wait(0.1)
            end
        end
        
        if self.state.autoFarm then
            if not shared.character:isPlayerInField(shared.main.currentField) then
                self:returnToField(function()
                    self:farmLoop()
                end)
            else
                self:farmLoop()
            end
        end
    end)
end

function Bot:stop()
    self.state.autoFarm = false
    self.movement:cancel()
    
    if self.farmThread then
        task.cancel(self.farmThread)
        self.farmThread = nil
    end
    
    self.state:reset()
    
    shared.Rayfield:Notify({
        Title = "Notification",
        Content = "Auto Farm has been stopped.",
        Duration = 3
    })
end

function Bot:destroy()
    self:stop()
    
    -- Disconnect all connections
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    self.connections = {}
    
    -- Destroy managers
    self.monsters:destroy()
    self.collectibles:clear()
end

return Bot