local product_cache = {}
local settings_cache = require("utility.settings_cache")
local production_cache = require("utility.production_cache")
-- This function populates the storage items table with a map of items to recipies.
function setupStorage()
	if global.storage.items == nil then global.storage.items = {} end
	if global.storage.productivityPercents == nil then global.storage.productivityPercents = {} end
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
			if global.storage.items[product.name] == nil then
				global.storage.items[product.name] = {
					recipes = {},
					type = product.type
				}
			end
			table.insert(global.storage.items[product.name]["recipes"], recipe.name)
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
	if global.storage.first_start then
        	global.storage.first_start = nil
        	local playerForce = game.forces['player']
		
		-- check if modded first, if its modded global.storage.items should be there. Affects migration.
 		local is_unmodded_save = (global.storage.items == nil or next(global.storage.items) == nil)
		if is_unmodded_save then game.print("Progressive Productivity: Starting initial calculations...")
		else game.print("Progressive Productivity: Starting migration") end
        	setupStorage()
		global.storage.productivityPercents = {} -- must be clear

        	-- STEP 1: Calculate what the current production values for each recipe.
        	local should_be_mod_bonuses = {}
        	local current_production_values = {}
        	for _, surface in pairs(game.surfaces) do
            		local item_stats = playerForce.get_item_production_statistics(surface)
            		local fluid_stats = playerForce.get_fluid_production_statistics(surface)
            		for item_name, _ in pairs(global.storage.items) do
                		current_production_values[item_name] = (current_production_values[item_name] or 0)
                                                    + item_stats.get_input_count(item_name)
                                                    + fluid_stats.get_input_count(item_name)
            		end
       		end
		-- STEP 2: Calculate what the mod bonus *should* be for each recipe attached to that item (eg multiple fuel recipes).
        	for item_name, production_count in pairs(current_production_values) do
            		if production_count > 0 then
                		local item_data = global.storage.items[item_name]
                		if item_data then
                    			local level = calculateProductivityLevel(item_data.type, production_count)
                    			local mod_bonus = calculateProductivityAmount(item_data.type, level)
                    			for _, recipe_name in pairs(item_data.recipes) do
                        			should_be_mod_bonuses[recipe_name] = math.max(should_be_mod_bonuses[recipe_name] or 0, mod_bonus)
                    			end
                		end
            		end
        	end
		-- STEP 3: Apply bonuses depending on migration conditions.
        	for recipe_name, recipe in pairs(playerForce.recipes) do
            		if recipe.valid and recipe.enabled then
                		local new_bonus = should_be_mod_bonuses[recipe_name] or 0
				if is_unmodded_save then
					-- add the bonus to unmodded
                    			recipe.productivity_bonus = (recipe.productivity_bonus or 0) + new_bonus
                		else
					-- take the max when migrating (preserves other productivity sources)
					recipe.productivity_bonus = math.max(new_bonus, recipe.productivity_bonus or 0)
 				end
                             	if new_bonus > 0 then
                    			global.storage.productivityPercents[recipe_name] = new_bonus
                		end
            		end
        	end
        	return
    	end

    for force_name, production_values in pairs(production_cache.production_statistics) do
        local force = game.forces[force_name]
        if not force then goto continue_force_loop end -- Safety check for cases like force being destroyed

        local processed_recipes = {} -- Stores the highest calculated `prod_bonus` for each recipe

        for item_name, production_count in pairs(production_values) do
            if production_count > 0 then
                local item_data = global.storage.items[item_name]
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
            local mod_previous_bonus_applied = global.storage.productivityPercents[recipe_name] or 0
            local base_productivity_from_research = current_total_recipe_bonus - mod_previous_bonus_applied
            local calculated_total_bonus = base_productivity_from_research + new_mod_prod_bonus_target

            -- Compare with a small epsilon to avoid unnecessary updates and notifications
            -- due to floating-point precision issues in Factorio's internal API.
            if not are_doubles_equal(current_total_recipe_bonus, calculated_total_bonus) then
                local display_item_name = {"?", {"item-name."..recipe_name}, {"fluid-name."..recipe_name}, {"entity-name."..recipe_name}, recipe_name}
                local display_value = string.format("%.2f", calculated_total_bonus * 100)
 		game.print({"", {"mod-message.progressive-productivity-progressed", display_item_name, display_value}})
                recipe.productivity_bonus = calculated_total_bonus
                global.storage.productivityPercents[recipe_name] = new_mod_prod_bonus_target
            end
            ::continue_recipe_loop::
        end
        ::continue_force_loop::
    end
end)

return product_cache
