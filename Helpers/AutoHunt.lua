local WP = workspace
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local AutoHunt = {}

-- Configuration
local CONFIG = {
    MOBS = {
        ["Rhino Beetle"] = true,
        ["Ladybug"] = true,
        ["Spider"] = true,
        ["Werewolf"] = true,
        ["Scorpion"] = true,
        -- ["Mantis"] = true,
    },
    TWEEN_DURATION = 2,
    MAIN_LOOP_INTERVAL = 0.5,
    JUMP_INTERVAL = 1.5,
    MAX_JUMP_ATTEMPTS = 50,
    TOKEN_COLLECTION_DISTANCE = 40,
    TERRITORY_HEIGHT_OFFSET = 3
}

function AutoHunt.new()
    local self = setmetatable({}, { __index = AutoHunt })
    
    -- State variables
    self.Enabled = shared.main.autoKillMobs
    self.hunting = false
    self.mobSpawners = {}
    self.tokens = {}
    self.currentTween = nil
    self.connections = {}
    
    -- Cache references
    self.Collectibles = shared.CollectiblesFolder
    
    -- Initialize
    self:_initialize()
    
    return self
end

function AutoHunt:_initialize()
    self:_cacheMobSpawners()
    self:_setupTokenCollection()
    self:_startMainLoop()
end

function AutoHunt:_cacheMobSpawners()
    local mobsFolder = workspace:WaitForChild("MonsterSpawners", 10)
    if not mobsFolder then
        warn("MonsterSpawners folder not found")
        return
    end
    
    self.mobSpawners = {}
    
    for _, mobSpawner in pairs(mobsFolder:GetChildren()) do
        local MonsterType = mobSpawner:FindFirstChild("MonsterType")
        if MonsterType and CONFIG.MOBS[MonsterType.Value] then
            local mobName = MonsterType.Value
            if not self.mobSpawners[mobName] then
                self.mobSpawners[mobName] = {}
            end
            table.insert(self.mobSpawners[mobName], mobSpawner)
        end
    end
end

function AutoHunt:_setupTokenCollection()
    if not self.Collectibles then return end
    
    -- Token addition handler
    self.connections.tokenAdded = self.Collectibles.ChildAdded:Connect(function(token)
        if not (self.Enabled and self.hunting and shared.character) then return end
        
        local distance = shared.character:getDistance(token.Position)
        if distance <= CONFIG.TOKEN_COLLECTION_DISTANCE then
            table.insert(self.tokens, token)
        end
    end)
    
    -- Token removal handler (optimized)
    self.connections.tokenRemoved = self.Collectibles.ChildRemoved:Connect(function(token)
        for i = #self.tokens, 1, -1 do
            if self.tokens[i] == token then
                table.remove(self.tokens, i)
                break
            end
        end
    end)
end

function AutoHunt:_startMainLoop()
    if not self.Enabled then return end
    self.connections.mainLoop = task.spawn(function()
        -- Wait for dependencies
        repeat task.wait(1) until shared.hiveHelper and shared.hiveHelper.Hive
        
        while self.Enabled do
            if not self.hunting then
                local readyMob = self:_getFirstReadyMob()
                if readyMob then
                    if shared.botHelper.state.autoFarm then shared.botHelper:stop() end
                    self:_huntMob(readyMob)
                end
            end
            task.wait(CONFIG.MAIN_LOOP_INTERVAL)
        end
        if shared.botHelper.state.autoFarm then shared.botHelper:start() end
    end)
end

function AutoHunt:_getFirstReadyMob()
    for mobName in pairs(CONFIG.MOBS) do
        if self:_isMobReady(mobName) then
            return mobName
        end
    end
    return nil
end

function AutoHunt:_isMobReady(mobName)
    local spawners = self.mobSpawners[mobName]
    if not spawners then return false end
    
    for _, mobSpawner in pairs(spawners) do
        if mobSpawner.Parent then
            local timerLabel = self:_getTimerLabel(mobSpawner)
            if timerLabel and not timerLabel.Visible then
                return true
            end
        end
    end
    return false
end

function AutoHunt:_getReadyMobSpawner(mobName)
    local spawners = self.mobSpawners[mobName]
    if not spawners then return nil end
    
    for _, mobSpawner in pairs(spawners) do
        if mobSpawner.Parent then
            local timerLabel = self:_getTimerLabel(mobSpawner)
            if timerLabel and not timerLabel.Visible then
                return mobSpawner
            end
        end
    end
    return nil
end

function AutoHunt:_tweenTo(targetPosition, callback)
    if not self:_validateCharacter() then return end
    
    -- Cancel current tween
    self:_cancelCurrentTween()
    
    local tweenInfo = TweenInfo.new(CONFIG.TWEEN_DURATION, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(
        shared.character.rootPart,
        tweenInfo,
        {CFrame = targetPosition}
    )
    
    self.currentTween = tween
    
    -- Handle completion
    local connection
    connection = tween.Completed:Connect(function(playbackState)
        connection:Disconnect()
        self.currentTween = nil
        
        if playbackState == Enum.PlaybackState.Completed and callback then
            callback()
        end
    end)
    
    tween:Play()
    return tween
end

function AutoHunt:_huntMob(mobName)
    local mobSpawner = self:_getReadyMobSpawner(mobName)
    if not mobSpawner then return end
    
    local territory = self:_getTerritory(mobSpawner)
    if not territory or not self:_validateCharacter() then return end
    
    -- Reset tokens and set hunting state
    self.tokens = {}
    self.hunting = true
    
    local targetPosition = CFrame.new(territory.Position + Vector3.new(0, CONFIG.TERRITORY_HEIGHT_OFFSET, 0))
    
    self:_tweenTo(targetPosition, function()
        self:_spawnMobAndCollectTokens(mobSpawner)
    end)
end

function AutoHunt:_spawnMobAndCollectTokens(mobSpawner)
    if not self.Enabled then return end
    
    local timerLabel = self:_getTimerLabel(mobSpawner)
    if not timerLabel then
        self.hunting = false
        return
    end
    

    local jumpAttempts = 0
    
    while (timerLabel and not timerLabel.Visible and 
            self:_validateCharacter() and 
            jumpAttempts < CONFIG.MAX_JUMP_ATTEMPTS and 
            self.Enabled) do
        
        shared.character.humanoid.Jump = true
        jumpAttempts += 1
        task.wait(CONFIG.JUMP_INTERVAL)
    end
    task.wait(1)
    self:_collectTokens()


end

function AutoHunt:_collectTokens()
    if not self:_validateCharacter() then return end
    
    local character = shared.character
    local humanoid = character.humanoid
    
    for i, token in ipairs(self.tokens) do
        if (token and token.Parent and 
            token:IsDescendantOf(self.Collectibles) and 
            token:IsA("BasePart")) then
            
            humanoid:MoveTo(token.Position)
            
            -- Wait with timeout
            local moveConnection
            local timeoutConnection
            local completed = false
            
            moveConnection = humanoid.MoveToFinished:Connect(function()
                completed = true
            end)
            
            timeoutConnection = task.delay(5, function()
                completed = true
            end)
            
            repeat task.wait() until completed
            
            moveConnection:Disconnect()
            task.cancel(timeoutConnection)
            
            if not self:_validateCharacter() then break end
        end
    end
    self.hunting = false
    self.tokens = {}

    local readyMob = self:_getFirstReadyMob()
    if not readyMob and not shared.botHelper.state.autoFarm then 
        shared.botHelper:start()
    end
end

function AutoHunt:_getTerritory(mobSpawner)
    if not mobSpawner then return nil end
    
    local Territory = mobSpawner:FindFirstChild("Territory")
    if not Territory or not Territory:IsA("ObjectValue") or not Territory.Value then
        return nil
    end
    
    local value = Territory.Value
    
    if value:IsA("BasePart") then
        return value
    elseif value:IsA("Folder") then
        for _, child in pairs(value:GetChildren()) do
            if child:IsA("BasePart") then
                return child
            end
        end
    end
    
    return nil
end

function AutoHunt:_getTimerLabel(mobSpawner)
    if not mobSpawner then return nil end
    
    local attachment = mobSpawner:FindFirstChildOfClass("Attachment")
    if not attachment then return nil end
    
    local TimerGui = attachment:FindFirstChild("TimerGui")
    if not TimerGui then return nil end
    
    return TimerGui:FindFirstChild("TimerLabel")
end

function AutoHunt:_validateCharacter()
    return shared.character and shared.character:isValid() and shared.character.rootPart
end

function AutoHunt:_cancelCurrentTween()
    if self.currentTween then
        self.currentTween:Cancel()
        self.currentTween = nil
    end
end

function AutoHunt:_cleanup()
    self:_cancelCurrentTween()
    
    -- Disconnect all connections
    for _, connection in pairs(self.connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        elseif typeof(connection) == "thread" then
            task.cancel(connection)
        end
    end
    
    self.connections = {}
end

function AutoHunt:Destroy()
    self.Enabled = false
    self.hunting = false
    self:_cleanup()
end

function AutoHunt:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
    return self.Enabled
end

function AutoHunt:Enable()
    if self.Enabled then return end
    
    self.Enabled = true
    self.hunting = false
    
    -- Restart main loop if it was stopped
    if not self.connections.mainLoop then
        self:_startMainLoop()
        print("start new loop")
    end
    
    -- Re-setup token collection if needed
    if not self.connections.tokenAdded or not self.connections.tokenRemoved then
        self:_setupTokenCollection()
        print("start new Token Collection")
    end
    
    print("AutoHunt: Enabled")
end

function AutoHunt:Disable()
    if not self.Enabled then return end
    
    self.Enabled = false
    self.hunting = false
    
    -- Cancel any current tween
    self:_cancelCurrentTween()
    
    -- Clear tokens
    self.tokens = {}
    print("AutoHunt: Disabled")
end

-- Optional: Get current state
function AutoHunt:IsEnabled()
    return self.Enabled
end
return AutoHunt