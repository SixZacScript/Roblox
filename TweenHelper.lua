local TweenService = game:GetService("TweenService")

local TweenHelper = {}

function TweenHelper:tweenTo(targetPosition, character, tweenSpeed)
	if not character or not character:IsDescendantOf(game) then
		return false -- ensure return value
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	if not rootPart then
		return false -- ensure return value
	end

	local newCFrame = CFrame.new(targetPosition + Vector3.new(0, rootPart.Size.Y, 0))
	local duration = tweenSpeed or 1

	character:PivotTo(character:GetPivot())
	rootPart.Anchored = true

	local tween = TweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = newCFrame
	})

	local cancelled = false
	local connection
	connection = character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			cancelled = true
			tween:Cancel()
			if connection then connection:Disconnect() end
		end
	end)

	tween:Play()
	tween.Completed:Wait()

	if connection then connection:Disconnect() end
	if character:IsDescendantOf(game) and rootPart then
		rootPart.Anchored = false
	end

	return not cancelled
end


return TweenHelper