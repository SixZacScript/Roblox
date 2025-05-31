local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HiveHelper = {}
HiveHelper.__index = HiveHelper

function HiveHelper.new()
    local self = setmetatable({}, HiveHelper)
    self.Hive = self:getHive()
    return self
end
function HiveHelper:getPlayerCharacter()
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    self.character = character
    return character
end
function HiveHelper:getHive()
    local LocalPlayer = Players.LocalPlayer
    local playerCharacter = self:getPlayerCharacter()
    local honeycombs = workspace.Honeycombs:GetChildren()

    -- First: check if player already owns a hive
    for _, hive in ipairs(honeycombs) do
        local owner = hive:FindFirstChild("Owner")
        if owner and owner.Value == LocalPlayer then
            self.Hive = hive
            return hive
        end
    end

    -- Third: fallback to finding the nearest hive and try to claim it
    local closestHive, closestDist, closestIndex = nil, math.huge, nil
    for i, hive in ipairs(honeycombs) do
        local Base = hive and hive:FindFirstChild("patharrow") and hive.patharrow:FindFirstChild("Base")
        local owner = hive:FindFirstChild("Owner")
        local dist = (playerCharacter.HumanoidRootPart.Position - Base.Position).Magnitude
        if dist < closestDist and (owner and not owner.Value) then
            closestHive = hive
            closestDist = dist
            closestIndex = i
        end
    end

    if closestIndex then
        game:GetService("ReplicatedStorage").Events.ClaimHive:FireServer(closestIndex)
        self.Hive = closestHive
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
    self:tweenTo(Base.Position + Vector3.new(0, 3, 0), onComplete)
end

function HiveHelper:tweenTo(targetPos, callback)
    local playerCharacter = self:getPlayerCharacter()
    local rootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
    
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(targetPos)})

	tween:Play()
	tween.Completed:Connect(function()
		if callback then callback() end
	end)
end
function HiveHelper:getBaseDistance()
    local Hive = self.Hive 
    local Base = Hive and Hive:FindFirstChild("patharrow") and Hive.patharrow:FindFirstChild("Base")
    local playerCharacter = self:getPlayerCharacter()
    local rootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
    local basePos = Vector3.new(Base.Position.X, rootPart.Position.Y, Base.Position.Z)
    local dist = Base and (playerCharacter.HumanoidRootPart.Position - basePos).Magnitude or math.huge

    return dist
end
return HiveHelper