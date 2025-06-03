local TweenService = game:GetService("TweenService")
local HiveHelper = {}
HiveHelper.__index = HiveHelper

function HiveHelper.new()
    local self = setmetatable({}, HiveHelper)
    self.Hive = self:getHive()

    self.CoreStats = shared.character.CoreStats
    self.PollenValue =  self.CoreStats.Pollen.Value
    self.HoneyValue = self.CoreStats.Honey.Value
    self.CapacityValue = self.CoreStats.Capacity.Value
    self:setupStatsConnection()
    return self
end
function HiveHelper:setupStatsConnection()
    local CoreStats = shared.character.CoreStats
    local Pollen = CoreStats:WaitForChild("Pollen")
    local Capacity = CoreStats:WaitForChild("Capacity")
    local Honey = CoreStats:WaitForChild("Honey")

    self._connections = self._connections or {}

    local function bindStat(statName, statObject)
        self[statName .. "Value"] = statObject.Value
        self._connections[statName] = statObject.Changed:Connect(function(val)
            self[statName .. "Value"] = val
        end)
    end

    bindStat("Pollen", Pollen)
    bindStat("Capacity", Capacity)
    bindStat("Honey", Honey)
end

function HiveHelper:isPollenFull()
    return self.PollenValue >= self.CapacityValue
end
function HiveHelper:getHive()
    print("Searching for Hive...")
    local LocalPlayer = shared.character.localPlayer
    local playerCharacter = shared.character.character
    local honeycombs = workspace.Honeycombs:GetChildren()

    -- First, check if already has hive
    for _, hive in ipairs(honeycombs) do
        local owner = hive:FindFirstChild("Owner")
        if owner and owner.Value == LocalPlayer then
            self.Hive = hive
            return hive
        end
    end

    -- Find the nearest unclaimed hive
    local closestHive, closestDist = nil, math.huge
    for _, hive in ipairs(honeycombs) do
        local base = hive:FindFirstChild("patharrow") and hive.patharrow:FindFirstChild("Base")
        local owner = hive:FindFirstChild("Owner")
        if base and (not owner or not owner.Value) then
            local dist = (shared.character.rootPart.Position - base.Position).Magnitude
            if dist < closestDist then
                closestHive = hive
                closestDist = dist
            end
        end
    end

    -- Function to retry hive claim
    local function tryClaimHive(hive)
        local basePos = hive.patharrow.Base.Position + Vector3.new(0, 3, 0)
        shared.character:tweenTo(basePos, function()
            task.wait(0.2)
            local VirtualInputManager = game:GetService("VirtualInputManager")
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

            -- Recheck after delay
            task.delay(0.5, function()
                for _, hive in ipairs(workspace.Honeycombs:GetChildren()) do
                    local owner = hive:FindFirstChild("Owner")
                    if owner and owner.Value == LocalPlayer then
                        self.Hive = hive
                        print("Hive claimed successfully.")
                        return
                    end
                end
                print("Hive claim failed. Retrying...")
                self:getHive() -- Retry if still not claimed
            end)
        end)
    end

    -- Try to claim the hive
    if closestHive then
        tryClaimHive(closestHive)
        return closestHive
    end

    return nil
end

function HiveHelper:gotoHive(onComplete)
    local Hive = self.Hive 
    local Base = Hive and Hive:FindFirstChild("patharrow") and Hive.patharrow:FindFirstChild("Base")
    if not Base then
        warn("Base not found in patharrow")
        return self:gotoHive(onComplete)
    end
    shared.character:tweenTo(Base.Position + Vector3.new(0, 3, 0), onComplete)
end

function HiveHelper:removeAllConnections()
    if self._connections then
        for _, conn in pairs(self._connections) do
            if conn.Disconnect then conn:Disconnect() end
        end
        self._connections = {}
    end
end
return HiveHelper