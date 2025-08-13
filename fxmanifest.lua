fx_version 'cerulean'
game 'gta5'

author 'Tufan Studio'
description 'Aircraft Carrier Heist Script'
version '1.0.2'

shared_scripts {
    'config.lua',
    'shared/*.lua'
}


client_scripts {
    'client/*.lua'
}

server_script 'server/sv.lua'

lua54 'yes'
