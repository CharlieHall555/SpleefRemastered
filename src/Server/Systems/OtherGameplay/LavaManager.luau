local LavaManager = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local TeleportManager = require(ModuleDirectory.Round.TeleportManager)

local lava: Part? = nil
local frameCounter = 0

-- Optional: only kill during round
local KILL_ONLY_DURING_ROUND = false

-- Teleport/kill debounce to prevent spam
local HIT_COOLDOWN_SEC = 1.0
local lastHitAt: { [Player]: number } = {}

-- Provide a safe default; can be overridden elsewhere via setter.
function LavaManager.getMap(_player) return nil end
function LavaManager.setGetMap(fn)
	if type(fn) == "function" then
		LavaManager.getMap = fn
	end
end

local function safeKill(char: Model)
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

local function killIfHasCharacter(p: Player)
	if p and p.Character then
		safeKill(p.Character)
	end
end

local function shouldProcess(player: Player): boolean
	-- Cooldown
	local now = os.clock()
	local last = lastHitAt[player] or 0
	if (now - last) < HIT_COOLDOWN_SEC then
		return false
	end

	if KILL_ONLY_DURING_ROUND then
		local state = RoundSystem.getState()
		if not (state == "ACTIVE" or state == "PREPARING") then
			return false
		end
	end

	lastHitAt[player] = now
	return true
end

local function handleLavaContactForCharacter(char: Model)
	if not char then return end
	local player = Players:GetPlayerFromCharacter(char)

	-- If it's not a player character, you can choose to kill or ignore.
	if not player then
		-- If lava should also kill NPCs:
		safeKill(char)
		return
	end

	if not shouldProcess(player) then
		return
	end

	local inTutorial = SessionVariables.getValue(player, "inTutorial") == true

	if inTutorial then
		-- Guard getMap call
		local tutorialMap = nil
		if type(LavaManager.getMap) == "function" then
			tutorialMap = LavaManager.getMap(player)
		end

		if tutorialMap and tutorialMap.OriginPosition then
			local TELEPORT_OFFSET = Vector3.new(0, 50, 0)
			TeleportManager.teleport(player, tutorialMap.OriginPosition + TELEPORT_OFFSET, true)
		else
			killIfHasCharacter(player)
		end
	else
		killIfHasCharacter(player)
	end
end

function LavaManager.init()
	ServerHitBoxManager.setUpCallback("Lava", function(player: Player, _otherPart: BasePart)
		-- Hitbox callback already knows the player; just handle once
		if player and player.Character then
			handleLavaContactForCharacter(player.Character)
		end
	end)

	RunService.PostSimulation:Connect(function()
		if not lava then return end

		if frameCounter > 10 then
			frameCounter = 0
			local partsInPart = workspace:GetPartsInPart(lava)
			for _, part in ipairs(partsInPart) do
				local parent = part.Parent
				if parent then
					local humanoid = parent:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local char = humanoid.Parent
						if char then
							handleLavaContactForCharacter(char)
						end
					end
				end
			end
		else
			frameCounter += 1
		end
	end)
end

function LavaManager.setLava(part: Part)
	lava = part
end

return LavaManager
