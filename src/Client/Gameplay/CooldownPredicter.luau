local RunService = game:GetService("RunService")
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local AbilitiesData = require(ClientModuleDirectory.AbilitiesData)
local TouchButtons = require(ClientModuleDirectory.Gui.TouchButtons)

local lastUsed: number = 0
local cooldown: number = 0

local abilityDef
local abilityName

local cooldownPredicter = {}

function cooldownPredicter.onProfileLoaded()
	UserProfile.setOnUpdateCallback(function(valueName, newValue)
		abilityName = newValue
		abilityDef = AbilitiesData[abilityName]
	end, "ability")

	abilityName = UserProfile.getValue("ability")
	abilityDef = AbilitiesData[abilityName]

	RemoteEventHandler.newEventConnection("FIRE_ABILITY", function()
		lastUsed = time()
	end)

	RunService.RenderStepped:Connect(function()
		if not abilityDef then
			return
		end
		local abilityCooldown = abilityDef.cooldown or 0
		cooldown = math.clamp(abilityCooldown - (time() - lastUsed), 0, abilityCooldown)

		if cooldown > 0 then
			TouchButtons.showCooldown()
			TouchButtons.setCooldown(cooldown + 1)
		else
			TouchButtons.hideCooldown()
		end
	end)
end

function cooldownPredicter.getCooldown(): number
	return cooldown
end

return cooldownPredicter
