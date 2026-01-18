local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local VectorUtil = require(ModuleDirectory.VectorUtil)

local LayerUtilities = {}



function LayerUtilities.groupLayers(layers: {}): { [number]: {} }
	local output = {}
	for _, eachLayer in layers do
		if not output[eachLayer.originPosition.Y] then
			output[eachLayer.originPosition.Y] = {}
		end

		table.insert(output[eachLayer.originPosition.Y], eachLayer)
	end

	return output
end

function LayerUtilities.getLayer(groupedLayers: { [number]: {} }, layerPosition: number): {}?
	return groupedLayers[layerPosition]
end

function LayerUtilities.combineLayers(layers : {}) : {[number] : {[Vector2] : {}}}
    local output : {[number] : {[Vector2] : {}}} = {}

    for _ , eachLayer in layers do
        for _ , block in eachLayer.blocks do
            if not output[eachLayer.originPosition.Y] then
                output[eachLayer.originPosition.Y] = {}
            end
            output[eachLayer.originPosition.Y][VectorUtil.SerializeVector2(block.LayerPosition)] = block
        end
    end

    return output
end

function LayerUtilities.getLayerPositionIsOn(groupedLayers: { [number]: {} }, targetPosition: Vector3): number?
	local targetY = targetPosition.Y
	local bestLayerY: number? = nil

	for layerY: number, _ in pairs(groupedLayers) do
		if layerY <= targetY then
			if bestLayerY == nil or layerY > bestLayerY then
				bestLayerY = layerY
			end
		end
	end

	return bestLayerY
end

return LayerUtilities
