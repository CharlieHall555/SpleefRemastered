export type ShovelDefinition = {
    name: string,
    displayName: string,
    image: string,
    cost: number,
    canBuy: boolean,
    showInShop: boolean,
    passLink: string?,
}

return {

    Default = {
        name = "DEFAULT",
        displayName = "Default Shovel",
        image = "rbxassetid://78996729241524",
        cost = 1,
        canBuy = true,
        showInShop = true,
        
    },
    Debug = {
        name = "Debug",
        displayName = "Debug Shovel",
        image = "rbxassetid://123456789",
        cost = 1,
        canBuy = true,
        showInShop = false,
    },
    VIP = {
        name = "VIP",
        displayName = "VIP Shovel",
        image = "rbxassetid://113069624280056",
        cost = 1,
        canBuy = false,
        showInShop = true,
        passLink = 1502789277 -- passlink must be a number
    },
    CrystalShovel = {
        name = "CrystalShovel",
        displayName = "Crystal Shovel",
        image = "rbxassetid://73421576945772",
        cost = 500,
        canBuy = true,
        showInShop = true,
    },

}