export type tutoiralStage = {
    stepNumber : number,
    messageMobile : string,
    messagePC: string,
    image : string,
    actionToComplete : string,
    autoCOmpleteTime : number?
}

export type TutorialStage = {
    stepNumber: number,
    messageMobile: string,
    messagePC: string,
    image: string,
    actionToComplete: string,
    autoCompleteTime: number?
}

return {

    [1] = {
        stepNumber = 1,
        messageMobile = "Welcome to Spleef!",
        messagePC = "Welcome to Spleef!",
        image = "rbxassetid://123617674579208",
        actionToComplete = "AUTO_COMPLETE",
        autoCompleteTime = 5
    },

    [2] = {
        stepNumber = 2,
        messageMobile = "This is the Tutorial Area",
        messagePC = "This is the Tutorial Area",
        image = "rbxassetid://117860991780103",
        actionToComplete = "AUTO_COMPLETE",
        autoCompleteTime = 6
    },

    [3] = {
        stepNumber = 3,
        messageMobile = "You can mine blocks by tapping on them.",
        messagePC = "You can mine blocks by clicking on them.",
        image = "rbxassetid://109827464005955",
        actionToComplete = "BREAK",
    },

    [4] = {
        stepNumber = 4,
        messageMobile = "Breaking blocks gives you ammo.",
        messagePC = "Breaking blocks gives you ammo.",
        image = "rbxassetid://91214120728139",
        actionToComplete = "AUTO_COMPLETE",
        autoCompleteTime = 6
    },

    [5] = {
        stepNumber = 5,
        messageMobile = "You can also shoot snowballs by firing at far away blocks.",
        messagePC = "You can also shoot snowballs by clicking far away blocks.",
        image = "rbxassetid://91214120728139",
        actionToComplete = "SHOOT",

    },

    [6] = {
        stepNumber = 6,
        messageMobile = "You can see your ability here.",
        messagePC = "You can see your ability here.",
        image = "rbxassetid://105149444573059",
        actionToComplete = "AUTO_COMPLETE",
        autoCompleteTime = 8
    },

    [7] = {
        stepNumber = 7,
        messageMobile = "Press the ability button to use your ability!",
        messagePC = "Press Q to use your ability!",
        image = "rbxassetid://105149444573059",
        actionToComplete = "ABILITY",
    },

    [9] = {
        stepNumber = 9,
        messageMobile = "Knock other players off with snowballs or mining!",
        messagePC = "Knock other players off with snowballs or mining!",
        image = "rbxassetid://83374499434122",
        actionToComplete = "AUTO_COMPLETE",
        autoCompleteTime = 8
    },

    [10] = {
        stepNumber = 10,
        messageMobile = "Tutorial complete, Returning to lobby",
        messagePC = "Tutorial complete, Returning to lobby",
        image = "rbxassetid://117860991780103",
        actionToComplete = "AUTO_COMPLETE",
        autoCompleteTime = 6
    }


}
