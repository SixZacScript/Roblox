-- Constants moved to top and made more efficient
local FIELD_DATA = {
    {"Sunflower Field", "🌻"},
    {"Dandelion Field", "🌼"},
    {"Mushroom Field", "🍄"},
    {"Clover Field", "☘️"},
    {"Blue Flower Field", "🌿"},
    {"Spider Field", "🕸️"},
    {"Strawberry Field", "🍓"},
    {"Bamboo Field", "🎌"},
    {"Pineapple Patch", "🍍"},
    {"Pumpkin Patch", "🎃"},
    {"Cactus Field", "🌵"},
    {"Pine Tree Forest", "🌳"},
    {"Rose Field", "🌹"},
    {"Stump Field", "🪵"},
    {"Mountain Top Field", "⛰️"},
    {"Coconut Field", "🫕"},
    {"Pepper Patch", "🌶️"}
}

-- Pre-computed lookups for O(1) access
local allFields = {}
local labelToKey = {}
local displayOptions = {}

-- Single loop to build all data structures
for _, data in ipairs(FIELD_DATA) do
    local key, emoji = data[1], data[2]
    local label = emoji .. " " .. key
    
    allFields[key] = label
    labelToKey[label] = key
    table.insert(displayOptions, label)
end

local function getFieldName(iconLabel)
    return labelToKey[iconLabel]
end

local FarmTab = {}
FarmTab.__index = FarmTab

function FarmTab.new()
    local self = setmetatable({}, FarmTab)
    self:afk(true)
    -- Cache shared references
    shared.MainTab = shared.RayWindow:CreateTab("Main", "home")
    shared.MainTab:CreateSection("Main Section")

    -- Get current field display name
    local currentFieldName = shared.main.currentField and shared.main.currentField.Name
    local currentDisplayName = currentFieldName and allFields[currentFieldName]
    
    self.FlowerDropdown = shared.MainTab:CreateDropdown({
        Name = "Select a Flower Zone",
        Options = displayOptions,
        CurrentOption = currentDisplayName,
        Callback = function(label)
            -- Handle both string and table inputs
            local selectedLabel = type(label) == "table" and label[1] or label
            local key = getFieldName(selectedLabel)
            task.spawn(function()
                if key then
                    self.selectedZone = key
                    shared.main.currentField = shared.FlowerZones:FindFirstChild(key)
                    while shared.botHelper.converting do
                        task.wait()
                    end
                    if shared.botHelper.autoFarm then
                        shared.botHelper:stop()
                        shared.botHelper:start()
                    end
                end
            end)
        end
    })

    self.farmToggle = shared.MainTab:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = false,
        Callback = function(value)
            shared.main.autoFarm = value
            if not value then return shared.botHelper:stop() end
            shared.botHelper:start()
        end
    })

    shared.MainTab:CreateToggle({
		Name = "Auto Dig",
		CurrentValue = false,
		Callback = function(value)
			shared.main.autoDig = value
            if not value then return end
            while shared.main.autoDig do
				if not shared.hiveHelper:isPollenFull() then
					local Event = game:GetService("ReplicatedStorage").Events.ToolCollect
					Event:FireServer()
				end
                task.wait(0.4)
            end
		end
	})
    shared.MainTab:CreateToggle({
        Name = "Farm Bubble",
        CurrentValue = true,
        Callback = function(value)
            shared.main.farmBubble = value
        end
    })
    shared.MainTab:CreateToggle({
        Name = "Auto Kill mobs",
        CurrentValue = shared.main.autoKillMobs,
        Callback = function(value)
            shared.main.autoKillMobs = value
            shared.AutoHunt:Toggle()
        end
    })
    return self
end

function FarmTab:afk(value)
	if value then
		if self.afkConnection then self.afkConnection:Disconnect() end
		self.afkConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
			game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			task.wait(1)
			game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		end)
	else
		if self.afkConnection then
			self.afkConnection:Disconnect()
			self.afkConnection = nil
		end
	end
	
end

function FarmTab:destroy()
    if self.afkConnection then
        self.afkConnection:Disconnect()
        self.afkConnection = nil
    end
    if self.FlowerDropdown then
        self.FlowerDropdown:Destroy()
        self.FlowerDropdown = nil
    end
    if self.farmToggle then
        self.farmToggle:Destroy()
        self.farmToggle = nil
    end
end

return FarmTab