local bitser = require('lib/bitser')
local sock = require('lib/sock')

local bump = require('lib/bump')

require('shared/useful')
require('shared/player')
require('shared/schemas')
local Floor = require('shared/floor')
local Bounce = require('shared/bounce')
local Networking = require('shared/networking')

local world_size = { width = 320 * 2.0, height = 180 * 2.0 }

local global_tick = 0;
local tick = 0

local objects = {}
local players = {}
local floor = {}
local world = {}

local push = function(world, col, x, y, w, h, goalX, goalY, filter)
  goalX           = goalX or x
  goalY           = goalY or y

  local tch, move = col.touch, col.move

  local is_below  =
      col.item.y - col.other.y > 0

  if col.other.grounded then
    if col.item.x > col.other.x then
      goalX = col.item.x + col.other.width * (0.1 * DefaultWeight) / col.other.weight
    else
      goalX = col.item.x - col.other.width * (0.1 * DefaultWeight) / col.other.weight;
    end
  end

  col.push        = { x = goalX, y = goalY }

  local cols, len = world:project(col.item, x, y, w, h, goalX, goalY, filter)

  return goalX, goalY, cols, len
end

local velocity_bounce = function(world, col, x, y, w, h, goalX, goalY, filter)
  goalX = goalX or x
  goalY = goalY or y

  local tch, move = col.touch, col.move
  local tx, ty = tch.x, tch.y

  local bx, by = tx, ty

  goalX = tch.x;
  goalY = tch.y;

  if col.normal.x ~= 0 then
    col.item.velocity.x = col.normal.x * 300.0;
    col.item.velocity.y = -300.0;
  end
  if col.normal.y ~= 0 then
    local diff = col.item.x - col.other.x - col.other.width * 0.5;
    col.item.velocity.x = -Sign(diff) * 300; --math.min(math.abs(diff), 300.0);
    col.item.velocity.y = col.normal.y * 300.0;
  end

  local cols, len = world:project(col.item, x, y, w, h, goalX, goalY, filter)
  return goalX, goalY, cols, len
end

function love.load()
  tick = 0

  Server = sock.newServer("*", 22123);
  Server:setSerialization(bitser.dumps, bitser.loads)
  print("Server started.")
  SetSchemas(Server);

  world = bump.newWorld();
  world:addResponse('push', push)
  world:addResponse('velocity_bounce', velocity_bounce)

  print("world created")

  local floor_height = 10;
  local floor_width = 160.0;
  local floor_x = -floor_width * 0.5;
  local floor_y = -floor_height;
  objects[0] = Floor.new(floor_x, floor_y, floor_width, floor_height);

  local bounds_thickness = 5.0;
  local width = world_size.width;
  local height = world_size.height;
  local half_height = height * 0.5
  local half_width = width * 0.5
  local half_thickness = bounds_thickness * 0.5;
  local bottom = half_height;
  local top = -half_height;
  local left = -half_width;
  local right = half_width;
  -- left wall
  objects[1] = Bounce.new(left - bounds_thickness, -half_height, bounds_thickness, height);
  -- top
  -- player underneath
  -- height 180 -16 = 164
  -- top top 164+5 = 169
  objects[2] = Bounce.new(left, top - bounds_thickness, width, bounds_thickness);
  -- right
  objects[3] = Bounce.new(right, -half_height, bounds_thickness, height);

  -- 640 x 360
  -- x = -320
  -- width = 640
  -- y = 180
  -- height = 5
  -- bottom
  objects[4] = Bounce.new(left, bottom, width, bounds_thickness);

  for _, object in pairs(objects) do
    world:add(object, object.x, object.y, object.width, object.height);
  end

  Server:on("connect", function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " connected.")
    local player = Player.new(0 * (idx * 10), -10.0);

    player.index = idx;
    players[idx] = player;
    world:add(players[idx], player.x, player.y, player.width, player.height)
    print("Server connect: " .. idx)


    client:send("spawnPlayer", { idx, player.x, player.y, global_tick });
    client:send("worldSize", { world_size.width, world_size.height })
    for i, object in pairs(objects) do
      client:send("addObject", { i, object.x, object.y, object.width, object.height });
    end
  end)

  Server:on('disconnect', function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " disconnected.")
    world:remove(players[idx]);
    players[idx] = nil
    --table.remove(players, idx);

    Server:sendToAll("playerDisconnected", idx);
  end)

  Server:setSchema("playerInput", { "global_index", "player_input" })
  Server:on('playerInput', function(data, client)
    local idx = client:getIndex();
    if players[idx] then
      players[idx].inputs[data.global_index] = data.player_input;
    end
  end)
end

function love.update(dt)
  Server:update()

  tick = tick + dt;

  if tick >= Networking.tick_rate then
    tick = tick - Networking.tick_rate;

    -- run everything from current tick
    for i, player in pairs(players) do
      local initial_y = player.velocity.y;
      player.velocity.y = player.velocity.y + player.weight * 98.0 * Networking.tick_rate;
      --player.y = player.y + 98.0 * Networking.tick_rate;
      player:input(global_tick, Networking.tick_rate);


      player:move(Networking.tick_rate)
      local new_x, new_y, cols, len = world:move(player, player.x, player.y, player:filter());
      player.x = new_x;
      player.y = new_y;
      player.grounded = false
      for j = 1, len do
        --if cols[j].other.isPlayer then
        --  local other_player = cols[j].other;
        --  local is_below =
        --      player.y - other_player.y > 0

        --  if other_player.grounded then                      --and other_player.y < player.y then
        --    if player.x > other_player.x then                -- + other_player.width then
        --      player.x = player.x + other_player.width * 0.1 --other_player.x + other_player.width * 0.1;
        --    else
        --      player.x = player.x - player.width * 0.1;      --other_player.x - player.width * 0.1;
        --    end
        --  end
        --end
        if cols[j].other.isDeath then
          player.x = 0;
          player.y = -10;
          world:update(player, player.x, player.y)
          player.velocity.x = 0;
          player.velocity.y = 0;
          player.grounded = false;
        end

        if cols[j].other.isFloor then
          if cols[j].normal.y < 0 then
            player.grounded = true;
          end
        end
      end
    end

    global_tick = global_tick + 1;

    for i, player in pairs(players) do
      local x, y = player.x, player.y;
      --print("left side: " .. x)
      --print("right side: " .. x + player.width)
      --print("top side: " .. y)
      --print("bottom side: " .. y + player.height)
      Server:sendToAll('playerState', { global_tick, i, x, y })
    end
  end
end

function love.draw()
  --for _, player in pairs(players) do
  --  love.graphics.polygon("fill", player.body:getWorldPoints(
  --    player.shape:getPoints()))
  --end
  --for _, object in pairs(objects) do
  --  love.graphics.polygon("fill", object.body:getWorldPoints(
  --    object.shape:getPoints()))
  --end
end
