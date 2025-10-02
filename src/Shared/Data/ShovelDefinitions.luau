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
        passLink = "rbxassetid://134332109977759"
    },

}