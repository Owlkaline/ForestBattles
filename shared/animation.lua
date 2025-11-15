local Animation = {
  loaded_images = {}
};

local frame_duration = 0.049;

function Animation.new(image_location, size)
  local image;
  if Animation.loaded_images[image_location] == nil then
    image = love.graphics.newImage(image_location);
  else
    image = Animation.loaded_images[image_location];
  end
  local frames = {}

  local image_width = image:getWidth();
  local image_height = image:getHeight();

  if image_width % size ~= 0 or image_height % size ~= 0 then
    print("Incompatiable image size with requested sprite sheet size")
  end

  local frames_per_width = image_width / size;
  local frames_per_height = image_height / size;

  for row = 1, frames_per_height do
    for column = 1, frames_per_width do
      local x = (column - 1) * size;
      local y = (row - 1) * size;
      frames[#frames + 1] = love.graphics.newQuad(x, y, size, size, image_width, image_height);
    end
  end

  local animation = {
    image = image,
    current_animation = nil,
    animations = {},
    frames = frames,
    frame_size = size,
    current_frame = 1,
    timer = 0,
    play_till_end = false,
    next_animation = nil,
    next_animation_play_till_end = nil,
    pause_at_end = false
  }

  return animation
end

function Animation.update(animation, dt)
  animation.timer = animation.timer - dt;
  if animation.timer < 0 then
    local current_animation = animation.animations[animation.current_animation];
    -- new frame
    if current_animation.loop or animation.current_frame < current_animation.end_frame then
      animation.current_frame = animation.current_frame + 1;
    end

    if animation.current_frame >= current_animation.end_frame then
      if animation.pause_at_end then
        return;
      end

      if animation.next_animation ~= nil then
        local next_animation = animation.next_animation;
        local play_till_end = animation.next_animation_play_till_end;
        animation.next_animation = nil;
        animation.next_animation_play_till_end = nil
        animation.play_till_end = false;
        if play_till_end == true then
          Animation.play_animation_till_finish(animation, next_animation);
        else
          Animation.play_animation(animation, next_animation);
        end

        --animation.current_frame = animation.animations[next_animation].start_frame;
      elseif current_animation.loop then
        animation.current_frame = current_animation.start_frame;
      end
    end

    if animation.current_frame < current_animation.start_frame then
      animation.current_frame = current_animation.start_frame;
    end
    animation.timer = frame_duration;
  end
end

function Animation.add_animation(animation, name, frame_start, frame_end, loop)
  local new_animation = {
    start_frame = frame_start,
    end_frame = frame_end,
    loop = loop,
  }
  animation.animations[name] = new_animation
  if animation.current_animation == nil then
    Animation.play_animation(animation, name)
  end
end

function Animation.play_animation(animation, name)
  if name == animation.current_animation then
    return
  end

  if animation.play_till_end then
    animation.next_animation = name;
    animation.next_animation_play_till_end = nil
  else
    animation.current_animation = name
    animation.play_till_end = nil
  end

  animation.pause_at_end = false;
end

function Animation.reset_animation(animation)
  animation.current_frame = animation.animations[animation.current_animation].start_frame
  animation.timer = frame_duration
end

function Animation.play_animation_till_finish(animation, name)
  if name == animation.current_animation then
    return
  end

  if animation.play_till_end then
    animation.next_animation = name;
    animation.next_animation_play_till_end = true;
  else
    animation.current_animation = name
    animation.play_till_end = true;
  end

  animation.pause_at_end = false;
end

function Animation.pause_at_end(animation)
  animation.pause_at_end = true;
end

function Animation.draw(animation, x, y, flip)
  local mirror = 1;
  if flip then
    mirror = -1
  end

  local draw_offset = animation.frame_size * 0.5;

  love.graphics.draw(animation.image, animation.frames[animation.current_frame], x, y, 0, mirror, 1, draw_offset,
    draw_offset)
end

return Animation;
