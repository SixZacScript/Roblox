-- local WP = game:GetService("Workspace")
-- local CollectiblesFolder = WP:WaitForChild("Collectibles")

-- local FarmModule = {}
-- FarmModule.__index = FarmModule

-- function FarmModule:init(managerRef)
--     self.manager = managerRef
--     self:initVariable()


--     if not managerRef.Hive then self:getUnclaimHive() end
--     return self
-- end

-- function FarmModule:initVariable()
--     self.itemToPickup = {}
--     self.startFarm = false
--     self.convertPollen = false
--     self.tokenMode = "First"
--     self.childAddedConn = nil
--     self.childRemovedConn = nil
-- end

-- function FarmModule:startFarming()
--     if not shared.main or not shared.main.currentField then
--         warn("Missing field configuration")
--         return
--     end

--     self:initVariable()
--     self:setupListener()
--     self:startGathering()
-- end

-- function FarmModule:startGathering()
--    local isConverting =  self:checkingPollen()
--    if isConverting then return end
--     self:gotoField(function()
--         print("Starting farming in field:", shared.main.currentField.Name)
--     end)
--     task.spawn(function()
--         while self.startFarm and not self.convertPollen do
--             while #self.itemToPickup > 0 do
--                 local item = self:getNextItem()
--                 if item and item:IsDescendantOf(CollectiblesFolder) and self:isInField(item.Position) then
--                     self:moveTo(item.Position, item)
--                 else
--                     for i, v in ipairs(self.itemToPickup) do
--                         if v == item then
--                             table.remove(self.itemToPickup, i)
--                             break
--                         end
--                     end
--                 end
--                 task.wait()
--             end

--             if not convertPollen then
--                 local randomPos = self:getRandomPosinField()
--                 self:moveTo(randomPos, nil)
--             end
--             task.wait()
--         end
--     end)
-- end

-- function FarmModule:getNextItem()
--     local character = self.manager.character
--     if self.tokenMode == "Nearest" and character then
--         local root = character.PrimaryPart
--         local closestItem, shortestDist = nil, math.huge
--         for _, item in ipairs(self.itemToPickup) do
--             if item and item:IsDescendantOf(CollectiblesFolder) then
--                 local dist = (item.Position - root.Position).Magnitude
--                 if dist < shortestDist then
--                     shortestDist = dist
--                     closestItem = item
--                 end
--             end
--         end
--         return closestItem
--     else
--         return self.itemToPickup[1]
--     end
-- end

-- function FarmModule:stopFarming()
--     self.startFarm = false
--     if self.childAddedConn then
--         self.childAddedConn:Disconnect()
--     end
--     if self.childRemovedConn then
--         self.childRemovedConn:Disconnect()
--     end
--     self:initVariable()
-- end

-- function FarmModule:moveTo(position, item)
--     local char = self.manager.character
--     local humanoid = char:FindFirstChild("Humanoid")
--     local reached = false
--     local successResult = false

--     humanoid:MoveTo(position)
--     local conn
--     conn = humanoid.MoveToFinished:Connect(function(success)
--         successResult = success
--         reached = true
--         if conn then
--             conn:Disconnect()
--         end
--     end)

--     while not reached and humanoid and humanoid.Health > 0 do
--         if not self.startFarm or self.convertPollen then
--             if conn then conn:Disconnect() end
--             break
--         end
--         if item and not item:IsDescendantOf(CollectiblesFolder) then
--             if conn then conn:Disconnect() end
--             break
--         end
--         task.wait()
--     end

--     if item and successResult then
--         for i, v in ipairs(self.itemToPickup) do
--             if v == item then
--                 table.remove(self.itemToPickup, i)
--                 break
--             end
--         end
--     end
-- end


-- function FarmModule:getRandomPosinField()
--     local character = self.manager.character
--     local rootPart = character.PrimaryPart
--     local currentField = shared.main.currentField
--     local position = currentField.Position
--     local maxDistance = 30
--     local offsetX, offsetZ

--     repeat
--         offsetX = (math.random() - 0.5) * 2 * maxDistance
--         offsetZ = (math.random() - 0.5) * 2 * maxDistance
--     until math.sqrt(offsetX * offsetX + offsetZ * offsetZ) <= maxDistance

--     local randomOffset = Vector3.new(offsetX, 0, offsetZ)
--     local targetPosition = position + randomOffset
--     return Vector3.new(targetPosition.X, rootPart.Position.Y, targetPosition.Z)
-- end

-- function FarmModule:isInField(position)
--     local currentField = shared.main.currentField
--     local size = currentField.Size
--     local center = currentField.Position
--     local halfSize = size * 0.5

--     local minX = center.X - halfSize.X
--     local maxX = center.X + halfSize.X
--     local minZ = center.Z - halfSize.Z
--     local maxZ = center.Z + halfSize.Z

--     return position.X >= minX and position.X <= maxX and position.Z >= minZ and position.Z <= maxZ
-- end

-- function FarmModule:changeTokenMode(mode)
--     self.tokenMode = mode
-- end

-- function FarmModule:CharacterAdded(char)
--     self.manager.character = char
-- end

-- function FarmModule:convertPollen()
--     local Capacity, Pollen = shared.main.Capacity, shared.main.Pollen
--     local Event = game:GetService("ReplicatedStorage").Events.PlayerHiveCommand
--     Event:FireServer("ToggleHoneyMaking")

--     repeat
--         Capacity, Pollen = shared.main.Capacity, shared.main.Pollen
--         task.wait(5)
--     until Pollen <= 0

--     self.convertPollen = false
--    if self.startFarm then  self:startGathering() end
-- end


-- function FarmModule:getUnclaimHive()
--     local Honeycombs = workspace:FindFirstChild("Honeycombs")
--     for index,hive in pairs(Honeycombs:GetChildren()) do
--         local OwnerObject = hive:FindFirstChild("Owner")
--         if OwnerObject and not OwnerObject.Value then
--             local Event = game:GetService("ReplicatedStorage").Events.ClaimHive
--             Event:FireServer(table.unpack({index}))
--             self.manager.Hive = hive
--             print("Claimed hive at index:", index)
--             return hive
--         end
--     end
-- end
-- function  FarmModule:gotoField(onComplete)
--     local currentField = shared.main.currentField
--     if not currentField then
--         warn("Current field is not set")
--         return
--     end
--     local distance = (currentField.Position - self.manager.character.PrimaryPart.Position).Magnitude
--     if distance <= 30 then
--         if onComplete then onComplete() end
--         return
--     end

--     local tween = self.manager.TweenHelper:tweenTo(currentField.Position, self.manager.character, onComplete)
--     return tween
-- end
-- function FarmModule:gotoHive(onComplete)
--     local Hive = self.manager.Hive
--     local patharrow = Hive and Hive:FindFirstChild("patharrow")
--     local Base = patharrow and patharrow:FindFirstChild("Base")
--     if not Base then
--         warn("Base not found in patharrow")
--         return
--     end

--     local tween = self.manager.TweenHelper:tweenTo(Base.Position, self.manager.character, onComplete)
--     return tween
-- end
-- function FarmModule:checkingPollen()
--     if self.convertPollen then return true end 
--     local Capacity, Pollen = shared.main.Capacity, shared.main.Pollen
--     if Pollen >= Capacity then
--         convertPollen = true
--         self:gotoHive(function()
--             task.wait(1)
--             print("Converting pollen to honey...")
--             self:convertPollen()
--         end)
--     end
--     return self.convertPollen
-- end

-- function FarmModule:setupListener()
--     self.childAddedConn = CollectiblesFolder.ChildAdded:Connect(function(item)
--         table.insert(self.itemToPickup, item)
--     end)

--     self.childRemovedConn = CollectiblesFolder.ChildRemoved:Connect(function(item)
--         for i, v in ipairs(self.itemToPickup) do
--             if v == item then
--                 table.remove(self.itemToPickup, i)
--                 break
--             end
--         end
--     end)
--     task.spawn(function()
--         while self.startFarm do
--             self:checkingPollen()
--             task.wait(0.1)
--         end
--     end)
-- end
-- return FarmModule
