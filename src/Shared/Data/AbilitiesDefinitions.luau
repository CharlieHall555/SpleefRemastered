export type Ability = {
    cooldown : number
}

return {

    ["DASH"] = {icon = "rbxassetid://136250138779933" , enabled = true,cooldown = 5  , activeTime = 0, cost=1, displayName = "Dash" , name = "DASH"},
    ["TELEPORT"] = {icon = "rbxassetid://94591374365238" , enabled = true,cooldown = 18  , activeTime = 0, cost=1000, displayName = "Teleport" , name = "TELEPORT"},
    ["BOMB"] = {icon = "rbxassetid://72606920632377" , enabled = true,cooldown = 10  , activeTime = 0, cost=750, displayName = "Bomb" , name = "BOMB"},
    ["BALLOONS"] = {icon = "rbxassetid://106225491444315" , enabled = false,cooldown = 20  , activeTime = 5, cost=1200, displayName = "Balloons" , name = "BALLOONS"},
    ["FEATHER-FALLING"] = {icon = "rbxassetid://102262912075252" , enabled = true,cooldown = 14  , activeTime = 5, cost=750, displayName = "Feather Falling" , name = "FEATHER-FALLING"},
    ["INFINITE_AMMO"] = {icon = "rbxassetid://106747775849842" , enabled = false ,cooldown = 20  , activeTime = 5, cost=1200, displayName = "Infinite Ammo" , name = "INFINITE_AMMO"},
    ["SPRING"] = {icon = "rbxassetid://129694227969563" , enabled = true,cooldown = 7  , activeTime = 5, cost=300, displayName = "Spring" , name = "SPRING"},

}