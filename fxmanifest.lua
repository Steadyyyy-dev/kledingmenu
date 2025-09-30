fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'SteadyyDev'
description 'Een kleding menu die je outfits laat passen, opslaan en direct aantrekken'
version '1.3.1'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'fivem-appearance'
,
    'ox_inventory'
}
