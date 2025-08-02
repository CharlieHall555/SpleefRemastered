local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Slot

local Container = {}
Container.__index = Container
export type Container = {

	ContainerId: number,
	Size: Vector2,
	Slots: {},
}

function Container.init()
	Slot = require(ModuleDirectory.Slot)
 end

function Container.new(ContainerId: number, Size: Vector2)
	local newContainer = {}
	setmetatable(newContainer, Container)
    newContainer.ContainerId = ContainerId
	newContainer.Slots = {}
    newContainer.Size = Size
	for x = 1, Size.X do
		table.insert(newContainer.Slots, {})
		for y = 1, Size.Y do
			newContainer.Slots[x][y] = Slot.new(Vector2.new(x, y))
		end
	end

	return newContainer
end

function Container:toString()
    local output = "--ContainerId: " .. self.ContainerId.. "--"
	for x = 1, self.Size.X do
        output = output .. "\n"
		for y = 1, self.Size.Y do
            local Slot : Slot.Slot = self.Slots[x][y]
            output = output .. Slot:toString()
		end
	end
    return output
end

function Container:InsertEntity(PositionToInsert: Vector2, Entity: any?)
	assert(Entity, "Given entity is nil.")
	assert(PositionToInsert.X > 0 and PositionToInsert.X <= self.Size.X, "Position to insert is out of range on X axis.")
	assert(PositionToInsert.Y > 0 and PositionToInsert.Y <= self.Size.Y, "Position to insert is out of range on Y axis.")
	local SlotToInsert: Slot.Slot = self.Slots[PositionToInsert.X][PositionToInsert.Y]
	SlotToInsert:setEntity(Entity)
end

return Container
