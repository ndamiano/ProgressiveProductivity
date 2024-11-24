

local items = {}
local fluids = {}

local itemsToSkip = {''}

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
        if settings.startup["progressive-productivity-intermediates-only"].value and recipe.allow_productivity ~= true then
            goto continue
        end
        for _, product in pairs(recipe.products) do
            if product.type == "item" then
                if items[product.name] == nil then
                    items[product.name] = {}
                end
                table.insert(items[product.name], recipe.name)
            end
            if product.type == "fluid" then
                if fluids[product.name] == nil then
                    fluids[product.name] = {}
                end
                table.insert(fluids[product.name], recipe.name)
            end
        end
        ::continue::
    end
    log("Dumping items")
    log(serpent.block(prototypes.item["iron-ore"].group.order))
    log(serpent.dump(prototypes.item["iron-ore"].group.name))
    log("items dumped")
    updateProductivity(0)
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
        cost = math.floor(cost * costMult)
    end
    return productivityBonus
end

function createCache()
    cache["item"] = {}
    cache["fluid"] = {}
    -- For each force
    for forceName, force in pairs(game.forces) do
        -- For each surface
        for surface, _ in pairs(game.surfaces) do
            cachedItemProduction = {}
            -- For each item we care about
            for item, _ in pairs(items) do
                if not cachedItemProduction[item] then
                    cachedItemProduction[item] = 0
                end
                -- Add this surface's produced amount to the cache
                cachedItemProduction[item] = cachedItemProduction[item] + force.get_item_production_statistics(surface).get_input_count(item)
            end
            cache["item"][forceName] = cachedItemProduction
            -- Repeat the process for fluids
            cachedFluidProduction = {}
            for fluid, _ in pairs(fluids) do
                if not cachedFluidProduction[fluid] then
                    cachedFluidProduction[fluid] = 0
                end
                cachedFluidProduction[fluid] = cachedFluidProduction[fluid] + force.get_fluid_production_statistics(surface).get_input_count(fluid)
            end
            cache["fluid"][forceName] = cachedFluidProduction
        end
    end
end

-- FUUUCCCCKKK. This has an issue when recipes have multiple outputs. God damnit.

function updateProductivity(tick)
    log("Updating Productivity on tick " .. tick)
    -- For each force
    for forceName, force in pairs(game.forces) do
        -- For each item
        for item, recipes in pairs(items) do
            -- Get the productivity bonus
            productivityBonus = calculateProductivityBonus("item", item, forceName, tick)
            for _, recipe in pairs(recipes) do
                -- And set it for the recipes
                force.recipes[recipe].productivity_bonus = productivityBonus
            end
        end
    end
    -- Repeat!
    for forceName, force in pairs(game.forces) do
        for fluid, recipes in pairs(fluids) do
            productivityBonus = calculateProductivityBonus("fluid", fluid, forceName, tick)
            for _, recipe in pairs(recipes) do
                force.recipes[recipe].productivity_bonus = productivityBonus
            end
        end
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
    local sorted_item_names = sortItems(items, prototypes)

    -- Process each item in sorted order
    for _, item in ipairs(sorted_item_names) do
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
    for fluid, _ in pairs(fluids) do
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

function sortItems(items, prototypes)
    -- Extract keys (item_names) into a list
    local item_names = {}
    for item_name, _ in pairs(items) do
        table.insert(item_names, item_name)
    end

    -- Custom sorting function
    table.sort(item_names, function(a, b)
        local itemA = prototypes.item[a]
        local itemB = prototypes.item[b]

        -- Define the priority order
        local priority_order = {
            {itemA.group.order, itemB.group.order},
            {itemA.group.name, itemB.group.name},
            {itemA.subgroup.order, itemB.subgroup.order},
            {itemA.subgroup.name, itemB.subgroup.name},
            {itemA.order, itemB.order},
            {itemA.name, itemB.name}
        }

        -- Compare each priority
        for _, pair in ipairs(priority_order) do
            if pair[1] ~= pair[2] then
                return pair[1] < pair[2]
            end
        end

        -- Default: equal items (shouldn't happen unless items are identical)
        return false
    end)

    return item_names
end