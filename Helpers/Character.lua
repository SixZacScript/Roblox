local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Character = {}
Character.__index = Character

function Character.new()
    local self = setmetatable({}, Character)

    self.localPlayer = Players.LocalPlayer
    self.character = self.localPlayer.Character or
                         self.localPlayer.CharacterAdded:Wait()
    self.rootPart = self.character.PrimaryPart
    self.humanoid = self.character:WaitForChild("Humanoid")
    self.health = self.humanoid.Health
    self.maxHealth = self.humanoid.MaxHealth
    self.humanoid.WalkSpeed = shared.main.defaultWalkSpeed
    self.humanoid.JumpPower = shared.main.defaultJumpPower
    self.CoreStats = self.localPlayer:WaitForChild("CoreStats")
    -- self.rootPart.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0)

    self.localPlayer.CharacterAdded:Connect(
        function(newCharacter)
            task.wait(3)
            self.character = newCharacter
            self.humanoid = newCharacter:WaitForChild("Humanoid")
            self.rootPart = self.character.PrimaryPart
            self.CoreStats = self.localPlayer:WaitForChild("CoreStats")
            self.health = self.humanoid.Health
            self.maxHealth = self.humanoid.MaxHealth
            self.humanoid.WalkSpeed = shared.main.defaultWalkSpeed
            self.humanoid.JumpPower = shared.main.defaultJumpPower
            if shared.botHelper.autoFarm then
                shared.botHelper:cancelCurrentMovement()
                shared.botHelper:returnToField(function()
                    shared.botHelper:farmInField()
                end)
            end
        end)
    return self
end

function Character:getDistance(targetPos)
    return
        (self.character:WaitForChild("HumanoidRootPart").Position - targetPos).Magnitude
end

function Character:createBillboard(pos, color)
    local partColor = color or Color3.fromRGB(255, 0, 0)

    local part = Instance.new("Part")
    part.Size = Vector3.new(2, 2, 2)
    part.Position = pos
    part.Anchored = true
    part.CanCollide = false
    part.Color = partColor
    part.Material = Enum.Material.Neon
    part.Name = "MoveToPart"
    part.Parent = workspace.Terrain

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MoveToBillboard"
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = part
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 251, 0)
    label.TextScaled = true
    label.Text = ""
    label.Parent = billboard

    -- Create beam line
    local a0 = Instance.new("Attachment")
    a0.Name = "StartAttachment"
    a0.Parent = shared.character.rootPart

    local a1 = Instance.new("Attachment")
    a1.Name = "EndAttachment"
    a1.Parent = part

    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Width0 = 0.3
    beam.Width1 = 0.3
    beam.FaceCamera = true
    beam.Color = ColorSequence.new(partColor)
    beam.LightEmission = 1
    beam.Transparency = NumberSequence.new(0)
    beam.Parent = a0

    task.spawn(function()
        while part and part.Parent and self:isValid() do
            local distance = (self.rootPart.Position - part.Position).Magnitude
            label.Text = string.format("%.1f studs", distance)
            task.wait(0.1)
        end
    end)
    local distance = (self.rootPart.Position - pos).Magnitude
    local speed = self.humanoid and self.humanoid.WalkSpeed or 16
    local lifetime = math.clamp(distance / speed + 2, 2, 10)
    Debris:AddItem(part, lifetime)

    return part, label
end


function Character:tweenTo(targetPos, callback)
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(self.rootPart, tweenInfo,
                                      {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Connect(function() if callback then callback() end end)
end

function Character:isValid()
    if not self.character or not self.character.Parent then return false end
    if not self.humanoid or not self.humanoid.Parent or self.humanoid.Health <=
        0 then return false end
    if not self.character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    self.health = self.humanoid.Health
    return true
end
function Character:isPlayerInField(field)
    if not field or not field:IsA("BasePart") then return false end
    local distance = (field.Position - self.rootPart.Position).Magnitude
    local fieldRadius = field.Size.Magnitude / 2
    return distance <= fieldRadius
end
return Character
