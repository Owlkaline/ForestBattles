Player = {}

function Player.new(x, y)
  local player = setmetatable({}, { __index = Player })

  player.x = x
  player.y = y
  player.width = 16
  player.height = 16
  player.inputs = {}

  return player;
end

function Player:input(global_tick, dt)
  local velocity = { x = 0, y = 0 };
  local speed = 200.0;

  local inputs = self.inputs[global_tick];
  if inputs == nil then
    return
  end

  if inputs['w'] then
    velocity.y = speed;
  end
  if inputs['s'] then
    velocity.y = -speed;
  end
  if inputs['a'] then
    velocity.x = -speed;
  end
  if inputs['d'] then
    velocity.x = speed;
  end

  local x, y = self.body:getLinearVelocity();
  self.body:setLinearVelocity(velocity.x, y)
  --self.x = self.x - velocity.x * dt;
  --self.y = self.y - velocity.y * dt;
end

return Player;
