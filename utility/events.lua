---This module simplifies event handling.
---
---It simplifies the events API and supports registering multiple handlers for the same event,
---thus allowing other modules to have better separation of concerns.
---
---*Annotations are currently based on the API Docs version 2.0.23.*
---@class events
---@field on_init fun(handler: fun()) Registers a function to be run on mod initialization.
---@field on_load fun(handler: fun()) Registers a function to be run on save load.
---@field on_configuration_changed fun(handler: fun(event_data: ConfigurationChangedData)) Registers a function to be run when mod configuration changes.
---@field on_nth_tick fun(tick: uint|Array<uint>, handler: fun(event_data: NthTickEventData)) Registers a handler to run every nth-tick(s).
local events = {}

--- FIXME: Add @field on_event properly
---
--- Right now, there is no real solution to this problem.
--- The following two alternatives are available:
---
--- Without @field:
---     - events.on_event is recognized as a generic "function" by the language server
---     - The language server picks up the correct overload, observable ...
---         - ... on the bottom of the tooltip
---         - ... on CTRL/CMD click on on_event (events.on_event)
---     - The parameter of the callback still gets assigned the basic EventData type
---     - Suggestions work halfway
---         - `event_data` is still not recognized automatically, but can be selected
---         - The suggestions for `event_data` are filtered by the selected value for `event`
---     - The tooltip of the callback does show the correct signature
---     - Even with the correctly selected overload, the language server issues type mismatch warnings
---
--- With @field:
---     - events.on_event is recognized as the base overload by the language server
---     - All other working aspects are lost
---
--- For now, the option of not including @field on_event outweights the option to include it.
--- Based on the outcomes of https://github.com/LuaLS/lua-language-server/issues/1456, this might be reconsidered.
--- When a considerable amount of .on_specific_event functions are added, the @field definition might be reconsidered.

--#region on_init

---Subscribers' handlers for on_init
---@type Array<fun()>
local on_init_handlers

---Register a function to be run on mod initialization.
---@param handler fun() The handler for this event.
---
---Wraps `script.on_init`, allowing multiple handlers to be registered without overwriting each other.
---Passing `nil` to unregister is not supported. (A new concept for unregistering handlers may be added in a future version.)
---
---**Important:** Due to how Factorio events work, calling `script.on_init` directly will interfere with `events.on_init`, disabling it completely.
---
---### Example
---
---```
----- Initialize a `players` table in `storage` for later use
---events.on_init(function()
---  storage.players = {}
---end)
---```
---
---### Original Description
---
---Register a function to be run on mod initialization.
---
---This is only called when a new save game is created or when a save file is loaded that previously didn't contain the mod. During it, the mod gets the chance to set up initial values that it will use for its lifetime. It has full access to [LuaGameScript](https://lua-api.factorio.com/latest/classes/LuaGameScript.html) and the [storage](https://lua-api.factorio.com/latest/auxiliary/storage.html) table and can change anything about them that it deems appropriate. No other events will be raised for the mod until it has finished this step.
---
---For more context, refer to the [Data Lifecycle](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html) page.
---
---[View Documentation](https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_init)
function events.on_init(handler)
    assert(handler, "Handler must not be nil. Unregistering event handlers is not supported yet.")

    -- If on_init is being registered for the first time ...
    if not on_init_handlers then
        -- ... initialize its handler list
        on_init_handlers = {} ---@type Array<fun()>
        -- ... register its dispatch logic with Factorio
        script.on_init(function()
            for _, on_init_handler in ipairs(on_init_handlers) do
                on_init_handler()
            end
        end)
    end

    -- Register the handler
    table.insert(on_init_handlers, handler)
end

--#endregion

--#region on_load

---Subscribers' handlers for on_load
---@type Array<fun()>
local on_load_handlers

---Register a function to be run on save load.
---@param handler fun() The handler for this event.
---
---Wraps `script.on_load`, allowing multiple handlers to be registered without overwriting each other.
---Passing `nil` to unregister is not supported. (A new concept for unregistering handlers may be added in a future version.)
---
---**Important:** Due to how Factorio events work, calling `script.on_load` directly will interfere with `events.on_load`, disabling it completely.
---
---### Example
---
---```
----- Create local reference to `storage.players` for later use
---events.on_load(function()
---  local players = storage.players
---end)
---```
---
---### Original Description
---
---Register a function to be run on save load. This is only called for mods that have been part of the save previously, or for players connecting to a running multiplayer session.
---
---It gives the mod the opportunity to rectify potential differences in local state introduced by the save/load cycle. Doing anything other than the following three will lead to desyncs, breaking multiplayer and replay functionality. Access to [LuaGameScript](https://lua-api.factorio.com/latest/classes/LuaGameScript.html) is not available. The [storage](https://lua-api.factorio.com/latest/auxiliary/storage.html) table can be accessed and is safe to read from, but not write to, as doing so will lead to an error.
---
---The only legitimate uses of this event are these:
---
---* Re-setup [metatables](https://www.lua.org/pil/13.html) as they are not persisted through the save/load cycle.
---
---* Re-setup conditional event handlers, meaning subscribing to an event only when some condition is met to save processing time.
---
---* Create local references to data stored in the [storage](https://lua-api.factorio.com/latest/auxiliary/storage.html) table.
---
---For all other purposes, [LuaBootstrap::on\_init](https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_init), [LuaBootstrap::on\_configuration\_changed](https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_configuration_changed) or [migrations](https://lua-api.factorio.com/latest/auxiliary/migrations.html) should be used instead.
---
---For more context, refer to the [Data Lifecycle](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html) page.
---
---[View Documentation](https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_load)
function events.on_load(handler)
    assert(handler, "Handler must not be nil. Unregistering event handlers is not supported yet.")

    -- If on_load is being registered for the first time ...
    if not on_load_handlers then
        -- ... initialize its handler list
        on_load_handlers = {} ---@type Array<fun()>
        -- ... register its dispatch logic with Factorio
        script.on_load(function()
            for _, on_load_handler in ipairs(on_load_handlers) do
                on_load_handler()
            end
        end)
    end

    -- Register the handler
    table.insert(on_load_handlers, handler)
end

--#endregion

--#region on_configuration_changed

---Subscribers' handlers for on_configuration_changed
---@type Array<fun(event_data: ConfigurationChangedData)>
local on_configuration_changed_handlers

---Register a function to be run when mod configuration changes.
---@param handler fun(event_data: ConfigurationChangedData) The handler for this event.
---
---Wraps `script.on_configuration_changed`, allowing multiple handlers to be registered without overwriting each other.
---Passing `nil` to unregister is not supported. (A new concept for unregistering handlers may be added in a future version.)
---
---**Important:** Due to how Factorio events work, calling `script.on_configuration_changed` directly will interfere with `events.on_configuration_changed`, disabling it completely.
---
---### Example
---
---```
----- Update the `players` table in `storage` for the new game version
---events.on_configuration_changed(function(event_data)
---  if event_data.mod_changes["my-mod-name"] then
---    storage.players = {}
---  end
---end)
---```
---
---### Original Description
---
---Register a function to be run when mod configuration changes.
---
---This is called when the game version or any mod version changed, when any mod was added or removed, when a startup setting has changed, when any prototypes have been added or removed, or when a migration was applied. It allows the mod to make any changes it deems appropriate to both the data structures in its [storage](https://lua-api.factorio.com/latest/auxiliary/storage.html) table or to the game state through [LuaGameScript](https://lua-api.factorio.com/latest/classes/LuaGameScript.html).
---
---For more context, refer to the [Data Lifecycle](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html) page.
---
---[View Documentation](https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_configuration_changed)
function events.on_configuration_changed(handler)
    assert(handler, "Handler must not be nil. Unregistering event handlers is not supported yet.")

    -- If on_configuration_changed is being registered for the first time ...
    if not on_configuration_changed_handlers then
        -- ... initialize its handler list
        on_configuration_changed_handlers = {} ---@type Array<fun(event_data: ConfigurationChangedData)>
        -- ... register its dispatch logic with Factorio
        script.on_configuration_changed(function(event_data)
            for _, on_configuration_changed_handler in ipairs(on_configuration_changed_handlers) do
                on_configuration_changed_handler(event_data)
            end
        end)
    end

    -- Register the handler
    table.insert(on_configuration_changed_handlers, handler)
end

--#endregion

--#region on_event

---Subscribers' handlers for on_event
---@type Dictionary<LuaEventType, Array<fun(event_data: EventData)>>
local on_event_handlers = {}

-- TODO: Open issue for LuaCATS to support callback parameter annotations.
--       E.g. for `event_data` below, related to the FIXME above.

-- TODO: To support filters in the future.
--       The filter passed with each handler must be stored separately and
--       the dispatcher must be reregistered with the superset of all filters.

---Register a handler to run on the specified event(s).
---@param event LuaEventType|Array<LuaEventType> The event(s) or custom-input to invoke the handler on.
---@param handler fun(event_data: EventData) The handler for this event.
---
---Wraps `script.on_event`, allowing multiple handlers to be registered for the same event types without overwriting each other.
---Passing `nil` to unregister is not supported. (A new concept for unregistering handlers may be added in a future version.)
---Filters are not supported yet, but are planned for a future version.
---
---**Important:** Due to how Factorio events work, calling `script.on_event` directly for an event handled by `events.on_event` will interfere with `events.on_event`, disabling it for that event.
---
---### Example
---
---```
----- Register for the on_tick event to print the current tick to console each tick
---events.on_event(defines.events.on_tick, function(event_data)
---  game.print("Current tick: " .. event_data.tick)
---end)
---```
---
---### Original Description
---
---Register a handler to run on the specified event(s). Each mod can only register once for every event, as any additional registration will overwrite the previous one. This holds true even if different filters are used for subsequent registrations.
---
---### Example
---
---```
----- Register for the on_tick event to print the current tick to console each tick
---script.on_event(defines.events.on_tick,
---function(event) game.print(event.tick) end)
---```
---
---### Example
---
---```
----- Register for the on_built_entity event, limiting it to only be received when a `"fast-inserter"` is built
---script.on_event(defines.events.on_built_entity,
---function(event) game.print("Gotta go fast!") end,
---{{filter = "name", name = "fast-inserter"}})
---```
---
---[View Documentation](https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_event)
---
---@overload fun(event: string, handler: fun(event_data: EventData))
---@overload fun(event: LuaCustomEventPrototype, handler: fun(event_data: EventData))
---@overload fun(event: LuaCustomInputPrototype, handler: fun(event_data: EventData.CustomInputEvent))
---@overload fun(event: defines.events.on_achievement_gained, handler: fun(event_data: EventData.on_achievement_gained))
---@overload fun(event: defines.events.on_ai_command_completed, handler: fun(event_data: EventData.on_ai_command_completed))
---@overload fun(event: defines.events.on_area_cloned, handler: fun(event_data: EventData.on_area_cloned))
---@overload fun(event: defines.events.on_biter_base_built, handler: fun(event_data: EventData.on_biter_base_built))
---@overload fun(event: defines.events.on_brush_cloned, handler: fun(event_data: EventData.on_brush_cloned))
---@overload fun(event: defines.events.on_build_base_arrived, handler: fun(event_data: EventData.on_build_base_arrived))
---@overload fun(event: defines.events.on_built_entity, handler: fun(event_data: EventData.on_built_entity))
---@overload fun(event: defines.events.on_cancelled_deconstruction, handler: fun(event_data: EventData.on_cancelled_deconstruction))
---@overload fun(event: defines.events.on_cancelled_upgrade, handler: fun(event_data: EventData.on_cancelled_upgrade))
---@overload fun(event: defines.events.on_cargo_pod_finished_ascending, handler: fun(event_data: EventData.on_cargo_pod_finished_ascending))
---@overload fun(event: defines.events.on_character_corpse_expired, handler: fun(event_data: EventData.on_character_corpse_expired))
---@overload fun(event: defines.events.on_chart_tag_added, handler: fun(event_data: EventData.on_chart_tag_added))
---@overload fun(event: defines.events.on_chart_tag_modified, handler: fun(event_data: EventData.on_chart_tag_modified))
---@overload fun(event: defines.events.on_chart_tag_removed, handler: fun(event_data: EventData.on_chart_tag_removed))
---@overload fun(event: defines.events.on_chunk_charted, handler: fun(event_data: EventData.on_chunk_charted))
---@overload fun(event: defines.events.on_chunk_deleted, handler: fun(event_data: EventData.on_chunk_deleted))
---@overload fun(event: defines.events.on_chunk_generated, handler: fun(event_data: EventData.on_chunk_generated))
---@overload fun(event: defines.events.on_combat_robot_expired, handler: fun(event_data: EventData.on_combat_robot_expired))
---@overload fun(event: defines.events.on_console_chat, handler: fun(event_data: EventData.on_console_chat))
---@overload fun(event: defines.events.on_console_command, handler: fun(event_data: EventData.on_console_command))
---@overload fun(event: defines.events.on_cutscene_cancelled, handler: fun(event_data: EventData.on_cutscene_cancelled))
---@overload fun(event: defines.events.on_cutscene_finished, handler: fun(event_data: EventData.on_cutscene_finished))
---@overload fun(event: defines.events.on_cutscene_started, handler: fun(event_data: EventData.on_cutscene_started))
---@overload fun(event: defines.events.on_cutscene_waypoint_reached, handler: fun(event_data: EventData.on_cutscene_waypoint_reached))
---@overload fun(event: defines.events.on_entity_cloned, handler: fun(event_data: EventData.on_entity_cloned))
---@overload fun(event: defines.events.on_entity_color_changed, handler: fun(event_data: EventData.on_entity_color_changed))
---@overload fun(event: defines.events.on_entity_damaged, handler: fun(event_data: EventData.on_entity_damaged))
---@overload fun(event: defines.events.on_entity_died, handler: fun(event_data: EventData.on_entity_died))
---@overload fun(event: defines.events.on_entity_logistic_slot_changed, handler: fun(event_data: EventData.on_entity_logistic_slot_changed))
---@overload fun(event: defines.events.on_entity_renamed, handler: fun(event_data: EventData.on_entity_renamed))
---@overload fun(event: defines.events.on_entity_settings_pasted, handler: fun(event_data: EventData.on_entity_settings_pasted))
---@overload fun(event: defines.events.on_entity_spawned, handler: fun(event_data: EventData.on_entity_spawned))
---@overload fun(event: defines.events.on_equipment_inserted, handler: fun(event_data: EventData.on_equipment_inserted))
---@overload fun(event: defines.events.on_equipment_removed, handler: fun(event_data: EventData.on_equipment_removed))
---@overload fun(event: defines.events.on_force_cease_fire_changed, handler: fun(event_data: EventData.on_force_cease_fire_changed))
---@overload fun(event: defines.events.on_force_created, handler: fun(event_data: EventData.on_force_created))
---@overload fun(event: defines.events.on_force_friends_changed, handler: fun(event_data: EventData.on_force_friends_changed))
---@overload fun(event: defines.events.on_force_reset, handler: fun(event_data: EventData.on_force_reset))
---@overload fun(event: defines.events.on_forces_merged, handler: fun(event_data: EventData.on_forces_merged))
---@overload fun(event: defines.events.on_forces_merging, handler: fun(event_data: EventData.on_forces_merging))
---@overload fun(event: defines.events.on_game_created_from_scenario, handler: fun(event_data: EventData.on_game_created_from_scenario))
---@overload fun(event: defines.events.on_gui_checked_state_changed, handler: fun(event_data: EventData.on_gui_checked_state_changed))
---@overload fun(event: defines.events.on_gui_click, handler: fun(event_data: EventData.on_gui_click))
---@overload fun(event: defines.events.on_gui_closed, handler: fun(event_data: EventData.on_gui_closed))
---@overload fun(event: defines.events.on_gui_confirmed, handler: fun(event_data: EventData.on_gui_confirmed))
---@overload fun(event: defines.events.on_gui_elem_changed, handler: fun(event_data: EventData.on_gui_elem_changed))
---@overload fun(event: defines.events.on_gui_hover, handler: fun(event_data: EventData.on_gui_hover))
---@overload fun(event: defines.events.on_gui_leave, handler: fun(event_data: EventData.on_gui_leave))
---@overload fun(event: defines.events.on_gui_location_changed, handler: fun(event_data: EventData.on_gui_location_changed))
---@overload fun(event: defines.events.on_gui_opened, handler: fun(event_data: EventData.on_gui_opened))
---@overload fun(event: defines.events.on_gui_selected_tab_changed, handler: fun(event_data: EventData.on_gui_selected_tab_changed))
---@overload fun(event: defines.events.on_gui_selection_state_changed, handler: fun(event_data: EventData.on_gui_selection_state_changed))
---@overload fun(event: defines.events.on_gui_switch_state_changed, handler: fun(event_data: EventData.on_gui_switch_state_changed))
---@overload fun(event: defines.events.on_gui_text_changed, handler: fun(event_data: EventData.on_gui_text_changed))
---@overload fun(event: defines.events.on_gui_value_changed, handler: fun(event_data: EventData.on_gui_value_changed))
---@overload fun(event: defines.events.on_land_mine_armed, handler: fun(event_data: EventData.on_land_mine_armed))
---@overload fun(event: defines.events.on_lua_shortcut, handler: fun(event_data: EventData.on_lua_shortcut))
---@overload fun(event: defines.events.on_marked_for_deconstruction, handler: fun(event_data: EventData.on_marked_for_deconstruction))
---@overload fun(event: defines.events.on_marked_for_upgrade, handler: fun(event_data: EventData.on_marked_for_upgrade))
---@overload fun(event: defines.events.on_market_item_purchased, handler: fun(event_data: EventData.on_market_item_purchased))
---@overload fun(event: defines.events.on_mod_item_opened, handler: fun(event_data: EventData.on_mod_item_opened))
---@overload fun(event: defines.events.on_object_destroyed, handler: fun(event_data: EventData.on_object_destroyed))
---@overload fun(event: defines.events.on_permission_group_added, handler: fun(event_data: EventData.on_permission_group_added))
---@overload fun(event: defines.events.on_permission_group_deleted, handler: fun(event_data: EventData.on_permission_group_deleted))
---@overload fun(event: defines.events.on_permission_group_edited, handler: fun(event_data: EventData.on_permission_group_edited))
---@overload fun(event: defines.events.on_permission_string_imported, handler: fun(event_data: EventData.on_permission_string_imported))
---@overload fun(event: defines.events.on_picked_up_item, handler: fun(event_data: EventData.on_picked_up_item))
---@overload fun(event: defines.events.on_player_alt_reverse_selected_area, handler: fun(event_data: EventData.on_player_alt_reverse_selected_area))
---@overload fun(event: defines.events.on_player_alt_selected_area, handler: fun(event_data: EventData.on_player_alt_selected_area))
---@overload fun(event: defines.events.on_player_ammo_inventory_changed, handler: fun(event_data: EventData.on_player_ammo_inventory_changed))
---@overload fun(event: defines.events.on_player_armor_inventory_changed, handler: fun(event_data: EventData.on_player_armor_inventory_changed))
---@overload fun(event: defines.events.on_player_banned, handler: fun(event_data: EventData.on_player_banned))
---@overload fun(event: defines.events.on_player_built_tile, handler: fun(event_data: EventData.on_player_built_tile))
---@overload fun(event: defines.events.on_player_cancelled_crafting, handler: fun(event_data: EventData.on_player_cancelled_crafting))
---@overload fun(event: defines.events.on_player_changed_force, handler: fun(event_data: EventData.on_player_changed_force))
---@overload fun(event: defines.events.on_player_changed_position, handler: fun(event_data: EventData.on_player_changed_position))
---@overload fun(event: defines.events.on_player_changed_surface, handler: fun(event_data: EventData.on_player_changed_surface))
---@overload fun(event: defines.events.on_player_cheat_mode_disabled, handler: fun(event_data: EventData.on_player_cheat_mode_disabled))
---@overload fun(event: defines.events.on_player_cheat_mode_enabled, handler: fun(event_data: EventData.on_player_cheat_mode_enabled))
---@overload fun(event: defines.events.on_player_clicked_gps_tag, handler: fun(event_data: EventData.on_player_clicked_gps_tag))
---@overload fun(event: defines.events.on_player_configured_blueprint, handler: fun(event_data: EventData.on_player_configured_blueprint))
---@overload fun(event: defines.events.on_player_controller_changed, handler: fun(event_data: EventData.on_player_controller_changed))
---@overload fun(event: defines.events.on_player_crafted_item, handler: fun(event_data: EventData.on_player_crafted_item))
---@overload fun(event: defines.events.on_player_created, handler: fun(event_data: EventData.on_player_created))
---@overload fun(event: defines.events.on_player_cursor_stack_changed, handler: fun(event_data: EventData.on_player_cursor_stack_changed))
---@overload fun(event: defines.events.on_player_deconstructed_area, handler: fun(event_data: EventData.on_player_deconstructed_area))
---@overload fun(event: defines.events.on_player_demoted, handler: fun(event_data: EventData.on_player_demoted))
---@overload fun(event: defines.events.on_player_died, handler: fun(event_data: EventData.on_player_died))
---@overload fun(event: defines.events.on_player_display_density_scale_changed, handler: fun(event_data: EventData.on_player_display_density_scale_changed))
---@overload fun(event: defines.events.on_player_display_resolution_changed, handler: fun(event_data: EventData.on_player_display_resolution_changed))
---@overload fun(event: defines.events.on_player_display_scale_changed, handler: fun(event_data: EventData.on_player_display_scale_changed))
---@overload fun(event: defines.events.on_player_driving_changed_state, handler: fun(event_data: EventData.on_player_driving_changed_state))
---@overload fun(event: defines.events.on_player_dropped_item, handler: fun(event_data: EventData.on_player_dropped_item))
---@overload fun(event: defines.events.on_player_fast_transferred, handler: fun(event_data: EventData.on_player_fast_transferred))
---@overload fun(event: defines.events.on_player_flipped_entity, handler: fun(event_data: EventData.on_player_flipped_entity))
---@overload fun(event: defines.events.on_player_flushed_fluid, handler: fun(event_data: EventData.on_player_flushed_fluid))
---@overload fun(event: defines.events.on_player_gun_inventory_changed, handler: fun(event_data: EventData.on_player_gun_inventory_changed))
---@overload fun(event: defines.events.on_player_input_method_changed, handler: fun(event_data: EventData.on_player_input_method_changed))
---@overload fun(event: defines.events.on_player_joined_game, handler: fun(event_data: EventData.on_player_joined_game))
---@overload fun(event: defines.events.on_player_kicked, handler: fun(event_data: EventData.on_player_kicked))
---@overload fun(event: defines.events.on_player_left_game, handler: fun(event_data: EventData.on_player_left_game))
---@overload fun(event: defines.events.on_player_locale_changed, handler: fun(event_data: EventData.on_player_locale_changed))
---@overload fun(event: defines.events.on_player_main_inventory_changed, handler: fun(event_data: EventData.on_player_main_inventory_changed))
---@overload fun(event: defines.events.on_player_mined_entity, handler: fun(event_data: EventData.on_player_mined_entity))
---@overload fun(event: defines.events.on_player_mined_item, handler: fun(event_data: EventData.on_player_mined_item))
---@overload fun(event: defines.events.on_player_mined_tile, handler: fun(event_data: EventData.on_player_mined_tile))
---@overload fun(event: defines.events.on_player_muted, handler: fun(event_data: EventData.on_player_muted))
---@overload fun(event: defines.events.on_player_pipette, handler: fun(event_data: EventData.on_player_pipette))
---@overload fun(event: defines.events.on_player_placed_equipment, handler: fun(event_data: EventData.on_player_placed_equipment))
---@overload fun(event: defines.events.on_player_promoted, handler: fun(event_data: EventData.on_player_promoted))
---@overload fun(event: defines.events.on_player_removed, handler: fun(event_data: EventData.on_player_removed))
---@overload fun(event: defines.events.on_player_removed_equipment, handler: fun(event_data: EventData.on_player_removed_equipment))
---@overload fun(event: defines.events.on_player_repaired_entity, handler: fun(event_data: EventData.on_player_repaired_entity))
---@overload fun(event: defines.events.on_player_respawned, handler: fun(event_data: EventData.on_player_respawned))
---@overload fun(event: defines.events.on_player_reverse_selected_area, handler: fun(event_data: EventData.on_player_reverse_selected_area))
---@overload fun(event: defines.events.on_player_rotated_entity, handler: fun(event_data: EventData.on_player_rotated_entity))
---@overload fun(event: defines.events.on_player_selected_area, handler: fun(event_data: EventData.on_player_selected_area))
---@overload fun(event: defines.events.on_player_set_quick_bar_slot, handler: fun(event_data: EventData.on_player_set_quick_bar_slot))
---@overload fun(event: defines.events.on_player_setup_blueprint, handler: fun(event_data: EventData.on_player_setup_blueprint))
---@overload fun(event: defines.events.on_player_toggled_alt_mode, handler: fun(event_data: EventData.on_player_toggled_alt_mode))
---@overload fun(event: defines.events.on_player_toggled_map_editor, handler: fun(event_data: EventData.on_player_toggled_map_editor))
---@overload fun(event: defines.events.on_player_trash_inventory_changed, handler: fun(event_data: EventData.on_player_trash_inventory_changed))
---@overload fun(event: defines.events.on_player_unbanned, handler: fun(event_data: EventData.on_player_unbanned))
---@overload fun(event: defines.events.on_player_unmuted, handler: fun(event_data: EventData.on_player_unmuted))
---@overload fun(event: defines.events.on_player_used_capsule, handler: fun(event_data: EventData.on_player_used_capsule))
---@overload fun(event: defines.events.on_player_used_spidertron_remote, handler: fun(event_data: EventData.on_player_used_spidertron_remote))
---@overload fun(event: defines.events.on_post_entity_died, handler: fun(event_data: EventData.on_post_entity_died))
---@overload fun(event: defines.events.on_pre_build, handler: fun(event_data: EventData.on_pre_build))
---@overload fun(event: defines.events.on_pre_chunk_deleted, handler: fun(event_data: EventData.on_pre_chunk_deleted))
---@overload fun(event: defines.events.on_pre_entity_settings_pasted, handler: fun(event_data: EventData.on_pre_entity_settings_pasted))
---@overload fun(event: defines.events.on_pre_ghost_deconstructed, handler: fun(event_data: EventData.on_pre_ghost_deconstructed))
---@overload fun(event: defines.events.on_pre_ghost_upgraded, handler: fun(event_data: EventData.on_pre_ghost_upgraded))
---@overload fun(event: defines.events.on_pre_permission_group_deleted, handler: fun(event_data: EventData.on_pre_permission_group_deleted))
---@overload fun(event: defines.events.on_pre_permission_string_imported, handler: fun(event_data: EventData.on_pre_permission_string_imported))
---@overload fun(event: defines.events.on_pre_player_crafted_item, handler: fun(event_data: EventData.on_pre_player_crafted_item))
---@overload fun(event: defines.events.on_pre_player_died, handler: fun(event_data: EventData.on_pre_player_died))
---@overload fun(event: defines.events.on_pre_player_left_game, handler: fun(event_data: EventData.on_pre_player_left_game))
---@overload fun(event: defines.events.on_pre_player_mined_item, handler: fun(event_data: EventData.on_pre_player_mined_item))
---@overload fun(event: defines.events.on_pre_player_removed, handler: fun(event_data: EventData.on_pre_player_removed))
---@overload fun(event: defines.events.on_pre_player_toggled_map_editor, handler: fun(event_data: EventData.on_pre_player_toggled_map_editor))
---@overload fun(event: defines.events.on_pre_robot_exploded_cliff, handler: fun(event_data: EventData.on_pre_robot_exploded_cliff))
---@overload fun(event: defines.events.on_pre_scenario_finished, handler: fun(event_data: EventData.on_pre_scenario_finished))
---@overload fun(event: defines.events.on_pre_script_inventory_resized, handler: fun(event_data: EventData.on_pre_script_inventory_resized))
---@overload fun(event: defines.events.on_pre_surface_cleared, handler: fun(event_data: EventData.on_pre_surface_cleared))
---@overload fun(event: defines.events.on_pre_surface_deleted, handler: fun(event_data: EventData.on_pre_surface_deleted))
---@overload fun(event: defines.events.on_redo_applied, handler: fun(event_data: EventData.on_redo_applied))
---@overload fun(event: defines.events.on_research_cancelled, handler: fun(event_data: EventData.on_research_cancelled))
---@overload fun(event: defines.events.on_research_finished, handler: fun(event_data: EventData.on_research_finished))
---@overload fun(event: defines.events.on_research_moved, handler: fun(event_data: EventData.on_research_moved))
---@overload fun(event: defines.events.on_research_reversed, handler: fun(event_data: EventData.on_research_reversed))
---@overload fun(event: defines.events.on_research_started, handler: fun(event_data: EventData.on_research_started))
---@overload fun(event: defines.events.on_resource_depleted, handler: fun(event_data: EventData.on_resource_depleted))
---@overload fun(event: defines.events.on_robot_built_entity, handler: fun(event_data: EventData.on_robot_built_entity))
---@overload fun(event: defines.events.on_robot_built_tile, handler: fun(event_data: EventData.on_robot_built_tile))
---@overload fun(event: defines.events.on_robot_exploded_cliff, handler: fun(event_data: EventData.on_robot_exploded_cliff))
---@overload fun(event: defines.events.on_robot_mined, handler: fun(event_data: EventData.on_robot_mined))
---@overload fun(event: defines.events.on_robot_mined_entity, handler: fun(event_data: EventData.on_robot_mined_entity))
---@overload fun(event: defines.events.on_robot_mined_tile, handler: fun(event_data: EventData.on_robot_mined_tile))
---@overload fun(event: defines.events.on_robot_pre_mined, handler: fun(event_data: EventData.on_robot_pre_mined))
---@overload fun(event: defines.events.on_rocket_launch_ordered, handler: fun(event_data: EventData.on_rocket_launch_ordered))
---@overload fun(event: defines.events.on_rocket_launched, handler: fun(event_data: EventData.on_rocket_launched))
---@overload fun(event: defines.events.on_runtime_mod_setting_changed, handler: fun(event_data: EventData.on_runtime_mod_setting_changed))
---@overload fun(event: defines.events.on_script_inventory_resized, handler: fun(event_data: EventData.on_script_inventory_resized))
---@overload fun(event: defines.events.on_script_path_request_finished, handler: fun(event_data: EventData.on_script_path_request_finished))
---@overload fun(event: defines.events.on_script_trigger_effect, handler: fun(event_data: EventData.on_script_trigger_effect))
---@overload fun(event: defines.events.on_sector_scanned, handler: fun(event_data: EventData.on_sector_scanned))
---@overload fun(event: defines.events.on_segment_entity_created, handler: fun(event_data: EventData.on_segment_entity_created))
---@overload fun(event: defines.events.on_selected_entity_changed, handler: fun(event_data: EventData.on_selected_entity_changed))
---@overload fun(event: defines.events.on_space_platform_built_entity, handler: fun(event_data: EventData.on_space_platform_built_entity))
---@overload fun(event: defines.events.on_space_platform_built_tile, handler: fun(event_data: EventData.on_space_platform_built_tile))
---@overload fun(event: defines.events.on_space_platform_changed_state, handler: fun(event_data: EventData.on_space_platform_changed_state))
---@overload fun(event: defines.events.on_space_platform_mined_entity, handler: fun(event_data: EventData.on_space_platform_mined_entity))
---@overload fun(event: defines.events.on_space_platform_mined_item, handler: fun(event_data: EventData.on_space_platform_mined_item))
---@overload fun(event: defines.events.on_space_platform_mined_tile, handler: fun(event_data: EventData.on_space_platform_mined_tile))
---@overload fun(event: defines.events.on_space_platform_pre_mined, handler: fun(event_data: EventData.on_space_platform_pre_mined))
---@overload fun(event: defines.events.on_spider_command_completed, handler: fun(event_data: EventData.on_spider_command_completed))
---@overload fun(event: defines.events.on_string_translated, handler: fun(event_data: EventData.on_string_translated))
---@overload fun(event: defines.events.on_surface_cleared, handler: fun(event_data: EventData.on_surface_cleared))
---@overload fun(event: defines.events.on_surface_created, handler: fun(event_data: EventData.on_surface_created))
---@overload fun(event: defines.events.on_surface_deleted, handler: fun(event_data: EventData.on_surface_deleted))
---@overload fun(event: defines.events.on_surface_imported, handler: fun(event_data: EventData.on_surface_imported))
---@overload fun(event: defines.events.on_surface_renamed, handler: fun(event_data: EventData.on_surface_renamed))
---@overload fun(event: defines.events.on_technology_effects_reset, handler: fun(event_data: EventData.on_technology_effects_reset))
---@overload fun(event: defines.events.on_tick, handler: fun(event_data: EventData.on_tick))
---@overload fun(event: defines.events.on_train_changed_state, handler: fun(event_data: EventData.on_train_changed_state))
---@overload fun(event: defines.events.on_train_created, handler: fun(event_data: EventData.on_train_created))
---@overload fun(event: defines.events.on_train_schedule_changed, handler: fun(event_data: EventData.on_train_schedule_changed))
---@overload fun(event: defines.events.on_trigger_created_entity, handler: fun(event_data: EventData.on_trigger_created_entity))
---@overload fun(event: defines.events.on_trigger_fired_artillery, handler: fun(event_data: EventData.on_trigger_fired_artillery))
---@overload fun(event: defines.events.on_undo_applied, handler: fun(event_data: EventData.on_undo_applied))
---@overload fun(event: defines.events.on_unit_added_to_group, handler: fun(event_data: EventData.on_unit_added_to_group))
---@overload fun(event: defines.events.on_unit_group_created, handler: fun(event_data: EventData.on_unit_group_created))
---@overload fun(event: defines.events.on_unit_group_finished_gathering, handler: fun(event_data: EventData.on_unit_group_finished_gathering))
---@overload fun(event: defines.events.on_unit_removed_from_group, handler: fun(event_data: EventData.on_unit_removed_from_group))
---@overload fun(event: defines.events.on_worker_robot_expired, handler: fun(event_data: EventData.on_worker_robot_expired))
---@overload fun(event: defines.events.script_raised_built, handler: fun(event_data: EventData.script_raised_built))
---@overload fun(event: defines.events.script_raised_destroy, handler: fun(event_data: EventData.script_raised_destroy))
---@overload fun(event: defines.events.script_raised_revive, handler: fun(event_data: EventData.script_raised_revive))
---@overload fun(event: defines.events.script_raised_set_tiles, handler: fun(event_data: EventData.script_raised_set_tiles))
---@overload fun(event: defines.events.script_raised_teleported, handler: fun(event_data: EventData.script_raised_teleported))
function events.on_event(event, handler)
    assert(event, "Event must not be nil.")
    assert(handler, "Handler must not be nil. Unregistering event handlers is not supported yet.")

    -- TODO: Add support for LuaCustomEventPrototype and LuaCustomInputPrototype.
    --       Both have not have not been tested yet and might fail.

    -- Convert the event to an array if it's a single event
    ---@type Array<LuaEventType>
    local event_list = type(event) == "table" and event or { event }

    -- Register the handler for each event type separately
    for _, event_type in ipairs(event_list) do
        assert(type(event_type) == "number" or type(event_type) == "string",
            "Event must be defines.events.*, string, or an array of defines.events or strings.")

        --#region Tell the language server that event_type that number should be defines.events
        -- As the language server changes the type to match the assertion,
        -- the change from defines.events to number must be undone.
        ---@cast event_type -number
        ---@cast event_type +defines.events
        --#endregion

        -- If the event type is being registered for the first time ...
        if not on_event_handlers[event_type] then
            -- ... initialize its handler list
            on_event_handlers[event_type] = {}
            -- ... register its dispatch logic with Factorio
            script.on_event(event_type, function(event_data)
                for _, on_event_handler in ipairs(on_event_handlers[event_type]) do
                    on_event_handler(event_data)
                end
            end)
        end

        -- Register the handler
        table.insert(on_event_handlers[event_type], handler)
    end
end

--#endregion

--#region on_nth_tick

---Subscribers' handlers for on_nth_tick
---@type Dictionary<uint, Array<fun(event_data: NthTickEventData)>>
local on_nth_tick_handlers = {}

---Register a handler to run every nth-tick(s).
---@param tick uint|Array<uint> The nth-tick(s) to invoke the handler on.
---@param handler fun(event_data: NthTickEventData) The handler to run.
---
---Wraps `script.on_nth_tick`, allowing multiple handlers to be registered for the same tick(s) without overwriting each other.
---Passing `nil` to unregister is not supported. (A new concept for unregistering handlers may be added in a future version.)
---
---**Important:** Due to how Factorio events work, calling `script.on_nth_tick` directly for a tick handled by `events.on_nth_tick` will interfere with `events.on_nth_tick`, disabling it for that tick completely.
---
---### Example
---
---```
----- Register for the 60th tick to print the current tick to console
---events.on_nth_tick(60, function(event_data)
---  game.print("Current tick: " .. event_data.tick)
---end)
---```
---
---### Original Description
---
---Register a handler to run every nth-tick(s). When the game is on tick 0 it will trigger all registered handlers.
---
---[View Documentation](https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_nth_tick)
function events.on_nth_tick(tick, handler)
    assert(tick, "Tick must not be nil. Unregistering event handlers is not supported yet.")
    assert(handler, "Handler must not be nil. Unregistering event handlers is not supported yet.")

    -- Convert the tick to an array if it's a single tick
    ---@type Array<uint>
    local tick_list = type(tick) == "table" and tick or { tick }

    -- Register the handler for each tick separately
    for _, nth_tick in ipairs(tick_list) do
        assert(type(nth_tick) == "number" and nth_tick > 0,
            "Tick must be a positive integer or an array of positive integers.")

        -- If the tick is being registered for the first time ...
        if not on_nth_tick_handlers[nth_tick] then
            -- ... initialize its handler list
            on_nth_tick_handlers[nth_tick] = {}
            -- ... register its dispatch logic with Factorio
            script.on_nth_tick(nth_tick, function(event_data)
                for _, on_nth_tick_handler in ipairs(on_nth_tick_handlers[nth_tick]) do
                    on_nth_tick_handler(event_data)
                end
            end)
        end

        -- Register the handler
        table.insert(on_nth_tick_handlers[tick], handler)
    end
end

--#endregion

return events
