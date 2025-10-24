local Floor = {}

function Floor.new(x, y, width, height)
  return {
    x = x,
    y = y,
    width = width,
    height = height,
    isWall = true
  }
end

return Floor;
