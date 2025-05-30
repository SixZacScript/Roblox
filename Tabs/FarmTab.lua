
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

	-- self.mainTab:CreateDropdown({
	-- 	Name = "Token Mode",
	-- 	Options = {"First", 'Nearest'},
	-- 	CurrentOption = 'First',
	-- 	Callback = function(mode)
	-- 		local newMode = typeof(mode) == "table" and mode[1] or mode
    --         shared.main.tokenMode = newMode
	-- 	end
	-- })

    self.mainTab:CreateSection("Collect Only Token")

 -- ปุ่มล้างทั้งหมด
    self.mainTab:CreateButton({
        Name = "Clear All Tokens",
        Callback = function()
            for assetID, toggle in pairs(self.tokenToggles) do
                shared.main.tokenList[assetID] = false
                toggle:Set(false)
            end
            shared.Rayfield:Notify({
                Title = "Tokens Cleared",
                Content = "All tokens have been cleared.",
                Duration = 3
            })
        end
    })

    -- ปุ่ม Toggle ทั้งหมด
    self.mainTab:CreateButton({
        Name = "Toggle All Tokens",
        Callback = function()
            local anyEnabled = false
            for _, v in pairs(shared.main.tokenList) do
                if v then
                    anyEnabled = true
                    break
                end
            end
            for assetID, toggle in pairs(self.tokenToggles) do
                local newValue = not anyEnabled
                shared.main.tokenList[assetID] = newValue
                toggle:Set(newValue)
            end
            shared.Rayfield:Notify({
                Title = "Tokens Toggled",
                Content = anyEnabled and "All tokens turned off." or "All tokens turned on.",
                Duration = 3
            })
        end
    })
	
    local sorted = {}
    self.tokenToggles = {}
	for name, assetID in pairs(manageRef.TokenData) do
		table.insert(sorted, {name = name, assetID = assetID})
	end
	table.sort(sorted, function(a, b) return a.name < b.name end)
	for _, item in ipairs(sorted) do
		local name, assetID = item.name, item.assetID
		local toggle = self.mainTab:CreateToggle({
			Name = name,
			Flag = tostring(assetID),
			CurrentValue = true,
			Callback = function(value)
				shared.main.tokenList[assetID] = value
			end
		})
		self.tokenToggles[assetID] = toggle
	end

   

    return self
end


return FarmTab
