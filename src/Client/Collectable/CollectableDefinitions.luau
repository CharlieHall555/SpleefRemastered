local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = ReplicatedStorage:WaitForChild("Resources")
local Models = Resources:WaitForChild("Models")

return {

    ["ammo"] = {template = Models:WaitForChild("Ammo")},
    ["coin"] = {template = Models:WaitForChild("Coin")}

}