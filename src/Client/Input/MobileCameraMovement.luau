local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local InputHandler = require(Root.Input.InputHandler)
local UserInputService = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local MobileCamera = require(ClientModuleDirectory.Input.MobileCamera)

--uid = InputHandler.bindActionStart(UserInputType , callback) to bind
--InputHandler.unbind(uid) to unbind

local MobileCameraMovemenet = {}

function MobileCameraMovemenet.init()


    UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
        
        if input.UserInputType == Enum.UserInputType.Touch and gameProcessedEvent == false then
            
            MobileCamera.look(
                -input.Delta.X,
                -input.Delta.Y
            )

        end

    end)
    
end

return MobileCameraMovemenet