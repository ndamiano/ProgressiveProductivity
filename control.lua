local storage_module = require("utility.storage_module")
local production_cache = require("utility.production_cache")
local product_cache = require("utility.product_cache")

-- When recipes could have changed or when we are initialized, create our local storage
script.on_configuration_changed(function(event)
   storage_module.initialize()
end)

script.on_init(function()
   storage_module.initialize()
end)

script.on_nth_tick(300, function(event)
   production_cache.refresh_production_statistics_cache()
end)

script.on_event(defines.events.on_research_finished, function(event)
    product_cache.update_research_bonuses(game.forces[event.research.force.name])
end)