AttackBox = {}

function AttackBox.new(parent, duration, direction, knockback_force, x, y, width, height)
  local attack_box = setmetatable({}, { __index = AttackBox })

  attack_box.x = x
  attack_box.y = y
  attack_box.width = width
  attack_box.height = height
  attack_box.isAttackBox = true
  attack_box.isWall = false
  attack_box.isFloor = false
  attack_box.isDeath = false
  attack_box.damage = 5;
  attack_box.parent = parent
  attack_box.duration = duration;
  attack_box.players_hit = {}
  attack_box.players_hit[parent.index] = true
  attack_box.direction = direction;
  attack_box.knockback_force = knockback_force

  return attack_box;
end

function AttackBox.update(boxs, dt, world)
  for _, box in pairs(boxs) do
    if box.isAttackBox and box.duration > 0 then
      box.duration = box.duration - dt;
      if box.duration <= 0 then
        -- Delete from world
        world:remove(box)
      end
    end
  end
end

return AttackBox;
