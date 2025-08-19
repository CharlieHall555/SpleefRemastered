return {
    ["grass_light"] = {
        -- Core
        Brightness = 1,
        Color = ColorSequence.new(Color3.fromRGB(52, 142, 64), Color3.fromRGB(43, 97, 1)),
        LightEmission = 0,
        LightInfluence = 0,
        LockedToPart = false,
        Enabled = true,

        -- Lifetime & Rate
        Lifetime = NumberRange.new(0.3, 0.5),
        Rate = 18,
        Speed = NumberRange.new(8),
        SpreadAngle = Vector2.new(360 , 360),

        -- Shape
        Shape = Enum.ParticleEmitterShape.Box,
        ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
        ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,

        -- Size & Transparency
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.385),
            NumberSequenceKeypoint.new(1, 0.22)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.8, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        }),

        -- Rotation & Movement
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(260),
        Drag = 0,
        Acceleration = Vector3.new(0, -5, 0),

        -- Visual
        Texture = "http://www.roblox.com/asset/?id=241685484",
        ZOffset = 0,

        -- Timing
        TimeScale = 1,
    },
    ["grass"] = {
        -- Core
        Brightness = 1,
        Color = ColorSequence.new(Color3.fromRGB(46, 224, 69), Color3.fromRGB(52, 119, 1)),
        LightEmission = 0,
        LightInfluence = 0,
        LockedToPart = false,
        Enabled = true,

        -- Lifetime & Rate
        Lifetime = NumberRange.new(0.3, 0.5),
        Rate = 18,
        Speed = NumberRange.new(8),
        SpreadAngle = Vector2.new(360 , 360),

        -- Shape
        Shape = Enum.ParticleEmitterShape.Box,
        ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
        ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,

        -- Size & Transparency
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.385),
            NumberSequenceKeypoint.new(1, 0.22)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.8, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        }),

        -- Rotation & Movement
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(260),
        Drag = 0,
        Acceleration = Vector3.new(0, -5, 0),

        -- Visual
        Texture = "http://www.roblox.com/asset/?id=241685484",
        ZOffset = 0,

        -- Timing
        TimeScale = 1,
    },
    ["ice"] = {
        -- Core
        Brightness = 1,
        Color = ColorSequence.new(Color3.fromRGB(19, 181, 226), Color3.fromRGB(3, 112, 143)),
        LightEmission = 0,
        LightInfluence = 0,
        LockedToPart = false,
        Enabled = true,

        -- Lifetime & Rate
        Lifetime = NumberRange.new(0.3, 0.5),
        Rate = 18,
        Speed = NumberRange.new(8),
        SpreadAngle = Vector2.new(360 , 360),

        -- Shape
        Shape = Enum.ParticleEmitterShape.Box,
        ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
        ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,

        -- Size & Transparency
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.385),
            NumberSequenceKeypoint.new(1, 0.22)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.8, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        }),

        -- Rotation & Movement
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(260),
        Drag = 0,
        Acceleration = Vector3.new(0, -5, 0),

        -- Visual
        Texture = "http://www.roblox.com/asset/?id=241685484",
        ZOffset = 0,

        -- Timing
        TimeScale = 1,
    },
    ["snow"] = {
        -- Core
        Brightness = 1,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(153, 149, 149)),
        LightEmission = 0,
        LightInfluence = 0,
        LockedToPart = false,
        Enabled = true,

        -- Lifetime & Rate
        Lifetime = NumberRange.new(0.3, 0.5),
        Rate = 18,
        Speed = NumberRange.new(8),
        SpreadAngle = Vector2.new(360 , 360),

        -- Shape
        Shape = Enum.ParticleEmitterShape.Box,
        ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
        ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,

        -- Size & Transparency
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.385),
            NumberSequenceKeypoint.new(1, 0.22)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.8, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        }),

        -- Rotation & Movement
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(260),
        Drag = 0,
        Acceleration = Vector3.new(0, -5, 0),

        -- Visual
        Texture = "http://www.roblox.com/asset/?id=241685484",
        ZOffset = 0,

        -- Timing
        TimeScale = 1,
    },
    ["PARTICLE_SNOWBALL"] = {
        -- Core
        Brightness = 1,
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(153, 149, 149)),
        LightEmission = 0,
        LightInfluence = 0,
        LockedToPart = false,
        Enabled = true,

        -- Lifetime & Rate
        Lifetime = NumberRange.new(0.3, 0.5),
        Rate = 18,
        Speed = NumberRange.new(8),
        SpreadAngle = Vector2.new(360 , 360),

        -- Shape
        Shape = Enum.ParticleEmitterShape.Box,
        ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
        ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,

        -- Size & Transparency
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.385),
            NumberSequenceKeypoint.new(1, 0.22)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.8, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        }),

        -- Rotation & Movement
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(260),
        Drag = 0,
        Acceleration = Vector3.new(0, -5, 0),

        -- Visual
        Texture = "http://www.roblox.com/asset/?id=241685484",
        ZOffset = 0,

        -- Timing
        TimeScale = 1,
    }
}