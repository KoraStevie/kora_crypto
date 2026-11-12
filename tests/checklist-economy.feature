# Converted from the communitybot legacy tests by kora-qa-panel/scripts/convert-legacy.mjs.
# The """ block under each Scenario is the original test text, verbatim. Review before applying.
Feature: kora_crypto — Economy

  @kora_crypto @checklist @checklist:kora_crypto:crack-cryptostick @cat:economy
  Scenario: Crack a cryptostick at the exchange
    """
    Checklist test: At 1276,-1709,54 (exchange) with a cryptostick, target 'Crack Crypto Stick', pass the key minigame; stick consumed, ~0.6-1.6 Qbit credited.
    """
    Given I have 1 "cryptostick"
    When I manually: go to the crypto exchange at 1276,-1709,54
    And I manually: use the target option 'Crack Crypto Stick'
    And I manually: pass the key minigame
    Then I should have no "cryptostick"
    And I confirm: my Qbit balance increased by roughly 0.6-1.6 Qbit

  @kora_crypto @checklist @checklist:kora_crypto:crack-minigame-fail @cat:economy
  Scenario: Failing the minigame destroys the stick
    """
    Checklist test: Fail the keys minigame at the exchange; cryptostick is removed and no Qbit awarded.
    """
    Given I have 1 "cryptostick"
    When I manually: go to the crypto exchange at 1276,-1709,54
    And I manually: use the target option 'Crack Crypto Stick'
    And I manually: fail the keys minigame
    Then I should have no "cryptostick"
    And I confirm: no Qbit was credited to me

  @kora_crypto @checklist @checklist:kora_crypto:crack-no-stick @cat:economy
  Scenario: No cryptostick, no reward
    """
    Checklist test: Trigger crack without a stick in inventory; nothing is credited.
    """
    Given I have no "cryptostick"
    When I manually: go to the crypto exchange at 1276,-1709,54
    And I manually: try to crack a cryptostick using the target option 'Crack Crypto Stick'
    Then I should have no "cryptostick"
    And I confirm: no Qbit was credited to me

  @kora_crypto @checklist @checklist:kora_crypto:crack-distance @cat:economy
  Scenario: Exchange only works near the location
    """
    Checklist test: Crack/fail events are rejected when more than 5m from the exchange.
    """
    Given I have 1 "cryptostick"
    When I manually: go more than 5 metres away from the crypto exchange at 1276,-1709,54
    And I manually: try to crack the cryptostick using the target option 'Crack Crypto Stick' if it is available
    Then I confirm: the crack request is rejected and no Qbit is credited
    And I should have 1 "cryptostick"

  @kora_crypto @checklist @checklist:kora_crypto:credit-notification @cat:economy
  Scenario: Phone transaction and credit message
    """
    Checklist test: After cracking, a 'credited with X Qbit(s)' phone transaction (qb-phone AddTransaction) is received.
    """
    Given I have 1 "cryptostick"
    When I manually: go to the crypto exchange at 1276,-1709,54
    And I manually: crack the cryptostick via target 'Crack Crypto Stick' and pass the minigame
    Then I confirm: I receive a phone transaction saying I was credited with X Qbit(s)

  @kora_crypto @checklist @checklist:kora_crypto:check-crypto-command @cat:economy
  Scenario: /checkCrypto command
    """
    Checklist test: Run /checkCrypto; notification shows your Qbit amount and its dollar value at the current Qbit price.
    """
    When I run the command "/checkCrypto"
    Then I confirm: the notification shows my Qbit amount and its dollar value at the current Qbit price

  @kora_crypto @checklist @checklist:kora_crypto:price-fluctuation @cat:economy
  Scenario: Qbit price changes every 10 minutes
    """
    Checklist test: Wait one refresh cycle (or watch GlobalState.Qbit.Worth); price moves, stays within 500-5000 and keeps last 4 history entries.
    """
    When I wait 120 seconds
    And I manually: wait until one full 10-minute refresh cycle has passed
    Then I confirm: the Qbit price has changed
    And I confirm: the Qbit price stays between 500 and 5000
    And I confirm: only the last 4 price history entries are kept

  @kora_crypto @checklist @checklist:kora_crypto:price-persists @cat:economy @manual
  Scenario: Price survives restart
    """
    Checklist test: Restart the resource; GlobalState.Qbit.Worth is restored from the crypto table, not reset.
    """
    When I manually: ask a Mod to restart the kora_crypto resource
    Then I confirm: the Qbit price is restored from the crypto table and not reset
