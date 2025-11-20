local Attack = {};

local Animation = require('shared/animation')

function ModifyPlayerAtStart(player)
  if player.grounded then
    player.velocity.x = 0
  end
end

function ModifyPlayerAtEnd(player)
  player.gravity_enabled = true
end

function Attack.new(name, num_frames, start_frame, input)
  return {
    input = input,
    name = name,
    num_frames = num_frames,
    start_frame = start_frame,
    current_frame = start_frame,
    frame_active_for = 0,
    frame_duration = 3,
    important_frames = {},
    combo_frames = {},
    total_frames = 0,
    stall_frames = 0, -- Extra frames to wait at end of animation
    input_was_release = false,
    is_active = false,
    modify_player_at_start = ModifyPlayerAtStart,
    modify_player_at_end = ModifyPlayerAtEnd
  }
end

function Attack.modify_player_at_start(attack, modify_player_func)
  attack.modify_player_at_start = modify_player_func
end

function Attack.modify_player_at_end(attack, modify_player_func)
  attack.modify_player_at_end = modify_player_func
end

function Attack.start_attack(attack, player)
  if attack.is_active then
    return -- do nothing if already attacking
  end

  Attack.reset(attack)
  attack.is_active = true;
  attack.modify_player_at_start(player)
end

function Attack.reset(attack)
  attack.input_was_release = false;
  attack.total_frames = 0;
  attack.stall_frames = 0;
  attack.current_frame = attack.start_frame
  attack.frame_active_for = 0
  attack.is_active = false
end

function Attack.is_active(attack)
  return attack.is_active
end

function Attack.update_frame(attack, player, all_inputs)
  local input = all_inputs[attack.input]

  local input_pressed_this_frame = false;
  if input == nil then
    attack.input_was_release = true
  elseif input == true and attack.input_was_release then
    input_pressed_this_frame = true
  end

  -- start attack if not active and you press the right button
  if Attack.is_active(attack) == false then
    if input_pressed_this_frame then
      Attack.start_attack(attack, player);
    end
    return
  end

  if input_pressed_this_frame and Attack.is_at_combo_frame(attack, attack.current_frame) then
    -- continue the combo
    attack.stall_frames = 0
    attack.input_was_release = false
  end

  if attack.stall_frames > 0 then
    attack.stall_frames = attack.stall_frames - 1;
    if attack.stall_frames == 0 then
      attack.is_active = false
    end
  else
    attack.frame_active_for = attack.frame_active_for + 1;
    if attack.frame_active_for > attack.frame_duration then
      attack.frame_active_for = 0
      attack.current_frame = attack.current_frame + 1;
      local important_frame = attack.important_frames[attack.current_frame]
      if important_frame ~= nil then
        -- create hitbox
      end
      if Attack.is_at_combo_frame(attack, attack.current_frame) then
        attack.stall_frames = attack.combo_frames[attack.current_frame];
      end
      if attack.start_frame + attack.num_frames < attack.current_frame then
        attack.is_active = false
      end
    end
  end

  attack.total_frames = attack.total_frames + 1

  if attack.is_active == false then
    attack.modify_player_at_end(player)
  end
end

function Attack.add_hitbox_at_frame(attack, frame, offset, size)
  attack.important_frames[frame] = { offset = offset, size = size }
end

function Attack.add_combo_at_frame(attack, frame, frames_to_wait)
  attack.combo_frames[frame] = frames_to_wait
end

function Attack.is_at_combo_frame(attack, frame)
  return attack.combo_frames[attack.current_frame] ~= nil
end

function Attack.draw(attack, player)
  Animation.draw_frame(player.animation, attack.current_frame, player.x, player.y, player.facing_left);
end

return Attack;
