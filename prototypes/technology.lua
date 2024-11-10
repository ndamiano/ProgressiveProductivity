local items = {}
local fluids = {}
for _, recipe in pairs(data.raw["recipe"]) do
	if recipe.results == nil or recipe.name:match"empty.*barrel" or recipe.name:match".+barrel" then 
		goto continue
	end
	log(serpent.block(recipe))
	if settings.startup["progressive-productivity-intermediates-only"].value and recipe.allow_productivity ~= true then
		goto continue
	end
	for _, product in pairs(recipe.results) do
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

local prodMult = settings.startup["progressive-productivity-productivity-addition"].value
local costBase = settings.startup["progressive-productivity-cost-base"].value
local costMult = settings.startup["progressive-productivity-cost-multiplier"].value
local maxInt = 2^31 - 1
local cost = costBase
local i = 0

-- If the cost goes over max int it breaks
while cost <= maxInt do
	for item, recipes in pairs(items) do
		local effects = {}
		for _, recipe in pairs(recipes) do
			table.insert(effects, 
			  {
				type = "change-recipe-productivity",
				recipe = recipe,
				change = prodMult
			  })
		end
		data:extend({{
			type = "technology",
			name = item .. "-progressive-productivity-"..i,
			localised_name = {"", {"?", {"item-name."..item}, {"entity-name."..item}}, " productivity"},
			icons = util.technology_icon_constant_recipe_productivity("__base__/graphics/technology/productivity-module-3.png"),
			icon_size = 256,
			effects = effects,
			research_trigger =
			{
			  type = "craft-item",
			  item = item,
			  count = cost
			},
			upgrade = true,
			hidden = true,
			essential = false
		}})
	end
	i = i + 1
	cost = costBase * (costMult^i)
end

-- Same loop, but separate for fluids, as they may have different values
prodMult = settings.startup["progressive-productivity-fluid-productivity-addition"].value
costBase = settings.startup["progressive-productivity-fluid-cost-base"].value
costMult = settings.startup["progressive-productivity-fluid-cost-multiplier"].value
maxInt = 2^31 - 1
cost = costBase
i = 0

while cost <= maxInt do
	for fluid, recipes in pairs(fluids) do
		local effects = {}
		for _, recipe in pairs(recipes) do
			table.insert(effects, 
			  {
				type = "change-recipe-productivity",
				recipe = recipe,
				change = prodMult
			  })
		end
		data:extend({{
			type = "technology",
			name = fluid .. "-progressive-productivity-"..i,
			localised_name = {"", {"fluid-name."..fluid}, " productivity"},
			icons = util.technology_icon_constant_recipe_productivity("__base__/graphics/technology/productivity-module-3.png"),
			icon_size = 256,
			effects = effects,
			research_trigger =
			{
			  type = "craft-fluid",
			  fluid = fluid,
			  amount = cost
			},
			upgrade = true,
			hidden = true,
			essential = false
		}})
	end
	i = i + 1
	cost = costBase * (costMult^i)
end