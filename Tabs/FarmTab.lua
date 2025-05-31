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
    ["Stump Field"] = "🪵 Stump Field",
    ["Mountain Top Field"] = "⛰️ Mountain Top Field",
    ["Coconut Field"] = "🫕 Coconut Field",
    ["Pepper Patch"] = "🌶️ Pepper Patch",
}

local orderedFieldKeys = {
    "Sunflower Field", "Dandelion Field","Clover Field","Mushroom Field",
    "Blue Flower Field", "Spider Field", "Strawberry Field", "Bamboo Field",
    "Pineapple Patch", "Pumpkin Patch", "Cactus Field", "Pine Tree Forest",
    "Rose Field", "Stump Field", "Mountain Top Field", "Coconut Field", "Pepper Patch"
}

local function getAllFieldKeys()
    return orderedFieldKeys
end

local function getFieldName(iconLabel)
    for key, label in pairs(allFields) do
        if label == iconLabel then
            return key
        end
    end
    return nil
end

local displayOptions = {}
for _, key in ipairs(getAllFieldKeys()) do
    table.insert(displayOptions, allFields[key])
end

local FarmTab = {}
FarmTab.__index = FarmTab

function FarmTab.new(manageRef)
    local self = setmetatable({}, FarmTab)
	self:afk(true)
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
                self.onFieldChange(shared.main.currentField)
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
  
	self.mainTab:CreateToggle({
        Name = "Farm Bubble",
        CurrentValue = false,
        Callback = function(value)
            shared.main.farmBubble = value
        end
    })
    self.mainTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = true,
        Callback = function(value)
            shared.main.antiAfk = value
			self:afk(value)
        end
    })

    self.mainTab:CreateSection("Collect Only Token")

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
		shared.main.tokenList[assetID] = true
	end

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
return FarmTab
