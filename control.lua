local settings_cache = require("utility.settings_cache")
local production_cache = require("utility.production_cache")
local productivity_manager = require("utility.productivity_manager")

local function initialize_progressive_productivity()
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
        if settings_cache.settings.intermediates_only and prototypes.recipe[recipe.name].allowed_effects["productivity"] == false then
            goto continue
        end
        for _, product in pairs(recipe.products) do
            if product.name ~= nil then
                new_items_map[product.name] = new_items_map[product.name] or {
                    recipes = {},
                    type = product.type
                }
                table.insert(new_items_map[product.name].recipes, recipe.name)
            end
        end
        ::continue::
    end
    
    storage.progressive_productivity = {
        research_bonuses = {},
        items = new_items_map,
        productivity_levels = {}
    }
end

script.on_configuration_changed(initialize_progressive_productivity)
script.on_init(initialize_progressive_productivity)

script.on_nth_tick(300, function(event)
   production_cache.refresh_production_statistics_cache()
end)

script.on_event(defines.events.on_research_finished, function(event)
    productivity_manager.update_research_bonuses(game.forces[event.research.force.name])
end)