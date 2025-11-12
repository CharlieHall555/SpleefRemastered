return {
    background = "Tutorial",
    originPosition = Vector3.new(0 , 10000 , 0),
	layerParams = {
		-- Layer 1: Random "islands" style
		{
			height = 0,
			size = Vector2.new(30, 30),
			shape = "Checked_Even",
            spawnsAmmo = true,
            regenerates = true,
            material = "sand",
		},

		{
			height = 0,
			size = Vector2.new(30, 30),
			shape = "Checked_Odd",
            spawnsAmmo = true,
            regenerates = true,
            material = "sandstone",
		},
    }

}
