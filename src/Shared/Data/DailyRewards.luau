export type reward = {
    currency: "COINS" | "LIVES",
    amount: number
}

export type dailyRewardDay = {
    dayName: string,
    number : reward
}

return {

    [1] = 5 * 60,
    [2] = 10 * 60,
    [3] = 15 * 60,

    ["MONDAY"] = {
        dayName = "Monday",
        [1] = { currency = "COINS", amount = 20 },
        [2] = { currency = "LIVES", amount = 1 },
        [3] = { currency = "COINS", amount = 40 }
    },

    ["TUESDAY"] = {
        dayName = "Tuesday",
        [1] = { currency = "COINS", amount = 25 },
        [2] = { currency = "LIVES", amount = 1 },
        [3] = { currency = "COINS", amount = 45 }
    },

    ["WEDNESDAY"] = {
        dayName = "Wednesday",
        [1] = { currency = "COINS", amount = 30 },
        [2] = { currency = "LIVES", amount = 1 },
        [3] = { currency = "COINS", amount = 55 }
    },

    ["THURSDAY"] = {
        dayName = "Thursday",
        [1] = { currency = "COINS", amount = 35 },
        [2] = { currency = "LIVES", amount = 1 },
        [3] = { currency = "COINS", amount = 60 }
    },

    ["FRIDAY"] = {
        dayName = "Friday",
        [1] = { currency = "COINS", amount = 40 },
        [2] = { currency = "LIVES", amount = 1 },
        [3] = { currency = "COINS", amount = 75 }
    },

    ["SATURDAY"] = {
        dayName = "Saturday",
        [1] = { currency = "COINS", amount = 45 },
        [2] = { currency = "LIVES", amount = 1 },
        [3] = { currency = "COINS", amount = 90 }
    },

    ["SUNDAY"] = {
        dayName = "Sunday",
        [1] = { currency = "COINS", amount = 50 },
        [2] = { currency = "LIVES", amount = 1 },
        [3] = { currency = "COINS", amount = 105 }
    }
}
