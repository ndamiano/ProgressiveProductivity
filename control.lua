local CacheUtil = require("cache")
local GUIUtil = require("gui_utility")

-- When recipes could have changed or when we are initialized, create our local storage
script.on_configuration_changed(function(event)
    CacheUtil.setupStorage()
end)

script.on_init(function(event)
    CacheUtil.setupStorage()
end)

-- If the player has updated the productivity amount, reset the storage. This refreshes bonus amounts
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting == "progressive-productivity-fluid-productivity-addition" or event.setting == "progressive-productivity-productivity-addition" then
        CacheUtil.setupStorage()
    end
end)

-- When a force is created, re-create the cache
script.on_event("on_force_created", function(event)
    CacheUtil.createCache()
end)

-- Every 5 seconds, check what the productivity level should be
script.on_nth_tick(300, function(event)
    CacheUtil.updateProductivity(event.tick)
end)

-- Events for toggling gui on and off
script.on_event("toggle_progressive_productivity_gui", function(event)
    local player = game.get_player(event.player_index)
    GUIUtil.toggleProgressiveProductivityUI(player, event.tick)
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == "toggle_progressive_productivity_gui_shortcut" then
        local player = game.get_player(event.player_index)
        GUIUtil.toggleProgressiveProductivityUI(player, event.tick)
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.name == "progressive_productivty_list" then
        local player = game.get_player(event.player_index)
        GUIUtil.toggleProgressiveProductivityUI(player, event.tick)
    end
end)