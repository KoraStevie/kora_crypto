
exports.kora_target:addBoxZone({
	coords = Crypto.Exchange,
	size = vector3(1.0, 1.0, 1.0),
	options = {
		{
			label = Kora.lang('target.label'),
			icon = Kora.lang('target.icon'),
			onSelect = function()
				local hasStick = Kora.callback.trigger('qb-crypto:server:hasCryptoStick')
				if not hasStick then
						if Crypto.NotifyNoStick then
							Kora.notify.send({title = 'Crypto', message = Kora.lang('notify.no_stick'), type = 'error', timeout = 3500})
						end
						return
					end
				local game = Kora.minigames.play('keys', {amount = 40})
				if game.success then
					TriggerServerEvent('qb-crypto:server:crackCryptoStick')
				else
					TriggerServerEvent('qb-crypto:server:ExchangeFail')
					if Crypto.NotifyStickLost then
						Kora.notify.send({title = 'Crypto', message = Kora.lang('notify.stick_lost'), type = 'error', timeout = 3500})
					end
				end
			end
		}
	}
})

RegisterCommand('checkCrypto', function()
	local data = exports.kora_core:getPlayerData()
	local cryptoAmount = data.money.crypto or 0
	local myPocket = math.ceil(cryptoAmount * GlobalState.Qbit.Worth)
	Kora.notify.send({title = 'Crypto', message = Kora.lang('notify.crypt_worth', cryptoAmount, myPocket), type = 'success', timeout = 3500})
end, false)