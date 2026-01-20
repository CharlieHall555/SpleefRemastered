local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Root = player:WaitForChild("PlayerScripts")

local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local WeatherData = require(ClientModuleDirectory.Weather.WeatherData)

local WeatherManager = {}

local activeWeatherPart: Part? = nil

function WeatherManager.setWeather(weatherName: string)
	local weatherConfig = WeatherData[weatherName]
	if not weatherConfig then
		warn("Weather config missing:", weatherName)
		weatherConfig = WeatherData.lobbyWeather
	end

	-- Lighting
	Lighting.Brightness = weatherConfig.brightness
	Lighting.FogStart = weatherConfig.fogStart
	Lighting.FogEnd = weatherConfig.fogEnd
	Lighting.FogColor = weatherConfig.fogColor
	Lighting.ClockTime = weatherConfig.clockTime

	-- Remove old weather effect
	if activeWeatherPart then
		activeWeatherPart:Destroy()
		activeWeatherPart = nil
	end

	-- Spawn new weather effect if present
	local weatherEffectTemplate: Part? = weatherConfig.weatherEffect
	if weatherEffectTemplate then
		local clone = weatherEffectTemplate:Clone()
		clone.Anchored = true
		clone.CanCollide = false
		clone.Parent = workspace
		activeWeatherPart = clone
	end
end

RunService.RenderStepped:Connect(function()
	if not activeWeatherPart then return end

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	activeWeatherPart.CFrame = hrp.CFrame + Vector3.new(0, 30, 0)
end)

function WeatherManager.init()
	RemoteEventHandler.newEventConnection("SET_CLIENT_WEATHER", WeatherManager.setWeather)
end

return WeatherManager
