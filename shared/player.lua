Player = {}

DefaultWeight = 8;

function Player.new(x, y)
  local player = setmetatable({}, { __index = Player })

  player.x = x
  player.y = y
  player.velocity = {
    x = 0,
    y = 0,
  };
  player.width = 16
  player.height = 16
  player.inputs = {}
  player.isPlayer = true
  player.weight = DefaultWeight
  player.grounded = false;

  return player;
end

function Player:filter()
  return function(item, other)
    if other.isPlayer then
      return 'push'
    elseif other.isBounce then
      return 'velocity_bounce'
    elseif other.isWall then
      return 'slide'
    end
    return nil
  end
end

function Player:move(dt)
  self.x = self.x + self.velocity.x * dt;
  self.y = self.y + self.velocity.y * dt;
end

function Player:input(global_tick, dt)
  local override_velocity = { x = 0, y = 0 };
  local speed = 200.0;
  local jump_velocity = 300.0;
  local started_grounded = self.grounded;

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
  if inputs['left'] then
    override_velocity.x = -speed;
  end
  if inputs['right'] then
    override_velocity.x = speed;
  end

  --local x, y = self.body:getLinearVelocity();

  --self.body:setLinearVelocity(velocity.x, y)

  --self.body:setLinearVelocity(velocity.x, y)

  self.velocity.x = override_velocity.x;
  if started_grounded then
    self.velocity.y = 0;
    --   self.grounded = false;
  else
    --    self.velocity.x = self.velocity.x + override_velocity.x * dt * 5.0;
  end
  if inputs['jump'] and started_grounded then
    self.velocity.y = -jump_velocity;
    self.grounded = false;
    -- y = -speed;
    -- self.body:applyLinearImpulse(0, -speed * 0.5 * dt);
    --self.body:applyForce(0, -speed)
  end


  --self.body:applyForce(velocity.x, 0);
  --self.body
end

return Player;
