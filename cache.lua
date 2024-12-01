local CacheUtil = {}

-- Cache the production amounts so we only need to calculate them once per nth tick
local cache = {}
local currentTick = -1

function setupStorage()
    -- Initialize the storages to empty tables
    storage.items = {}
    storage.fluids = {}
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
        if settings.startup["progressive-productivity-intermediates-only"].value and prototypes.recipe[recipe.name].allowed_effects["productivity"] == false then
            goto continue
        end
        for _, product in pairs(recipe.products) do
            if product.type == "item" then
                if storage.items[product.name] == nil then
                    storage.items[product.name] = {}
                end
                table.insert(storage.items[product.name], recipe.name)
            end
            if product.type == "fluid" then
                if storage.fluids[product.name] == nil then
                    storage.fluids[product.name] = {}
                end
                table.insert(storage.fluids[product.name], recipe.name)
            end
        end
        ::continue::
    end
    items = {}
    for item, _ in pairs(storage.items) do
        items[item] = 0
    end
    for item, _ in pairs(storage.fluids) do
        items[item] = 0
    end
    for forceName, _ in pairs(game.forces) do
        otherforceItems = {}
        for k,v in pairs(items) do
            otherforceItems[k] = v
        end
        storage.productivityPercents[forceName] = otherforceItems
    end
    updateProductivity(0)
end
CacheUtil.setupStorage = setupStorage

function createCache()
    cache["item"] = {}
    cache["fluid"] = {}
    -- For each force
    for forceName, force in pairs(game.forces) do
        -- For each surface
        cachedItemProduction = {}
        cachedFluidProduction = {}
        for surface, _ in pairs(game.surfaces) do
            -- For each item we care about
            for item, _ in pairs(storage.items) do
                if not cachedItemProduction[item] then
                    cachedItemProduction[item] = 0
                end
                -- Add this surface's produced amount to the cache
                cachedItemProduction[item] = cachedItemProduction[item] + force.get_item_production_statistics(surface).get_input_count(item)
            end
            cache["item"][forceName] = cachedItemProduction
            -- Repeat the process for fluids
            for fluid, _ in pairs(storage.fluids) do
                if not cachedFluidProduction[fluid] then
                    cachedFluidProduction[fluid] = 0
                end
                cachedFluidProduction[fluid] = cachedFluidProduction[fluid] + force.get_fluid_production_statistics(surface).get_input_count(fluid)
            end
            cache["fluid"][forceName] = cachedFluidProduction
        end
    end
end
CacheUtil.createCache = createCache

---@param type string
---@param item string
---@param force string|int
---@param tick int
function calculateProductivityLevel(type, item, force, tick)
    -- If we're on a new tick, calculate production numbers
    if currentTick ~= tick then
        createCache()
        currentTick = tick
    end
    -- Get the number of an item / fluid produced
    if type == "item" then
        cost_base = settings.global["progressive-productivity-cost-base"].value
        cost_mult = settings.global["progressive-productivity-cost-multiplier"].value
    else
        cost_base = settings.global["progressive-productivity-fluid-cost-base"].value
        cost_mult = settings.global["progressive-productivity-fluid-cost-multiplier"].value
    end
    productionAmount = cache[type][force][item]
    cost = cost_base
    count = 0
    while productionAmount >= cost do
        count = count + 1
        cost = math.ceil(cost * cost_mult)
    end
    return count
end
CacheUtil.calculateProductivityLevel = calculateProductivityLevel

---@param type string
---@param level int
function calculateProductivityAmount(type, level)
    if (type == "item") then
        prod_mult = settings.global["progressive-productivity-productivity-addition"].value
    else
        prod_mult = settings.global["progressive-productivity-fluid-productivity-addition"].value
    end
    return level * prod_mult
end
CacheUtil.calculateProductivityAmount = calculateProductivityAmount

---@param tick int
function updateProductivity(tick)
    -- For each force
    for forceName, force in pairs(game.forces) do
        -- For each type
        for type, table in pairs({item = storage.items, fluid = storage.fluids}) do
            -- For each item
            for item, recipes in pairs(table) do
                -- Get the productivity bonus
                level = calculateProductivityLevel(type, item, forceName, tick)
                prod_bonus = calculateProductivityAmount(type, level)
                for _, recipe in pairs(recipes) do
                    if prod_bonus ~= storage.productivityPercents[forceName][item] then
                        setProductivityAmount(recipe, force, prod_bonus, item)
                    end
                end
            end
        end
    end
end
CacheUtil.updateProductivity = updateProductivity

---@param recipe string
---@param force LuaForce
---@param prod_bonus int
---@param item string
function setProductivityAmount(recipe, force, prod_bonus, item)
    baseProd = force.recipes[recipe].productivity_bonus - storage.productivityPercents[force.name][item]
    force.recipes[recipe].productivity_bonus = baseProd + prod_bonus
    storage.productivityPercents[force.name][item] = prod_bonus
    if force.name == "player" then
        game.print({"", {"mod-message.progressive-productivity-progressed", item, (prod_bonus * 100)}})
    end
end
CacheUtil.setProductivityAmount = setProductivityAmount

return CacheUtil