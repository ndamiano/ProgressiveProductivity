-- This module handles the caching and updating of mod settings for progressive productivity.
-- It provides functionality to refresh settings, notify subscribers of changes,
-- and handle runtime mod setting changes.

---Represents the cache for settings and handles changes.
---@class SettingsCache
---@field settings ModSettings The mods settings, automatically kept up to date.
---@field on_settings_changed fun(subscriber: fun()) Registers a subscriber to be notified when the settings have changed.

-- TODO: Add descriptions once the localizations have been improved
---Represents the mod settings for progressive productivity.
---@class ModSettings
---@field item ProductSettings
---@field fluid ProductSettings
---@field intermediates_only boolean

-- TODO: Add descriptions once the localizations have been improved
---Represents the settings for a product type.
---@class ProductSettings
---@field cost_base int
---@field cost_multiplier double
---@field productivity_bonus double

local last_settings_changed_event_tick = -1 -- The event tick of the last settings changed event
local settings_changed_subscribers = {}     -- List of subscribers to notify when settings have changed

---@type SettingsCache
local settings_cache = {
    settings = {
        item = {
            cost_base = 0,
            cost_multiplier = 0.0,
            productivity_bonus = 0.0
        },
        fluid = {
            cost_base = 0,
            cost_multiplier = 0.0,
            productivity_bonus = 0.0
        },
        intermediates_only = false,
        disable_messages = false
    },
    on_settings_changed = function(subscriber)
        table.insert(settings_changed_subscribers, subscriber)
    end
}

--#region Helper functions

---Clones the settings table
---@param original_settings ModSettings The settings to clone
---@return ModSettings settings_clone The cloned settings
local function clone_settings(original_settings)
    return {
        item = {
            cost_base = original_settings.item.cost_base,
            cost_multiplier = original_settings.item.cost_multiplier,
            productivity_bonus = original_settings.item.productivity_bonus
        },
        fluid = {
            cost_base = original_settings.fluid.cost_base,
            cost_multiplier = original_settings.fluid.cost_multiplier,
            productivity_bonus = original_settings.fluid.productivity_bonus
        },
        intermediates_only = original_settings.intermediates_only,
        disable_messages = original_settings.disable_messages
    }
end

---Checks if the settings have changed
---@param previous_settings ModSettings The previous settings to compare against
---@return boolean result True if the settings have changed, false otherwise
local function settings_have_changed(previous_settings)
    return previous_settings.item.cost_base ~= settings_cache.settings.item.cost_base or
        previous_settings.item.cost_multiplier ~= settings_cache.settings.item.cost_multiplier or
        previous_settings.item.productivity_bonus ~= settings_cache.settings.item.productivity_bonus or
        previous_settings.fluid.cost_base ~= settings_cache.settings.fluid.cost_base or
        previous_settings.fluid.cost_multiplier ~= settings_cache.settings.fluid.cost_multiplier or
        previous_settings.fluid.productivity_bonus ~= settings_cache.settings.fluid.productivity_bonus or
        previous_settings.intermediates_only ~= settings_cache.settings.intermediates_only
end

--#endregion

---Refreshes the settings cache, updating it with the current mod settings
local function refresh_settings_cache()
    -- Shortcut to the global settings for performance and readability (better syntax highlighting)
    local global_settings = settings.global
    settings_cache.settings.item.cost_base =
        global_settings["progressive-productivity-item-cost-base"].value --[[@as int]]
    settings_cache.settings.item.cost_multiplier =
        global_settings["progressive-productivity-item-cost-multiplier"].value --[[@as double]]
    settings_cache.settings.item.productivity_bonus =
        global_settings["progressive-productivity-item-productivity-addition"].value --[[@as double]]
    settings_cache.settings.fluid.cost_base =
        global_settings["progressive-productivity-fluid-cost-base"].value --[[@as int]]
    settings_cache.settings.fluid.cost_multiplier =
        global_settings["progressive-productivity-fluid-cost-multiplier"].value --[[@as double]]
    settings_cache.settings.fluid.productivity_bonus =
        global_settings["progressive-productivity-fluid-productivity-addition"].value --[[@as double]]
    settings_cache.settings.intermediates_only =
        settings.startup["progressive-productivity-intermediates-only"].value --[[@as boolean]]
    settings_cache.settings.disable_messages =
        global_settings["progressive-productivity-disable-messages"].value --[[@as boolean]]
end

-- Fetch initial values
refresh_settings_cache()

---Notifies all registered subscribers that the settings have changed
local function notify_settings_changed()
    -- Iterate over all subscribers and call each one
    for _, subscriber in ipairs(settings_changed_subscribers) do
        subscriber()
    end
end

---Refreshes the settings cache and notifies subscribers if mod settings have changed
---@param event EventData.on_runtime_mod_setting_changed The event data for the runtime mod setting changed event
local function handle_runtime_mod_setting_change(event)
    -- For performance reasons and to avoid event spam, only handle changes once per tick
    if last_settings_changed_event_tick ~= event.tick then
        last_settings_changed_event_tick = event.tick

        -- table.deepcopy is not available in the control phase
        local previous_settings = clone_settings(settings_cache.settings)
        refresh_settings_cache()

        if settings_have_changed(previous_settings) then
            notify_settings_changed()
        end
    end
end

-- Register the above event handler
script.on_event(defines.events.on_runtime_mod_setting_changed, handle_runtime_mod_setting_change)

return settings_cache
