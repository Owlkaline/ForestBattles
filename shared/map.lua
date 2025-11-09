local Map = {}

local Floor = require('shared/floor')
local Bounce = require('shared/bounce')

function Map.get_objects(world_size)
    local objects = {};

    local floor_height = 10;
    local floor_width = 160.0;
    local floor_x = -floor_width * 0.5;
    local floor_y = -floor_height;
    objects[0] = Floor.new(floor_x, floor_y, floor_width, floor_height);

    local bounds_thickness = 5.0;
    local width = world_size.width;
    local height = world_size.height;
    local half_height = height * 0.5
    local half_width = width * 0.5
    local half_thickness = bounds_thickness * 0.5;
    local bottom = half_height;
    local top = -half_height;
    local left = -half_width;
    local right = half_width;
    -- left wall
    objects[1] = Bounce.new(left - bounds_thickness, -half_height, bounds_thickness, height);
    -- top
    -- player underneath
    -- height 180 -16 = 164
    -- top top 164+5 = 169
    objects[2] = Bounce.new(left, top - bounds_thickness, width, bounds_thickness);
    -- right
    objects[3] = Bounce.new(right, -half_height, bounds_thickness, height);

    -- 640 x 360
    -- x = -320
    -- width = 640
    -- y = 180
    -- height = 5
    -- bottom
    objects[4] = Bounce.new(left, bottom, width, bounds_thickness);

    return objects
end

return Map
