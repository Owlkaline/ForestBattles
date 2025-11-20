local Mushroom = {};

local Animation = require('shared/animation')
local Attack = require('shared/attacks')
local NewAnimation = require('shared/new_animation')

local punch_one_combo_window = 0.1;

function Yeet(player)
  player.velocity.y = -300.0;
  return true
end

function WaitTillTop(player)
  return player.velocity.y > -80
end

function Landed(player)
  return player.grounded
end

function None(player)
  return false
end

function MushroomSpecialStart(player)
  player.grounded = false;
  local spin_velocity = 300.0;
  if player.facing_left then
    spin_velocity = -spin_velocity;
  end
  player.velocity.x = spin_velocity;
  player.velocity.y = 0
  player.gravity_enabled = false;
end

function MushroomSpecialEnd(player)
  player.gravity_enabled = true;
  player.velocity.x = 0;
end

function JumpContinous(player, animation)
  local jump_start_frame = 33;
  local frame_to_start_jump = jump_start_frame + 3;
  local landing_frame_start = jump_start_frame + 12;
  if animation.current_frame > frame_to_start_jump + 1 and animation.current_frame < landing_frame_start then
    if player.grounded then
      animation.current_frame = landing_frame_start
    end
  end
end

function Mushroom.jump()
  local total_frames = 14

  local frames_to_wait = 12;
  local jump_start_frame = 33;
  local frame_to_start_jump = jump_start_frame + 3;
  local landing_frame_start = jump_start_frame + 12;

  local jump = NewAnimation.new("jump", total_frames, jump_start_frame, Action.Jump);

  NewAnimation.add_requirement_at_frame(jump, frame_to_start_jump, Yeet);

  local going_up_frame = jump_start_frame + 5;

  NewAnimation.add_requirement_at_frame(jump, going_up_frame, WaitTillTop);

  local going_down_frame = jump_start_frame + 11;
  NewAnimation.add_requirement_at_frame(jump, going_down_frame, None);

  NewAnimation.add_requirement_at_frame(jump, landing_frame_start, Landed);

  jump.check_continously = JumpContinous;

  return jump
end

function Mushroom.punch_combo()
  local total_frames = 7
  local start_frame = 65;

  local frames_to_wait = 12;

  local attack = Attack.new("punch", total_frames, start_frame, Action.Attack1);

  local end_of_first_punch = 67
  Attack.add_combo_at_frame(attack, end_of_first_punch, frames_to_wait);

  local hitbox_offset = { x = 0, y = 0 };
  local hitbox_size = { width = 10, height = 10 };
  Attack.add_hitbox_at_frame(attack, end_of_first_punch, hitbox_offset, hitbox_size);

  local end_of_second_punch = 69
  Attack.add_combo_at_frame(attack, end_of_second_punch, frames_to_wait);

  hitbox_offset = { x = 0, y = 0 };
  hitbox_size = { width = 10, height = 10 };
  Attack.add_hitbox_at_frame(attack, end_of_second_punch, hitbox_offset, hitbox_size);

  local end_of_third_punch = 72
  Attack.add_hitbox_at_frame(attack, end_of_third_punch, hitbox_offset, hitbox_size);
  Attack.add_combo_at_frame(attack, end_of_third_punch, frames_to_wait);

  return attack
end

function Mushroom.kick()
  local total_frames = 2
  local start_frame = 81;

  local frames_to_wait = 6;

  local attack = Attack.new("kick", total_frames, start_frame, Action.Attack2);

  local hitbox_offset = { x = 0, y = 0 };
  local hitbox_size = { width = 10, height = 10 };
  Attack.add_hitbox_at_frame(attack, 83, hitbox_offset, hitbox_size)
  Attack.add_combo_at_frame(attack, 83, frames_to_wait)

  return attack
end

function Mushroom.special_attack()
  local total_frames = 11
  local start_frame = 97;

  local attack = Attack.new("special", total_frames, start_frame, Action.SpecialAttack);

  Attack.modify_player_at_start(attack, MushroomSpecialStart)

  Attack.modify_player_at_end(attack, MushroomSpecialEnd)
  --local hitbox_offset = { x = 0, y = 0 };
  --local hitbox_size = { width = 10, height = 10 };
  --Attack.add_hitbox_at_frame(attack, 76, hitbox_offset, hitbox_size)
  --Attack.add_combo_at_frame(attack, 76, frames_to_wait)
  return attack
end

function Mushroom.animation()
  local spriteSheetAnimation = Animation.new('assets/mushroom_spritesheet.png', 32)
  local loop = true;
  local dont_loop = false;

  Animation.add_animation(spriteSheetAnimation, "idle", 1, 1, loop);
  Animation.add_animation(spriteSheetAnimation, "running", 17, 26, loop);
  Animation.add_animation(spriteSheetAnimation, "jump", 33, 46, dont_loop); -- 52, false)
  Animation.add_animation(spriteSheetAnimation, "land", 47, 52, dont_loop); -- 52, false)
  Animation.add_animation(spriteSheetAnimation, "punch", 64, 72, dont_loop);
  Animation.add_animation(spriteSheetAnimation, "kick", 81, 83, dont_loop);
  Animation.add_animation(spriteSheetAnimation, "special", 97, 108, dont_loop);
  Animation.play_animation(spriteSheetAnimation, "idle")

  return spriteSheetAnimation;
end

--function Mushroom.attack(player, inputs)
--  local new_attack_box = {}
--
--  Attack.update_frame(player.attacks[Action.Attack1], inputs)
--
--  --if inputs[Action.Attack1] and (player.timers[Action.Attack1] or 0) <= 0 then
--  --  --print("player attacking")
--  --  new_attack_box[#new_attack_box + 1] = {};
--
--  --  local width = 5.0;
--  --  local height = 5.0;
--
--  --  local knockback_force = 2.5;
--  --  local duration = 0.5;
--  --  local x = player.x + player.width;
--  --  local y = player.y + player.height * 0.5 - width * 0.5
--
--  --  local direction = { x = 1, y = 0 };
--  --  if player.facing_left then
--  --    x = player.x - width
--  --    direction.x = direction.x * -1.0;
--  --  end
--
--  --  new_attack_box[#new_attack_box] = AttackBox.new(player, duration, direction, knockback_force, x, y, width, height)
--  --  player.timers[Action.Attack1] = 0.3
--  --  --    player.new_animation = "punching_first_half"
--  --  if player.animation ~= nil then
--  --    if player.action == Action.Attack1 and Players.is_stunned(player) then
--  --      print("Doing second half of punch combo")
--  --      Animation.play_animation_till_finish(player.animation, "punching_second_half");
--  --      -- queue idle animation
--  --      Animation.play_animation(player.animation, "idle")
--  --      player.timers[Action.Stunned] = player.timers[Action.Attack1];
--  --      player.action = nil
--  --    else
--  --      Animation.play_animation_till_finish(player.animation, "punching_first_half");
--  --      Animation.pause_at_end(player.animation)
--  --    end
--  --    player.timers[Action.Stunned] = player.timers[Action.Attack1] + punch_one_combo_window;
--  --    player.action = Action.Attack1
--  --  end
--  --end
--
--  return new_attack_box
--end

return Mushroom
