local BounceSurface = {}

function BounceSurface.new(x, y, width, height)
  return {
    x = x,
    y = y,
    width = width,
    height = height,
    isFloor = false,
    isWall = true,
    isBounce = false,
    isDeath = true,
    isAttackBox = false
  }
end

return BounceSurface;
