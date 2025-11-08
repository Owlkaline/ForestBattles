local bump = require('lib/bump')

local simulation = {};

local push = function(world, col, x, y, w, h, goalX, goalY, filter)
    goalX           = goalX or x
    goalY           = goalY or y

    local tch, move = col.touch, col.move

    local is_below  =
        col.item.y - col.other.y > 0

    if col.other.grounded and (col.normal.y ~= 0 or col.normal.x ~= 0) then
        if col.item.x > col.other.x then
            goalX = col.item.x + col.other.width * (0.1 * DefaultWeight) / col.other.weight
        else
            goalX = col.item.x - col.other.width * (0.1 * DefaultWeight) / col.other.weight;
        end
    end

    col.push        = { x = goalX, y = goalY }

    local cols, len = world:project(col.item, x, y, w, h, goalX, goalY, filter)

    if col.item.grounded then
        if col.item.x > col.other.x then
            col.other.x = goalX - col.other.width;
        else
            col.other.x = goalX + col.item.width;
        end
    end

    return goalX, goalY, cols, len
end

local velocity_bounce = function(world, col, x, y, w, h, goalX, goalY, filter)
    goalX = goalX or x
    goalY = goalY or y

    local tch, move = col.touch, col.move
    local tx, ty = tch.x, tch.y

    local bx, by = tx, ty

    goalX = tch.x;
    goalY = tch.y;

    if col.normal.x ~= 0 then
        col.item.velocity.x = col.normal.x * 300.0;
        col.item.velocity.y = -300.0;
    end
    if col.normal.y ~= 0 then
        local diff = col.item.x - col.other.x - col.other.width * 0.5;
        col.item.velocity.x = -Sign(diff) * 300; --math.min(math.abs(diff), 300.0);
        col.item.velocity.y = col.normal.y * 300.0;
    end

    local cols, len = world:project(col.item, x, y, w, h, goalX, goalY, filter)
    return goalX, goalY, cols, len
end

function simulation.new(tick_rate)
    local world = bump.newWorld();
    world:addResponse('push', push)
    world:addResponse('velocity_bounce', velocity_bounce)

    local sim = {
        world = world,
        players = {},
        objects = {},
        attack_boxs = {},
        tick = 0,
        tick_rate = tick_rate,
        dt = 0,
    }

    return sim;
end

function simulation.spawn_player(sim, index, character)
    local player = Players.new(0 * (index * 10), -10.0, character);

    player.index = index;
    sim.players[index] = player;
    sim.world:add(sim.players[index], player.x, player.y, player.width, player.height)

    return player.x, player.y
end

function simulation.despawn_player(sim, index)
    sim.world:remove(sim.players[index]);
    sim.players[index] = nil
end

function simulation.spawn_object(sim, new_object)
    sim.objects[#sim.objects + 1] = new_object;
    sim.world:add(sim.objects[#sim.objects], new_object.x, new_object.y, new_object.width, new_object.height);
end

function simulation.add_input(sim, player_num, tick, input)
    sim.players[player_num].inputs[tick] = input;
end

function simulation.set_tick(sim, new_tick)
    sim.tick = new_tick
end

function simulation.update_player_state(sim, idx, state)
    simulation.set_player_position(sim, state.x, state.y, idx)
    simulation.set_player_damage(sim, state.damage, idx)
    sim.players[idx].velocity.x = state.vel_x;
    sim.players[idx].velocity.y = state.vel_y;
    sim.players[idx].facing_left = state.facing_left;
end

function simulation.set_player_position(sim, x, y, index)
    sim.players[index].x = x;
    sim.players[index].y = y;
    sim.players[index].velocity.x = 0;
    sim.players[index].velocity.y = 0;
    sim.world:update(sim.players[index], x, y)
    Players.update_world(sim.players, sim.world);
    --sim.world:move(sim.players[index], x, y)
end

function simulation.set_player_damage(sim, damage, index)
    sim.players[index].damage = damage;
end

function simulation.current_tick(sim)
    return sim.tick
end

function simulation.objects(sim)
    return sim.objects
end

function simulation.players(sim)
    return sim.players
end

function simulation.update(sim)
    -- run everything from current tick
    AttackBox.update(sim.attack_boxs, sim.tick_rate, sim.world)
    Players.update_timers(sim.players, sim.tick_rate)
    Players.apply_gravity(sim.players, sim.tick_rate)
    local objects = Players.input(sim.players, sim.world, sim.attack_boxs, sim.tick, sim.tick_rate);
    Players.move(sim.players, sim.tick_rate)
    Players.update_world(sim.players, sim.world);

    return objects
end

-- Lock step update functions
function simulation.lockstep_update(sim, dt)
    local did_update = false;
    local new_objects = {}
    sim.dt = sim.dt + dt;

    if sim.dt >= sim.tick_rate then
        local progress_game = true;

        -- check for inputs
        for i, player in pairs(sim.players) do
            if player.inputs[sim.tick] == nil then
                progress_game = false;
            end
        end

        if progress_game then
            sim.dt = sim.dt - sim.tick_rate;
            new_objects = simulation.update(sim)
            did_update = true;
            sim.tick = sim.tick + 1;
        end
    end

    return did_update, new_objects
end

function simulation.update_tick_only(sim, dt)
    local did_update = false;
    local new_objects = {}

    sim.dt = sim.dt + dt;

    if sim.dt >= sim.tick_rate then
        sim.dt = sim.dt - sim.tick_rate;
        sim.tick = sim.tick + 1;
        did_update = true
    end

    return did_update, new_objects
end

-- Yolo update funciton
function simulation.yolo_update(sim, dt) --love.update(dt)
    local did_update = false;
    local new_objects = {}

    sim.dt = sim.dt + dt;

    if sim.dt >= sim.tick_rate then
        sim.dt = sim.dt - sim.tick_rate;

        new_objects = simulation.update(sim)
        sim.tick = sim.tick + 1;
        did_update = true
    end

    return did_update, new_objects
end

return simulation
