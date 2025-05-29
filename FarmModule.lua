-- Optimized FarmModule

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectiblesFolder = Workspace:WaitForChild("Collectibles")

local FarmModule = {}
FarmModule.__index = FarmModule

local itemToPickup, startFarm, convertPollen, tokenMode = {}, false, false, "First"
local childAddedConn, childRemovedConn

function FarmModule:init(managerRef)
    self.manager = managerRef
    local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    character:WaitForChild("Humanoid")
    character:WaitForChild("HumanoidRootPart")
    self.character = character
    if not managerRef.Hive then self:getUnclaimHive() end
    return self
end

function FarmModule:startFarming()
    if not shared.main or not shared.main.currentField then
        warn("Missing field configuration")
        return
    end

    startFarm = true
    self:setupListener()
    self:checkingStatus()

    task.spawn(function()
        while startFarm do
            if shared.main.Pollen >= shared.main.Capacity and not convertPollen then
                convertPollen = true
                self:gotoHive(function() self:convertPollen() end)
            end
            task.wait(0.1)
        end
    end)

    task.spawn(function()
        while startFarm do
            if not convertPollen then
                while #itemToPickup > 0 do
                    local item = self:getNextItem()
                    if item and item:IsDescendantOf(CollectiblesFolder) and self:isInField(item.Position) then
                        self:moveTo(item.Position, item)
                    else
                        for i, v in ipairs(itemToPickup) do
                            if v == item then
                                table.remove(itemToPickup, i)
                                break
                            end
                        end
                    end
                    task.wait()
                end

                local randomPos = self:getRandomPosinField()
                self:moveTo(randomPos)
            end
            task.wait()
        end
    end)
end

function FarmModule:getNextItem()
    if tokenMode == "Nearest" and self.character then
        local root = self.character.PrimaryPart
        local closestItem, shortestDist = nil, math.huge
        for _, item in ipairs(itemToPickup) do
            if item and item:IsDescendantOf(CollectiblesFolder) then
                local dist = (item.Position - root.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestItem = item
                end
            end
        end
        return closestItem
    end
    return itemToPickup[1]
end

function FarmModule:stopFarming()
    startFarm = false
    if childAddedConn then childAddedConn:Disconnect() end
    if childRemovedConn then childRemovedConn:Disconnect() end
end

function FarmModule:moveTo(position, item)
    local humanoid = self.character:FindFirstChild("Humanoid")
    humanoid:MoveTo(position)
    local reached = false

    local conn = humanoid.MoveToFinished:Connect(function(success)
        reached = true
        if success and item then
            for i, v in ipairs(itemToPickup) do
                if v == item then
                    table.remove(itemToPickup, i)
                    break
                end
            end
        end
        conn:Disconnect()
    end)

    while not reached and humanoid and humanoid.Health > 0 and startFarm do
        if item and not item:IsDescendantOf(CollectiblesFolder) then break end
        task.wait()
    end
end

function FarmModule:setupListener()
    childAddedConn = CollectiblesFolder.ChildAdded:Connect(function(item)
        table.insert(itemToPickup, item)
    end)

    childRemovedConn = CollectiblesFolder.ChildRemoved:Connect(function(item)
        for i, v in ipairs(itemToPickup) do
            if v == item then
                table.remove(itemToPickup, i)
                break
            end
        end
    end)
end

function FarmModule:getRandomPosinField()
    local root = self.character.PrimaryPart
    local field = shared.main.currentField
    local offsetX, offsetZ

    repeat
        offsetX = (math.random() - 0.5) * 60
        offsetZ = (math.random() - 0.5) * 60
    until (offsetX^2 + offsetZ^2) <= 900

    local target = field.Position + Vector3.new(offsetX, 0, offsetZ)
    return Vector3.new(target.X, root.Position.Y, target.Z)
end

function FarmModule:isInField(position)
    local field = shared.main.currentField
    local size, center = field.Size, field.Position
    return position.X >= center.X - size.X/2 and position.X <= center.X + size.X/2
        and position.Z >= center.Z - size.Z/2 and position.Z <= center.Z + size.Z/2
end

function FarmModule:changeTokenMode(mode)
    tokenMode = mode
end

function FarmModule:convertPollen()
    local Event = ReplicatedStorage.Events.PlayerHiveCommand
    Event:FireServer("ToggleHoneyMaking")
    repeat task.wait(3) until shared.main.Pollen <= 0
    convertPollen = false
end

function FarmModule:getUnclaimHive()
    for i, hive in pairs(Workspace.Honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and not hive.Owner.Value then
            ReplicatedStorage.Events.ClaimHive:FireServer(i)
            self.manager.Hive = hive
            print("Claimed hive at index:", i)
            return hive
        end
    end
end

function FarmModule:gotoHive(onComplete)
    local Hive = self.manager.Hive
    local Base = Hive and Hive:FindFirstChild("patharrow") and Hive.patharrow:FindFirstChild("Base")
    if not Base then return warn("Base not found") end
    local tween = self.manager.TweenHelper:tweenTo(Base.Position, self.manager.character)
    if tween and onComplete then onComplete() end
    return tween
end

function FarmModule:checkingStatus()
    local Capacity, Pollen = shared.main.Capacity, shared.main.Pollen
    if Pollen >= Capacity and not convertPollen then
        convertPollen = true
        self:gotoHive(function() self:convertPollen() end)
    elseif not convertPollen then
        local field = self.flowerZones:FindFirstChild(self.selectedZone)
        local distance = (self.character.PrimaryPart.Position - field.Position).Magnitude
        if distance > 30 then
            local success = self.TweenHelper:tweenTo(field.Position, self.character)
            if not success then warn("Tween to field failed") end
        else
            self:moveTo(self:getRandomPosinField())
        end
    end
end

return FarmModule
