storage.progressiveProductivityItems = {}
storage.progressiveProductivityFluids = {}

script.on_init(function()
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
        if not recipe.allow_productivity then
            recipe.allow_productivity = false
        end
        if settings.startup["progressive-productivity-intermediates-only"].value and recipe.allow_productivity ~= true then
            goto continue
        end
        for _, product in pairs(recipe.products) do
            if product.type == "item" then
                if storage.progressiveProductivityItems[product.name] == nil then
                    storage.progressiveProductivityItems[product.name] = {}
                end
                table.insert(storage.progressiveProductivityItems[product.name], recipe.name)
            end
            if product.type == "fluid" then
                if storage.progressiveProductivityFluids[product.name] == nil then
                    storage.progressiveProductivityFluids[product.name] = {}
                end
                table.insert(storage.progressiveProductivityFluids[product.name], recipe.name)
            end
        end
        ::continue::
    end
    updateProductivity(0)
end)

script.on_event("on_force_created", function(event)
    createCache()
end)

script.on_nth_tick(300, function(event)
    updateProductivity(event.tick)
end)

-- Cache the production amounts so we only need to calculate them once per nth tick
local cache = {}
local currentTick = -1

-- Get the cost / mult / prod bonus from settings
local prodMult = settings.startup["progressive-productivity-productivity-addition"].value
local costBase = settings.startup["progressive-productivity-cost-base"].value
local costMult = settings.startup["progressive-productivity-cost-multiplier"].value

function calculateProductivityBonus(type, item, force, tick)
    -- If we're on a new tick, calculate production numbers
    if currentTick ~= tick then
        createCache()
        currentTick = tick
    end
    -- Get the number of an item / fluid produced
    productionAmount = cache[type][force][item]
    cost = costBase
    productivityBonus = 0
    while productionAmount >= cost and productivityBonus < 3 do
        productivityBonus = productivityBonus + prodMult
        cost = math.ceil(cost * costMult)
    end
    return productivityBonus
end

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
            for item, _ in pairs(storage.progressiveProductivityItems) do
                if not cachedItemProduction[item] then
                    cachedItemProduction[item] = 0
                end
                -- Add this surface's produced amount to the cache
                cachedItemProduction[item] = cachedItemProduction[item] + force.get_item_production_statistics(surface).get_input_count(item)
            end
            cache["item"][forceName] = cachedItemProduction
            -- Repeat the process for fluids
            for fluid, _ in pairs(storage.progressiveProductivityFluids) do
                if not cachedFluidProduction[fluid] then
                    cachedFluidProduction[fluid] = 0
                end
                cachedFluidProduction[fluid] = cachedFluidProduction[fluid] + force.get_fluid_production_statistics(surface).get_input_count(fluid)
            end
            cache["fluid"][forceName] = cachedFluidProduction
        end
    end
end

local previousRun = {}
function updateProductivity(tick)
    -- For each force
    for forceName, force in pairs(game.forces) do
        local recipeToProductivity = {}
        -- For each item
        for item, recipes in pairs(storage.progressiveProductivityItems) do
            -- Get the productivity bonus
            productivityBonus = calculateProductivityBonus("item", item, forceName, tick)
            for _, recipe in pairs(recipes) do
                -- If the current productivity bonus is higher than the recipe, we check if it's the highest one so far for this recipe
                -- If it is, we add it to the map. Otherwise, continue
                if productivityBonus - force.recipes[recipe].productivity_bonus > 0.1 then
                    local result = {}
                    result["value"] = productivityBonus
                    result["item"] = item
                    if not recipeToProductivity[recipe] or recipeToProductivity[recipe]["value"] < productivityBonus then
                        recipeToProductivity[recipe] = result
                    end
                end
            end
        end
        for fluid, recipes in pairs(storage.progressiveProductivityFluids) do
            productivityBonus = calculateProductivityBonus("fluid", fluid, forceName, tick)
            for _, recipe in pairs(recipes) do
                if productivityBonus - force.recipes[recipe].productivity_bonus > 0.1  then
                    local result = {}
                    result["value"] = productivityBonus
                    result["item"] = fluid
                    if not recipeToProductivity[recipe] or recipeToProductivity[recipe]["value"] < productivityBonus then
                        recipeToProductivity[recipe] = result
                    end
                end
            end
        end
        -- We have all the ones we should actually use, now update the productivity
        for recipe, result in pairs(recipeToProductivity) do
            if (previousRun[recipe] and previousRun[result] == result) then
                goto continue
            end
            force.recipes[recipe].productivity_bonus = result["value"]
            local item = {"?", {"item-name."..result["item"]}, {"entity-name."..result["item"]}, {"fluid-name."..result["item"]}}
            game.print({"", {"mod-message.progressive-productivity-progressed", item, (result["value"] * 100)}})
            ::continue::
        end
        previousRun = recipeToProductivity
    end
end


-- Events for toggling gui on and off
script.on_event("toggle_progressive_productivity_gui", function(event)
    local player = game.get_player(event.player_index)
    toggleProgressiveProductivityUI(player, event.tick)
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == "toggle_progressive_productivity_gui_shortcut" then
        local player = game.get_player(event.player_index)
        toggleProgressiveProductivityUI(player, event.tick)
    end
end)

function toggleProgressiveProductivityUI(player, tick)
    local frame = player.gui.screen.progressive_productivty_list
    if frame == nil then
        createProgressiveProductivityUI(player, tick)
    else
        frame.destroy()
    end
end

-- Create the gui every time it gets opened. Probably less efficient than saving it, but likely not an actual problem. 
function createProgressiveProductivityUI(player, tick)
    -- Create UI frame
    local gui = player.gui.screen
    local main_frame = gui.add{
        type = "frame",
        name = "progressive_productivty_list",
        caption = "List of recipe productivity bonuses",
        direction = "vertical",
        visible = true,
    }
    main_frame.style.maximal_height = 800
    local scrollable = main_frame.add{
        type = "scroll-pane"
    }
    local table = scrollable.add{
        type = "table",
        name = "item-table",
        column_count = 5
    }

    -- Process each item in sorted order
    for item, _ in pairs(storage.progressiveProductivityItems) do
        local itemFrame = table.add{
            type = "frame",
            name = "item-frame-"..item,
            tooltip = {"?", {"item-name."..item}, {"entity-name."..item}}
        }
        itemFrame.style.minimal_width = 110
        itemFrame.add{
            type = "sprite",
            sprite = "item/"..item,
            tooltip = {"?", {"item-name."..item}, {"entity-name."..item}}
        }
        itemFrame.add{
            type = "label",
            tooltip = {"?", {"item-name."..item}, {"entity-name."..item}},
            caption = calculateProductivityBonus("item", item, player.force.name, tick) * 100 .. "%"
        }
    end
    for fluid, _ in pairs(storage.progressiveProductivityFluids) do
        local itemFrame = table.add{
            type = "frame",
            name = "item-frame-"..fluid,
            tooltip = {"?", {"fluid-name."..fluid}, {"entity-name."..fluid}}
        }
        itemFrame.style.minimal_width = 110
        itemFrame.add{
            type = "sprite",
            sprite = "fluid/"..fluid,
            tooltip = {"?", {"fluid-name."..fluid}, {"entity-name."..fluid}}
        }
        itemFrame.add{
            type = "label",
            tooltip = {"?", {"fluid-name."..fluid}, {"entity-name."..fluid}},
            caption = calculateProductivityBonus("fluid", fluid, player.force.name, tick) * 100 .. "%"
        }
    end
    main_frame.auto_center = true
    player.opened = main_frame
end

script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.name == "progressive_productivty_list" then
        local player = game.get_player(event.player_index)
        toggleProgressiveProductivityUI(player)
    end
end)