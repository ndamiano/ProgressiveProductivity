data:extend({
	{
		type = "int-setting",
		name = "progressive-productivity-item-cost-base",
		setting_type = "runtime-global",
		minimum_value = 1,
		default_value = 10,
		order = "a"
	},
	{
		type = "double-setting",
		name = "progressive-productivity-item-cost-multiplier",
		setting_type = "runtime-global",
		minimum_value = 1.01,
		default_value = 2,
		order = "b"
	},
	{
		type = "double-setting",
		name = "progressive-productivity-item-productivity-addition",
		setting_type = "runtime-global",
		minimum_value = 0.001,
		default_value = 0.05,
		maximum_value = 1,
		order = "c"
	},
	{
		type = "int-setting",
		name = "progressive-productivity-fluid-cost-base",
		setting_type = "runtime-global",
		minimum_value = 1,
		default_value = 100,
		order = "d"
	},
	{
		type = "double-setting",
		name = "progressive-productivity-fluid-cost-multiplier",
		setting_type = "runtime-global",
		minimum_value = 1.01,
		default_value = 2,
		order = "e"
	},
	{
		type = "double-setting",
		name = "progressive-productivity-fluid-productivity-addition",
		setting_type = "runtime-global",
		minimum_value = 0.001,
		default_value = 0.05,
		maximum_value = 1,
		order = "f"
	},
	{
		type = "bool-setting",
		name = "progressive-productivity-intermediates-only",
		setting_type = "startup",
		default_value = true,
		order = "g"
	}
})
