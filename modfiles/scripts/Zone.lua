-- This is a 'class' representing a specific area that is to be analysed
Zone = {}
Zone.__index = Zone

function Zone.init(player, area)
    local zone = {
        surface = player.surface,
        area = area,
        render_objects = {}
    }
    setmetatable(zone, Zone)

    -- If snapping returns false, the zone is not 2-dimensional
    if not zone:snap_to_grid() then return nil end

    zone:redraw()
    
    return zone
end

-- Runs cleanup before this zone can be dereferenced
function Zone:destroy()
    for _, render_object_id in pairs(self.render_objects) do
        rendering.destroy(render_object_id)
    end
end

-- Redraws everything related to the zone
function Zone:redraw()
    local border_id = self.render_objects.border
    if border_id then rendering.destroy(border_id) end
    self.render_objects.border = renderer.draw_zone_border(self)
end

-- Adjusts the area of the zone to the nearest tile borders
function Zone:snap_to_grid()
    local left_top = self.area.left_top
    left_top.x = math.floor(left_top.x+0.5)
    left_top.y = math.floor(left_top.y+0.5)
    local right_bottom = self.area.right_bottom
    right_bottom.x = math.floor(right_bottom.x+0.5)
    right_bottom.y = math.floor(right_bottom.y+0.5)

    -- Make sure that the zone is two-dimensional
    return (left_top.x < right_bottom.x and left_top.y < right_bottom.y)
end

-- Returns whether the given zone overlaps with this one
function Zone:overlaps_with(zone)
    return (self.surface.name == zone.surface.name and
        math2d.bounding_box.collides_with(self.area, zone.area))
end