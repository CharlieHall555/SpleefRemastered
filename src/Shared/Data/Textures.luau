local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = ReplicatedStorage:WaitForChild("Resources")
local Textures = Resources:WaitForChild("Textures")

return {

    ["grass_light"] = Textures:WaitForChild("grass_light" , 10),
    ["grass_dark"] = Textures:WaitForChild("grass_dark" , 10),
    ["ice"] = Textures:WaitForChild("ice" , 10),
    ["dark_sand"] = Textures:WaitForChild("dark_sand" , 10),
    ["light_sand"] = Textures:WaitForChild("light_sand" , 10),
    ["dark_ice"] = Textures:WaitForChild("dark_ice" , 10),

}
