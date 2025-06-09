local product_cache = {}

local settings_cache = require("utility.settings_cache")
local production_cache = require("utility.production_cache")

-- This function creates a map of item to recipe 
function setupStorage()
    storage.items = {}
    storage.productivityPercents = {}
    -- Get our list of item -> recipe
    playerForce = game.forces['player']
    recipes = playerForce.recipes
    for _, recipe in pairs(recipes) do
        if recipe.products == nil or recipe.name:match"empty.*barrel" or recipe.name:match".+barrel" then 
            goto continue
        end
        if recipe.name:match".*recycling" then
            goto continue
        end
        if settings.startup['progressive-productivity-intermediates-only'].value and prototypes.recipe[recipe.name].allowed_effects["productivity"] == false then
            goto continue
        end
        for _, product in pairs(recipe.products) do
            if storage.items[product.name] == nil then
                storage.items[product.name] = {
                    recipes = {},
                    type = product.type
                }
            end
            table.insert(storage.items[product.name]["recipes"], recipe.name)
        end
        ::continue::
    end
end
product_cache.setupStorage = setupStorage

---@param type string
---@param production_amount number
function calculateProductivityLevel(type, production_amount)
    -- Get the number of an item / fluid produced-- Get the amount of an item or fluid produced
    local product_settings = settings_cache.settings[type] --[[@as ProductSettings]]
    local cost = product_settings.cost_base
    local level = 0
    while production_amount >= cost do
        level = level + 1
        cost = math.ceil(cost * product_settings.cost_multiplier)
    end
    return level
end
product_cache.calculateProductivityLevel = calculateProductivityLevel

---@param type string
---@param level int
function calculateProductivityAmount(type, level)
    prod_mult = settings_cache.settings[type].productivity_bonus
    return level * prod_mult
end
product_cache.calculateProductivityAmount = calculateProductivityAmount

local function are_doubles_equal(a, b, epsilon)
    epsilon = epsilon or 1e-4  -- Default epsilon value
    return math.abs(a - b) < epsilon
end

production_cache.on_production_statistics_may_have_changed(function()
    for force_name, production_values in pairs(production_cache.production_statistics) do
        local force = game.forces[force_name]
        if not force then goto continue_force_loop end -- Safety check for cases like force being destroyed

        local processed_recipes = {} -- Stores the highest calculated `prod_bonus` for each recipe

        for item_name, production_count in pairs(production_values) do
            if production_count > 0 then
                local item_data = storage.items[item_name]
                if not item_data then
                    -- This item might be produced but not tracked by your setupStorage (e.g., filtered out)
                    goto continue_item_loop
                end

                local level = calculateProductivityLevel(item_data.type, production_count)
                local mod_calculated_prod_bonus = calculateProductivityAmount(item_data.type, level)

                for _, recipe_name in pairs(item_data.recipes) do
                    -- Ensure `processed_recipes` stores the *maximum* bonus from any of its products
                    processed_recipes[recipe_name] = math.max(processed_recipes[recipe_name] or 0, mod_calculated_prod_bonus)
                end
            end
            ::continue_item_loop::
        end

        for recipe_name, new_mod_prod_bonus_target in pairs(processed_recipes) do
            local recipe = force.recipes[recipe_name]
            if not recipe or not recipe.valid or not recipe.enabled then
                goto continue_recipe_loop -- Skip invalid/disabled recipes
            end

            local current_total_recipe_bonus = recipe.productivity_bonus or 0
            local mod_previous_bonus_applied = storage.productivityPercents[recipe_name] or 0
            local base_productivity_from_research = current_total_recipe_bonus - mod_previous_bonus_applied
            local calculated_total_bonus = base_productivity_from_research + new_mod_prod_bonus_target

            -- Compare with a small epsilon to avoid unnecessary updates and notifications
            -- due to floating-point precision issues in Factorio's internal API.
            if not are_doubles_equal(current_total_recipe_bonus, calculated_total_bonus) then
                local display_item_name = {"?", {"item-name."..recipe_name}, {"fluid-name."..recipe_name}, {"entity-name."..recipe_name}, recipe_name}
                local display_value = string.format("%.2f", calculated_total_bonus * 100)
 		game.print({"", {"mod-message.progressive-productivity-progressed", display_item_name, display_value}})
                recipe.productivity_bonus = calculated_total_bonus
                storage.productivityPercents[recipe_name] = new_mod_prod_bonus_target
            end
            ::continue_recipe_loop::
        end
        ::continue_force_loop::
    end
end)


return product_cache
