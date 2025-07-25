-- This module handles the caching of production statistics for progressive productivity.
-- It provides functionality to refresh production statistics cache in certain situations
-- and at certain intervals automatically. Subscribers get notified after each refresh.
local storage_module = require("utility.storage_module")

---Represents the self refreshing cache for production statistics.
---@class ProductionStatisticsCache
---@field production_statistics ProductionStatistics The production statistics for all forces.
---@field on_production_statistics_may_have_changed fun(subscriber: fun()) Registers a subscriber to be notified when the production statistics get refreshed.

---Represents the production statistics for all forces.
---@alias ProductionStatistics Dictionary<ForceProductionStatistics>

---Represents the production statistics for a specific force.
---@class ForceProductionStatistics
---@field item ProductProductionStatistics The item production statistics for a specific force.
---@field fluid ProductProductionStatistics The fluid production statistics for a specific force.

---Represents the production statistics for a specific product type.
---@alias ProductProductionStatistics Dictionary<number>

--- List of subscribers to notify when production statistics may have changed
---@type Array<fun()>
local production_statistics_changed_subscribers = {}

---@type ProductionStatisticsCache
local production_statistics_cache = {
    production_statistics = {},
    on_production_statistics_may_have_changed = function(subscriber)
        table.insert(production_statistics_changed_subscribers, subscriber)
    end
}
--#region Helper functions

---Refreshes the production statistics cache
local function refresh_production_statistics_cache()
    -- Create a new cache for the production statistics
    ---@type Dictionary<ForceProductionStatistics>
    local new_production_statistics = {}

    for force_name, force in pairs(game.forces) do
        local item_statistics = {} ---@type ProductProductionStatistics

        for surface, _ in pairs(game.surfaces) do
            -- Add all produced items of the current surface to the cache
            local force_surface_item_statistics = force.get_item_production_statistics(surface)
            local force_surface_fluid_statistics = force.get_fluid_production_statistics(surface)
            for item_name, item in pairs(storage.progressive_productivity.items) do
                if prototypes[item.type] then
                    if prototypes[item.type][item_name] then
                        if item.type == "item" then
                            item_statistics[item_name] = (item_statistics[item_name] or 0) + force_surface_item_statistics.get_input_count(item_name)
                        end
                        if item.type == "fluid" then
                            item_statistics[item_name] = (item_statistics[item_name] or 0) + force_surface_fluid_statistics.get_input_count(item_name)
                        end
                    else
                        storage.progressive_productivity.items[item_name]=nil
                        log("item " .. item_name .. " has vanished")
                    end
                else
                    log("no prototypes[" .. item.type .. "] found")
                end
            end
        end
        -- Add the forces current production statistics to the new cache
        new_production_statistics[force_name] = item_statistics
    end

    -- Replace the old cache with the new one
    production_statistics_cache.production_statistics = new_production_statistics

    -- TODO: Consider notifying subscribers for changed production statistics on a per item/fluid basis (cleaner? simpler? easier to debug? or just more overhead?)
    -- Notify the subscribers that the production statistics may have changed
    for _, subscriber in ipairs(production_statistics_changed_subscribers) do
        subscriber()
    end
end

--#endregion

-- Refresh production statistics cache every 5 seconds
script.on_nth_tick(300, function(event)
    -- Refresh the production statistics cache
    refresh_production_statistics_cache()
end)

-- Refresh production statistics cache when a force is created
script.on_event(defines.events.on_force_created, refresh_production_statistics_cache)

return production_statistics_cache