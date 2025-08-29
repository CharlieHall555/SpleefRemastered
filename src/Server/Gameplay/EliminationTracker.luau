local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local BlockDestructionTracker = require(ModuleDirectory.Gameplay.BlockDestructionTracker)
local PlayerDeathDetector = require(ModuleDirectory.Round.PlayerDeathDetector)
local TouchedBlockTracker = require(ModuleDirectory.Gameplay.TouchedBlockTracker)
local KnockbackTracker = require(ModuleDirectory.Gameplay.KnockbackTracker)

local EliminationTracker = {}

-- Tunables (adjust in playtests)
local T_KNOCKBACK_WINDOW = 4 -- seconds: max time from knockback to death
local T_TILE_WINDOW  = 2 -- seconds: max time from block break to death
local REQUIRE_TOUCH_BEFORE_BREAK = true -- must have touched block before it broke

function EliminationTracker.configure(opts: { knockbackWindow: number?, tileWindow: number? })
	if opts.knockbackWindow then T_KNOCKBACK_WINDOW = opts.knockbackWindow end
	if opts.tileWindow then T_TILE_WINDOW = opts.tileWindow end
end

-- Knockback attribution
local function resolveKnockbackKO(victim: Player, deathTime: number): Player?
	local knocks: {KnockbackTracker.KnockbackRecord} = KnockbackTracker.getKnockbacksFor(victim) or {}
	local best: KnockbackTracker.KnockbackRecord? = nil

	for _, rec in ipairs(knocks) do
		if rec and rec.time and rec.originPlayer then
			local dt = deathTime - rec.time
			if dt >= 0 and dt <= T_KNOCKBACK_WINDOW then
				if not best or rec.time > best.time then
					best = rec
				end
			end
		end
	end

	return best and best.originPlayer or nil
end

-- Tile-break attribution
local function resolveTileBreakKO(victim: Player, deathTime: number): Player?
	local touches: {TouchedBlockTracker.TouchRecord} = TouchedBlockTracker.getLastTouchedBlocks(victim) or {}

	for _, touch in ipairs(touches) do
		if touch and touch.blockId and touch.time then
			local record = BlockDestructionTracker.getDestroyRecord(touch.blockId)
			if record and record.time and record.player then
				local breakDt = deathTime - record.time
				local touchedBeforeBreakOk = (not REQUIRE_TOUCH_BEFORE_BREAK) or (record.time >= touch.time)
				if breakDt >= 0 and breakDt <= T_TILE_WINDOW and touchedBeforeBreakOk then
					return record.player
				end
			end
		end
	end

	return nil
end

-- Main attribution
function EliminationTracker.getEliminator(playerWhoDied: Player): Player?
	if not playerWhoDied then return nil end

	-- Death time should come from detector (which uses time())
	local deathTime: number? = PlayerDeathDetector.getDeathTime and PlayerDeathDetector.getDeathTime(playerWhoDied) or nil
	if not deathTime then
		return nil
	end

	-- 1) Knockback attribution first
	local kbKiller = resolveKnockbackKO(playerWhoDied, deathTime)
	if kbKiller then
		return kbKiller
	end

	-- 2) Tile-break attribution
	local tileKiller = resolveTileBreakKO(playerWhoDied, deathTime)
	if tileKiller then
		return tileKiller
	end

	-- 3) No clear killer = suicide
	return nil
end

return EliminationTracker
