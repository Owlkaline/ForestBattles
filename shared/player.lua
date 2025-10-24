Player = {}

function Player.new(x, y)
  local player = setmetatable({}, { __index = Player })

  player.x = x
  player.y = y
  player.width = 16
  player.height = 16
  player.inputs = {}
  player.isPlayer = true

  return player;
end

function Player:filter()
  return function(item, other)
    if other.isPlayer then
      return 'push'
    elseif other.isWall then
      return 'slide'
    end
    return nil
  end
end

function Player:input(global_tick, dt)
  local velocity = { x = 0, y = 0 };
  local speed = 200.0;

  local inputs = self.inputs[global_tick];
  if inputs == nil then
    return
  end

  --if inputs['w'] then
  --  velocity.y = speed;
  --end
  --if inputs['s'] then
  --  velocity.y = -speed;
  --end
  if inputs['a'] then
    velocity.x = -speed;
  end
  if inputs['d'] then
    velocity.x = speed;
  end

  --local x, y = self.body:getLinearVelocity();

  --self.body:setLinearVelocity(velocity.x, y)

  --self.body:setLinearVelocity(velocity.x, y)

  if inputs['space'] and y == 0 then
    print("space bar pressed")
    velocity.y = speed;
    -- y = -speed;
    -- self.body:applyLinearImpulse(0, -speed * 0.5 * dt);
    --self.body:applyForce(0, -speed)
  end

  --self.body:applyForce(velocity.x, 0);

  --self.body
  self.x = self.x + velocity.x * dt;
  self.y = self.y + velocity.y * dt;
end

return Player;
