fx_version 'cerulean'
game 'gta5'

description 'core_gps - Location Marker Management System'
author 'ChrisNewmanDev'
version '1.1.1'

shared_scripts {
    'config.lua',
    'framework.lua'
}

client_scripts {
    'client/cl_gps.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_gps.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/gps_ui.png',
    'version.json'
}

lua54 'yes'