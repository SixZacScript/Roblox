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
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Example Key System",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"ExampleKey"}
    }
})