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
        force = game.forces[force_name]
        processed_recipes = {}
        for item_name, production_count in pairs(production_values) do
            if production_count > 0 then
                item = storage.items[item_name]
                level = calculateProductivityLevel(item.type, production_count)
                prod_bonus = calculateProductivityAmount(item.type, level)
                for _, recipe_name in pairs(item.recipes) do
                    recipe = force.recipes[recipe_name]
                    if processed_recipes[recipe_name] == nil then
                        processed_recipes[recipe_name] = prod_bonus
                    end
                    if processed_recipes[recipe_name] < prod_bonus then
                        processed_recipes[recipe_name] = prod_bonus
                    end
                end
            end
        end
        for recipe_name, prod_bonus in pairs(processed_recipes) do
            if not are_doubles_equal(force.recipes[recipe_name].productivity_bonus, prod_bonus) then
                local display_item_name = {"?", {"item-name."..recipe_name}, {"fluid-name."..recipe_name}, {"entity-name."..recipe_name}, recipe_name}
                game.print({"", {"mod-message.progressive-productivity-progressed", display_item_name, (prod_bonus * 100)}})
                force.recipes[recipe_name].productivity_bonus = prod_bonus
            end
        end
    end
end)

return product_cache