local WP = game:GetService("Workspace")
local Players = game:GetService("Players")
local FieldDecosFolder = WP:WaitForChild("FieldDecos")
local DecorationsFolder = WP:WaitForChild("Decorations")

shared.FlowerZones = WP:WaitForChild("FlowerZones")
shared.FlowerZones = WP:WaitForChild("FlowerZones")

local FarmingManager = {}
FarmingManager.__index = FarmingManager
function FarmingManager.new()
    local self = setmetatable({}, FarmingManager)
    shared.Rayfield = loadstring(readfile("NewBee/Data/Rayfield.lua"))()

    shared.RayWindow = shared.Rayfield:CreateWindow({
        Name = "Rayfield Example Window",
        Icon = 0,
        LoadingTitle = "Rayfield Interface Suite",
        LoadingSubtitle = "by Sirius",
        Theme = "Default",
        ToggleUIKeybind = "F", 
    })
    shared.main = {
        autoFarm = false,
        autoDig = false,
        farmBubble = true,
        defaultWalkSpeed = 100,
        defaultJumpPower = 75,
        currentField = shared.FlowerZones:WaitForChild("Sunflower Field"),
    }
    

    self:initi()
    return self
end

function FarmingManager:initi()
    shared.localPlayer = Players.LocalPlayer
    self.CoreStats = shared.localPlayer:WaitForChild("CoreStats")
    shared.main.Pollen = self.CoreStats:WaitForChild("Pollen").Value
	shared.main.Honey = self.CoreStats:WaitForChild("Honey").Value
	shared.main.Capacity = self.CoreStats:WaitForChild("Capacity").Value

    local characterModule = loadstring(readfile("NewBee/Helpers/Character.lua"))()
    local hiveModule = loadstring(readfile("NewBee/Helpers/Hive.lua"))()
    local espModule = loadstring(readfile("NewBee/Helpers/ESP.lua"))()

    local farmTab  = loadstring(readfile("NewBee/Tabs/FarmTab.lua"))()
    local MovementTab  = loadstring(readfile("NewBee/Tabs/MovementTab.lua"))()
    local BindTab  = loadstring(readfile("NewBee/Tabs/BindTab.lua"))()

    local botHelper = loadstring(readfile("NewBee/Class/Bot.lua"))()
    -- Initialize module

    shared.character = characterModule.new()
    shared.hiveHelper = hiveModule.new()
    shared.espModule = espModule:Enable()


    shared.FarmTab = farmTab.new()
    shared.MovementTab = MovementTab.new()
    shared.BindTab = BindTab.new()
    shared.botHelper = botHelper.new()

  local folders = {FieldDecosFolder, DecorationsFolder}

for _, folder in ipairs(folders) do
    for _, part in ipairs(folder:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0.8
            part.CanCollide = false
            part.CastShadow = false
        end
    end
end


end

local manager = FarmingManager.new()
