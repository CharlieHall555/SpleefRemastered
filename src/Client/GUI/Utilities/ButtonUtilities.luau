local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlayerGui = game.Players.LocalPlayer.PlayerGui


local ButtonUtilities = {}
 
function ButtonUtilities.setGreyed(buttonRoot : Frame , value : boolean)

    local greyScreen = buttonRoot:FindFirstChild("GreyScreen")
    if greyScreen then
        greyScreen.Visible = value
    else
        print("no grey screen")
    end
    
end

function ButtonUtilities.setUpButton(buttonRoot : Frame)

    local main : Frame? = buttonRoot:FindFirstChild("Main")
    local clickable : TextButton? = buttonRoot:FindFirstChild("Clickable")

    if not (main and clickable) then
        return
    end

    local base = buttonRoot.BackgroundColor3
    local highlight = buttonRoot.Main.BackgroundColor3

    buttonRoot:SetAttribute("baseColor" , base)
    buttonRoot:SetAttribute("highlightColor" , highlight)

    clickable.MouseEnter:Connect(function()
        main.BackgroundColor3 = base
    end)

    clickable.MouseLeave:Connect(function()
        main.BackgroundColor3 = highlight
    end)

end 

function ButtonUtilities.parseRoot()
    
    local all_desc = PlayerGui:GetDescendants()

    for _ , each in all_desc do
        
        if each:HasTag("Button") then
            ButtonUtilities.setUpButton(each)
        end

    end

end



return ButtonUtilities
