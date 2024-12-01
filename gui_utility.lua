local GUI = {}

---@param player ?LuaPlayer
---@param tick int
function GUI.toggleProgressiveProductivityUI(player, tick)
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

    currentLevels = storage.productivityPercents[player.force.name]
    -- For each type
    for type, cache in pairs({item = storage.items, fluid = storage.fluids }) do
        -- Process each item in sorted order
        for item, _ in pairs(cache) do
            local tooltip = {"?", {"item-name."..item}, {"fluid-name."..item}, {"entity-name."..item}}
            local itemFrame = table.add{
                type = "frame",
                name = "item-frame-"..item,
                tooltip = tooltip
            }
            itemFrame.style.minimal_width = 110
            itemFrame.add{
                type = "sprite",
                sprite = type.."/"..item,
                tooltip = tooltip
            }
            itemFrame.add{
                type = "label",
                tooltip = tooltip,
                caption = currentLevels[item] * 100 .. "%"
            }
        end
    end
    main_frame.auto_center = true
    player.opened = main_frame
end

return GUI