fx_version 'cerulean'
game 'gta5'

author 'Codeverse Scripts'
description 'Payphone for FiveM'
version '1.4.0'

ui_page('ui/index.html')

client_scripts {
    'Config.lua',
    'Client/Main.lua',
    'Client/Interaction.lua'
}

server_scripts {
    'Config.lua',
    'Server/Main.lua',
}

files {
    'ui/index.html',
    'ui/main.js',
    'ui/style.css',
    'ui/assets/images/*.png',
    'ui/assets/sounds/*.mp3',
}

lua54 'yes'

escrow_ignore {
    'Config.lua',
    'Client/Interaction.lua'
}