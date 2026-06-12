fx_version 'cerulean'
game 'gta5'

author 'Adam'
description 'Adam Car Radio UI with Freeworld-style redesign'
version '1.0.0'

lua54 'yes'

dependencies {
    'xsound'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
