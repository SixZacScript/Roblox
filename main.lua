-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- FarmingManager Class
local FarmingManager = {}
FarmingManager.__index = FarmingManager

function FarmingManager.new()
	local self = setmetatable({}, FarmingManager)
	local DEBUG_MODE = false
	local basePath = DEBUG_MODE and "BeeSwarm/" or "https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/"
	local loader = DEBUG_MODE and function(path) return loadstring(readfile(basePath .. path))() end or function(path) return loadstring(game:HttpGet(basePath .. path))() end

	self.Window      = loader("Window.lua")
	self.farmTab     = loader("Tabs/FarmTab.lua")
	self.movementTab = loader("Tabs/Movement.lua")
	self.espTab      = loader("Tabs/ESPTab.lua")
	self.bindTab     = loader("Tabs/BindTab.lua")
	
	self.hiveHelper   = loader("Helpers/Hive.lua")
	self.botHelper   = loader("Helpers/AutoFarm.lua")
	self.TokenData   = loader("TokenData.lua")


	-- Initialize services and properties
	self.localPlayer = Players.LocalPlayer
	self.CoreStats = self.localPlayer:WaitForChild("CoreStats")
	self.character = self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
	self.rootPart = self.character:WaitForChild("HumanoidRootPart")
	self.flowerZones = Workspace:WaitForChild("FlowerZones")

	-- Initialize CoreStats
	self.Pollen = self.CoreStats:WaitForChild("Pollen")
	self.Honey = self.CoreStats:WaitForChild("Honey")
	self.Capacity = self.CoreStats:WaitForChild("Capacity")
	self.HoneycombObject = self.localPlayer:FindFirstChild("Honeycomb")
	self.Hive = self.HoneycombObject and self.HoneycombObject.Value or nil

	self:init()
	return self
end

function FarmingManager:init()
	shared.hiveHelper = self.hiveHelper.new()
	shared.main = {
		currentField = self.flowerZones:FindFirstChild("Sunflower Field"),

		Pollen = self.Pollen.Value or 0,
		Capacity = self.Capacity.Value or 0,
		Honey = self.Honey.Value or 0,
		tokenList = {},
		tweenSpeed = 0.6,
		tokenRadius = 35,
		defaultWalkSpeed = 60,
		defaultJumpPower = 70,

	}
	-- tabs
	self.farmTab = self.farmTab.new(self)
	self.movementTab = self.movementTab.new(self)
	-- self.espTab = self.espTab.new(self)
	self.bindTab = self.bindTab.new(self)

	-- helpers
	self.botHelper = self.botHelper.new(self)

	for _, prop in ipairs({"Capacity", "Pollen", "Honey"}) do
		self[prop]:GetPropertyChangedSignal("Value"):Connect(function()
			shared.main[prop] = self[prop].Value
		end)
	end

	self.farmTab.onAutoFarmToggle = function(Enabled)
		if not Enabled then self.botHelper:stop() return end
		self.botHelper:start()
	end
	self.farmTab.onFieldChange = function(field)
		if self.botHelper.autoFarm then
			self.botHelper:stop()
			self.botHelper:start()
		end
	end
	shared.hiveHelper = self.hiveHelper.new()
end



FarmingManager.new()
