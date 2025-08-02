local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local Slot = {}
Slot.__index = Slot

export type Slot = {

	Position: Vector2,
}

function Slot.init() end

function Slot.new(Position: Vector2)
	local newSlot = {}
	setmetatable(newSlot, Slot)
	newSlot.Position = Position
	newSlot.Entity = nil
	return newSlot
end

function Slot:setPosition(newPosition: Vector2)
	self.Position = newPosition
end

function Slot:toString()
	if self.Entity == nil then
		return "[EMPTY]"
	else
		return "[x" .. self.Entity.Amount .. "" .. string.sub(self.Entity.Name, 1, 3) .. "]"
	end
end

function Slot:setEntity(newEntity: any)
	self.Entity = newEntity
end

return Slot
