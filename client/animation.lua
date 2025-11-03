local Animation = {};

function Animation.new(image_location, size)
  local image = love.graphics.newImage(image_location);
  local frames = {}

  local image_width = image:getWidth();
  local image_height = image:getHeight();

  if image_width % size ~= 0 or image_height % size ~= 0 then
    print("Incompatiable image size with requested sprite sheet size")
  end

  local frames_per_width = image_width / size;

  for row = 1, frames_per_width do
    for column = 1, frames_per_width do
      local x = (column - 1) * size;
      local y = (row - 1) * size;
      frames[#frames + 1] = love.graphics.newQuad(x, y, size, size, image_width, image_height);
    end
  end

  local animation = {
    image = image,
    current_animation = "",
    animations = {},
    frames = frames,
    current_frame = 1,
    timer = 0,
  }

  return animation
end

function Animation.update(animation, dt)
  animation.timer = animation.timer - dt;
  if animation.timer < 0 then
    -- new frame
    animation.current_frame = animation.current_frame + 1;
    if animation.current_frame > animation.animations[animation.current_animation].end_frame or
        animation.current_frame < animation.animations[animation.current_animation].start_frame then
      animation.current_frame = animation.animations[animation.current_animation].start_frame;
    end
    animation.timer = 1;
  end
end

function Animation.add_animation(animation, name, frame_start, frame_end)
  local new_animation = {
    start_frame = frame_start,
    end_frame = frame_end
  }
  animation.animations[name] = new_animation
end

function Animation.play_animation(animation, name)
  animation.current_animation = name
end

function Animation.draw(animation, x, y)
  love.graphics.draw(animation.image, animation.frames[animation.current_frame], x, y)
end

return Animation;
