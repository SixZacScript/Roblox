local Bind = {}
Bind.__index = Bind

function Bind.new()
    local self = setmetatable({}, Bind)
	
    self.bindTab = shared.RayWindow:CreateTab("Keybinds", "keyboard")
    self.Keybind = self.bindTab:CreateKeybind({
		Name = "Toggle Farming",
		CurrentKeybind = "Q",
		HoldToInteract = false,
		Flag = "Keybind1",
		Callback = function(Keybind)
			shared.FarmTab.farmToggle:Set(not shared.main.autoFarm)
		end,
	})
    self.GoToHaveKeybind = self.bindTab:CreateKeybind({
		Name = "Go To Hive",
		CurrentKeybind = "B",
		HoldToInteract = false,
		Flag = "Keybind2",
		Callback = function(Keybind)
			if shared.botHelper.autoFarm then 
				shared.main.autoFarm = false
				shared.botHelper:stop()
				shared.FarmTab.farmToggle:Set(false)
				shared.Rayfield:Notify({
					Title = "Notification",
					Content = "Auto Farm has been stopped.",
					Duration = 6.5,
				})
			end
			shared.hiveHelper:gotoHive()
		end,
	})
end

return Bind