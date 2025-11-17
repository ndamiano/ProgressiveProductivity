local production_statistics_cache = {}

local subscribers = {}

production_statistics_cache.production_statistics = {}

function production_statistics_cache.on_production_statistics_may_have_changed(subscriber)
    table.insert(subscribers, subscriber)
end

local function refresh_production_statistics_cache()
    local new_production_statistics = {}

    for force_name, force in pairs(game.forces) do
        local item_statistics = {}

        for surface, _ in pairs(game.surfaces) do
            local item_stats = force.get_item_production_statistics(surface)
            local fluid_stats = force.get_fluid_production_statistics(surface)
            
            for item_name, item_data in pairs(storage.progressive_productivity.items) do
                local prototype_category = prototypes[item_data.type]
                if not prototype_category then
                    log("no prototypes[" .. item_data.type .. "] found")
                    goto continue_item
                end
                
                if not prototype_category[item_name] then
                    storage.progressive_productivity.items[item_name] = nil
                    log("item " .. item_name .. " has vanished")
                    goto continue_item
                end

                local stats = item_data.type == "item" and item_stats or fluid_stats
                item_statistics[item_name] = (item_statistics[item_name] or 0) + stats.get_input_count(item_name)
                
                ::continue_item::
            end
        end
        
        new_production_statistics[force_name] = item_statistics
    end

    production_statistics_cache.production_statistics = new_production_statistics

    for _, subscriber in ipairs(subscribers) do
        subscriber()
    end
end

script.on_event(defines.events.on_force_created, refresh_production_statistics_cache)
production_statistics_cache.refresh_production_statistics_cache = refresh_production_statistics_cache

return production_statistics_cache