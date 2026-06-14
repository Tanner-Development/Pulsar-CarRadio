--[[
ALL RIGHTS RESERVED - Tanner Development
This code and associated assets are the intellectual property of Tanner Development.
Unauthorized use, reproduction, or distribution of this code or its assets is strictly prohibited.
For inquiries or permissions, please contact Tanner Development directly.
]]

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
