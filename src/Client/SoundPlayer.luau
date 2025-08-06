local SoundPlayer = {}

local QueuedSounds = {}

function SoundPlayer.init()
    
end

export type SpatialSoundPlayer = {

    part : Part,
    sound : Sound,
    inUse : boolean

}

return SoundPlayer