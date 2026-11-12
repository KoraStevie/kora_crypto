Crypto = {
    Lower = 500,
    Upper = 5000,
    qbit = {},
    Worth =  1000,
    Labels = 'Qbit',
    Exchange = vector3(1276.21, -1709.88, 54.57),
    Coin = 'qbit',
    RefreshTimer = 10, -- In minutes, so every 10 minutes.
    NotifyStickLost = true, -- Notify the player when they lose a cryptostick by failing the minigame.
    NotifyNoStick = true, -- Notify the player when they try to crack a cryptostick without having one.

    ChanceOfCrashOrLuck = 2, -- This is in % (1-100)
    Crash = { 20, 80 },      -- Min / Max
    Luck = { 20, 45 },       -- Min / Max
    ChanceOfDown = 30,   -- If out of 100 hits less or equal to
    ChanceOfUp = 60,     -- If out of 100 is greater or equal to
    CasualDown = { 1, 10 }, -- Min / Max (If it goes down)
    CasualUp = { 1, 10 }, -- Min / Max (If it goes up)
}

if Kora and Kora.config and Kora.config.adopt then Crypto = Kora.config.adopt(Crypto) end
