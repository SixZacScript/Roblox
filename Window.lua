-- local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SixZacScript/Roblox/refs/heads/main/Rayfield.lua'))()
local Rayfield = loadstring(readfile("BeeSwarm/Rayfield.lua"))()
shared.Rayfield = Rayfield
return Rayfield:CreateWindow({
    Name = "Sippy Hub | SixZacScript",
    LoadingTitle = "Rayfield Interface Suite",
    LoadingSubtitle = "by Sirius",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "FlowerZonesConfig"
    },

})