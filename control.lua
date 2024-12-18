---@diagnostic enable:spell-check

if script.active_mods["gvv"] then require("__gvv__.gvv")() end

local product_cache = require("utility.product_cache")
local gui_module = require("utility.gui_module")

-- When recipes could have changed or when we are initialized, create our local storage
script.on_configuration_changed(function(event)
    product_cache.setupStorage()
end)

script.on_init(function(event)
    product_cache.setupStorage()
end)

-- Events for toggling gui on and off
script.on_event("toggle_progressive_productivity_gui", function(event)
    --#region Tell the language server that event_data is of type EventData.CustomInputEvent
    ---The callback's parameter gets assigned the basic EventData type.
    ---This is a limitation of @overloads, that has been documented in detail in events.lua
    ---@cast event EventData.CustomInputEvent
    --#endregion

    local player = game.get_player(event.player_index)
    gui_module.toggleProgressiveProductivityUI(player, event.tick)
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    --#region Tell the language server that event_data is of type EventData.on_lua_shortcut
    ---The callback's parameter gets assigned the basic EventData type.
    ---This is a limitation of @overloads, that has been documented in detail in events.lua
    ---@cast event EventData.on_lua_shortcut
    --#endregion

    if event.prototype_name == "toggle_progressive_productivity_gui_shortcut" then
        local player = game.get_player(event.player_index)
        gui_module.toggleProgressiveProductivityUI(player, event.tick)
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    --#region Tell the language server that event_data is of type EventData.on_gui_closed
    ---The callback's parameter gets assigned the basic EventData type.
    ---This is a limitation of @overloads, that has been documented in detail in events.lua
    ---@cast event EventData.on_gui_closed
    --#endregion

    if event.element and event.element.name == "progressive_productivty_list" then
        local player = game.get_player(event.player_index)
        gui_module.toggleProgressiveProductivityUI(player, event.tick)
    end
end)
