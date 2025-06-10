local product_cache = {}
local settings_cache = require("utility.settings_cache")
local production_cache = require("utility.production_cache")

function setupStorage()
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
			if new_items_map[product.name] == nil then
				new_items_map[product.name] = {
					recipes = {},
					type = product.type
				}
			end
			table.insert(new_items_map[product.name]["recipes"], recipe.name)
		end
		::continue::
	end
	storage.items = new_items_map
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
	local prod_mult = settings_cache.settings[type].productivity_bonus
	return level * prod_mult
end
product_cache.calculateProductivityAmount = calculateProductivityAmount

local function are_doubles_equal(a, b, epsilon)
	epsilon = epsilon or 1e-4
	return math.abs(a - b) < epsilon
end

-- This function calculates the research bonuses.
function get_research_bonuses_by_recipe(force)
	local recipe_bonuses = {}
	for tech_name, technology in pairs(force.technologies) do
		if technology.level > 1 and string.match(technology.name, "-productivity") then
			for _, effect in pairs(technology.prototype.effects) do
				if effect.type == "change-recipe-productivity" then
					local recipe_name = effect.recipe
					local change_per_level = effect.change or 0
					local total_bonus = change_per_level * (technology.level - 1)
					recipe_bonuses[recipe_name] = (recipe_bonuses[recipe_name] or 0) + total_bonus
				end	
			end
			-- DEBUG game.print(string.format("%s, %.2f", technology.name, technology.level * 10))
		end
	end
	return recipe_bonuses
end

production_cache.on_production_statistics_may_have_changed(function()
	for force_name, production_values in pairs(production_cache.production_statistics) do
		local force = game.forces[force_name]
		if not force then goto continue_force_loop end

		setupStorage()

		-- STEP 1: Get the base productivity from vanilla/other mod research.
		local research_bonuses = get_research_bonuses_by_recipe(force)
		-- TODO: Extract this from on_production_statistics and put it in its own cache (storage.research) and update it on_research_completed to save some UPS
			
		-- STEP 2: Calculate what this mod's bonus *should* be for each recipe.
		local should_be_mod_bonuses = {}
		for item_name, production_count in pairs(production_values) do
			if production_count > 0 then
				local item_data = storage.items[item_name]
				if item_data then
					local level = calculateProductivityLevel(item_data.type, production_count)
					local mod_bonus = calculateProductivityAmount(item_data.type, level)
					for _, recipe_name in pairs(item_data.recipes) do
						should_be_mod_bonuses[recipe_name] = math.max(should_be_mod_bonuses[recipe_name] or 0, mod_bonus)
					end
				end
			end
		end
		-- STEP 3: Apply the calculations
		for recipe_name, recipe in pairs(force.recipes) do
			if recipe.valid and recipe.enabled then
				local research_bonus = research_bonuses[recipe_name] or 0
				local mod_bonus = should_be_mod_bonuses[recipe_name] or 0
				local prod_bonus = research_bonus + mod_bonus
				if not are_doubles_equal(recipe.productivity_bonus, prod_bonus) then
					local display_item_name = {"?", {"item-name."..recipe_name}, {"fluid-name."..recipe_name}, {"entity-name."..recipe_name}, recipe_name}
					-- This is because Factorio internally floors productivity_bonus to 2 decimal places. This causes 1.05 to (which is a float equal to 1.0499999523162841796875) to round to 1.04, causing many notifications
					game.print({"", {"mod-message.progressive-productivity-progressed", display_item_name, (prod_bonus * 100)}})
					prod_bonus = prod_bonus + 0.00001
					recipe.productivity_bonus = prod_bonus
				end
			end
		end
		::continue_force_loop::
	end
end)
return product_cache
