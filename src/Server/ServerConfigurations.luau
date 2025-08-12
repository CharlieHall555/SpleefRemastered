return {

    --//====================================================
    --// Performance / Part Pooling
    --//====================================================
    PARTS_PER_FRAME = 50,              -- Max parts processed each frame
    INITIAL_PART_POOL = 50,            -- Initial pooled parts
    MAX_PARTS_PER_FRAME_PER_LAYER = 25,-- Max parts per frame per map layer
    BLOCK_SIZE = 5,                    -- Size of a block in studs

    --//====================================================
    --// Game / Round Core Settings
    --//====================================================
    REQUIRED_PLAYERS = 2,              -- Players needed to start a round
    PLAYERS_TO_END = 1,                -- Players left to trigger end
    INTERMISSION_TIME = 5,             -- Time between rounds
    PREPARING_TIME = 5,                -- Pre-round prep time
    ROUND_TIME = 100,                   -- Normal round duration
    MAXIMUM_ROUND_TIME = 500,           -- Emergency round cut-off

    --//====================================================
    --// Teleportation Settings
    --//====================================================
    TELEPORT_RETRIES = 1,              -- Retry attempts if teleport fails
    TELEPORT_RETRY_DELAY = 1,          -- Delay between teleport retries (s)

    --//====================================================
    --// Snowball Mechanics
    --//====================================================
    SNOWBALL_DISTANCE_THRESHOLD = 10,  -- Max hit detection distance
    SNOWBALL_COOLDOWN = 0.02,          -- Time between throws (s)

    --//====================================================
    --// Client Responsiveness
    --//====================================================
    UNRESPONSIVE_CLIENT_THRESHOLD = 2, -- Seconds before marking a client unresponsive

    --//====================================================
    --// Sudden Death Settings
    --//====================================================
    SUDDEN_DEATH_DELAY = 0.5,          -- Delay before sudden death starts
    SUDDEN_DEATH_BLOCKS_CHOSEN = 5,    -- Blocks removed per sudden death tick
    SLOW_FALL_TIME = 2,                -- Time for blocks to fall slowly

    --//====================================================
    --// Ammo System
    --//====================================================
    STARTING_AMMO = 30,                -- Ammo given at start
    MAX_AMMO = 30,                     -- Ammo cap
    AMMO_REGEN_INTERVAL = 0.5,           -- Time between ammo regen ticks (s)
    RESPAWN_TIME = 1,                   -- Time to respawn after elimination
    MAX_AMMO_PICKUPS = 15,
    AMMO_SPAWN_GAP = 5,
    AMMO_PICKUP_LIFETIME = 30,
    AMMO_PICKUP_VALUE = 30,

    KNOCKBACK_COOLDOWN = 2,
    KNOCKBACK_POWER = 20000,
}