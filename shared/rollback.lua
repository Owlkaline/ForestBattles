local Rollback = {}

local GameState = require('shared/game_state')

Events = {
  AddPlayer = 1,
  RemovePlayer = 2,
  AddObject = 3,
}

function Rollback.new(starting_frame)
  local game_states = {};
  game_states[starting_frame] = GameState.new(starting_frame)
  GameState.new_world(game_states[starting_frame])

  return {
    game_states = game_states,
    events = {},
    object_id = 1,
  }
end

function Rollback.add_object(rb, frame, x, y, width, height, isFloor, isWall, isAttackBox)
  rb.object_id = rb.object_id + 1;

  Rollback.add_object_with_id(rb, frame, rb.object_id, x, y, width, height, isFloor, isWall, isAttackBox);

  return rb.object_id
end

function Rollback.add_object_with_id(rb, frame, idx, x, y, width, height, isFloor, isWall, isAttackBox)
  print("objects before rb add_object " .. #rb.game_states[frame].objects)
  GameState.add_object(rb.game_states[frame], idx, x, y, width, height, isFloor, isWall, isAttackBox)
  print("objects after rb add_object " .. #rb.game_states[frame].objects)
  if rb.events[frame] == nil then
    rb.events[frame] = {}
  end

  print("object idx: " .. idx)
  table.insert(rb.events[frame], idx, { type = Events.AddObject, idx = idx })
end

function Rollback.add_player(rb, frame, idx, x, y, width, height, vel_x, vel_y)
  GameState.add_player(rb.game_states[frame], idx, x, y, width, height, vel_x, vel_y)
  if rb.events[frame] == nil then
    rb.events[frame] = {}
  end
  table.insert(rb.events[frame], idx, { type = Events.AddPlayer, idx = idx })
end

function Rollback.remove_player(rb, frame, idx)
  GameState.remove_player(rb.game_states[frame], idx)
  if rb.events[frame] == nil then
    rb.events[frame] = {}
  end
  table.insert(rb.events[frame], idx, { type = Events.RemovePlayer, idx = idx })
end

function Rollback.get_all_player_inputs(rb)
  local newest_state = Rollback.latest_state(rb)
  local all_inputs = {};
  for idx, player in pairs(newest_state.players) do
    all_inputs[idx] = player.inputs;
  end

  return all_inputs
end

function Rollback.get_object_from_frame(rb, frame, object_idx)
  return Rollback.get_game_state_at_frame(rb, frame).objects[object_idx]
end

function Rollback.get_player_from_frame(rb, frame, player_idx)
  return Rollback.get_game_state_at_frame(rb, frame).players[player_idx]
end

function Rollback.latest_state(rb)
  return rb.game_states[Rollback.latest_frame(rb)]
end

function Rollback.latest_frame(rb)
  local latest_frame = 0;
  for frame, _ in pairs(rb.game_states) do
    if latest_frame < frame then
      latest_frame = frame
    end
  end
  return latest_frame
end

function Rollback.progress_frame(rb, player_inputs, frame)
  local new_state = GameState.copy(Rollback.get_game_state_at_frame(rb, frame))
  --if #new_state.players == 0 then
  --    return
  --end

  Rollback.update_game(new_state, player_inputs)

  rb.game_states[frame + 1] = new_state;
end

function Rollback.get_game_state_at_frame(rb, frame)
  return rb.game_states[frame]
end

function Rollback.update_game(new_state, player_inputs)
  --GameState.predict_input(new_state, player_inputs)
  GameState.progress_frame(new_state, player_inputs)
end

function Rollback.add_input(rb, idx, frame, input)
  if frame > #rb.game_states then
    -- this is in the future, we will get there
    print("future frame discarding")
    return
  end
  local player_inputs = rb.game_states[frame].players[idx].inputs;
  player_inputs[frame] = input;

  Rollback.update_inputs(rb, idx, player_inputs)
end

--function Rollback.update_inputs(rb, idx, inputs)
--    print("rollback update inputs")
--    local inputs_not_matching = true
--
--    local frame = #rb.game_states;
--
--    while inputs_not_matching do
--        local state = rb.game_states[frame];
--
--        local result = GameState.matching_inputs(state, idx, inputs);
--        if result == true then
--            --inputs match and are same length
--            inputs_not_matching = false;
--        elseif result == false then
--            -- inputs differ go back a frame
--            frame = frame - 1;
--        else
--            -- Same length game state but the past differs
--            -- result is the frame that has different input
--            if not (type(result) == "boolean") then
--                frame = result
--                inputs_not_matching = false;
--            end
--        end
--    end
--
--    Rollback.recalculate_from_frame(rb, frame)
--end
--
--function Rollback.recalculate_from_frame(rb, last_correct_frame)
--    local goal_frame = Rollback.latest_state(rb).frame;
--
--    if goal_frame == last_correct_frame then
--        return;
--    end
--
--    local not_caught_up = true;
--    while not_caught_up do
--        local new_state = GameState.copy(rb.game_states[last_correct_frame])
--        Rollback.update_game(new_state, {});
--        rb.game_states[last_correct_frame + 1] = new_state
--
--        last_correct_frame = last_correct_frame + 1;
--
--        if last_correct_frame == goal_frame then
--            not_caught_up = false
--        end
--    end
--end

return Rollback
