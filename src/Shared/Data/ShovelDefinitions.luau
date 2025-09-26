export type ShovelDefinition = {
    name: string,
    displayName: string,
    image: string,
    cost: number,
    canBuy: boolean,
    showInShop: boolean,
}

return {

    Default = {
        name = "DEFAULT",
        displayName = "Default Shovel",
        image = "rbxassetid://123456789",
        cost = 1,
        canBuy = true,
        showInShop = true,
    },
    VIP = {
        name = "VIP",
        displayName = "VIP Shovel",
        image = "rbxassetid://123456789",
        cost = 1,
        canBuy = false,
        showInShop = false,
    }

}