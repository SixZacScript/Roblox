-- Optimized and Efficient Bot Module
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local CollectiblesFolder = Workspace:WaitForChild("Collectibles")
local ParticlesFolder = Workspace:WaitForChild("Particles")

local Bot = {}
Bot.__index = Bot

local FIELD_PADDING = 5
local MOVEMENT_TWEEN_TIME = 1
local CONVERSION_DELAY = 5
local PRIORITY_CHECK_INTERVAL = 0.08
local REGULAR_CHECK_INTERVAL = 0.2


function Bot.new()
    local self = setmetatable({}, Bot)
    self:destroy()

    self.autoFarm = false
    self.converting = false
    self.farmThread = nil
    self.collectibles = {}
    self.nearbyCollectibles = {}
    self.isMoving = false
    self.movingToCollectible = false
    self.currentMoveConnection = nil
    self.lastPriorityCheck = 0
    self.lastRegularCheck = 0

    self:setupCollectiblesDetection()
    self:setupRealtimeCheck()

    return self
end

function Bot:setupRealtimeCheck()
    self.lastField = shared.main.currentField

    self.realtimeCheckConnection = RunService.Heartbeat:Connect(function()
        if not self.autoFarm or self.converting then return end

        local currentTime = tick()
        if currentTime - self.lastPriorityCheck >= PRIORITY_CHECK_INTERVAL then
            self.lastPriorityCheck = currentTime
            self:cleanupNearby()
            if #self.nearbyCollectibles > 0 and not self.movingToCollectible then
                local bestCollectible = self:getBestNearbyCollectible()
                if bestCollectible then
                    self:cancelCurrentMovement()
                    task.spawn(function()
                        self:collectItem(bestCollectible)
                    end)
                    return
                end
            end
        end

        if currentTime - self.lastRegularCheck >= REGULAR_CHECK_INTERVAL then
            self.lastRegularCheck = currentTime
            if shared.main.currentField ~= self.lastField then
                self.lastField = shared.main.currentField
                self:cancelCurrentMovement()
                self:clearCollectibles()
                self:setupCollectiblesDetection()
                self:returnToField()
                return
            end

            if shared.hiveHelper and shared.hiveHelper:isPollenFull() then
                self:cancelCurrentMovement()
                task.spawn(function()
                    self:convertPollen()
                end)
                return
            end

            if self.isMoving and not self.movingToCollectible and #self.nearbyCollectibles == 0 then
                local nearestCollectible = self:getNearestCollectible()
                if nearestCollectible then
                    self:cancelCurrentMovement()
                    task.spawn(function()
                        self:collectItem(nearestCollectible)
                    end)
                end
            end
        end
    end)
end

function Bot:setupCollectiblesDetection()
    local folders = { CollectiblesFolder, ParticlesFolder }
    local shouldFarmBubble = shared.main.farmBubble
    
    -- Store connections separately to avoid modifying game objects
    local touchedConnections = {}

    local function shouldTrack(child)
        return ((child.Name == "Bubble" and shouldFarmBubble) or child.Name == "C") and not child:GetAttribute("Collected")
    end

    local function getPriority(child)
        return child.Name == "Bubble" and 0 or (child:GetAttribute("Priority") or 1)
    end

    local function isInField(child)
        local currentField = shared.main.currentField
        return currentField and (child.Position - currentField.Position).Magnitude <= currentField.Size.Magnitude / 2
    end

    local function insertCollectible(child)
        table.insert(self.collectibles, { part = child, priority = getPriority(child) })
    end

    local function disconnectTouchedConnection(child)
        if touchedConnections[child] then
            touchedConnections[child]:Disconnect()
            touchedConnections[child] = nil
        end
    end

    for _, folder in ipairs(folders) do
        for _, child in ipairs(folder:GetChildren()) do
            if shouldTrack(child) and isInField(child) then
                insertCollectible(child)
            end
        end

        folder.ChildAdded:Connect(function(child)
            if not shouldTrack(child) then return end

            local function onTouched(hit)
                if hit and hit:IsDescendantOf(shared.character.character) and not child:GetAttribute("Collected") then
                    child:SetAttribute("Collected", true)
                    self:removeCollectibleFromTable(child)
                    disconnectTouchedConnection(child)
                end
            end

            if isInField(child) then
                insertCollectible(child)
                
                -- Check if the child is a BasePart before connecting to Touched
                if child:IsA("BasePart") then
                    touchedConnections[child] = child.Touched:Connect(onTouched)
                end

                local priority = getPriority(child)
                local distance = (self:getCollectiblePosition(child) - shared.character.rootPart.Position).Magnitude
                if self.autoFarm and not self.converting then
                    if priority >= 3 or distance <= 10 then
                        self:cancelCurrentMovement()
                        self:collectItem(child)
                    end
                end
            end
        end)

        folder.ChildRemoved:Connect(function(child)
            self:removeCollectibleFromTable(child)
            disconnectTouchedConnection(child)
        end)
    end
end


function Bot:cleanupNearby()
    for i = #self.nearbyCollectibles, 1, -1 do
        local item = self.nearbyCollectibles[i]
        if not item.part or not item.part.Parent then
            table.remove(self.nearbyCollectibles, i)
        end
    end
end

function Bot:getBestNearbyCollectible()
    self:cleanupNearby()
    local best, bestScore = nil, math.huge
    for i = 1, math.min(#self.nearbyCollectibles, 10) do
        local item = self.nearbyCollectibles[i]
        local score = item.distance - (item.priority * 5)
        if score < bestScore then
            bestScore = score
            best = item.part
        end
    end
    return best
end

function Bot:cancelCurrentMovement()
    if self.currentMoveConnection then
        self.currentMoveConnection:Disconnect()
        self.currentMoveConnection = nil
    end
    shared.character.humanoid:MoveTo(shared.character.rootPart.Position)
    self.isMoving = false
    self.movingToCollectible = false
    if self.VisualPart then self.VisualPart:Destroy() self.VisualPart = nil end
end

function Bot:getNearestCollectible()
    for i = #self.collectibles, 1, -1 do
        local item = self.collectibles[i]
        if not item.part or not item.part.Parent or (item and item.part and item.part:GetAttribute("Collected")) then
            table.remove(self.collectibles, i)
        end
    end

    local best, bestScore = nil, math.huge
    for i = 1, #self.collectibles do
        local item = self.collectibles[i]
        local score = self:getDistanceToCollectible(item.part) - (item.priority * 10)
        if score < bestScore  then
            bestScore = score
            best = item.part
        end
    end
    return best
end

function Bot:collectItem(collectible)
    if not collectible or not collectible.Parent then return end
    local pos = self:getCollectiblePosition(collectible)

    self:moveToAsync(pos, true, collectible)

end

function Bot:getCollectiblePosition(collectible)
    return collectible:IsA("Model") and collectible:GetPivot().Position or collectible.Position
end

function Bot:getDistanceToCollectible(collectible)
    return (shared.character.rootPart.Position - self:getCollectiblePosition(collectible)).Magnitude
end

function Bot:removeCollectibleFromTable(collectible)
    for _, list in ipairs({ self.collectibles, self.nearbyCollectibles }) do
        for _, item in ipairs(list) do
            if item.part == collectible then
                item.part = nil
                break
            end
        end
    end
end

function Bot:tweenTo(position, onComplete)
    local tween = TweenService:Create(shared.character.rootPart, TweenInfo.new(MOVEMENT_TWEEN_TIME, Enum.EasingStyle.Linear), {CFrame = CFrame.new(position)})
    tween:Play()
    tween.Completed:Wait()
    if onComplete then onComplete() end
end

function Bot:moveToAsync(position, isCollectible, item)
    if self.VisualPart then self.VisualPart:Destroy() end
    if not self.autoFarm then return end
    self.isMoving = true
    self.movingToCollectible = isCollectible or false

    shared.character.humanoid:MoveTo(position)
    local startTime, timeout = tick(), (shared.character:getDistance(position) / (shared.character.humanoid.WalkSpeed > 0 and shared.character.humanoid.WalkSpeed or 16)) + 2

    self.currentMoveConnection = shared.character.humanoid.MoveToFinished:Connect(function()
        if self.currentMoveConnection then self.currentMoveConnection:Disconnect() self.currentMoveConnection = nil end
        self.isMoving = false
        self.movingToCollectible = false
    end)
    local color = item and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    self.VisualPart = shared.character:createBillboard(position, color)

    while self.isMoving and self.autoFarm and not self.converting and shared.character:isValid() do
        if tick() - startTime > timeout then
            warn("Movement timed out")
            if self.currentMoveConnection then self.currentMoveConnection:Disconnect() self.currentMoveConnection = nil end
            self.isMoving = false
            self.movingToCollectible = false
            break
        end
        task.wait()
    end
    if item then 
        item:SetAttribute("Collected",true)
    end
    if self.VisualPart then self.VisualPart:Destroy() end
end

function Bot:getRandomPositionInField()
    local field = shared.main.currentField
    if not field then return shared.character.rootPart.Position end
    local size, center = field.Size, field.Position
    local padding, y = FIELD_PADDING + 10, shared.character.rootPart.Position.Y
    local x = center.X + math.random(-size.X / 2 + padding, size.X / 2 - padding)
    local z = center.Z + math.random(-size.Z / 2 + padding, size.Z / 2 - padding)
    return Vector3.new(x, y, z)
end

function Bot:convertPollen()
    if self.converting then return end
    self.converting = true
    self:cancelCurrentMovement()
    shared.hiveHelper:gotoHive(function()
        task.wait(1)
        game:GetService("ReplicatedStorage").Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
        while shared.hiveHelper.PollenValue > 0 and self.autoFarm and self.converting do task.wait(0.2) end
        task.wait(CONVERSION_DELAY)
        self.converting = false
        if self.autoFarm then task.spawn(function() self:returnToField() end) end
    end)
end

function Bot:returnToField(onComplete)
    if not self.autoFarm then return end
    if not shared.character:isPlayerInField() and shared.main.currentField then
        local fieldPos = shared.main.currentField.Position + Vector3.new(0, 3, 0)
        pcall(function() self:tweenTo(fieldPos, onComplete) end)
    elseif onComplete then
        onComplete()
    end
end

function Bot:farmInField()
    while self.autoFarm do
        local isInField = shared.character:isPlayerInField(shared.main.currentField)
        if shared.hiveHelper and shared.hiveHelper:isPollenFull() then
            self:convertPollen()
            while self.converting and self.autoFarm do task.wait(0.1) end
            if not self.autoFarm then break end
        end
        if isInField then 
            local nearest = self:getNearestCollectible()
            if nearest then 
                self:collectItem(nearest)
            else 
                self:moveToAsync(self:getRandomPositionInField(), false)
            end
        end
        
        task.wait()
    end
end

function Bot:start()
    if self.autoFarm then return end
    self.autoFarm = true
    local isInField = shared.character:isPlayerInField(shared.main.currentField)
    self.farmThread = task.spawn(function()
        shared.Rayfield:Notify({ Title = "Notification", Content = "Auto Farm has been started.", Duration = 6.5 })
        if shared.hiveHelper and shared.hiveHelper:isPollenFull() then
            self:convertPollen()
            while self.converting and self.autoFarm do task.wait(0.1) end
        end
        if self.autoFarm and not isInField then
            self:returnToField(function() self:farmInField() end)
        else
            self:farmInField()
        end
    end)
end

function Bot:stop()
    self.autoFarm = false
    if self.VisualPart then self.VisualPart:Destroy() self.VisualPart = nil end
    self:cancelCurrentMovement()
    if self.farmThread then task.cancel(self.farmThread) self.farmThread = nil end
    self.converting = false
    shared.Rayfield:Notify({ Title = "Notification", Content = "Auto Farm has been stopped.", Duration = 6.5 })
end

function Bot:clearCollectibles()
    self.collectibles = {}
    self.nearbyCollectibles = {}
end

function Bot:destroy()
    self:stop()
    if self.realtimeCheckConnection then self.realtimeCheckConnection:Disconnect() self.realtimeCheckConnection = nil end
    self:clearCollectibles()
end

return Bot
