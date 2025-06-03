-- Services
local WP = game:GetService("Workspace")
local Players = game:GetService("Players")
local FieldDecosFolder = WP:WaitForChild("FieldDecos")
local DecorationsFolder = WP:WaitForChild("Decorations")

-- Globals
shared.FlowerZones = WP:WaitForChild("FlowerZones")

-- Module Cache
local loadedModules = {}
local function loadModuleOnce(path)
    if not loadedModules[path] then
        loadedModules[path] = loadstring(readfile(path))()
    end
    return loadedModules[path]
end

-- Cleanup Function for Shared Globals
local function cleanupShared()
    if shared.character and shared.character.destroy then shared.character:destroy() end
    if shared.hiveHelper and shared.hiveHelper.destroy then shared.hiveHelper:destroy() end
    if shared.espModule and shared.espModule.Disable then shared.espModule:Disable() end
    if shared.botHelper and shared.botHelper.destroy then shared.botHelper:destroy() end
end

-- FarmingManager Definition
local FarmingManager = {}
FarmingManager.__index = FarmingManager

function FarmingManager.new()
    cleanupShared()
    local self = setmetatable({}, FarmingManager)

    shared.Rayfield = loadModuleOnce("NewBee/Data/Rayfield.lua")
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

    self:init()
    return self
end

function FarmingManager:init()
    shared.localPlayer = Players.LocalPlayer
    self.CoreStats = shared.localPlayer:WaitForChild("CoreStats")

    shared.main.Pollen = self.CoreStats:WaitForChild("Pollen").Value
    shared.main.Honey = self.CoreStats:WaitForChild("Honey").Value
    shared.main.Capacity = self.CoreStats:WaitForChild("Capacity").Value

    -- Load and initialize modules
    local characterModule = loadModuleOnce("NewBee/Helpers/Character.lua")
    local TokensModule = loadModuleOnce("NewBee/Data/Tokens.lua")
    local hiveModule = loadModuleOnce("NewBee/Helpers/Hive.lua")
    local espModule = loadModuleOnce("NewBee/Helpers/ESP.lua")
    local farmTab = loadModuleOnce("NewBee/Tabs/FarmTab.lua")
    local MovementTab = loadModuleOnce("NewBee/Tabs/MovementTab.lua")
    local BindTab = loadModuleOnce("NewBee/Tabs/BindTab.lua")
    local botHelper = loadModuleOnce("NewBee/Class/Bot.lua")

    shared.character = characterModule.new()
    shared.Tokens = TokensModule
    shared.hiveHelper = hiveModule.new()
    shared.espModule = espModule:Enable()

    shared.FarmTab = farmTab.new()
    shared.MovementTab = MovementTab.new()
    shared.BindTab = BindTab.new()
    shared.botHelper = botHelper.new()

    -- Optional: Visual settings for parts
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

-- Create and initialize the manager
local manager = FarmingManager.new()