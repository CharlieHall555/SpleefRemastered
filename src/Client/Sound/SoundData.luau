export type SoundEntry = {
    id: string,
    volume: number?,
    playbackSpeed: number?,
    looped: boolean?
}

local SoundData: { [string]: SoundEntry } = {
    -- Example entries - replace with your actual sound IDs
    -- ["explosion"] = {
    --     id = "rbxassetid://12345678",
    --     volume = 0.7,
    -- },
    -- ["jump"] = {
    --     id = "rbxassetid://87654321",
    --     volume = 0.5,
    --     playbackSpeed = 1.2,
    -- },
    ["coin_ding"] = {
        id = "rbxassetid://135402320029366",
        volume = 0.25,
        playbackSpeed = 1
    },

    ["firework"] = {
        id = "rbxassetid://9113263649",
        volume = 0.5,
        playbackSpeed = 1
    },

    ["countdown_tick"] = {
        id = "rbxassetid://92235033335714",
        volume = 0.5,
        playbackSpeed = 1
    },

    ["countdown_end"] = {
        id = "rbxassetid://138059333294391",
        volume = 0.5,
        playbackSpeed = 1
    },

    ["powerup_charged"] = {
        id = "rbxassetid://111021757361384",
        volume = 0.5,
        playbackSpeed = 1
    },
    ["block_break"] = {
        id = "rbxassetid://124677843669892",
        volume = 0.5,
        playbackSpeed = 1

    },
    ["snowball_impact"] = {
        id = "rbxassetid://125553928613877",
        volume = 0.5,
        playbackSpeed = 1
    },
    ["death_sound"] = {
        id = "rbxassetid://6994934244",
        volume = 0.5,
        playbackSpeed = 1
    },
    ["error_blip"] = {
        id = "rbxassetid://70373378044427",
        volume = 1,
        playbackSpeed = 1
    },
    ["no_ammo"] = {
        id = "rbxassetid://138708208704130",
        volume = 0.3,
        playbackSpeed = 1
    },
    ["ammo_pickup"] = {
        id = "rbxassetid://18919192805",
        volume = 0.3,
        playbackSpeed = 1
    },
    ["slap"] = {
        id = "rbxassetid://107118274345536",
        volume = 0.5,
        playbackSpeed = 1
    },
    ["dash_sound"] = {
        id = "rbxassetid://80426554346602",
        volume = 0.5,
        playbackSpeed = 1
    },
    ["teleport_noise"] = {
        id = "rbxassetid://4562690876",
        volume = 0.5,
        playbackSpeed = 1,
    },
    ["claim_sound"] = {
        id = "rbxassetid://86832085549408",
        volume = 0.5,
        playbackSpeed = 1,
    },

    ["cha_ching"] = {
        id = "rbxassetid://116467459427704",
        volume = 0.45,
        playbackSpeed = 1,
    }

}

return SoundData
