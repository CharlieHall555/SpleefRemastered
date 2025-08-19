return {
    ["PARTICLE_DESTROY_GRASS"] = {
        -- Core
        Brightness = 1,
        Color = ColorSequence.new(Color3.fromRGB(89, 239, 7), Color3.fromRGB(64, 140, 7)),
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