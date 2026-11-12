-- Run from the resource directory: lua test/credit.lua
local events, paid, transactions = {}, 0, 0
local near, removed, credited = true, true, true
source = 12
GlobalState = {}
Crypto = { Coin = 'qbit', Exchange = {} }
CreateThread = function() end
RegisterServerEvent = function(name, handler) events[name] = handler end
Kora = {
    lang = function(key) return key end,
    distance = { player = function() return near end },
}
exports = {
    ['qb-inventory'] = { RemoveItem = function(_, src, item, amount)
        assert(src == source and item == 'cryptostick' and amount == 1)
        return removed
    end },
    kora_core = {
        addMoney = function(_, src, account, amount)
            assert(src == source and account == 'crypto' and amount > 0)
            if not credited then return false end
            paid = paid + amount
            return true
        end,
        getPlayerData = function(_, src) return { source = src, money = { crypto = paid } } end,
        toLegacyPlayerData = function(_, data) return data end,
    },
}
TriggerClientEvent = function(name, src, player)
    assert(name == 'qb-phone:client:AddTransaction' and src == source)
    assert(player.PlayerData.money.crypto == paid, 'legacy event retains its player data argument')
    transactions = transactions + 1
end
dofile('server/server.lua')
local crack = assert(events['qb-crypto:server:crackCryptoStick'])
crack()
assert(paid > 0 and transactions == 1)
local balance = paid
removed = false
crack()
removed, credited = true, false
crack()
assert(paid == balance and transactions == 1, 'rejected removal or credit cannot report a payout')
near = false
assert(not pcall(crack) and paid == balance)
print('kora_crypto: native credit, legacy notification and rejected payout checks passed')
