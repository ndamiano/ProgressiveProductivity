local production_cache = require "utility.production_cache"
local gui_module = {}

-- TODO: Add a close button, then change the toggle approach (E and ESC are already taken care off by the game itself)

---Creates the Progressive Productivity UI
---@param player LuaPlayer
---@param tick int
local function createProgressiveProductivityUI(player, tick)
    -- Creates the gui every time it gets opened. Probably less efficient than saving it, but likely not an actual problem.
    if production_cache.production_statistics[player.force.name] == nil then
        -- TODO make a simple "initializing" UI
        return
    end

    -- Create UI frame
    local screen = player.gui.screen
    local main_frame = screen.add({
        type = "frame",
        name = "progressive_productivty_list",
        caption = "List of recipe productivity bonuses",
        direction = "vertical",
        visible = true,
    })
    main_frame.style.maximal_height = 800
    local scrollable = main_frame.add({
        type = "scroll-pane"
    })
    local table = scrollable.add({
        type = "table",
        name = "item-table",
        column_count = 5
    })

    for item_name, item in pairs(storage.items) do
        local tooltip = {"?", {"item-name."..item_name}, {"fluid-name."..item_name}, {"entity-name."..item_name}}

        local itemFrame = table.add {
            type = "frame",
            name = "item-frame-" .. item_name,
            tooltip = tooltip
        }
        itemFrame.style.minimal_width = 110
        itemFrame.add {
            type = "sprite",
            sprite = item.type .. "/" .. item_name,
            tooltip = tooltip
        }
        level = calculateProductivityLevel(item.type, production_cache.production_statistics[player.force.name][item_name])
        prod_bonus = calculateProductivityAmount(item.type, level)
        itemFrame.add {
            type = "label",
            tooltip = tooltip,
            caption = (prod_bonus * 100) .. "%"
        }
    end

    main_frame.auto_center = true
    player.opened = main_frame
end

---Toggles the visibility of the Progressive Productivity UI
---@param player LuaPlayer|nil
---@param tick int
local function toggleProgressiveProductivityUI(player, tick)
    if player == nil then
        return
    end

    local frame = player.gui.screen.progressive_productivty_list
    if frame == nil then
        createProgressiveProductivityUI(player, tick)
    else
        frame.destroy()
    end
end
gui_module.toggleProgressiveProductivityUI = toggleProgressiveProductivityUI

return gui_module