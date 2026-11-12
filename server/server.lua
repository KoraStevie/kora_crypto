local coin = Crypto.Coin
Crypto.History = Crypto.History or {}
Crypto.History[coin] = Crypto.History[coin] or {}

local function UpdateGlobalState()
    GlobalState.Qbit = {
        Worth = Crypto.Worth,
        History = Crypto.History[coin]
    }
end

local function RefreshCrypto()
    local result = Kora.sql.query('SELECT * FROM crypto WHERE crypto = ?', { coin })
    if result ~= nil and result[1] ~= nil then
        Crypto.Worth = result[1].worth
        if result[1].history ~= nil and result[1].history ~= "" then
            Crypto.History[coin] = json.decode(result[1].history)
        else
            Crypto.History[coin] = {}
        end
    end
    UpdateGlobalState()
end

local function HandlePriceChance()
    local currentValue = Crypto.Worth
    local prevValue = Crypto.Worth
    local trend = math.random(0, 100)
    local event = math.random(1, 100)
    local chance = tonumber(Crypto.ChanceOfCrashOrLuck)

    if event > chance then
        if trend <= Crypto.ChanceOfDown then
            currentValue = currentValue - math.random(Crypto.CasualDown[1], Crypto.CasualDown[2])
        elseif trend >= Crypto.ChanceOfUp then
            currentValue = currentValue + math.random(Crypto.CasualUp[1], Crypto.CasualUp[2])
        end
    else
        if math.random(0, 1) == 1 then
            currentValue = currentValue + math.random(Crypto.Luck[1], Crypto.Luck[2])
        else
            currentValue = currentValue - math.random(Crypto.Crash[1], Crypto.Crash[2])
        end
    end

    if currentValue <= Crypto.Lower then
        currentValue = Crypto.Lower
    elseif currentValue >= Crypto.Upper then
        currentValue = Crypto.Upper
    end

    if not Crypto.History[coin] then
        Crypto.History[coin] = {}
    end

    if #Crypto.History[coin] >= 4 then
        for k = 1, 3 do
            Crypto.History[coin][k] = Crypto.History[coin][k + 1]
        end
        Crypto.History[coin][4] = { PreviousWorth = prevValue, NewWorth = currentValue }
    else
        Crypto.History[coin][#Crypto.History[coin] + 1] = { PreviousWorth = prevValue, NewWorth = currentValue }
    end

    Crypto.Worth = currentValue

    local history = json.encode(Crypto.History[coin])
    local props = {
        ['worth'] = currentValue,
        ['history'] = history,
        ['crypto'] = coin
    }

    local affectedRows, err = Kora.sql.update(
        'UPDATE crypto SET worth = :worth, history = :history WHERE crypto = :crypto', props
    )
    if affectedRows == nil then
        print(('[kora_crypto] Price update failed: %s'):format(tostring(err)))
        return
    end
    if affectedRows < 1 then
        local inserted, insertErr = Kora.sql.insert('INSERT INTO crypto (crypto, worth, history) VALUES (:crypto, :worth, :history)', props)
        if inserted == nil then
            print(('[kora_crypto] Price insert failed: %s'):format(tostring(insertErr)))
            return
        end
    end
    RefreshCrypto()
end

-- The minigame that decides a crack's outcome runs entirely client-side (there
-- is no server-side equivalent to replay it against), so the client's own
-- report of success/failure can never be fully trusted. This ticket at least
-- closes the gap where a modified client fires crackCryptoStick directly,
-- over and over with no delay, for every cryptostick it holds: a ticket is
-- only minted when hasCryptoStick last confirmed a stick, is single-use, and
-- ExchangeFail/crackCryptoStick are refused unless enough time has passed for
-- the insert bar and the minigame to have actually run.
local pending = {}
local CRACK_MIN_MS = 1200 -- floor for how long an honest insert + minigame attempt takes
local CRACK_TICKET_MS = 60000 -- a ticket this old is stale and no longer honoured

local function beginCrack(src)
    pending[src] = GetGameTimer()
end

local function takeTicket(src)
    local startedAt = pending[src]
    pending[src] = nil
    if not startedAt then return false, 'start again' end
    local elapsed = GetGameTimer() - startedAt
    if elapsed < CRACK_MIN_MS then return false, 'too fast' end
    if elapsed > CRACK_TICKET_MS then return false, 'expired' end
    return true
end

Kora.callback.register('qb-crypto:server:hasCryptoStick', function(source)
    if not source or source <= 0 then return false end
    local has = exports['qb-inventory']:HasItem(source, 'cryptostick', 1) and true or false
    if has then beginCrack(source) end
    return has
end)

RegisterServerEvent('qb-crypto:server:ExchangeFail', function()
    local src = source
    assert(src ~= nil, Kora.lang('asserts.no_src'))
    assert(Kora.distance.player(src, Crypto.Exchange, 5.0), Kora.lang('asserts.too_far', src))
    local ok, why = takeTicket(src)
    if not ok then
        print(('[kora_crypto] %s reported a failed crack without a valid ticket (%s); ignored'):format(src, why))
        return
    end
    exports['qb-inventory']:RemoveItem(src, 'cryptostick', 1, false, 'qb-crypto:server:ExchangeFail')
end)

RegisterServerEvent('qb-crypto:server:crackCryptoStick', function()
    local src = source
    assert(src ~= nil, Kora.lang('asserts.no_src'))
    assert(Kora.distance.player(src, Crypto.Exchange, 5.0), Kora.lang('asserts.too_far', src))
    local ok, why = takeTicket(src)
    if not ok then
        print(('[kora_crypto] %s claimed a successful crack without a valid ticket (%s); ignored'):format(src, why))
        return
    end
    local DeelNumber = 1000000
    local Amount = (math.random(611111, 1599999) / DeelNumber)

    if not exports['qb-inventory']:RemoveItem(src, 'cryptostick', 1, false, 'qb-crypto:server:crackCryptoStick') then return end
    if not exports.kora_core:addMoney(src, 'crypto', Amount, 'qb-crypto:server:crackCryptoStick') then return end
    local player = { PlayerData = exports.kora_core:toLegacyPlayerData(exports.kora_core:getPlayerData(src)) }
    TriggerClientEvent('qb-phone:client:AddTransaction', src, player, {}, Kora.lang('credited_amount', Amount), 'Credit')
end)

AddEventHandler('playerDropped', function()
    pending[source] = nil
end)

CreateThread(function()
    if Kora.sql.ready(60000) then
        local reports, schemaErr = Kora.sql.ensureTables(KoraCryptoSchema)
        if schemaErr then
            print(('^1[kora_crypto]^7 schema failed: %s'):format(tostring(schemaErr)))
        end
        for _, report in ipairs(reports or {}) do
            for _, warning in ipairs(report.warnings or {}) do
                print(('^3[kora_crypto]^7 %s: %s'):format(tostring(report.table), tostring(warning)))
            end
        end
    else
        print('^1[kora_crypto]^7 kora_sql was unavailable; the crypto table was not checked.')
    end
    RefreshCrypto()
    while true do
        Wait(Crypto.RefreshTimer * 60000)
        HandlePriceChance()
    end
end)
