-- ESP Module with Line Drawing to Player

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ParticlesFolder = game:GetService("Workspace"):WaitForChild("Particles")
local CollectiblesFolder = workspace:WaitForChild("Collectibles")
local WTsFolder = ParticlesFolder:WaitForChild("WTs")

local ESP = {}

local assets = {
    ['WaitingThorn'] = 2324352587
}

local espItems = {
    ['1471849394'] = {color = Color3.fromRGB(255, 215, 0)},
    ['1471850677'] = {color = Color3.fromRGB(0, 255, 255)},
    ['1674871631'] = {color = Color3.fromRGB(255, 255, 255)},
    ['2504978518'] = {color = Color3.fromRGB(128, 255, 128)},
    ['2542899798'] = {color = Color3.fromRGB(255, 0, 255)},
}

ESP.TrackedObjects = {}
ESP.ESP_Lines = {}
ESP.DistanceLabels = {}
ESP.EnableESP = false
ESP.AllFolders = {}
ESP.ShowLines = true
ESP.ESP_Range = 500
ESP.ShowDistance = false

function ESP.new(manageRef)
    local self = setmetatable({}, {__index = ESP})
    self.TrackedObjects = {}
    self.ESP_Lines = {}
    self.DistanceLabels = {}
    self.EnableESP = false
    self.ShowLines = true
    self.ESP_Range = 1000
    self.ShowDistance = false
    self.manageRef = manageRef
    self.espTab = manageRef.Window:CreateTab("ESP", "eye")

    self.espTab:CreateToggle({
        Name = "Enable ESP",
        CurrentValue = false,
        Flag = "EnableESP",
        Callback = function(value)
            self.EnableESP = value
            self:RefreshESP()
        end,
    })

    self.espTab:CreateToggle({
        Name = "Show Lines",
        CurrentValue = true,
        Flag = "ShowLines",
        Callback = function(value)
            self.ShowLines = value
            for object, lineData in pairs(self.ESP_Lines) do
                if lineData.beam then
                    lineData.beam.Enabled = self.EnableESP and value
                end
            end
        end,
    })

    self.espTab:CreateToggle({
        Name = "Show Distance",
        CurrentValue = false,
        Flag = "ShowDistance",
        Callback = function(value)
            self.ShowDistance = value
        end,
    })

    self.espTab:CreateSlider({
        Name = "ESP Range",
        Range = {0, 1000},
        Increment = 10,
        Suffix = "Studs",
        CurrentValue = 1000,
        Flag = "ESPRadius",
        Callback = function(value)
            self.ESP_Range = value
            self:RefreshESP()
        end,
    })

    RunService.Heartbeat:Connect(function()
        if self.EnableESP then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            for object, label in pairs(self.DistanceLabels) do
                if self.ShowDistance and root and object and object.Parent then
                    local dist = math.floor((object.Position - root.Position).Magnitude)
                    label.Text = tostring(dist) .. "m"
                elseif label then
                    label.Text = ""
                end
            end
        end
    end)

    self:TrackingFolder(CollectiblesFolder)
    self:TrackingFolder(WTsFolder)
    return self
end

function ESP:RefreshESP()
    for _, obj in ipairs(self.TrackedObjects) do
        if obj:FindFirstChildWhichIsA("BillboardGui") then
            obj:FindFirstChildWhichIsA("BillboardGui"):Destroy()
        end
    end
    self.TrackedObjects = {}

    for object, data in pairs(self.ESP_Lines) do
        if data.beam and data.beam.Parent then
            data.beam:Destroy()
        end
        for _, att in ipairs(data.attachments) do
            if att and att.Parent then
                att:Destroy()
            end
        end
    end
    self.ESP_Lines = {}
    self.DistanceLabels = {}

    for _, folder in ipairs(self.AllFolders) do
        for _, child in ipairs(folder:GetChildren()) do
            self:AddObject(child, folder.Name)
        end
    end
end

function ESP:AddObject(object, folderName)
    local assetId

    if folderName == "Collectibles" then
        local decal = object:FindFirstChild("FrontDecal")
        if decal and decal:IsA("Decal") and object.Transparency == 0 then
            local texture = decal.Texture
            assetId = tonumber(texture:match("(%d+)$"))
            if not espItems[tostring(assetId)] then
                return
            end
        else
            return
        end
    else
        assetId = assets[object.Name]
        if not assetId then
            return
        end
    end

    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or (object.Position - root.Position).Magnitude > self.ESP_Range then return end

    table.insert(self.TrackedObjects, object)
    self:addBillboard(object, assetId)
    self:drawLineToObject(object, assetId)

    local lineData = self.ESP_Lines[object]
    if lineData and lineData.beam then
        lineData.beam.Enabled = self.EnableESP and self.ShowLines
    end
end

function ESP:addBillboard(object, assetId)
    local billboard = Instance.new("BillboardGui")
    local imageLabel = Instance.new("ImageLabel")
    local distanceLabel = Instance.new("TextLabel")

    billboard.Adornee = object
    billboard.Size = UDim2.new(0, 40, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.Parent = object

    imageLabel.Parent = billboard
    imageLabel.Size = UDim2.new(1, 0, 0.6, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = "rbxassetid://" .. assetId

    distanceLabel.Parent = billboard
    distanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.Font = Enum.Font.SourceSansBold
    distanceLabel.TextScaled = true
    distanceLabel.Text = ""

    self.DistanceLabels[object] = distanceLabel
end

function ESP:drawLineToObject(object, assetId)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local line = Instance.new("Beam")
    local a0 = Instance.new("Attachment")
    local a1 = Instance.new("Attachment")

    a0.Name = "ESP_Start"
    a1.Name = "ESP_End"

    a0.Parent = root
    a1.Parent = object

    line.Attachment0 = a0
    line.Attachment1 = a1
    line.Width0 = 0.1
    line.Width1 = 0.1
    line.FaceCamera = true

    local colorInfo = espItems[tostring(assetId)]
    local beamColor = colorInfo and colorInfo.color or Color3.new(1, 1, 0)
    line.Color = ColorSequence.new(beamColor)
    line.Transparency = NumberSequence.new(0.2)
    line.Enabled = self.EnableESP and self.ShowLines
    line.Parent = object

    self.ESP_Lines[object] = {beam = line, attachments = {a0, a1}}
end

function ESP:RemoveObject(object)
    for i, obj in ipairs(self.TrackedObjects) do
        if obj == object then
            table.remove(self.TrackedObjects, i)
            break
        end
    end

    local lineData = self.ESP_Lines[object]
    if lineData then
        for _, att in ipairs(lineData.attachments) do
            if att and att.Parent then att:Destroy() end
        end
        if lineData.beam and lineData.beam.Parent then
            lineData.beam:Destroy()
        end
        self.ESP_Lines[object] = nil
    end

    self.DistanceLabels[object] = nil
end

function ESP:TrackingFolder(folder)
    if not folder or not folder:IsA("Folder") then
        error("Invalid folder provided for ESP tracking.")
    end

    table.insert(self.AllFolders, folder)

    local function onChildAdded(child)
        if self.EnableESP and (child:IsA("BasePart") or child:IsA("Model") or child:IsA('MeshPart')) then
            self:AddObject(child, folder.Name)
        end
    end

    local function onChildRemoved(child)
        self:RemoveObject(child)
    end

    folder.ChildAdded:Connect(onChildAdded)
    folder.ChildRemoved:Connect(onChildRemoved)

    for _, child in ipairs(folder:GetChildren()) do
        onChildAdded(child)
    end
end

function ESP:GetTrackedObjects()
    return self.TrackedObjects
end

return ESP
