math2d = require("math2d")  -- base game lualib

require("scripts.handler")
require("scripts.events")
require("scripts.gui")

require("scripts.Zone")
require("scripts.Schedule")
require("scripts.Entity")

DEVMODE = true  -- Enables certain conveniences for development
REDRAW_CYCLE_RATE = 120

if DEVMODE then
    LLOG_EXCLUDES = {}
end

-- ** DATA **
DATA = { status_to_statistic = {} }

DATA.type_to_category = {
    ["assembling-machine"] = "assembler",
    ["rocket-silo"] = "assembler",
    ["furnace"] = "assembler",
    ["lab"] = "lab",
    ["mining-drill"] = "mining_drill",
    ["inserter"] = "inserter"
}


DATA.status_to_statistic.assembler = {
    [defines.entity_status.working] = "working",
    [defines.entity_status.fluid_production_overload] = "output_overload",
    [defines.entity_status.item_production_overload] = "output_overload",
    [defines.entity_status.fluid_ingredient_shortage] = "input_shortage",
    [defines.entity_status.item_ingredient_shortage] = "input_shortage",
    [defines.entity_status.no_power] = "insufficient_power",
    [defines.entity_status.no_fuel] = "insufficient_power",
    [defines.entity_status.low_power] = "insufficient_power",
    [defines.entity_status.no_recipe] = "disabled",
    [defines.entity_status.disabled_by_script] = "disabled",
    [defines.entity_status.marked_for_deconstruction] = "disabled",
    [defines.entity_status.waiting_to_launch_rocket] = "disabled"
}

DATA.status_to_statistic.lab = {
    [defines.entity_status.working] = "working",
    [defines.entity_status.missing_science_packs] = "input_shortage",
    [defines.entity_status.no_power] = "insufficient_power",
    [defines.entity_status.no_fuel] = "insufficient_power",
    [defines.entity_status.low_power] = "insufficient_power",
    [defines.entity_status.no_research_in_progress] = "disabled",
    [defines.entity_status.disabled_by_script] = "disabled",
    [defines.entity_status.marked_for_deconstruction] = "disabled"
}

DATA.status_to_statistic.mining_drill = {
    [defines.entity_status.working] = "working",
    [defines.entity_status.no_minable_resources] = "input_shortage",
    [defines.entity_status.missing_required_fluid] = "input_shortage",
    [defines.entity_status.waiting_for_space_in_destination] = "output_overload",
    [defines.entity_status.no_power] = "insufficient_power",
    [defines.entity_status.no_fuel] = "insufficient_power",
    [defines.entity_status.low_power] = "insufficient_power",
    [defines.entity_status.disabled_by_control_behavior] = "disabled",
    [defines.entity_status.disabled_by_script] = "disabled",
    [defines.entity_status.marked_for_deconstruction] = "disabled"
}

DATA.status_to_statistic.inserter = {
    [defines.entity_status.working] = "working",
    [defines.entity_status.waiting_for_source_items] = "input_shortage",
    [defines.entity_status.waiting_for_space_in_destination] = "output_overload",
    [defines.entity_status.no_power] = "insufficient_power",
    [defines.entity_status.no_fuel] = "insufficient_power",
    [defines.entity_status.low_power] = "insufficient_power",
    [defines.entity_status.disabled_by_control_behavior] = "disabled",
    [defines.entity_status.disabled_by_script] = "disabled",
    [defines.entity_status.marked_for_deconstruction] = "disabled"
}


function DATA.statistics_template()
    return {
        working = 0,
        output_overload = 0,
        input_shortage = 0,
        insufficient_power = 0,
        disabled = 0
    }
end

-- Defines order and color of the status-categories
DATA.render_parameters = {
    [1] = {
        name = "working",
        color = {0, 135, 0}
    },
    [2] = {
        name = "output_overload",
        color = {102, 224, 0}
    },
    [3] = {
        name = "input_shortage",
        color = {255, 165, 0}
    },
    [4] = {
        name = "insufficient_power",
        color = {204, 0, 0}
    },
    [5] = {
        name = "disabled",
        color = {204, 0, 204}
    }
}


-- ** LLOG **
-- Internally used logging function for a single table
local function _llog(table)
    local excludes = LLOG_EXCLUDES or {}  -- Optional custom excludes defined by the parent mod

    if type(table) ~= "table" then return (tostring(table)) end

    local tab_width, super_space = 2, ""
    for _=0, tab_width-1, 1 do super_space = super_space .. " " end

    local function format(table, depth)
        if table_size(table) == 0 then return "{}" end

        local spacing = ""
        for _=0, depth-1, 1 do spacing = spacing .. " " end
        local super_spacing = spacing .. super_space

        local out, first_element = "{", true
        local preceding_name = 0

        for name, value in pairs(table) do
            local element = tostring(value)
            if type(value) == "string" then
                element = "'" .. element .. "'"
            elseif type(value) == "table" then
                if excludes[name] ~= nil then
                    element = value.name or "EXCLUDE"
                else
                    element = format(value, depth+tab_width)
                end
            end

            local comma = (first_element) and "" or ","
            first_element = false

            -- Print string and continuous numerical keys only
            local key = (type(name) == "number" and preceding_name+1 ~= name) and "" or (name .. " = ")
            preceding_name = name

            out = out .. comma .. "\n" .. super_spacing .. key .. element
        end

        return (out .. "\n" .. spacing .. "}")
    end

    return format(table, 0)
end

-- User-facing function, handles multiple tables at being passed at once
function llog(...)
    local info = debug.getinfo(2, "Sl")
    local out = "\n" .. info.short_src .. ":" .. info.currentline .. ":"

    local arg_nr = table_size({...})
    if arg_nr == 0 then
        out = out .. " No arguments"
    elseif arg_nr == 1 then
        out = out .. " " .. _llog(select(1, ...))
    else
        for index, table in ipairs{...} do
            out = out .. "\n" .. index .. ": " ..  _llog(table)
        end
    end

    log(out)
end