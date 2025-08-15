local Players = game:GetService("Players")
local player = Players.LocalPlayer
local GUIAssets = game:GetService("ReplicatedStorage").GUIAssets

local HowToPlay = {}

local howToPlayGUI : Frame

function HowToPlay.onProfileLoaded()

    task.spawn(function()
        task.wait(0.5)
        howToPlayGUI = GUIAssets:WaitForChild("HowToPlay")
        if howToPlayGUI then
            howToPlayGUI.Parent = player.PlayerGui.General

            howToPlayGUI.Play.Activated:Once(function()
                howToPlayGUI:Destroy()
            end)

        end
    end)
  

end

return HowToPlay