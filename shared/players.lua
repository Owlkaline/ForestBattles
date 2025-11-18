require('shared/attack_box')
Mushroom = require('shared/characters/mushroom')
local Animation = require('shared/animation')
local Attack = require('shared/attacks')
local NewAnimation = require('shared/new_animation')

Players = {}

DefaultWeight = 8;

Character = {
  Box = 0,
  Mushroom = 1
}

function Character.attack(player, inputs)
  if player.character == Character.Mushroom then
    return Mushroom.attack(player, inputs)
  end
end

Action = {
  Left = 1,
  Right = 2,
  Jump = 3,
  Stunned = 4,
  Attack1 = 5,
  Attack2 = 6,
  SpecialAttack = 7
}

function Players.new(idx, x, y, character)
  local player = {}
  player.x = x
  player.y = y
  player.velocity = {
    x = 0,
    y = 0,
  };
  player.width = 8
  player.height = 8
  player.character = character;
  player.damage = 0
  player.isPlayer = true
  player.weight = DefaultWeight
  player.grounded = false;
  player.grounded_last_frame = false;
  player.facing_left = false
  player.timers = {}
  player.action = nil;
  player.index = idx;
  player.gravity_enabled = true;
  -- player.timers[Attacks.Attack1] = 0
  if character == Character.Mushroom then
    player.attacks = {}
    player.attacks[Action.Attack1] = Mushroom.punch_combo();
    player.attacks[Action.Attack2] = Mushroom.kick();
    player.attacks[Action.SpecialAttack] = Mushroom.special_attack();
    player.jump = Mushroom.jump();
  end

  return player;
end

function Players.new_with_animation(idx, x, y, character)
  local player = Players.new(idx, x, y, character);

  local animation = Mushroom.animation();

  player.animation = animation

  return player;
end

function Players.filter()
  return function(item, other)
    if other.isPlayer then
      return 'push'
    elseif other.isBounce then
      return 'velocity_bounce'
    elseif other.isWall then
      return 'slide'
    elseif other.isAttackBox then
      return 'cross'
    end
    return nil
  end
end

function Players.update_timers(players, dt)
  for _, player in pairs(players) do
    for i, timer in pairs(player.timers) do
      if timer > 0 then
        player.timers[i] = timer - dt;
      end
    end
  end
end

function Players.apply_gravity(players, dt)
  for _, player in pairs(players) do
    if player.gravity_enabled then
      player.velocity.y = player.velocity.y + player.weight * 98.0 * dt;
    end
  end
end

function Players.move(players, dt)
  for _, player in pairs(players) do
    player.x = player.x + player.velocity.x * dt;
    player.y = player.y + player.velocity.y * dt;
  end
end

function Players.update_world(players, world)
  for _, player in pairs(players) do
    local new_x, new_y, cols, len = world:move(player, player.x, player.y, Players.filter());
    local started_grounded = player.grounded;
    player.x = new_x;
    player.y = new_y;
    player.grounded = false

    local did_collide_with_floor = false;

    for j = 1, len do
      if cols[j].other.isDeath then
        player.x = 0;
        player.y = -50;
        world:update(player, player.x, player.y)
        player.velocity.x = 0;
        player.velocity.y = 0;
        player.grounded = false;
      end

      if cols[j].other.isAttackBox then
        if cols[j].other.players_hit[player.index] == (false or nil) then
          player.damage = player.damage + cols[j].other.damage;

          local blast_back = 500 * (cols[j].other.knockback_force * (1.0 + player.damage * 0.01)) /
              player.weight;
          player.velocity.x = player.velocity.x + blast_back * cols[j].other.direction.x;
          player.velocity.y = player.velocity.y + blast_back * cols[j].other.direction.y;

          cols[j].other.players_hit[player.index] = true
          player.timers['stunned'] = 0.1
        end
      end

      if cols[j].other.isFloor then
        did_collide_with_floor = true;
        if cols[j].normal.y < 0 then
          player.grounded = true;
          player.velocity.y = 0;

          -- we were jumping but then landed
          --if started_grounded == false then
          --  NewAnimation.start_new_animation(player.jump, player)
          --  -- start the land animation
          --  player.jump.current_frame = 33 + 12;
          --  player.action = nil
          --end
        end
      end
    end
    if player.grounded == false and player.velocity.y > 0 then
      if Players.is_attacking(player) == false and NewAnimation.is_active(player.jump) == false then
        NewAnimation.start_new_animation(player.jump, player);
        player.jump.current_frame = 33 + 6
      end
    end
  end
end

function Players.is_stunned(player)
  return (player.timers[Action.Stunned] or -1) > 0
end

function Players.input(players, players_inputs_for_frame, dt)
  local new_objects = {}

  for i, player in pairs(players) do
    local override_velocity = { x = 0, y = 0 };
    local speed = 200.0;
    local jump_velocity = 300.0;
    local started_grounded = player.grounded;

    if players_inputs_for_frame == nil or players_inputs_for_frame[i] == nil then
      print("No input at all - no players")
      return new_objects
    end

    local inputs = players_inputs_for_frame[i]

    local player_is_attacking = Players.is_attacking(player)
    local player_is_not_attacking = player_is_attacking == false

    if player_is_not_attacking then
      -- idle
      if player.action ~= Action.Jump and Players.is_stunned(player) == false then
        if player.animation ~= nil then
          Animation.play_animation(player.animation, "idle")
        end
      end

      -- run left
      if inputs[Action.Left] then
        player.facing_left = true
        override_velocity.x = -speed;
        if player.animation ~= nil then
          if player.grounded then
            Animation.play_animation(player.animation, "running")
          end
        end
        --  print("Player moving left now")
      end

      -- run right
      if inputs[Action.Right] then
        player.facing_left = false
        override_velocity.x = speed;

        if player.animation ~= nil then
          if player.grounded then
            Animation.play_animation(player.animation, "running")
          end
        end
      end

      -- Jump
      if NewAnimation.is_active(player.jump) then
        NewAnimation.update_frame(player.jump, player, inputs)
      elseif started_grounded then
        NewAnimation.update_frame(player.jump, player, inputs)
      end
    end

    if Players.is_stunned(player) or player_is_attacking then
      player.velocity.x = player.velocity.x + override_velocity.x * 0.1
    else
      player.velocity.x = override_velocity.x;
    end

    for _, attack in pairs(player.attacks) do
      if player_is_not_attacking or (player_is_attacking and Attack.is_active(attack)) then
        Attack.update_frame(attack, player, inputs)
      end
    end

    --new_objects = Character.attack(player, inputs);
    --if new_boxs ~= nil then
    --    for _, box in pairs(new_boxs) do
    --        new_objects[#new_objects + 1] = box
    --        attack_boxs[#attack_boxs + 1] = box;
    --        world:add(attack_boxs[#attack_boxs], box.x, box.y, box.width, box.height);
    --        -- server:sendToAll("addObject", { 99999, box.x, box.y, box.width, box.height });
    --    end
    --end
  end

  return new_objects
end

function Players.is_attacking(player)
  local is_attacking = false
  for _, attack in pairs(player.attacks) do
    if Attack.is_active(attack) then
      is_attacking = true
    end
  end

  return is_attacking
end

function Players.get_active_attack(player)
  local attack = nil
  for _, atk in pairs(player.attacks) do
    if Attack.is_active(atk) then
      attack = atk;
      break;
    end
  end

  return attack
end

function Players.draw(player)
  if Players.is_attacking(player) then
    local active_attack = Players.get_active_attack(player);
    Attack.draw(active_attack, player)
  elseif NewAnimation.is_active(player.jump) then
    NewAnimation.draw(player.jump, player)
  else
    Animation.draw(player.animation, player.x, player.y, player.facing_left)
  end

  --local start = 97;
  --for i = start, start + 11 do
  --  --print(i)
  --  Animation.draw_frame(player.animation, i, player.x + player.width * 2 * (i - 11 - start),
  --    player.y - player.height * 2.0,
  --    player
  --    .facing_left);
  --end
end

return Players;
