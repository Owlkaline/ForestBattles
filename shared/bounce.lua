local BounceSurface = {}

function BounceSurface.new(x, y, width, height)
  return {
    x = x,
    y = y,
    width = width,
    height = height,
    isWall = true,
    isBounce = false,
    isDeath = true
  }
end

return BounceSurface;
