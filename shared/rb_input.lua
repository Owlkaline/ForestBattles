local InputManager = {}

function InputManager.new()
    return {
        inputs = {}
    }
end

function InputManager.add_input(im, id, frame, input_id, value)
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

    InputManager.set_input(im, id, frame, input_id, value)

    return inputs_differ
end

function InputManager.get_all_inputs_for_entity(im, id)
    return im.inputs[id] or nil
end

function InputManager.predict_and_get_all_inputs_for_frame(im, frame)
    local inputs_for_frame = {};
    for id, frames in pairs(im.inputs) do
        inputs_for_frame[id] = InputManager.get_inputs_for_frame(im, id, frame)
        if inputs_for_frame[id] == nil then
            -- Just use previous frames input
            inputs_for_frame[id] = InputManager.get_inputs_for_frame(im, id, frame - 1)
        end
    end

    return inputs_for_frame
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
