-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DecorationsFolder = Workspace:WaitForChild("Decorations")
local Window = loadstring(game:HttpGet('https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/Window.lua'))()

-- FarmingManager Class
local FarmingManager = {}
FarmingManager.__index = FarmingManager

function FarmingManager.new()
	local self = setmetatable({}, FarmingManager)
	-- External Helpers
	-- self.TweenHelper = loadstring(game:HttpGet('https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/TweenHelper.lua'))()
	-- self.botHelper = loadstring(game:HttpGet('https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/Bot.lua'))()
	-- self.PlayerMovement = loadstring(game:HttpGet("https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/PlayerMovement.lua"))()
	-- self.TokenData = loadstring(game:HttpGet("https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/TokenData.lua"))()
	self.botHelper = loadstring(readfile("BeeSwarm/Bot.lua"))()
    self.PlayerMovement = loadstring(readfile("BeeSwarm/PlayerMovement.lua"))()
    self.TokenData = loadstring(readfile("BeeSwarm/TokenData.lua"))()
    -- self.hiveHelper = loadstring(readfile("BeeSwarm/Hive.lua"))()

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
		startFarming = false,
		autoDigEnabled = true,
		convertPollen = false,
		tokenMode = 'First',
		tokenList = {},
		Pollen = self.Pollen.Value or 0,
		Capacity = self.Capacity.Value or 0,
		Honey = self.Honey.Value or 0,
		Hove = self.Hive,
		tweenSpeed = 0.6,
		tokenRadius = 35,

	}
	-- shared.hiveHelper = self.hiveHelper.new(self.character, self)
	self.botHelper = self.botHelper.new(self.character, self)

	self:createUI()

	for _, prop in ipairs({"Capacity", "Pollen", "Honey"}) do
		self[prop]:GetPropertyChangedSignal("Value"):Connect(function()
			shared.main[prop] = self[prop].Value
			if shared.main.startFarming then self.botHelper:checkPollen() end
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
	local bindTab = Window:CreateTab("Keybinds", "keyboard")

	mainTab:CreateSection("Farming Zones")

	mainTab:CreateDropdown({
		Name = "Select a Flower Zone",
		Options = self.zoneNames,
		CurrentOption = self.selectedZone,
		Callback = function(zone)
			self.selectedZone = typeof(zone) == "table" and zone[1] or zone
			shared.main.currentField = self.flowerZones:FindFirstChild(self.selectedZone)
			if shared.main.startFarming then
				self.botHelper:checkPollen(function()
					self.botHelper:stopFarming()
					self.botHelper:startFarming()
				end)
			end
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

	self.farmToggle = mainTab:CreateToggle({
		Name = "Start Farming",
		CurrentValue = false,
		Callback = function(value)
			if not value then 
				shared.main.startFarming = false
				self.botHelper:addTask({type = "stop"})
				return
			end
			shared.main.startFarming = true
			self.botHelper:addTask({type = "start"})
		end
	})
	mainTab:CreateDropdown({
		Name = "Token Mode",
		Options = {"First", 'Nearest'},
		CurrentOption = 'First',
		Callback = function(mode)
			local newMode = typeof(mode) == "table" and mode[1] or mode
            shared.main.tokenMode = newMode
			-- self.FarmHelper:changeTokenMode(newMode)
		end
	})
	mainTab:CreateSection("Collect Only Token")


	local sorted = {}
	for name, assetID in pairs(self.TokenData) do
		table.insert(sorted, {name = name, assetID = assetID})
	end

	table.sort(sorted, function(a, b)
		return a.name < b.name
	end)

	for _, item in ipairs(sorted) do
		local name, assetID = item.name, item.assetID
		mainTab:CreateToggle({
			Name = name,
			Flag = tostring(assetID),
			CurrentValue = true,
			Callback = function(value)
				shared.main.tokenList[assetID] = value
				print(name .. " toggled:", value)
			end
		})
		shared.main.tokenList[assetID] = true
	end

	self.PlayerMovement:start(movementTab)

	local Keybind = bindTab:CreateKeybind({
		Name = "Toggle Farming",
		CurrentKeybind = "Q",
		HoldToInteract = false,
		Flag = "Keybind1",
		Callback = function(Keybind)
			self.farmToggle:Set(not shared.main.startFarming)
		end,
	})
	for _, part in pairs(DecorationsFolder:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Transparency = 0.3
		end
	end
end

FarmingManager.new()
