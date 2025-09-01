local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local PlayerData = require(ModuleDirectory.Player.PlayerData)

local LevelController = {} -- public facing api

-- Grants XP, carrying overflow across levels.
-- On each level up, XP for the new level starts from 0, and any remaining overflow continues.
function LevelController.giveXp(player: Player, xpAmount: number): nil
	if not player or type(xpAmount) ~= "number" or xpAmount <= 0 then
		return
	end

	local level = PlayerData.getLevel(player) or 1
	local xp = PlayerData.getXP(player) or 0

	local overflow = xp + xpAmount
	local safety = 0

	while true do
		local needed = LevelUtilities.xpToNextLevel(level)
		if overflow >= needed then
			overflow -= needed
			PlayerData.incrementLevel(player, 1) -- fires client "PROFILE_UPDATE" for level
			level += 1
			safety += 1
			if safety > 100 then
				break
			end
		else
			break
		end
	end

	PlayerData.setXP(player, overflow)
end

return LevelController
