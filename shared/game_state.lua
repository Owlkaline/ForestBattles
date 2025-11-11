local GameState = {};
-- pyom
--2333333rf novcxxmmm9999999999voo       m9999999999999jjjjjjjjjjjjjjjjjjjjj99998                    5 4

local bump = require('lib/bump')
local Networking = require('shared/networking')

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

function GameState.new(starting_frame)
    return {
        players = {},
        objects = {},
        inputs = {},
        world = {},
        frame = starting_frame,
        fixed_dt = Networking.tick_rate
    }
end

function GameState.copy(state)
    local function deepCopy(original)
        if type(original) ~= 'table' then
            return original -- Return non-table values as-is
        end

        local copy = {} -- Create a new table

        local mt = getmetatable(original)
        if mt then
            setmetatable(copy, deepCopy(mt)) -- Deep copy the metatable
        end

        for key, value in next, original, nil do
            copy[deepCopy(key)] = deepCopy(value) -- Recursively copy keys and values
        end

        return copy
    end

    local new_copy = deepCopy(state)
    GameState.new_world(new_copy);

    for _, object in pairs(new_copy.objects) do
        new_copy.world:add(object, object.x, object.y, object.width, object.height)
    end
    for _, player in pairs(new_copy.players) do
        new_copy.world:add(player, player.x, player.y, player.width, player.height)
    end

    return new_copy;
end

function GameState.new_world(state)
    local world = bump.newWorld();
    world:addResponse('push', push)
    world:addResponse('velocity_bounce', velocity_bounce)

    state.world = world
end

function GameState.remove_player(state, idx)
    state.world:remove(state.players[idx]);
    state.players[idx] = nil;
end

function GameState.add_player(state, idx, x, y, width, height, vel_x, vel_y)
    state.players[idx] = {
        x = x,
        y = y,
        width = width,
        height = height,
        velocity = { x = vel_x, y = vel_y },
        inputs = {},
        weight = 8,
        timers = {}
    }
    state.world:add(state.players[idx], x, y, width, height)
end

function GameState.add_object(state, x, y, width, height, isFloor, isWall, isAttackBox)
    state.objects[#state.objects + 1] = {
        x = x,
        y = y,
        width = width,
        height = height,
        isFloor = isFloor,
        isWall = isWall,
        isAttackBox = isAttackBox
    }
    state.world:add(state.objects[#state.objects], x, y, width, height)
end

function GameState.predict_input(state, player_inputs)
    for idx, player in pairs(state.players) do
        if player_inputs[idx] == nil then
            player_inputs[idx] = {}
        end
        local not_caught_up = true;
        local frame_check = state.frame;
        local goal_frame = state.frame;
        while not_caught_up do
            if player_inputs[idx][frame_check] ~= nil then
                if frame_check == goal_frame then
                    break
                end
                player_inputs[idx][frame_check + 1] = player_inputs[idx][frame_check]
                frame_check = frame_check + 1;
            else
                if goal_frame - frame_check > 5 then
                    player_inputs[idx][goal_frame] = {}
                    break;
                end
                frame_check = frame_check - 1;
            end
        end
        player.inputs = player_inputs[idx]
    end
end

function GameState.progress_frame(state, inputs)
    local dt = state.fixed_dt;

    AttackBox.update(state.objects, dt, state.world)
    Players.update_timers(state.players, dt)
    Players.apply_gravity(state.players, dt)
    local objects = Players.input(state.players, inputs, dt);
    Players.move(state.players, dt)
    Players.update_world(state.players, state.world);

    state.frame = state.frame + 1
end

function GameState.replace_inputs(new_state, idx, inputs)
    new_state.players[idx].inputs = inputs;
end

local function inputsAreEqual(table1, table2)
    -- Check if both tables are the same reference
    if table1 == table2 then return true end

    -- Check the length of the tables
    if #table1 ~= #table2 then return false end

    -- Iterate through each key in the first table
    for key, value in pairs(table2) do
        if table1[key] ~= value then
            return key -- Found a difference
        end
    end

    return true -- All checks passed; tables are equal
end

function GameState.matching_inputs(state, player_idx, inputs)
    --if latest_state
    local result = inputsAreEqual(state.players[player_idx].inputs, inputs)
    return result
end

return GameState
