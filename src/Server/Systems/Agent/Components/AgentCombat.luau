local Debris = game:GetService("Debris")

local Combat = {}

local function disconnectMove(agent)
	if agent._moveConnection then
		agent._moveConnection:Disconnect()
		agent._moveConnection = nil
	end
end

local function fireDied(agent, damagingPlayer)
	-- callback is stored on the Agent module table (set by Agent.setUpCallback)
	if agent.onDiedCallback then
		agent.onDiedCallback(agent, damagingPlayer)
	end
end

function Combat.die(agent)
	if not agent.model then
		return nil
	end

	if agent.healthBar then
		agent.healthBar:setEnabled(false)
	end

	disconnectMove(agent)

	for _, child in pairs(agent.model:GetDescendants()) do
		if child.Name == "NameTagTemplate" then
			child:Destroy()
		end

		if child:IsA("Motor6D") then
			child:Destroy()
		elseif child:IsA("BasePart") then
			Debris:AddItem(child, 2)
		end
	end

	Debris:AddItem(agent.model, 5)

	return nil
end

function Combat.takeDamage(agent, value: number, damagingPlayer)
	if agent.model == nil then
		warn("Agent has no model")
		return nil
	end

	agent.health -= value

	if agent.healthBar then
		agent.healthBar:update(agent.health)
	end

	if agent.health <= 0 then
		agent.health = 0
		Combat.die(agent)
		fireDied(agent, damagingPlayer)
	end

	return nil
end

return Combat
