local camera_class = require('camera')

Pixel = {
  canvas = {},
  scale = 3,
  camera = {},
}

function Pixel:load()
  self.camera = camera_class;
  love.graphics.setLineStyle('rough')
  love.graphics.setDefaultFilter("nearest", "nearest", 1)
  --love.window.setMode(320, 180);

  self.canvas = love.graphics.newCanvas(320.0, 180.0);
  self.canvas:setFilter('nearest', 'nearest');

  love.window.setMode(self.canvas:getWidth() * self.scale, self.canvas:getHeight() * self.scale)
  self.camera:setScale(self.scale);
  self.camera:safeScale(self.canvas);
end

function Pixel:followEntity(entity, world_size)
  --  local _, _, windowWidth, windowHeight = love.window.getSafeArea()
  local width, height = self.canvas:getWidth(), self.canvas:getHeight();
  self.camera.x = entity.x - width * 0.5;
  self.camera.y = entity.y - height * 0.5;

  local left_furthest = -world_size.width * 0.5;
  if self.camera.x < left_furthest then
    self.camera.x = left_furthest;
  end

  local right_furthest = world_size.width * 0.5 - width;
  if self.camera.x > right_furthest then
    self.camera.x = right_furthest;
  end

  local bottom_furthest = world_size.height * 0.5 - height;
  if self.camera.y > bottom_furthest then
    self.camera.y = bottom_furthest;
  end

  local top_furthest = -world_size.height * 0.5;
  if self.camera.y < top_furthest then
    self.camera.y = top_furthest;
  end
end

function Pixel:startDraw()
  love.graphics.setCanvas(self.canvas);
  love.graphics.clear();
  love.graphics.push();

  love.graphics.translate(-self.camera.x, -self.camera.y);
end

function Pixel:endDraw()
  love.graphics.pop();
  love.graphics.push();
  love.graphics.setCanvas();
  love.graphics.scale(self.camera.scale);
  love.graphics.draw(self.canvas)
  love.graphics.pop();
end

return Pixel
