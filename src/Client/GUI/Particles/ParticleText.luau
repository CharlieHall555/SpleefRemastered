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
    new: (parentView: GuiObject, text: number, origin: Vector2, speed: Vector2, gravity: number?, size: UDim2?, lifeTime: number?) -> ParticleText,
    loop: (self: ParticleText, dt: number) -> nil,
    Destroy: (self: ParticleText) -> nil
}

local ParticleText = {}
ParticleText.__index = ParticleText
--//====================================================
--// Imports / Services
--//====================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
--//====================================================
--// Local Variables / Constants
--//====================================================
local didLoad = false

local TEXT_GRAVITY = -0.05
local DEFAULT_TEXT_LIFETIME = 1.5

local particleTextTemplate: TextLabel
local counter = 0

local loadedParticleText = {}
--//====================================================
--// Local Function
--//====================================================

function ParticleText.mainLoop(dt) : nil
    
    for _ , each in loadedParticleText do
        each:loop(dt)
    end

end

function ParticleText.onLoaded(): nil
    if didLoad == false then
        didLoad = true
        particleTextTemplate = game:GetService("ReplicatedStorage").GuiAssets.Particles:WaitForChild("ParticleText") :: TextLabel
        RunService.PreRender:Connect(ParticleText.mainLoop)
    end
end

function ParticleText.new(parentView: GuiObject, text: number, origin: Vector2, speed: Vector2, gravity: number?, size: UDim2?, lifeTime: number?): ParticleText
    local newParticleText = particleTextTemplate:Clone()
    setmetatable(newParticleText, ParticleText)

    newParticleText.Id = counter
    counter += 1

    local textLifeTime = lifeTime or DEFAULT_TEXT_LIFETIME
    local fadeDelay = 0.25 * textLifeTime
    local fadeInfo = TweenInfo.new(textLifeTime - fadeDelay, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, fadeDelay)

    newParticleText.Root.Text = tostring(text)
    newParticleText.SpawnTime = time()
    newParticleText.DestroyTime = newParticleText.SpawnTime + textLifeTime
    newParticleText.Speed = speed
    newParticleText.Root.Position = UDim2.fromScale(origin.X, origin.Y)
    newParticleText.Root.TextColor3 = Color3.fromRGB(math.random(1, 255), math.random(1, 255), math.random(1, 255))

    local fadeTweenText = TweenService:Create(newParticleText.Root, fadeInfo, { TextTransparency = 1 })
    local fadeTweenStroke = TweenService:Create(newParticleText.Root.UIStroke, fadeInfo, { Transparency = 1 })
    fadeTweenText:Play()
    fadeTweenStroke:Play()

    if size then
        newParticleText.Root.Size = size
    end

    newParticleText.Gravity = gravity
    loadedParticleText[newParticleText.Id] = newParticleText

    return newParticleText :: ParticleText
end

function ParticleText:loop(dt: number)
    local pos = self.Root.Position
    self.Root.Position = UDim2.fromScale(pos.X.Scale + (self.Speed.X * dt), pos.Y.Scale + (-self.Speed.Y * dt))
    self.Speed += Vector2.new(0, self.Gravity or TEXT_GRAVITY)

    if time() > self.DestroyTime then
        loadedParticleText[self.Id] = nil
        self:Destroy()
    end
end

return ParticleText