local Movement = {}
Movement.__index = Movement

function Movement.new(manageRef)
    local self = setmetatable({}, Movement)
    self.mainTab = manageRef.mainTab
    self.currentWalkSpeed = shared.main.defaultWalkSpeed
	self.currentJumpPower = shared.main.defaultJumpPower
    self.MovementTab = manageRef.Window:CreateTab("Movement", "dumbbell")

    self.MovementTab:CreateSlider({
		Name = "Walk Speed",
		Range = {16, 100},
		Increment = 1,
		Suffix = "Speed",
		CurrentValue = self.currentWalkSpeed,
		Callback = function(value)
			self.currentWalkSpeed = value
			local character = manageRef.character
			if character and character:FindFirstChild("Humanoid") then
				character.Humanoid.WalkSpeed = value
			end
		end,
	})
	self.MovementTab:CreateSlider({
		Name = "Jump Power",
		Range = {50, 150},
		Increment = 1,
		Suffix = "Power",
		CurrentValue = self.currentJumpPower,
		Callback = function(value)
			self.currentJumpPower = value
			local character = manageRef.character
			if character and character:FindFirstChild("Humanoid") then
				character.Humanoid.JumpPower = value
			end
		end,
	})

    local function applyMovementStats(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = self.currentWalkSpeed
		humanoid.JumpPower = self.currentJumpPower

		humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if humanoid.WalkSpeed ~= self.currentWalkSpeed then
				humanoid.WalkSpeed = self.currentWalkSpeed
			end
		end)
	end

	if manageRef.character then
		applyMovementStats(manageRef.character)
	end

	manageRef.localPlayer.CharacterAdded:Connect(applyMovementStats)
end

return Movement