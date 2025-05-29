local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerMovementModule = {}
local currentWalkSpeed = 16
local currentJumpPower = 50
function PlayerMovementModule:start(mainTab)
	local movementSection = mainTab:CreateSection("Player Movement")
	mainTab:CreateSlider({
		Name = "Walk Speed",
		Range = {16, 100},
		Increment = 1,
		Suffix = "Speed",
		CurrentValue = 16,
		Callback = function(value)
			currentWalkSpeed = value
			local character = LocalPlayer.Character
			if character and character:FindFirstChild("Humanoid") then
				character.Humanoid.WalkSpeed = value
			end
		end,
		SectionParent = movementSection
	})

	mainTab:CreateSlider({
		Name = "Jump Power",
		Range = {50, 150},
		Increment = 1,
		Suffix = "Power",
		CurrentValue = 50,
		Callback = function(value)
			currentJumpPower = value
			local character = LocalPlayer.Character
			if character and character:FindFirstChild("Humanoid") then
				character.Humanoid.JumpPower = value
			end
		end,
		SectionParent = movementSection
	})

	LocalPlayer.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = currentWalkSpeed
		humanoid.JumpPower = currentJumpPower
	end)
end

return PlayerMovementModule