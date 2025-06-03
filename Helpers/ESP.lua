local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")


local HiddenStickersFolder = Workspace:WaitForChild("HiddenStickers")
local ParticlesFolder = Workspace:WaitForChild("Particles")
local WTsFolder = ParticlesFolder:WaitForChild("WTs")

local ESPModule = {}
ESPModule.Billboards = {}

local function createBillboard(part)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 100, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true

    local decal = part:FindFirstChildWhichIsA("Decal")
    if decal then
        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Size = UDim2.new(1, 0, 0.7, 0)
        imageLabel.Position = UDim2.new(0, 0, 0, 0)
        imageLabel.BackgroundTransparency = 1
        imageLabel.ScaleType = Enum.ScaleType.Fit
        imageLabel.Parent = billboard
        imageLabel.Image = decal.Texture
    end
    

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0.3, 0)
    textLabel.Position = UDim2.new(0, 0, 0.7, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = "..."
    textLabel.Parent = billboard

    billboard.Parent = part
    return billboard, textLabel
end

function ESPModule:AddESP(part, originFolder)
    if not part:IsA("BasePart") then return end
    if self.Billboards[part] then return end

    local billboard, label = createBillboard(part)
    self.Billboards[part] = {
        billboard = billboard,
        label = label,
        origin = originFolder
    }
end

function ESPModule:Enable()
    local folderConditions = {
        [HiddenStickersFolder] = function(part) return true end,
        [WTsFolder] = function(part) return part.Name == "WaitingThorn" or part.Name == "Vicious" end
    }

    self.childAddedConnections = {}

    for folder, condition in pairs(folderConditions) do
        for _, part in ipairs(folder:GetChildren()) do
            if condition(part) then
                self:AddESP(part, folder)
            end
        end

        local conn = folder.ChildAdded:Connect(function(part)
            if condition(part) then
                self:AddESP(part, folder)
            end
        end)
        table.insert(self.childAddedConnections, conn)
    end


    self.updateConnection = RunService.RenderStepped:Connect(function()
        for part, data in pairs(self.Billboards) do
            if part and part.Parent then
                local distance = (shared.character.rootPart.Position - part.Position).Magnitude
                local labelText = string.format("%s\n%.1f studs", part.Name, distance)

                if data.origin == WTsFolder then
                    labelText = string.format("Vicious Bee\n%.1f studs", distance)
                end

                data.label.Text = labelText
            end
        end
    end)



    return self
end

function ESPModule:Disable()
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end

    if self.childAddedConnections then
        for _, conn in ipairs(self.childAddedConnections) do
            conn:Disconnect()
        end
        self.childAddedConnections = nil
    end

    for _, data in pairs(self.Billboards) do
        if data.billboard then
            data.billboard:Destroy()
        end
    end
    self.Billboards = {}
end


return ESPModule