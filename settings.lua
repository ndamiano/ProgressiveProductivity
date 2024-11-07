data:extend({
	{
		type = "int-setting",
		name = "cost-base",
		setting_type = "startup",
		minimum_value = 1,
		default_value = 10,
		order = "a"
	},
	{
		type = "int-setting",
		name = "cost-multiplier",
		setting_type = "startup",
		minimum_value = 2,
		default_value = 2,
		order = "b"
	},
	{
		type = "double-setting",
		name = "productivity-addition",
		setting_type = "startup",
		minimum_value = 0.001,
		default_value = 0.05,
		maximum_value = 1,
		order = "c"
	},
	{
		type = "int-setting",
		name = "fluid-cost-base",
		setting_type = "startup",
		minimum_value = 1,
		default_value = 100,
		order = "d"
	},
	{
		type = "int-setting",
		name = "fluid-cost-multiplier",
		setting_type = "startup",
		minimum_value = 2,
		default_value = 2,
		order = "e"
	},
	{
		type = "double-setting",
		name = "fluid-productivity-addition",
		setting_type = "startup",
		minimum_value = 0.001,
		default_value = 0.05,
		maximum_value = 1,
		order = "f"
	}
})