local HiveHelper = {}
HiveHelper.__index = HiveHelper

function HiveHelper.new()
    local self = setmetatable({}, HiveHelper)

    return self
end

return HiveHelper