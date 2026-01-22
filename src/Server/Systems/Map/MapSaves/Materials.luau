local CustomMaterials = {}

local validMateirals = {}

export type CustomMaterial = {
    material : string,
    color : Color3,
    transparency : number?
}

materials = {}
materials.sand = {
    material = Enum.Material.Sand,
    color = Color3.fromRGB(177, 139, 79)
}

materials.sandstone = {
    material = Enum.Material.Sandstone,
    color = Color3.fromRGB(130, 94, 49)
}

materials.mud = {
    material = Enum.Material.Mud,
    color = Color3.new(0.333333, 0.215686, 0.207843)
}

materials.obsidian = {
    material = Enum.Material.CrackedLava,
    color = Color3.fromRGB(98, 37, 209)
}

materials.grass = {
    material = Enum.Material.Grass,
    color = Color3.fromRGB(52, 142, 64)
}

materials.grass_light = {
    material = Enum.Material.Grass,
    color = Color3.fromRGB(46, 224, 69)
}

materials.stone = {
    material = Enum.Material.Slate,
    color = Color3.fromRGB(75, 75, 75)
}

materials.snow = {
    material = Enum.Material.Snow,
    color = Color3.fromRGB(221, 221, 221)
}

materials.ice = {
    material = Enum.Material.Ice,
    color = Color3.fromRGB(19, 181, 226)
}

materials.plastic_yellow = {
    material = Enum.Material.SmoothPlastic,
    color = Color3.new(0.839216, 0.729412, 0.113725)
}

materials.plastic_blue = {
    material = Enum.Material.SmoothPlastic,
    color = Color3.new(0.156863, 0.392157, 0.827451)
}

materials.plastic_red = {
    material = Enum.Material.SmoothPlastic,
    color = Color3.new(1, 0.282353, 0.188235)
}

materials.plastic_green = {
    material = Enum.Material.SmoothPlastic,
    color = Color3.new(0.305882, 0.615686, 0.454902)
}

materials.pink_sand = {
    material = Enum.Material.Sand,
    color = Color3.new(0.858824, 0.568627, 0.898039)
}

materials.sand_blue = {
    material = Enum.Material.Sand,
    color = Color3.new(0.188235, 0.470588, 1)
}

materials.sand_red = {
    material = Enum.Material.Sand,
    color = Color3.new(0.847059, 0.227451, 0.160784)
}

materials.sand_green = {
    material = Enum.Material.Sand,
    color = Color3.new(0.333333, 0.666667, 0.498039)
}


materials.dark_candy = {
    material = Enum.Material.Grass,
    color = Color3.fromRGB(128, 0, 96)
}


materials.light_candy = {
    material = Enum.Material.Grass,
    color = Color3.fromRGB(255, 102, 204)
}


function CustomMaterials.init()

    for eachKey , _ in materials do
        table.insert(validMateirals , eachKey)
    end

end

function CustomMaterials.get(name : string) : CustomMaterial?
    return materials[name] or {}
end

return CustomMaterials
