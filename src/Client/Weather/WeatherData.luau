local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeatherPartFolder = ReplicatedStorage:WaitForChild("Resources"):WaitForChild("Weather")

export type Weather = {
	brightness: number,
	fogStart: number,
	fogEnd: number,
	clockTime: number,
	fogColor: Color3,
}


local Weathers = {


	lobbyWeather = {
		brightness = 1.5,
		fogStart = 0,
		fogEnd = 10000,
		clockTime = 12,
		fogColor = Color3.fromRGB(192, 192, 192),
	},

	snowyWeather = {
		brightness = 0.9,
		fogStart = 0,
		fogEnd = 800,
		clockTime = 10,
        weatherEffect = WeatherPartFolder:WaitForChild("SnowEmitterPart" , 3),
		fogColor = Color3.fromRGB(225, 235, 255),
	},

    desertWeather = {
		brightness = 0.9,
		fogStart = 0,
		fogEnd = 500,
		clockTime = 10,
		fogColor = Color3.fromRGB(130, 94, 49),
	},
}

return Weathers
