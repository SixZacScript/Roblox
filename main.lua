-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local infinite = loadstring(game:HttpGet('https://raw.githubusercontent.com/DarkNetworks/Infinite-Yield/main/latest.lua'))()
local Window = loadstring(game:HttpGet('https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/Window.lua'))()
local TweenHelper = loadstring(game:HttpGet('https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/TweenHelper.lua'))()
local FarmHelper = loadstring(game:HttpGet('https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/FarmModule.lua'))()
local PlayerMovement = loadstring(game:HttpGet("https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/PlayerMovement.lua"))()

-- FarmingManager Class
local FarmingManager = {}
FarmingManager.__index = FarmingManager

function FarmingManager.new()
	local self = setmetatable({}, FarmingManager)
	self.localPlayer = Players.LocalPlayer
	self.character = self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
	self.rootPart = self.character:WaitForChild("HumanoidRootPart")
	self.flowerZones = Workspace:WaitForChild("FlowerZones")
	self.collectibles = Workspace:WaitForChild("Collectibles")
	self.zoneNames = {}
	self.selectedZone = "Dandelion Field"
	self:init()
	return self
end

function FarmingManager:init()
	for _, zone in ipairs(self.flowerZones:GetChildren()) do
		table.insert(self.zoneNames, zone.Name)
	end

	shared.main = {
		currentField = self.flowerZones:FindFirstChild(self.selectedZone),
		startFarming = true,
		autoDigEnabled = true,
		tokenMode = 'First'
	}
	FarmHelper:init()
	self:createUI()
	self.humanoid.Died:Connect(function()
		FarmHelper:stopFarming()
		shared.main.startFarming = false
	end)
end

function FarmingManager:updateCharacter()
	self.character = self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
	self.rootPart = self.character:WaitForChild("HumanoidRootPart")
end

function FarmingManager:createUI()
	local mainTab = Window:CreateTab("Main", "flower")
	local statsTab = Window:CreateTab("Stats", "bar-chart")
	local movementTab = Window:CreateTab("Movement", "dumbbell")

	mainTab:CreateSection("Farming Zones")

	mainTab:CreateDropdown({
		Name = "Select a Flower Zone",
		Options = self.zoneNames,
		CurrentOption = self.selectedZone,
		Callback = function(zone)
			self.selectedZone = typeof(zone) == "table" and zone[1] or zone
			shared.main.currentField = self.flowerZones:FindFirstChild(self.selectedZone)
		end
	})

	mainTab:CreateToggle({
		Name = "Auto Dig",
		CurrentValue = false,
		Callback = function(value)
			shared.main.autoDigEnabled = value
            if not value then return end
            while shared.main.autoDigEnabled do
                local Event = game:GetService("ReplicatedStorage").Events.ToolCollect
                Event:FireServer()
                task.wait(0.35)
            end
		end
	})

	mainTab:CreateToggle({
		Name = "Start Farming",
		CurrentValue = false,
		Callback = function(value)
			if not value then return FarmHelper:stopFarming() end
			shared.main.startFarming = true
			self:updateCharacter()
			local field = self.flowerZones:FindFirstChild(self.selectedZone)
			local success = TweenHelper:tweenTo(field.Position, self.character)
			if success then
				FarmHelper:startFarming()
			else
				print("Tween was interrupted or character destroyed.")
			end
		end
	})
	mainTab:CreateDropdown({
		Name = "Token Mode",
		Options = {"First", 'Nearest'},
		CurrentOption = 'First',
		Callback = function(mode)
			local newMode = typeof(mode) == "table" and mode[1] or mode
            shared.main.tokenMode = newMode
			FarmHelper:changeTokenMode(newMode)
		end
	})
	PlayerMovement:start(movementTab)
end

FarmingManager.new()
