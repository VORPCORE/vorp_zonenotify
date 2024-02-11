
fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'


author 'VORP @Bytesized'
description 'A zone notify for vorp core framework'
repository 'https://github.com/VORPCORE/vorp_zonenotify'

shared_scripts {
    'config.lua',
    'locale.lua',
    'locales/es.lua',
    'locales/en.lua',
}
client_scripts {
    'client/warmenu.lua',
    'client/client.lua',
    'config.lua'
}

server_scripts {
    'config.lua',
    'server/server.lua',
}


files {
    'ui/*',
    'ui/assets/*',
    'ui/assets/fonts/*'
}
    
ui_page 'ui/index.html'

version '1.0'
vorp_checker 'yes'
vorp_name '^4Resource version Check^3'
vorp_github 'https://github.com/VORPCORE/vorp_zonenotify'
