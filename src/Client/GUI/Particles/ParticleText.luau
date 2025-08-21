--//====================================================
--// Type Def
--//====================================================
export type ParticleText = {
    Id: number,
    Root: TextLabel,
    SpawnTime: number,
    DestroyTime: number,
    Speed: Vector2,
    Gravity: number?,
    init: (self: ParticleText) -> nil,
    new: (parent: GuiObject, text: string, origin: Vector2, opts: ParticleTextOptions?) -> ParticleText,
    loop: (self: ParticleText, dt: number) -> nil,
    Destroy: (self: ParticleText) -> nil
}

export type ParticleTextOptions = {
    color: Color3?,
    image: string?,
    speed: Vector2?,
    gravity: number?,
    size: UDim2?,
    lifeTime: number?
}

local ParticleText = {}
ParticleText.__index = ParticleText

--//====================================================
--// Imports / Services
--//====================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--//====================================================
--// Local Variables / Constants
--//====================================================
local didLoad = false
local TEXT_GRAVITY = -0.05
local DEFAULT_TEXT_LIFETIME = 1.5
local DEFAULT_COLOR = Color3.fromRGB(255, 255, 255)

local particleTextTemplate: TextLabel
local counter = 0
local loadedParticleText: { [number]: ParticleText } = {}

--//====================================================
--// Local Function
--//====================================================

function ParticleText.mainLoop(dt: number)
    for _, each in loadedParticleText do
        each:loop(dt)
    end
end

function ParticleText.onLoaded(): nil
    if not didLoad then
        didLoad = true
        particleTextTemplate = game:GetService("ReplicatedStorage").GuiAssets.Particles:WaitForChild("ParticleText") :: TextLabel
        RunService.PreRender:Connect(ParticleText.mainLoop)
    end
end

function ParticleText.new(parent: GuiObject, text: string, origin: Vector2, opts: ParticleTextOptions?): ParticleText
    local newParticleText = setmetatable({}, ParticleText)

    counter += 1
    newParticleText.Id = counter

    local options = opts or {}
    local lifeTime = options.lifeTime or DEFAULT_TEXT_LIFETIME
    local gravity = options.gravity or TEXT_GRAVITY
    local speed = options.speed or Vector2.new(0, 50) -- default gentle upward drift
    local color = options.color or DEFAULT_COLOR
    local image = options.image or ""
    local size = options.size

    newParticleText.SpawnTime = time()
    newParticleText.DestroyTime = newParticleText.SpawnTime + lifeTime
    newParticleText.Speed = speed
    newParticleText.Gravity = gravity

    newParticleText.Root = particleTextTemplate:Clone()
    newParticleText.Root.Parent = parent
    newParticleText.Root.Text = text
    newParticleText.Root.Position = UDim2.fromOffset(origin.X, origin.Y)
    newParticleText.Root.TextColor3 = color
    newParticleText.Root.Image.Image = image

    if size then
        newParticleText.Root.Size = size
    end

    -- fade out tweens
    local fadeDelay = 0.25 * lifeTime
    local fadeInfo = TweenInfo.new(lifeTime - fadeDelay, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, fadeDelay)

    local fadeTweenText = TweenService:Create(newParticleText.Root, fadeInfo, { TextTransparency = 1 })
    local fadeTweenStroke = TweenService:Create(newParticleText.Root.UIStroke, fadeInfo, { Transparency = 1 })
    local fadeTweenImage = TweenService:Create(newParticleText.Root.Image, fadeInfo, { ImageTransparency = 1 })

    fadeTweenText:Play()
    fadeTweenImage:Play()
    fadeTweenStroke:Play()

    loadedParticleText[newParticleText.Id] = newParticleText
    return newParticleText
end

function ParticleText:loop(dt: number)
    local pos = self.Root.Position
    self.Root.Position = UDim2.fromOffset(pos.X.Offset + (self.Speed.X * dt), pos.Y.Offset + (-self.Speed.Y * dt))
    self.Speed += Vector2.new(0, self.Gravity or TEXT_GRAVITY)

    if time() > self.DestroyTime then
        loadedParticleText[self.Id] = nil
        self:Destroy()
    end
end

function ParticleText:Destroy()
    if self.Root then
        self.Root:Destroy()
        self.Root = nil
    end
    loadedParticleText[self.Id] = nil
    setmetatable(self, nil)
end

return ParticleText
