local production_statistics_cache = {}

local subscribers = {}

production_statistics_cache.production_statistics = {}

local READS_PER_TICK = 50

function production_statistics_cache.on_production_statistics_may_have_changed(subscriber)
    table.insert(subscribers, subscriber)
end

local function cache_storage()
    storage.pp_production_cache = storage.pp_production_cache or {}
    return storage.pp_production_cache
end

local function get_cycle_qualities(refresh, force)
    local cached = refresh.qualities[force.name]
    if cached then
        return cached
    end
    local names = {}
    for _, quality in pairs(prototypes.quality) do
        if force.is_quality_unlocked(quality) then
            names[#names + 1] = quality.name
        end
    end
    refresh.qualities[force.name] = names
    return names
end

local function prune_vanished_items()
    local tracked = storage.progressive_productivity.items
    for item_name, item_data in pairs(tracked) do
        local prototype_category = prototypes[item_data.type]
        if not prototype_category then
            log("no prototypes[" .. item_data.type .. "] found, dropping " .. item_name)
            tracked[item_name] = nil
        elseif not prototype_category[item_name] then
            log("item " .. item_name .. " has vanished")
            tracked[item_name] = nil
        end
    end
end

function production_statistics_cache.schedule_refresh()
    local cache = cache_storage()
    if cache.refresh then
        return
    end

    prune_vanished_items()

    local jobs = {}
    for force_name in pairs(game.forces) do
        for _, surface in pairs(game.surfaces) do
            jobs[#jobs + 1] = { force_name = force_name, surface_index = surface.index }
        end
    end

    cache.refresh = {
        jobs = jobs,
        job_index = 1,
        current = nil,
        results = {},
        qualities = {},
    }
end

local function build_job(job_spec, force, surface)
    local tracked = storage.progressive_productivity.items
    local entries = {}

    local item_stats = force.get_item_production_statistics(surface)
    for product_name in pairs(item_stats.input_counts) do
        local item_data = tracked[product_name]
        if item_data and item_data.type == "item" then
            entries[#entries + 1] = { name = product_name, type = "item" }
        end
    end

    local fluid_stats = force.get_fluid_production_statistics(surface)
    for product_name in pairs(fluid_stats.input_counts) do
        local item_data = tracked[product_name]
        if item_data and item_data.type == "fluid" then
            entries[#entries + 1] = { name = product_name, type = "fluid" }
        end
    end

    if #entries == 0 then
        return nil
    end

    return {
        force_name = job_spec.force_name,
        surface_index = job_spec.surface_index,
        entries = entries,
        cursor = 1,
    }
end

local function publish(cache, refresh)
    cache.published = refresh.results
    cache.refresh = nil
    production_statistics_cache.production_statistics = refresh.results

    for _, subscriber in ipairs(subscribers) do
        subscriber()
    end
end

local function process_refresh_tick()
    local cache = storage.pp_production_cache
    if not cache or not cache.refresh then
        return
    end
    local refresh = cache.refresh

    local budget = READS_PER_TICK
    while budget > 0 do
        local job = refresh.current

        if not job then
            local job_spec = refresh.jobs[refresh.job_index]
            if not job_spec then
                publish(cache, refresh)
                return
            end
            refresh.job_index = refresh.job_index + 1

            local force = game.forces[job_spec.force_name]
            local surface = game.surfaces[job_spec.surface_index]
            if force and force.valid and surface and surface.valid then
                refresh.current = build_job(job_spec, force, surface)
            end
            budget = budget - 1
        else
            local force = game.forces[job.force_name]
            local surface = game.surfaces[job.surface_index]
            if not (force and force.valid and surface and surface.valid) then
                refresh.current = nil
            else
                local item_stats = force.get_item_production_statistics(surface)
                local fluid_stats = force.get_fluid_production_statistics(surface)
                local qualities = get_cycle_qualities(refresh, force)

                refresh.results[job.force_name] = refresh.results[job.force_name] or {}
                local force_results = refresh.results[job.force_name]

                while budget > 0 do
                    local entry = job.entries[job.cursor]
                    if not entry then
                        refresh.current = nil
                        break
                    end
                    job.cursor = job.cursor + 1

                    local count = 0
                    if entry.type == "item" then
                        for _, quality_name in ipairs(qualities) do
                            count = count + item_stats.get_input_count({ name = entry.name, quality = quality_name })
                        end
                        budget = budget - #qualities
                    else
                        count = fluid_stats.get_input_count(entry.name)
                        budget = budget - 1
                    end

                    if count > 0 then
                        force_results[entry.name] = (force_results[entry.name] or 0) + count
                    end
                end
            end
        end
    end
end


script.on_event(defines.events.on_tick, process_refresh_tick)

script.on_event(defines.events.on_force_created, function()
    production_statistics_cache.schedule_refresh()
end)

script.on_load(function()
    local cache = storage.pp_production_cache
    if cache and cache.published then
        production_statistics_cache.production_statistics = cache.published
    end
end)

return production_statistics_cache