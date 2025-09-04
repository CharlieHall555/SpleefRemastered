local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local LocalPlayer = game.Players.LocalPlayer
local ParticlePlayer = require(ClientModuleDirectory.ParticlePlayer)
local CollectionService = game:GetService("CollectionService")

local ClientSnowballVisual = {}

local _tagHandlers: { [string]: (hitObject: Instance) -> () } = {}

function ClientSnowballVisual.registerTag(tagName: string, fn: (hitObject: Instance) -> ())
	if typeof(tagName) ~= "string" or tagName == "" then
		return
	end
	if typeof(fn) ~= "function" then
		return
	end
	_tagHandlers[tagName] = fn
end

function ClientSnowballVisual.unregisterTag(tagName: string): nil
	_tagHandlers[tagName] = nil
end

-- on every snowball hit, if the hit instance has any registered tag(s), fire their callbacks
local function onSnowballHit(hitPos: Vector3, hitInstance: Instance?)
	if hitPos then
		ParticlePlayer.queueEmission("PARTICLE_SNOWBALL", hitPos, 12)
		SoundPlayer.queuePositionalSound("rbxassetid://9119310655", hitPos, { volume = 0.75, playbackSpeed = 1.2 })
	end

	if not hitInstance then
		return
	end

	local tags = CollectionService:GetTags(hitInstance)
	if #tags == 0 then
		return
	end

	for _, tag in ipairs(tags) do
		local handler = _tagHandlers[tag]
		if handler then
			task.spawn(function()
				local ok, err = pcall(handler, hitInstance)
				if not ok then
					warn("[ClientSnowballVisual] tag handler error for tag '" .. tag .. "': " .. tostring(err))
				end
			end)
		end
	end
end

function ClientSnowballVisual.init()
	RemoteEventHandler.newEventConnection("SNOWBALL_IMPACT", onSnowballHit)
end

return ClientSnowballVisual
