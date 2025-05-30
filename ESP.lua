
local ESP = {}
ESP.TrackedObjects = {}

function ESP:AddObject(object)
    table.insert(self.TrackedObjects, object)
end

-- Function to remove an object from ESP tracking
function ESP:RemoveObject(object)
    for i, obj in ipairs(self.TrackedObjects) do
        if obj == object then
            table.remove(self.TrackedObjects, i)
            break
        end
    end
end

function ESP:TrackingFolder(folder)
    if not folder or not folder:IsA("Folder") then
        error("Invalid folder provided for ESP tracking.")
    end

    local function onChildAdded(child)
        if child:IsA("BasePart") or child:IsA("Model") then
            self:AddObject(child)
        end
    end

    local function onChildRemoved(child)
        self:RemoveObject(child)
    end

    folder.ChildAdded:Connect(onChildAdded)
    folder.ChildRemoved:Connect(onChildRemoved)

    for _, child in ipairs(folder:GetChildren()) do
        onChildAdded(child)
    end
    
end

function ESP:GetTrackedObjects()
    return self.TrackedObjects
end

return ESP