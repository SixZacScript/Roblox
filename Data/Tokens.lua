local TokenHelper = {}

function TokenHelper:getAllToken()
   return {
        -- TIER 1: ULTRA RARE (Priority 100) - Extremely valuable items
        ["💎 Diamond Egg"] = {id = 1471850677, isSkill = false, priority = 100},
        ["⭐ Starjelly"] = {id = 2319943273, isSkill = false, priority = 100},
        ["🥇 Gold Egg"] = {id = 1471849394, isSkill = false, priority = 95},

        -- TIER 2: HIGH VALUE CONSUMABLES (Priority 80-90)
        ["👑 Royal Jelly"] = {id = 1471882621, isSkill = false, priority = 90},
        ["📋 Oil"] = {id = 2545746575, isSkill = false, priority = 85},
        ["✨ Glitter"] = {id = 2542899798, isSkill = false, priority = 85},
        ["🧪 Glue"] = {id = 2504978518, isSkill = false, priority = 85},
        ["🎫 Ticket"] = {id = 1674871631, isSkill = false, priority = 85},
        ["🔷 Blue Extract"] = {id = 2495935302, isSkill = false, priority = 80},
        ["🔴 Red Extract"] = {id = 2495935302, isSkill = false, priority = 80},
        ["🌱 Sprout"] = {id = 2529092039, isSkill = false, priority = 80},

        -- TIER 3: POWERFUL BOOSTS & SYNCS (Priority 70-75)
        ["🔗 Link Token"] = {id = 1629547638, isSkill = true, priority = 75},
        ["💣+ Buzz Bomb Plus"] = {id = 1442764904, isSkill = true, priority = 70},
        ["🔗 Blue Sync"] = {id = 1874692303, isSkill = true, priority = 70},
        ["🔗 Red Sync"] = {id = 1874704640, isSkill = true, priority = 70},
        ["🎲 Dice 3"] = {id = 8055428094, isSkill = false, priority = 70},

        -- TIER 4: STRONG BOOSTS (Priority 60-65)
        ["🟥 Red Boost"] = {id = 1442859163, isSkill = true, priority = 65},
        ["🟦 Blue Boost"] = {id = 1442863423, isSkill = true, priority = 65},
        ["🎯 Focus"] = {id = 1629649299, isSkill = true, priority = 60},
        ["💥 Pulse"] = {id = 1874564120, isSkill = true, priority = 60},
        ["💣 Buzz Bomb"] = {id = 1442725244, isSkill = true, priority = 60},
        ["🎲 Dice 2"] = {id = 8054996680, isSkill = false, priority = 60},

        -- TIER 5: UTILITY ITEMS (Priority 50-55)
        ["🔶 Honey Mark"] = {id = 2499514197, isSkill = true, priority = 55},
        ["🌙 Moon Charm"] = {id = 2306224717, isSkill = false, priority = 55},
        ["🦮 Honey Suckle"] = {id = 8277901755, isSkill = false, priority = 50},
        ["🐜 Antpass"] = {id = 2060626811, isSkill = false, priority = 50},
        ["📯 Broken Drive"] = {id = 13369738621, isSkill = false, priority = 50},

        -- TIER 6: MEDIUM VALUE ITEMS (Priority 40-45)
        ["☁️ Cloud Vial"] = {id = 3030569073, isSkill = false, priority = 45},
        ["🔄 Micro Converter"] = {id = 2863122826, isSkill = false, priority = 45},
        ["🤖 Robot Pass"] = {id = 3036899811, isSkill = false, priority = 40},
        ["💧 Gumdrops"] = {id = 1838129169, isSkill = false, priority = 40},
        ["🥥 Coconut"] = {id = 3012679515, isSkill = false, priority = 40},

        -- TIER 7: FOOD & TREATS (Priority 30-35)
        ["🍬 Jellybean 2"] = {id = 3080740120, isSkill = false, priority = 35},
        ["🍍 Pineapple Candy"] = {id = 2584584968, isSkill = false, priority = 35},
        ["🔵 Blue Berry"] = {id = 2028453802, isSkill = false, priority = 30},
        ["🎈 Red Balloon"] = {id = 8058047989, isSkill = false, priority = 30},

        -- TIER 8: BASIC RESOURCES (Priority 20-25)
        ["🌻 Sunflowerseed"] = {id = 1952682401, isSkill = false, priority = 25},
        ["🍍 Pineapple"] = {id = 1952796032, isSkill = false, priority = 25},
        ["🍓 Strawberry"] = {id = 1952740625, isSkill = false, priority = 25},
        ["🍯 Honey"] = {id = 1472135114, isSkill = false, priority = 20},

        -- TIER 9: LOW PRIORITY (Priority 10-15)
        ["⚡ Speed"] = {id = 65867881, isSkill = true, priority = 15},
        ["😡 Rage"] = {id = 1442700745, isSkill = true, priority = 10},
        ["🍬 Treat"] = {id = 2028574353, isSkill = false, priority = 10},
    }
end

function TokenHelper:getTokenById(searchId)
    for name, data in pairs(self:getAllToken()) do
        if data.id == searchId then
            return name, data
        end
    end
    return nil
end

return TokenHelper