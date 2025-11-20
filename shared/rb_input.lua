local InputManager = {}

function InputManager.new()
  return {
    inputs = {}
  }
end

function InputManager.add_inputs_for_frame(im, id, frame, inputs)
  local differs = false;
  for input, value in pairs(inputs) do
    if InputManager.check_input_differs(im, id, frame, input, value) then
      differs = true;
    end
  end

  if im.inputs == nil then
    im.inputs = {}
  end

  if im.inputs[id] == nil then
    im.inputs[id] = {};
  end
  im.inputs[id][frame] = inputs;

  return differs;
end

function InputManager.check_input_differs(im, id, frame, input_id, value)
  local inputs_differ = false;
  local all_inputs_for_frame = InputManager.get_inputs_for_frame(im, id, frame)

  inputs_differ = true
  -- check that this is new inputs
  if all_inputs_for_frame ~= nil then
    -- if its not new inputs for a frame then we check if they are different
    local predicted_input = InputManager.get_input(im, id, frame, input_id)
    if predicted_input ~= value then
      inputs_differ = true
    end
  end

  return inputs_differ
end

function InputManager.get_all_inputs_for_entity(im, id)
  return im.inputs[id] or nil
end

function InputManager.predict_and_get_all_inputs_for_frame(im, active_players, goal_frame)
  local player_inputs_for_this_frame = {}

  for _, idx in pairs(active_players) do
    player_inputs_for_this_frame[idx] = {}

    -- Add player inputs if they dont exist
    if im.inputs[idx] == nil then
      im.inputs[idx] = {}
    end

    local not_caught_up = true;
    local frame_to_check = goal_frame;
    while not_caught_up do
      if InputManager.get_inputs_for_frame(im, idx, frame_to_check) ~= nil then
        -- There is input

        -- If there is already input for this frame and it is the latest one
        -- Great! we are done
        if frame_to_check == goal_frame then
          player_inputs_for_this_frame[idx] = InputManager.get_inputs_for_frame(im, idx, frame_to_check);
          not_caught_up = false;
          -- break
        else
          -- this is a past frame, bring the input forward
          im.inputs[idx][frame_to_check + 1] = InputManager.get_inputs_for_frame(im, idx, frame_to_check);
          frame_to_check = frame_to_check + 1;
        end
      else
        -- No input for this frame


        -- If we are far enoguh in the past, presume no inputs
        if goal_frame - frame_to_check > 5 or frame_to_check == 1 then
          im.inputs[idx][frame_to_check] = {}
          --InputManager.add_input(im, idx, frame_to_check, )
          -- Loop back ground with current frame with no inputs
        else
          -- check frame before this one
          frame_to_check = frame_to_check - 1;
        end
      end
    end
  end
  --local inputs_for_frame = {};
  --for id, frames in pairs(im.inputs) do
  --  inputs_for_frame[id] = InputManager.get_inputs_for_frame(im, id, frame)
  --  if inputs_for_frame[id] == nil then
  --    -- Just use previous frames input
  --    inputs_for_frame[id] = InputManager.get_inputs_for_frame(im, id, frame - 1)
  --  end
  --end

  return player_inputs_for_this_frame
end

function InputManager.get_inputs_for_frame(im, id, frame)
  if im.inputs[id] and im.inputs[id][frame] then
    return im.inputs[id][frame]
  end
  return nil
end

function InputManager.get_input(im, id, frame, input_id)
  return InputManager.get_inputs_for_frame(im, id, frame)[input_id] or nil
end

function InputManager.set_input(im, id, frame, input_id, value)
  if im.inputs[id] == nil then
    im.inputs[id] = {};
  end
  if im.inputs[id][frame] == nil then
    im.inputs[id][frame] = {}
  end
  im.inputs[id][frame][input_id] = value
end

return InputManager;
