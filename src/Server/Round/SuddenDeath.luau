local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Map = require(ModuleDirectory.Map.Map)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local RoundSystem = require(ModuleDirectory.RoundSystem)
local BlockFactory = require(ModuleDirectory.Map.BlockFactory)

local SuddenDeath = {}

function SuddenDeath.start(map: Map.Map): nil
	task.spawn(function()
		while RoundSystem.getState() == "ACTIVE" do
			task.wait(Config.SUDDEN_DEATH_DELAY)

			for _ = 1, Config.SUDDEN_DEATH_BLOCKS_CHOSEN do
				SuddenDeath.destroyRandomBlock(map)
			end
		end
	end)

	print("end")
end

function SuddenDeath.destroyRandomBlock(map: Map.Map)
	local randomLayer = map:getRandomLayer()
	local randomBlock = randomLayer:getRandomBlock()
	if randomBlock then
		BlockFactory.slowDestroy(randomBlock)
	end
end

return SuddenDeath
