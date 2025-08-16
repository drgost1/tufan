fx_version 'cerulean'
game 'gta5'

author 'Tufan Studio'
description 'Bridge System between Resources'
version '1.0.1'

shared_scripts {
    'config.lua',
    'shared/*.lua'
}


client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/framework.lua',
    'server/sv.lua'
}

-- (Server exports are defined inline via exports(...) in server/framework.lua)

lua54 'yes'
