local NewAnimation = {};

local Animation = require('shared/animation')

function NewAnimation.new(name, num_frames, start_frame, input)
  return {
    input = input,
    name = name,
    num_frames = num_frames,
    start_frame = start_frame,
    current_frame = start_frame,
    frame_active_for = 0,
    frame_duration = 3,
    requirement_at_frame = {},
    combo_frames = {},
    total_frames = 0,
    stall_frames = 0, -- Extra frames to wait at end of animation
    input_was_release = false,
    is_active = false,
    modify_player_at_start = function(player)
      if player.grounded then
        player.velocity.x = 0
      end
    end,
    modify_player_at_end = function(player)
      player.gravity_enabled = true
    end,
    check_continously = function(player, animation)

    end
  }
end

function NewAnimation.modify_player_at_start(new_animation, modify_player_func)
  new_animation.modify_player_at_start = modify_player_func
end

function NewAnimation.modify_player_at_end(new_animation, modify_player_func)
  new_animation.modify_player_at_end = modify_player_func
end

function NewAnimation.add_requirement_at_frame(new_animation, frame, requirement)
  new_animation.requirement_at_frame[frame] = requirement
end

function NewAnimation.start_new_animation(new_animation, player)
  if new_animation.is_active then
    return -- do nothing if already new_animation
  end

  NewAnimation.reset(new_animation)
  new_animation.is_active = true;
  new_animation.modify_player_at_start(player)
end

function NewAnimation.reset(new_animation)
  new_animation.input_was_release = false;
  new_animation.total_frames = 0;
  new_animation.stall_frames = 0;
  new_animation.current_frame = new_animation.start_frame
  new_animation.frame_active_for = 0
  new_animation.is_active = false
end

function NewAnimation.is_active(new_animation)
  return new_animation.is_active
end

function NewAnimation.update_frame(new_animation, player, all_inputs)
  local input = all_inputs[new_animation.input]

  local input_pressed_this_frame = false;
  if input == nil then
    new_animation.input_was_release = true
  elseif input == true and new_animation.input_was_release then
    input_pressed_this_frame = true
  end

  -- start new_animation if not active and you press the right button
  if NewAnimation.is_active(new_animation) == false then
    if input_pressed_this_frame then
      NewAnimation.start_new_animation(new_animation, player);
    end
    return
  end

  new_animation.check_continously(player, new_animation)

  --if input_pressed_this_frame and NewAnimation.is_at_combo_frame(new_animation, new_animation.current_frame) then
  --  -- continue the combo
  --  new_animation.stall_frames = 0
  --  new_animation.input_was_release = false
  --end
  if new_animation.stall_frames > 0 then
    if new_animation.requirement_at_frame[new_animation.current_frame] ~= nil then
      if new_animation.requirement_at_frame[new_animation.current_frame](player) then
        new_animation.stall_frames = 0
      end
    else
      new_animation.stall_frames = new_animation.stall_frames - 1;
    end
  else
    new_animation.frame_active_for = new_animation.frame_active_for + 1;
    if new_animation.frame_active_for > new_animation.frame_duration then
      print("New jump frame: " .. new_animation.current_frame)
      new_animation.frame_active_for = 0
      new_animation.current_frame = new_animation.current_frame + 1;
      if new_animation.requirement_at_frame[new_animation.current_frame] ~= nil then
        new_animation.stall_frames = 1;
      end
      if NewAnimation.is_at_combo_frame(new_animation, new_animation.current_frame) then
        new_animation.stall_frames = new_animation.combo_frames[new_animation.current_frame];
      end
      if new_animation.start_frame + new_animation.num_frames < new_animation.current_frame then
        new_animation.is_active = false
      end
    end
  end

  new_animation.total_frames = new_animation.total_frames + 1

  if new_animation.is_active == false then
    NewAnimation.modify_player_at_end(player)
  end
end

function NewAnimation.add_combo_at_frame(new_animation, frame, frames_to_wait)
  new_animation.combo_frames[frame] = frames_to_wait
end

function NewAnimation.is_at_combo_frame(new_animation, frame)
  return new_animation.combo_frames[new_animation.current_frame] ~= nil
end

function NewAnimation.draw(new_animation, player)
  Animation.draw_frame(player.animation, new_animation.current_frame, player.x, player.y, player.facing_left);
end

return NewAnimation;
