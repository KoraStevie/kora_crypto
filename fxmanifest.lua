fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Provides the logic for handling cryptocurrency aka qbit'
version '0.2.0'

dependency 'kora_lib'
dependency 'kora_core'
dependency 'kora_sql'
dependency 'kora_target'

shared_scripts {
    '@kora_lib/init.lua',
    '@kora_core/init.lua',
    'shared/config.lua'
}
server_scripts {
    '@kora_sql/init.lua',
    'server/schema.lua',
    'server/server.lua'
}
client_script 'client/client.lua'
files { 'locales/*.lua' }

-- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
qa_feature 'tests/*.feature'
