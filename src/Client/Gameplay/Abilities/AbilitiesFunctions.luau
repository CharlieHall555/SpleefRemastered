--client abilities function
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local abilityFunctions = {}

local Camera : Camera?

function abilityFunctions.init()
    Camera = workspace.CurrentCamera
end


abilityFunctions["DASH"] = function(player, character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    local dashSound = "rbxassetid://80426554346602"

    if humanoid then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            SoundPlayer.playSound(dashSound , {volume = 0.35 , playbackSpeed = 1.2})
            local principle = Camera or rootPart
            local linearVelocity = Instance.new("LinearVelocity")
            linearVelocity.Attachment0 = rootPart:FindFirstChildWhichIsA("Attachment")
            linearVelocity.MaxForce = math.huge
            local LookVector = Vector3.new(principle.CFrame.LookVector.X, 0, principle.CFrame.LookVector.Z).Unit
            linearVelocity.VectorVelocity = LookVector * 45
            linearVelocity.Parent = rootPart
            game.Debris:AddItem(linearVelocity, 0.4)
        end
    end
end



return abilityFunctions 