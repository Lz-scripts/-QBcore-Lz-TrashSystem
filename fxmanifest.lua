fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Lahmiiz'
version '1.0'
description 'Trash System By Lz-scripts'

shared_scripts {
    'config.lua',
}

client_script {
    'client/main.lua',

}
ui_page 'html/index.html' 

files {
    'html/index.html',
    'html/styles.css',
    'html/script.js',
    'html/img/*.png'
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}
