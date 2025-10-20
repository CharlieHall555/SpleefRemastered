local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ProfileManager = require(ModuleDirectory.Player.ProfileManager)

local ConstraintManager = {}

--Contraints garantee thefield is a certain value fall back is the value in profile tempalte found in playerdata.

function ConstraintManager.init()
	ProfileManager.setFieldConstraint("xp", {
		type = "number",
		min = 0,
	})

	ProfileManager.setFieldConstraint("level", {
		type = "number",
		min = 1,
	})

	ProfileManager.setFieldConstraint("respawns", {
		type = "number",
		min = 0,
	})

	ProfileManager.setFieldConstraint("coins", {
		type = "number",
		min = 0,
	})

	ProfileManager.setFieldConstraint("onboardingStep", {
		type = "number",
		min = 0,
		max = 10,
	})

	ProfileManager.setFieldConstraint("onboardingComplete", {
		type = "boolean",
	})

	ProfileManager.setFieldConstraint("hasJoinedBefore", {
		type = "boolean",
	})

	ProfileManager.setFieldConstraint("shovel", {
		type = "whitelist",
		allowedValues = { "DEFAULT", "Debug" ,"GOLD", "ICE", "SHADOW", "VIP" , "CrystalShovel" },
	})

	ProfileManager.setFieldConstraint("ability" , {
		type = "whitelist",
		allowedValues = { "DASH" , "TELEPORT" , "FEATHER-FALLING" , "BALLOONS" , "BOMB" , "INFINITE_AMMO" , "SPRING"},
	})

	ProfileManager.setFieldConstraint("abilities" , {
		type = "list",
		allowedValues = { "DASH" , "TELEPORT" , "FEATHER-FALLING" , "BALLOONS" , "BOMB" , "INFINITE_AMMO" , "SPRING"},
		canBeEmpty = false,
	})

	ProfileManager.setFieldConstraint("shovels" , {
		type = "list",
		allowedValues = { "DEFAULT" , "Debug" , "VIP" , "CrystalShovel"},
		canBeEmpty = false,
	})

	ProfileManager.setFieldConstraint("dailyRewardClaims" , {
		type = "list",
		allowedValues = { 1 , 2 , 3},
		canBeEmpty = true,
	})

	ProfileManager.setFieldConstraint("lastRewardSession", {
		type = "number",
	})
end

return ConstraintManager
