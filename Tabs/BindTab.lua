local Bind = {}
Bind.__index = Bind

function Bind.new(manageRef)
    local self = setmetatable({}, Bind)
    self.bindTab = manageRef.Window:CreateTab("Keybinds", "keyboard")
    self.Keybind = self.bindTab:CreateKeybind({
		Name = "Toggle Farming",
		CurrentKeybind = "Q",
		HoldToInteract = false,
		Flag = "Keybind1",
		Callback = function(Keybind)
			manageRef.farmTab.farmToggle:Set(not shared.main.autoFarm)
		end,
	})
end

return Bind