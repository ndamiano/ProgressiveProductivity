data:extend({
    {
        type = "custom-input",
        name = "toggle_progressive_productivity_gui",
        key_sequence = "CONTROL + P",
        order = "a"
    },
    {
        type = "shortcut",
        name = "toggle_progressive_productivity_gui_shortcut",
        action = "lua",
        localised_name = {"shortcut.progressive-productivity-toggle-gui"},
        icon = "__base__/graphics/icons/shortcut-toolbar/mip/alt-mode-x56.png",
        icon_size = 56,
        small_icon = "__base__/graphics/icons/shortcut-toolbar/mip/alt-mode-x24.png",
        small_icon_size = 24,
        toggleable = false
    }
})