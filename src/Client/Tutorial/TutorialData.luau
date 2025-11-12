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
		autoCompleteTime = 4
	},

	[2] = {
		stepNumber = 2,
		messageMobile = "This is the tutorial area.",
		messagePC = "This is the tutorial area.",
		image = "rbxassetid://117860991780103",
		actionToComplete = "AUTO_COMPLETE",
		autoCompleteTime = 4
	},

	[3] = {
		stepNumber = 3,
		messageMobile = "Move around with your joystick!",
		messagePC = "Move using W, A, S, D or arrow keys.",
		image = "rbxassetid://125158588700543",
		actionToComplete = "MOVE",
	},

	[4] = {
		stepNumber = 4,
		messageMobile = "Tap blocks to break them!",
		messagePC = "Click blocks to break them!",
		image = "rbxassetid://109827464005955",
		actionToComplete = "BREAK",
	},

	[5] = {
		stepNumber = 5,
		messageMobile = "Breaking blocks gives snowball ammo.",
		messagePC = "Breaking blocks gives snowball ammo.",
		image = "rbxassetid://91214120728139",
		actionToComplete = "AUTO_COMPLETE",
		autoCompleteTime = 5
	},

	[6] = {
		stepNumber = 6,
		messageMobile = "Shoot snowballs at far blocks!",
		messagePC = "Shoot snowballs at far blocks!",
		image = "rbxassetid://91214120728139",
		actionToComplete = "SHOOT",
	},

	[7] = {
		stepNumber = 7,
		messageMobile = "Your ability bar is here.",
		messagePC = "Your ability bar is here.",
		image = "rbxassetid://105149444573059",
		actionToComplete = "AUTO_COMPLETE",
		autoCompleteTime = 6
	},

	[8] = {
		stepNumber = 8,
		messageMobile = "Tap the button to use your ability!",
		messagePC = "Press Q to use your ability!",
		image = "rbxassetid://105149444573059",
		actionToComplete = "ABILITY",
	},

	[9] = {
		stepNumber = 9,
		messageMobile = "Knock players into the lava!",
		messagePC = "Knock players into the lava!",
		image = "rbxassetid://83374499434122",
		actionToComplete = "AUTO_COMPLETE",
		autoCompleteTime = 6
	},

	[10] = {
		stepNumber = 10,
		messageMobile = "Don't fall in the lava!",
		messagePC = "Don't fall in the lava!",
		image = "rbxassetid://112304910791011",
		actionToComplete = "AUTO_COMPLETE",
		autoCompleteTime = 6
	},

	[11] = {
		stepNumber = 11,
		messageMobile = "Tutorial complete! Returning to lobby.",
		messagePC = "Tutorial complete! Returning to lobby.",
		image = "rbxassetid://117860991780103",
		actionToComplete = "AUTO_COMPLETE",
		autoCompleteTime = 4
	}

}
