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
		allowedValues = { "DEFAULT", "Debug" ,"GOLD", "ICE", "SHADOW", "VIP"},
	})

	ProfileManager.setFieldConstraint("ability" , {
		type = "whitelist",
		allowedValues = { "DASH" },
	})

	ProfileManager.setFieldConstraint("abilities" , {
		type = "list",
		allowedValues = { "DASH" },
		canBeEmpty = false,
	})

	ProfileManager.setFieldConstraint("shovels" , {
		type = "list",
		allowedValues = { "DEFAULT" , "Debug" , "VIP"},
		canBeEmpty = false,
	})
end

return ConstraintManager
