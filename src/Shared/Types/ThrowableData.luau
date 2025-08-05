local ThrowableData = {}

ThrowableDataMappings = {
    sP = "startingPosition",
    d = "direction",
    t = "type",
    s = "sentAt,",
    uid = "uid"
}

export type ThrowableData = { --sent over network so small keys
    sP : string, --compressed vector
    d : string, -- compressed vector
    t : string, -- string
    s : number, -- number
    uid : number,
}

return ThrowableData