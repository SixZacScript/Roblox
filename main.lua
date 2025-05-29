-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Window = loadstring(game:HttpGet('https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/Window.lua'))()

-- FarmingManager Class
local FarmingManager = {}
FarmingManager.__index = FarmingManager

function FarmingManager.new()
	local self = setmetatable({}, FarmingManager)
	-- External Helpers
	self.TweenHelper = loadstring(game:HttpGet('https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/TweenHelper.lua'))()
	self.FarmHelper = loadstring(game:HttpGet('https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/FarmModule.lua'))()
	self.PlayerMovement = loadstring(game:HttpGet("https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/PlayerMovement.lua"))()
	self.TokenData = loadstring(game:HttpGet("https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/TokenData.lua"))()
	-- Initialize services and properties
	self.localPlayer = Players.LocalPlayer
	self.CoreStats = self.localPlayer:WaitForChild("CoreStats")
	self.character = self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
	self.rootPart = self.character:WaitForChild("HumanoidRootPart")
	self.flowerZones = Workspace:WaitForChild("FlowerZones")
	self.collectibles = Workspace:WaitForChild("Collectibles")
	-- Initialize CoreStats
	self.Pollen = self.CoreStats:WaitForChild("Pollen")
	self.Honey = self.CoreStats:WaitForChild("Honey")
	self.Capacity = self.CoreStats:WaitForChild("Capacity")
	self.HoneycombObject = self.localPlayer:FindFirstChild("Honeycomb")
	self.Hive = self.HoneycombObject and self.HoneycombObject.Value or nil
	-- Initialize other properties
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
		tokenMode = 'First',
		Pollen = self.Pollen.Value or 0,
		Capacity = self.Capacity.Value or 0,
		Honey = self.Honey.Value or 0,
		Hove = self.Hive,
	}
	self.FarmHelper:init(self)
	self:createUI()
	self.humanoid.Died:Connect(function()
		self.FarmHelper:stopFarming()
		shared.main.startFarming = false
	end)
	for _, prop in ipairs({"Capacity", "Pollen", "Honey"}) do
		self[prop]:GetPropertyChangedSignal("Value"):Connect(function()
			shared.main[prop] = self[prop].Value
		end)
	end

end

function FarmingManager:updateCharacter()
	self.character = self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
	self.rootPart = self.character:WaitForChild("HumanoidRootPart")
end

function FarmingManager:createUI()
	local mainTab = Window:CreateTab("Main", "flower")
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
				if shared.main.Pollen < shared.main.Capacity then
					local Event = game:GetService("ReplicatedStorage").Events.ToolCollect
					Event:FireServer()
				end
                task.wait(0.35)
            end
		end
	})

	mainTab:CreateToggle({
		Name = "Start Farming",
		CurrentValue = false,
		Callback = function(value)
			if not value then return self.FarmHelper:stopFarming() end
			shared.main.startFarming = true
			-- self:updateCharacter()
			-- local field = self.flowerZones:FindFirstChild(self.selectedZone)
			-- local success = self.TweenHelper:tweenTo(field.Position, self.character)
			-- if success then
				self.FarmHelper:startFarming()
			-- else
			-- 	print("Tween was interrupted or character destroyed.")
			-- end
		end
	})
	mainTab:CreateDropdown({
		Name = "Token Mode",
		Options = {"First", 'Nearest'},
		CurrentOption = 'First',
		Callback = function(mode)
			local newMode = typeof(mode) == "table" and mode[1] or mode
            shared.main.tokenMode = newMode
			self.FarmHelper:changeTokenMode(newMode)
		end
	})
	mainTab:CreateSection("Collect Only Token")
	shared.tokenToggles = {}

	for name, assetID in pairs(self.TokenData) do
		local toggle = mainTab:CreateToggle({
			Name = name,
			Flag = tostring(assetID),
			CurrentValue = false,
			Callback = function(value)
				shared.main[assetID] = value
				print(name .. " toggled:", value)
			end
		})
		shared.tokenToggles[assetID] = toggle
	end

	self.PlayerMovement:start(movementTab)
end

FarmingManager.new()
