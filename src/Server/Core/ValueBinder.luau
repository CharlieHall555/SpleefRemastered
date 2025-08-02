--local EventHandler = require(game:GetService("ReplicatedStorage").EventHandler)
local Players = game.Players
local HttpService = game:GetService("HttpService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local SharedValues = {}

local ValueBinder = {}
ValueBinder.__index = ValueBinder

export type ValueBinder = {

    Player : Player,
    Cache : {},

}

function ValueBinder.init(): nil
end

function ValueBinder.new(Player: Player) : ValueBinder
	local newValueBinder = {}
	setmetatable(newValueBinder, ValueBinder)
	newValueBinder.Player = Player
	newValueBinder.Cache = {}

	return newValueBinder
end

function ValueBinder.UpdateSharedValue(ValueName: string, Value: any): nil
	SharedValues[ValueName] = Value

	for Index, EachPlayer in Players:GetChildren() do
		RemoteEventHandler.FireOnClient(EachPlayer, "UpdateValue", ValueName, Value)
	end
end

function ValueBinder:UpdateValue(ValueName: string, Value: any): nil
	self.Cache[self.Player.UserId][ValueName] = Value

	RemoteEventHandler.FireOnClient(self.Player, "UpdateValue", ValueName, Value)
end

function ValueBinder.GetSharedValues(): string
	return HttpService:JSONEncode(SharedValues)
end

function ValueBinder:GetValues() : string
    return HttpService:JSONEncode(self.Cache)
end


return ValueBinder
