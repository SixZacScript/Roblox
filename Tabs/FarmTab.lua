local allFields = {
    ["Sunflower Field"] = "🌻 Sunflower Field",
    ["Clover Field"] = "☘️ Clover Field",
    ["Dandelion Field"] = "🌼 Dandelion Field",
    ["Blue Flower Field"] = "🌿 Blue Flower Field",
    ["Mushroom Field"] = "🍄 Mushroom Field",
    ["Spider Field"] = "🕸️ Spider Field",
    ["Strawberry Field"] = "🍓 Strawberry Field",
    ["Bamboo Field"] = "🎌 Bamboo Field",
    ["Pineapple Patch"] = "🍍 Pineapple Patch",
    ["Pumpkin Patch"] = "🎃 Pumpkin Patch",
    ["Cactus Field"] = "🌵 Cactus Field",
    ["Pine Tree Forest"] = "🌳 Pine Tree Forest",
    ["Rose Field"] = "🌹 Rose Field",
    ["Mountain Top Field"] = "⛰️ Mountain Top Field",
    ["Coconut Field"] = "🥥 Coconut Field",
    ["Pepper Patch"] = "🌶️ Pepper Patch",
}
local displayOptions = {}

local function getAllFieldKeys()
    local keys = {}
    for key, _ in pairs(allFields) do
        table.insert(keys, key)
    end
    return keys
end

local function getFieldName(iconLabel)
    for key, label in pairs(allFields) do
        if label == iconLabel then
            return key
        end
    end
    return nil
end
for _, key in ipairs(getAllFieldKeys()) do
    table.insert(displayOptions, allFields[key])
end
local FarmTab = {}
FarmTab.__index = FarmTab

function FarmTab.new(manageRef)
    local self = setmetatable({}, FarmTab)
	self.mainTab = manageRef.Window:CreateTab("Main", "flower")
    self.mainTab:CreateSection("Farming Zones")
    self.mainTab:CreateDropdown({
		Name = "Select a Flower Zone",
		Options = displayOptions,
		CurrentOption = allFields[shared.main.currentField.Name],
		Callback = function(label)
			local key = getFieldName(typeof(label) == "table" and label[1] or label)
			if key then
				self.selectedZone = key
				shared.main.currentField = manageRef.flowerZones:FindFirstChild(key)
			end
		end
	})
    self.mainTab:CreateToggle({
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
                task.wait(0.3)
            end
		end
	})

    self.farmToggle = self.mainTab:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = false,
        Callback = function(value)
            shared.main.autoFarm = value
            if self.onAutoFarmToggle then
                self.onAutoFarmToggle(value)
            end
        end
    })

	self.mainTab:CreateDropdown({
		Name = "Token Mode",
		Options = {"First", 'Nearest'},
		CurrentOption = 'First',
		Callback = function(mode)
			local newMode = typeof(mode) == "table" and mode[1] or mode
            shared.main.tokenMode = newMode
		end
	})

    self.mainTab:CreateSection("Collect Only Token")

    local sorted = {}
	for name, assetID in pairs(manageRef.TokenData) do
		table.insert(sorted, {name = name, assetID = assetID})
	end

	table.sort(sorted, function(a, b) return a.name < b.name end)

	for _, item in ipairs(sorted) do
		local name, assetID = item.name, item.assetID
		self.mainTab:CreateToggle({
			Name = name,
			Flag = tostring(assetID),
			CurrentValue = true,
			Callback = function(value)
				shared.main.tokenList[assetID] = value
			end
		})
		shared.main.tokenList[assetID] = true
	end

    return self
end


return FarmTab