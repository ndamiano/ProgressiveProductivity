local storage_module = {}
local settings_cache = require("utility.settings_cache")

-- Initialize or reset all storage
function storage_module.initialize()
    if not storage.progressive_productivity then
        storage.progressive_productivity = {}
    end
    local new_items_map = {}
    local playerForce = game.forces['player']
    local recipes = playerForce.recipes

    for _, recipe in pairs(recipes) do
        if recipe.products == nil or recipe.name:match"empty.*barrel" or recipe.name:match".+barrel" then
            goto continue
        end
        if recipe.name:match".*recycling" then
            goto continue
        end
        -- Use settings_cache for consistency
        if settings_cache.settings.intermediates_only and prototypes.recipe[recipe.name].allowed_effects["productivity"] == false then
            goto continue
        end
        for _, product in pairs(recipe.products) do
            if product.name ~= nil then
                if new_items_map[product.name] == nil then
                    new_items_map[product.name] = {
                        recipes = {},
                        type = product.type
                    }
                end
                table.insert(new_items_map[product.name]["recipes"], recipe.name)
            end
        end
        ::continue::
    end
    storage.progressive_productivity = {
        research_bonuses = {},
        items = new_items_map,
        productivity_levels = {}
    }
    return storage.progressive_productivity
end

-- Get research bonuses for a force
function storage_module.get_research_bonuses(force_name)
    return storage.progressive_productivity.research_bonuses[force_name] or {}
end

-- Update research bonuses for a force
function storage_module.update_research_bonuses(force_name, bonuses)
    storage.progressive_productivity.research_bonuses[force_name] = bonuses
end

-- Get items cache
function storage_module.get_items()
    return storage.progressive_productivity.items
end

-- Update items cache
function storage_module.update_items(items)
    if items ~= storage.progressive_productivity.items then
        storage.progressive_productivity.items = items
    end
end

-- Return a table of [item_name] = level for a force
function storage_module.get_cached_productivity_levels(force_name)
    storage.progressive_productivity = storage.progressive_productivity or {}
    storage.progressive_productivity.productivity_levels = storage.progressive_productivity.productivity_levels or {}
    storage.progressive_productivity.productivity_levels[force_name] =
        storage.progressive_productivity.productivity_levels[force_name] or {}

    return storage.progressive_productivity.productivity_levels[force_name]
end

-- Update the cached productivity level for a specific item in a specific force
function storage_module.update_cached_productivity_level(force_name, item_name, new_level)
    storage.progressive_productivity = storage.progressive_productivity or {}
    storage.progressive_productivity.productivity_levels = storage.progressive_productivity.productivity_levels or {}
    storage.progressive_productivity.productivity_levels[force_name] =
        storage.progressive_productivity.productivity_levels[force_name] or {}
    storage.progressive_productivity.productivity_levels[force_name][item_name] = new_level
end

return storage_module
