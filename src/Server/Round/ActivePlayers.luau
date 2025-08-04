local Players = game:GetService("Players")
local ActivePlayers = {}
ActivePlayers.__index = ActivePlayers

export type ActivePlayers = {
	playersAlive: { Player },
    setOnChange : (self: ActivePlayers, fn : (playerList : {Players}) -> ()) -> nil,
    onChange : (playerList : {Players}) -> (),
	isAlive: (self: ActivePlayers, player: Player) -> boolean,
	removePlayer: (self: ActivePlayers, player: Player) -> nil,
	addPlayer: (self: ActivePlayers, player: Player) -> nil,
	getSize: (self: ActivePlayers) -> number,
	clear: (self: ActivePlayers) -> nil,
}

function ActivePlayers.new(): ActivePlayers
	local self = setmetatable({
		playersAlive = {},
        onChange = nil
	}, ActivePlayers)
	return self
end

function ActivePlayers:setOnChange(fn : (playerList : {Players}) -> ())
	self.onChange = fn
end

function ActivePlayers:isAlive(player: Player): boolean
	for _, p in ipairs(self.playersAlive) do
		if p == player then
			return true
		end
	end
	return false
end

function ActivePlayers:addPlayer(player: Player): nil
	if not self:isAlive(player) then
		table.insert(self.playersAlive, player)
	end
    if self.onChange then
        self.onChange(self.playersAlive)
    end
end

function ActivePlayers:removePlayer(player: Player): nil
	for i, p in ipairs(self.playersAlive) do
		if p == player then
			table.remove(self.playersAlive, i)
			break
		end
	end
    if self.onChange then
        self.onChange(self.playersAlive)
    end
end

function ActivePlayers:getSize(): number
	return #self.playersAlive
end

function ActivePlayers:clear(): nil
	self.playersAlive = {}
end

return ActivePlayers
