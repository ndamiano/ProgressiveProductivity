local product_cache = {}

local settings_cache = require("utility.settings_cache")
local production_cache = require("utility.production_cache")

-- Cache the production amounts so we only need to calculate them once per nth tick
local cache = {}
local currentTick = -1

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

function createCache()
    -- For each force
    for forceName, force in pairs(game.forces) do
        -- For each surface
        cachedItemProduction = {}
        for surface, _ in pairs(game.surfaces) do
            -- For each item we care about
            for item_name, item in pairs(storage.items) do
                if not cachedItemProduction[item_name] then
                    cachedItemProduction[item_name] = 0
                end
                -- Add this surface's produced amount to the cache
                if (item.type == "item") then
                    cachedItemProduction[item_name] = cachedItemProduction[item_name] + force.get_item_production_statistics(surface).get_input_count(item_name)
                end
                if (item.type == "fluid") then
                    cachedItemProduction[item_name] = cachedItemProduction[item_name] + force.get_fluid_production_statistics(surface).get_input_count(item_name)
                end
            end
            cache[forceName] = cachedItemProduction
        end
    end
end
product_cache.createCache = createCache

---@param type string
---@param item_name string
---@param force string|int
---@param tick int
function calculateProductivityLevel(type, item_name, force, tick)
    -- If we're on a new tick, calculate production numbers
    if currentTick ~= tick then
        createCache()
        currentTick = tick
    end
    -- Get the number of an item / fluid produced-- Get the amount of an item or fluid produced
    local product_settings = settings_cache.settings[type] --[[@as ProductSettings]]
    local production_amount = cache[force][item_name]
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

---@param tick int
function updateProductivity(tick)
    -- For each force
    for force_name, force in pairs(game.forces) do
        processed_recipes = {}
        -- For each item
        for item_name, item in pairs(storage.items) do
            level = calculateProductivityLevel(item.type, item_name, force_name, tick)
            prod_bonus = calculateProductivityAmount(item.type, level)
            -- For each recipe set prod bonus to expected amount
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
        for recipe_name, prod_bonus in pairs(processed_recipes) do
            if not are_doubles_equal(force.recipes[recipe_name].productivity_bonus, prod_bonus) then
                local display_item_name = {"?", {"item-name."..recipe_name}, {"fluid-name."..recipe_name}, {"entity-name."..recipe_name}, recipe_name}
                game.print({"", {"mod-message.progressive-productivity-progressed", display_item_name, (prod_bonus * 100)}})
                force.recipes[recipe_name].productivity_bonus = prod_bonus
            end
        end
    end
end
product_cache.updateProductivity = updateProductivity

return product_cache