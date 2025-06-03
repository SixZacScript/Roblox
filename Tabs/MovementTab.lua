local Movement = {}
Movement.__index = Movement

function Movement.new()
    local self = setmetatable({}, Movement)

    self.MovementTab = shared.RayWindow:CreateTab("Movement", "dumbbell")

    self.MovementTab:CreateSlider({
		Name = "Walk Speed",
		Range = {16, 100},
		Increment = 1,
		Suffix = "Speed",
		CurrentValue = shared.main.defaultWalkSpeed,
		Callback = function(value)
			shared.main.defaultWalkSpeed = value
		end,
	})
	self.MovementTab:CreateSlider({
		Name = "Jump Power",
		Range = {50, 150},
		Increment = 1,
		Suffix = "Power",
		CurrentValue = shared.main.defaultJumpPower,
		Callback = function(value)
			shared.main.defaultJumpPower = value
		end,
	})
	task.spawn(function()
		while true do
			if shared.character and  shared.character.humanoid then
				local humanoid = shared.character.humanoid
				humanoid.WalkSpeed = shared.main.defaultWalkSpeed
				humanoid.JumpPower = shared.main.defaultJumpPower
			end
			task.wait()
		end
	end)

end

return Movement