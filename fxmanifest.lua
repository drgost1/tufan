fx_version 'cerulean'
game 'gta5'

author 'Tufan Studio'
description 'Aircraft Carrier Heist Script'
version '1.0.2'

shared_scripts {
    '@ox_lib/init.lua',
    -- 'locales/*.lua',
    'config.lua',
    'shared/*.lua'
}


client_scripts {
    'client/*.lua'
}

server_script 'server/*.lua'
-- ui_page 'html/index.html'

-- escrow_ignore {
-- }
-- files {
--     'html/index.html',
-- }
-- dependencies {
    
-- }


exports {
    -- Zone Exports
    'AddBoxZone',
    'AddCircleZone',
    'AddPolyZone',
    'RemoveZone',

    -- Entity Exports
    'AddLocalEntity',
    'RemoveLocalEntity',
    'AddEntityTarget',   -- Alias
    'RemoveEntityTarget',-- Alias

    -- Model Exports
    'AddModel',
    'RemoveModel',
    'AddModelTarget',    -- Alias
    'RemoveModelTarget', -- Alias

    -- Bone Exports
    'SetBoneTarget',
    'RemoveBoneTarget',
    'AddTargetBone',     -- Alias
    'RemoveTargetBone',  -- Alias

    -- Utility Exports
    'IsTargeting',
    'GetNearbyEntities'
}
lua54 'yes'
