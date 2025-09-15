local ClientVoice = {}

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function onDescendantAdded(descendant: Instance)
	if descendant:IsA("Wire") then
		descendant:Destroy()
	end
end

function ClientVoice.init()
	for _, descendant in player:GetDescendants() do
		onDescendantAdded(descendant)
	end
	player.DescendantAdded:Connect(onDescendantAdded)
end

return ClientVoice
