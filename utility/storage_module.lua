local storage_module = {}

-- Initialize or reset all storage
function storage_module.initialize()
    if not global then
        -- Return a temporary table if global isn't available yet
        return {
            research_bonuses = {},
            items = {}
        }
    end
    
    if not global.progressive_productivity then
        global.progressive_productivity = {
            research_bonuses = {},
            items = {}
        }
    end
    return global.progressive_productivity
end

-- Get research bonuses for a force
function storage_module.get_research_bonuses(force_name)
    local storage = storage_module.initialize()
    return storage.research_bonuses[force_name] or {}
end

-- Update research bonuses for a force
function storage_module.update_research_bonuses(force_name, bonuses)
    local storage = storage_module.initialize()
    if global then
        storage.research_bonuses[force_name] = bonuses
    end
end

-- Get items cache
function storage_module.get_items()
    local storage = storage_module.initialize()
    return storage.items
end

-- Update items cache
function storage_module.update_items(items)
    local storage = storage_module.initialize()
    if global then
        storage.items = items
    end
end

return storage_module
