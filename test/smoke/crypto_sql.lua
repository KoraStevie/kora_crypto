-- Run from kora_crypto: lua test/smoke/crypto_sql.lua [server-source]
-- Actual server/config and kora_sql wrapper; controlled driver, no live SQL/host.
dofile('../kora_core/test/mocks.lua').install() -- existing deterministic JSON codec
local checks = 0
local function check(value, reason) assert(value, reason); checks = checks + 1 end
local function setup(existing, random, configure)
    local f = { calls = {}, events = {}, threads = {}, row = existing, logs = {} }
    local env = {}
    for key, value in pairs(_G) do env[key] = value end
    env.Kora, env.GlobalState = {}, {}
    env.vector3 = function(x, y, z) return { x = x, y = y, z = z } end
    env.Crypto = nil
    env.math = {}; for key, value in pairs(math) do env.math[key] = value end
    env.math.random = random or function(first, last)
        -- Keep persistence checks on the normal price path.
        return first == 1 and last == 100 and 100 or first
    end
    env.RegisterServerEvent = function(name, callback) f.events[name] = callback end
    env.CreateThread = function(callback) f.threads[#f.threads + 1] = coroutine.create(callback) end
    env.Wait = function(ms) return coroutine.yield(ms) end
    env.print = function(value) f.logs[#f.logs + 1] = value end
    env.promise = { new = function()
        return {
            resolve = function(p, value) p.settled, p.value = true, value end,
            reject = function(p, err) p.settled, p.err = true, err end,
        }
    end }
    env.Citizen = { Await = function(p)
        if not p.settled then coroutine.yield('SQL wait') end
        assert(p.settled, 'complete the driver before resuming')
        if p.err then error(p.err, 0) end
        return p.value
    end }
    local function submit(kind, sql, params, callback)
        local request = { kind = kind, sql = sql, params = params, callback = callback }
        f.calls[#f.calls + 1] = request
        if sql:match('^SELECT') then
            callback(f.row and { { worth = f.row.worth, history = f.row.history } } or {})
        else
            check(f.pending == nil, 'writes stay sequential')
            f.pending = request
        end
    end
    local driver = {}
    for _, kind in ipairs({ 'query', 'update', 'insert' }) do
        driver[kind] = function(_, sql, params, callback) submit(kind, sql, params, callback) end
    end
    driver.isReady = function() return true end
    driver.ensureTables = function(_, specs, _, callback)
        f.ensured = specs
        callback({ { table = 'crypto', warnings = {} } })
    end
    env.exports = { kora_sql = driver }
    assert(loadfile('../kora_sql/init.lua', 't', env))()
    assert(loadfile('shared/config.lua', 't', env))()
    if configure then configure(env.Crypto) end
    assert(loadfile('server/schema.lua', 't', env))()
    assert(loadfile(arg[1] or 'server/server.lua', 't', env))()
    check(f.events['qb-crypto:server:ExchangeFail'] and f.events['qb-crypto:server:crackCryptoStick'], 'event names retained')
    check(#f.threads == 1, 'one existing market worker')
    f.env, f.worker = env, f.threads[1]
    function f.resume()
        local ok, result = coroutine.resume(f.worker); assert(ok, result); return result
    end
    function f.complete(failure)
        local request = assert(f.pending); f.pending = nil
        if failure then request.callback(nil, 'controlled SQL failure'); return end
        local count = 0
        if request.sql:match('^UPDATE') then
            if f.row then
                f.row = { worth = request.params.worth, history = request.params.history }; count = 1
            end
        else
            check(request.sql:match('^INSERT'), 'only expected INSERT fallback')
            check(f.row == nil, 'no duplicate INSERT against an existing row')
            f.row = { worth = request.params.worth, history = request.params.history }; count = 1
        end
        local result = request.kind == 'query' and { affectedRows = count, insertId = 0 }
            or request.kind == 'insert' and 0 or count
        request.callback(result)
    end
    function f.start()
        check(f.resume() == env.Crypto.RefreshTimer * 60000, 'initial read precedes unchanged market timer')
        check(f.ensured == env.KoraCryptoSchema, 'schema is ensured before the first read')
        check(env.GlobalState.Qbit.Worth == (existing and existing.worth or 1000), 'startup publishes loaded/default worth')
    end
    return f
end
local function row(worth) return { worth = worth, history = json.encode({ { PreviousWorth = worth, NewWorth = worth } }) } end

do
    local f = setup(row(1500))
    local spec = f.env.KoraCryptoSchema[1]
    check(#f.env.KoraCryptoSchema == 1 and spec.name == 'crypto' and spec.primary[1] == 'crypto', 'schema declares the crypto table')
    check(spec.seed.rows[1].crypto == 'qbit' and spec.seed.rows[1].worth == 1000, 'schema seeds the qbit row')
end

-- Existing row: publish only after the awaited UPDATE and refresh read.
do
    local f = setup(row(1500)); f.start(); local initial = f.env.GlobalState.Qbit
    check(f.resume() == 'SQL wait', 'periodic UPDATE waits')
    check(f.env.GlobalState.Qbit == initial and initial.Worth == 1500, 'pending write cannot publish new worth')
    f.complete()
    check(f.row.worth == 1499 and f.env.GlobalState.Qbit == initial, 'database completes before publication')
    check(f.resume() == 600000, 'market continues at configured interval')
    check(f.env.GlobalState.Qbit.Worth == 1499, 'periodic update refreshes replicated price')
    check(#f.calls == 3 and f.calls[2].kind == 'update' and f.calls[3].sql:match('^SELECT'), 'existing row needs UPDATE then refresh only')
    check(#json.decode(f.row.history) == 2 and #f.env.GlobalState.Qbit.History == 2, 'history roundtrip retained')
end

-- Missing row: await UPDATE(0), INSERT(0 is valid), then refresh.
do
    local f = setup(); f.start(); local initial = f.env.GlobalState.Qbit
    check(f.resume() == 'SQL wait', 'missing-row UPDATE waits')
    f.complete()
    check(f.resume() == 'SQL wait', 'missing row reaches awaited INSERT')
    check(f.pending.kind == 'insert' and f.pending.params.crypto == 'qbit', 'coin and INSERT contract retained')
    check(f.pending.params.worth == 999 and type(f.pending.params.history) == 'string', 'named bind values retained')
    check(f.row == nil and f.env.GlobalState.Qbit == initial, 'INSERT cannot publish before completion')
    f.complete()
    check(f.row.worth == 999 and f.env.GlobalState.Qbit == initial, 'zero insert id is successful')
    check(f.resume() == 600000, 'fresh market keeps interval')
    check(f.env.GlobalState.Qbit.Worth == 999 and #f.calls == 4, 'fresh row is stored and refreshed')
end

-- A failed write returns to the next interval without INSERT/refresh fallout.
do
    local f = setup(row(1500)); f.start(); local initial = f.env.GlobalState.Qbit
    check(f.resume() == 'SQL wait'); f.complete(true)
    check(f.resume() == 600000, 'UPDATE error does not kill worker')
    check(f.row.worth == 1500 and f.env.GlobalState.Qbit == initial and #f.calls == 2, 'failed UPDATE preserves last published price')
end
do
    local f = setup(); f.start(); local initial = f.env.GlobalState.Qbit
    check(f.resume() == 'SQL wait'); f.complete()
    check(f.resume() == 'SQL wait'); f.complete(true)
    check(f.resume() == 600000, 'INSERT error does not kill worker')
    check(f.row == nil and f.env.GlobalState.Qbit == initial and #f.calls == 3, 'failed INSERT cannot publish an unpersisted fresh price')
end
-- The documented percent controls rare events without changing normal trends or price bounds.
local function market(worth, rolls, chance, history)
    local existing = row(worth)
    if history then existing.history = json.encode(history) end
    local f = setup(existing, function(first, last)
        local value = table.remove(rolls, 1)
        check(value ~= nil and value >= first and value <= last, 'market roll stays inside requested bounds')
        return value
    end, function(config)
        if chance ~= nil then config.ChanceOfCrashOrLuck = chance end
    end)
    f.start()
    check(f.resume() == 'SQL wait', 'market waits for price persistence')
    f.complete()
    check(f.resume() == 600000, 'market keeps its existing interval')
    check(f.env.GlobalState.Qbit.Worth == f.row.worth, 'market publishes the persisted price')
    return f.row.worth, f
end
local rare = 0
for event = 1, 100 do
    local worth = market(2500, { 45, event, 1, 20 })
    check(worth == (event <= 2 and 2520 or 2500), 'default two percent selects only event rolls one and two')
    if worth ~= 2500 then rare = rare + 1 end
end
check(rare == 2, 'default rare-event chance is exactly two of one hundred rolls')
check(market(2500, { 45, 1, 0, 20 }) == 2480, 'crash branch subtracts its configured amount')
check(market(2500, { 0, 100, 1 }) == 2499, 'normal decrease stays unchanged')
check(market(2500, { 100, 100, 1 }) == 2501, 'normal increase stays unchanged')
check(market(501, { 45, 1, 0, 80 }) == 500, 'crash keeps configured lower bound')
check(market(4999, { 45, 1, 1, 45 }) == 5000, 'luck keeps configured upper bound')
check(market(2500, { 45, 1 }, 0) == 2500, 'zero probability disables rare events')
check(market(2500, { 45, 100, 1, 20 }, 100) == 2520, 'one hundred probability always permits rare events')
check(market(2500, { 45, 35, 1, 20 }, 35) == 2520, 'custom probability includes its boundary')
check(market(2500, { 45, 36 }, 35) == 2500, 'roll above custom probability stays on normal path')
check(market(2500, { 45, 2, 1, 20 }, '2') == 2520, 'numeric string probability retains legacy Lua coercion')

-- Four observations retain their order when the next observation replaces the oldest.
local observations = {}
for index = 1, 4 do observations[index] = { PreviousWorth = 1000 + index, NewWorth = 1100 + index } end
local rolls = { 100, 100, 1 }
local _, marketState = market(2500, rolls, nil, observations)
local firstNew = { PreviousWorth = 2500, NewWorth = 2501 }
local expected = { observations[2], observations[3], observations[4], firstNew }
check(json.encode(json.decode(marketState.row.history)) == json.encode(expected), 'fifth observation preserves previous two three and four in order')
check(json.encode(marketState.env.GlobalState.Qbit.History) == json.encode(expected), 'rolling history publishes persisted observations')
rolls[1], rolls[2], rolls[3] = 100, 100, 2
check(marketState.resume() == 'SQL wait', 'next history observation waits for persistence')
marketState.complete()
check(marketState.resume() == 600000, 'history update retains market interval')
expected = { observations[3], observations[4], firstNew, { PreviousWorth = 2501, NewWorth = 2503 } }
check(json.encode(json.decode(marketState.row.history)) == json.encode(expected), 'sixth observation drops exactly one oldest record')
check(json.encode(marketState.env.GlobalState.Qbit.History) == json.encode(expected), 'subsequent persisted history is published unchanged')
for length = 0, 3 do
    local initial = {}; for index = 1, length do initial[index] = observations[index] end
    local _, f = market(2500, { 100, 100, 1 }, nil, initial)
    initial[length + 1] = firstNew
    check(json.encode(json.decode(f.row.history)) == json.encode(initial), 'short history appends without changing existing records')
    check(json.encode(f.env.GlobalState.Qbit.History) == json.encode(initial), 'short persisted history is published unchanged')
end

print(('crypto_sql: %d actual-source checks passed'):format(checks))
