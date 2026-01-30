local LocalizationService = game:GetService("LocalizationService")
--CLIENT ABILITIES START
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local ClientBlockSelector = require(ClientModuleDirectory.ClientBlockSelector)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local Resources = game:GetService("ReplicatedStorage"):WaitForChild("Resources")
local Debris = game:GetService("Debris")
local ParticlePlayer = require(ClientModuleDirectory.ParticlePlayer)
local AbilitiesData = require(ClientModuleDirectory.AbilitiesData)

local abilityFunctions = {}

local Camera : Camera?

local function getModelMass(model : Model)
    local totalMass = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            totalMass = totalMass + part:GetMass()
        end
    end
    return totalMass
end

function abilityFunctions.init()
    Camera = workspace.CurrentCamera
end


abilityFunctions["DASH"] = function(player, character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")



    if humanoid then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local charMass = getModelMass(character)
            SoundPlayer.playSound("dash_sound" , {volume = 0.35 , playbackSpeed = 1.2})
            local principle = Camera or rootPart
            local linearVelocity = Instance.new("LinearVelocity")
            linearVelocity.Attachment0 = rootPart:FindFirstChildWhichIsA("Attachment")
            linearVelocity.MaxForce = charMass * workspace.Gravity * 10
            local LookVector = Vector3.new(principle.CFrame.LookVector.X, 0, principle.CFrame.LookVector.Z).Unit
            linearVelocity.VectorVelocity = LookVector * 75
            linearVelocity.Parent = rootPart
            Debris:AddItem(linearVelocity, 0.4)
        end
    end
end

abilityFunctions["SPRING"] = function(player, character)
    local humanoid : Humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local charMass = getModelMass(character)
            SoundPlayer.playSound("dash_sound" , {volume = 0.35 , playbackSpeed = 1.2})
            local principle = Camera or rootPart
            local linearVelocity = Instance.new("LinearVelocity")
            linearVelocity.Attachment0 = rootPart:FindFirstChildWhichIsA("Attachment")
            linearVelocity.MaxForce = charMass * workspace.Gravity * 10
            local LookVector = Vector3.new(0, 1, 0)
            linearVelocity.VectorVelocity = LookVector * 110
            linearVelocity.Parent = rootPart
            Debris:AddItem(linearVelocity, 0.4)
        end
    end
end

abilityFunctions["BALLOONS"] = function(player, character)
    local humanoid : Humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local charMass = getModelMass(character)
            SoundPlayer.playSound("dash_sound" , {volume = 0.35 , playbackSpeed = 1.2})
            local principle = Camera or rootPart
            local linearVelocity = Instance.new("LinearVelocity")
            linearVelocity.Attachment0 = rootPart:FindFirstChildWhichIsA("Attachment")
            linearVelocity.MaxForce = charMass * workspace.Gravity * 1.5
            local LookVector = Vector3.new(0, 1, 0)
            linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
            linearVelocity.LineVelocity = 6
            linearVelocity.LineDirection = LookVector
            linearVelocity.Parent = rootPart
            Debris:AddItem(linearVelocity, AbilitiesData["BALLOONS"].activeTime)
        end
    end
end

local featherParticle = Resources:WaitForChild("UIParticles"):WaitForChild("Feather")

abilityFunctions["FEATHER-FALLING"] = function(player, character)
    local humanoid : Humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            
            local charMass = getModelMass(character)

            local newParticle
            if ParticlePlayer.getVisible() then
                newParticle = featherParticle:Clone()
                newParticle.Parent = rootPart
                newParticle.Enabled = true
                Debris:AddItem(newParticle, AbilitiesData["FEATHER-FALLING"].activeTime + 3)
            end

            local vectorForce = Instance.new("VectorForce")
            vectorForce.Attachment0 = rootPart:FindFirstChildWhichIsA("Attachment")
            vectorForce.Parent = rootPart
            vectorForce.Force = Vector3.new(0, charMass * workspace.Gravity * 0.9, 0)

            local jumpConnection = humanoid.StateChanged:Connect(function(_, newState)
                if newState == Enum.HumanoidStateType.Jumping then
                    vectorForce.Force = Vector3.new(0, 0, 0)
                    if newParticle then
                        newParticle.Enabled = false
                    end
                end
            end)

            Debris:AddItem(vectorForce, AbilitiesData["FEATHER-FALLING"].activeTime)

            task.delay(AbilitiesData["FEATHER-FALLING"].activeTime, function()
                if newParticle then
                    newParticle.Enabled = false
                end
                if jumpConnection then
                    jumpConnection:Disconnect()
                end
               
                vectorForce = nil

            end)

        end
    end
end


abilityFunctions["TELEPORT"] = function(player, character)
    local selectedBlock = ClientBlockSelector.getFocused()
    SoundPlayer.playSound("teleport_noise" , {volume = 0.8 , playbackSpeed = 1.1})

    if selectedBlock then      
        RemoteEventHandler.FireOnServer("REQUEST_TELEPORT" , selectedBlock)
    end

end


return abilityFunctions 