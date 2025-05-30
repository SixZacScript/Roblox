local allFields = {
    "Sunflower Field",
    "Clover Field",
    "Dandelion Field",
    "Blue Flower Field",
    "Mushroom Field",
    "Spider Field",
    "Strawberry Field",
    "Bamboo Field",
    "Pineapple Patch",
    "Pumpkin Patch",
    "Cactus Field",
    "Pine Tree Forest",
    "Rose Field",
    "Mountain Top Field",
    "Coconut Field",
    "Pepper Patch"
}

local FarmTab = {}
FarmTab.__index = FarmTab

function FarmTab.new(manageRef)
    local self = setmetatable({}, FarmTab)
	self.mainTab = manageRef.Window:CreateTab("Main", "flower")
    self.mainTab:CreateSection("Farming Zones")
    self.mainTab:CreateDropdown({
		Name = "Select a Flower Zone",
		Options = allFields,
		CurrentOption = shared.main.currentField.Name,
		Callback = function(zone)
			self.selectedZone = typeof(zone) == "table" and zone[1] or zone
			shared.main.currentField = manageRef.flowerZones:FindFirstChild(self.selectedZone)
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