local Players = game:GetService("Players")
local WP = game:GetService("Workspace")
local CollectiblesFolder = WP:WaitForChild("Collectibles")

local FarmModule = {}
FarmModule.__index = FarmModule

local itemToPickup = {}
local startFarm = false
local tokenMode = "First"
local childAddedConn, childRemovedConn

function FarmModule:init()
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    character:WaitForChild("Humanoid")
    character:WaitForChild("HumanoidRootPart")
    self.character = character
end

function FarmModule:startFarming()
    if not shared.main or not shared.main.currentField then
        warn("Missing field configuration")
        return
    end

    startFarm = true
    self:setupListener()

    task.spawn(function()
        while startFarm do
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
            self:moveTo(randomPos, nil)
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
    else
        return itemToPickup[1]
    end
end

function FarmModule:stopFarming()
    startFarm = false
    if childAddedConn then
        childAddedConn:Disconnect()
    end
    if childRemovedConn then
        childRemovedConn:Disconnect()
    end
end

function FarmModule:moveTo(position, item)
    local char = self.character
    local humanoid = char:FindFirstChild("Humanoid")
    local rootPart = char.PrimaryPart

    local reached = false
    local successResult = false

    humanoid:MoveTo(position)
    local conn
    conn = humanoid.MoveToFinished:Connect(function(success)
        successResult = success
        reached = true
        if conn then
            conn:Disconnect()
        end
    end)

    while not reached and humanoid and humanoid.Health > 0 do
        if not startFarm then
            break
        end
        if item and not item:IsDescendantOf(CollectiblesFolder) then
            break
        end
        task.wait()
    end

    if item and successResult then
        for i, v in ipairs(itemToPickup) do
            if v == item then
                table.remove(itemToPickup, i)
                break
            end
        end
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
    local character = self.character
    local rootPart = character.PrimaryPart
    local currentField = shared.main.currentField
    local size = currentField.Size
    local position = currentField.Position

    local maxDistance = 30
    local offsetX, offsetZ

    repeat
        offsetX = (math.random() - 0.5) * 2 * maxDistance
        offsetZ = (math.random() - 0.5) * 2 * maxDistance
    until math.sqrt(offsetX * offsetX + offsetZ * offsetZ) <= maxDistance

    local randomOffset = Vector3.new(offsetX, 0, offsetZ)
    local targetPosition = position + randomOffset
    return Vector3.new(targetPosition.X, rootPart.Position.Y, targetPosition.Z)
end

function FarmModule:isInField(position)
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

function FarmModule:changeTokenMode(mode)
    tokenMode = mode
end

return FarmModule
