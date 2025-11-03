local Mushroom = {};

function Mushroom.attack(player, inputs)
  local new_attack_box = {}

  if inputs[Attacks.Attack2] and (player.timers[Attacks.Attack1] or 0) <= 0 then
    --print("player attacking")
    new_attack_box[#new_attack_box + 1] = {};

    local knockback_force = 5.5;
    local duration = 0.5;

    local width = 15.0;
    local height = 15.0;

    local x = player.x + player.width;
    local y = player.y + player.height * 0.5 - width * 0.5

    local direction = { x = 1, y = 0 };
    if player.facing_left then
      x = player.x - width
      direction.x = direction.x * -1.0;
    end

    new_attack_box[#new_attack_box] = AttackBox.new(player, duration, direction, knockback_force, x, y, width, height)
    player.timers[Attacks.Attack1] = 0.5
  end

  if inputs[Attacks.Attack1] and (player.timers[Attacks.Attack1] or 0) <= 0 then
    --print("player attacking")
    new_attack_box[#new_attack_box + 1] = {};

    local width = 5.0;
    local height = 5.0;

    local knockback_force = 0.5;
    local duration = 0.5;
    local x = player.x + player.width;
    local y = player.y + player.height * 0.5 - width * 0.5

    local direction = { x = 1, y = 0 };
    if player.facing_left then
      x = player.x - width
      direction.x = direction.x * -1.0;
    end

    new_attack_box[#new_attack_box] = AttackBox.new(player, duration, direction, knockback_force, x, y, width, height)
    player.timers[Attacks.Attack1] = 0.5
  end

  return new_attack_box
end

return Mushroom
