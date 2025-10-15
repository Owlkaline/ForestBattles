local camera = require('camera')

Pixel = {

  canvas = {},
  scale = 3,
}

function Pixel.load()
  love.graphics.setLineStyle('rough')
  love.graphics.setDefaultFilter("nearest", "nearest", 1)
  --love.window.setMode(320, 180);

  Pixel.canvas = love.graphics.newCanvas(320.0, 180.0);
  Pixel.canvas:setFilter('nearest', 'nearest');

  love.window.setMode(Pixel.canvas:getWidth() * Pixel.scale, Pixel.canvas:getHeight() * Pixel.scale)
  camera:setScale(Pixel.scale);
  camera:safeScale(Pixel.canvas);
end

function Pixel:startDraw()
  love.graphics.setCanvas(Pixel.canvas);
  love.graphics.clear();
  love.graphics.push();
end

function Pixel:endDraw()
  love.graphics.pop();
  love.graphics.push();
  love.graphics.setCanvas();
  love.graphics.translate(-camera.x, -camera.y);
  love.graphics.scale(camera.scale);
  love.graphics.draw(Pixel.canvas)
  love.graphics.pop();
end

return Pixel
