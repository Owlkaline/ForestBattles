local bitser = require('lib/bitser')
local sock = require('lib/sock')

local bump = require('lib/bump')

require('shared/player')
require('shared/schemas')
local Floor = require('shared/floor')
local Networking = require('shared/networking')

local world_size = { width = 320, height = 180 }

local global_tick = 0;
local tick = 0

local objects = {}
local players = {}
local floor = {}
local world = {}

function love.load()
  --love.physics.setMeter(180) --the height of a meter our worlds will be 64px
  --world = love.physics.newWorld(0, 9.81 * 64, true)
  --objects.ground.body = love.physics.newBody(world, 320 / 2, 180 - 10 / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
  --objects.ground.shape = love.physics.newRectangleShape(320, 10)           --make a rectangle with a width of 650 and a height of 50
  --objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape)

  tick = 0

  Server = sock.newServer("*", 22123);
  Server:setSerialization(bitser.dumps, bitser.loads)
  print("Server started.")
  SetSchemas(Server);

  world = bump.newWorld();
  world:addResponse('push', function(world, col, x, y, w, h, goalX, goalY, filter)
    goalX           = goalX or x
    goalY           = goalY or y

    local tch, move = col.touch, col.move

    if move.x > 0 then
      if col.normal.x ~= 0 then
        col.other.x = goalX + col.other.width;
        goalX = tch.x;
      end
    end
    if move.x < 0 then
      if col.normal.x ~= 0 then
        col.other.x = goalX - col.other.width;
        goalX = tch.x;
      end
    end

    col.push        = { x = goalX, y = goalY }

    --x, y            = tch.x, tch.y
    local cols, len = world:project(col.item, x, y, w, h, goalX, goalY, filter)
    return goalX, goalY, cols, len
  end)

  print("world created")

  local floor_height = 10;
  local floor_width = world_size.width * 0.5;
  local floor_x = 0.0;
  local floor_y = world_size.height - floor_height;
  objects[0] = Floor.new(floor_x, floor_y, floor_width, floor_height);

  world:add(objects[0], floor_x, floor_y, floor_width, floor_height);

  --objects[0].body = love.physics.newBody(world, floor_x + floor_width * 0.5, floor_y + floor_height * 0.5) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
  --objects[0].shape = love.physics.newRectangleShape(floor_width, floor_height)                             --make a rectangle with a width of 650 and a height of 50
  --objects[0].fixture = love.physics.newFixture(objects[0].body, objects[0].shape)

  Server:on("connect", function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " connected.")
    local player = Player.new(10 * idx, 10 * idx);
    --player.body = love.physics.newBody(world, player.x + player.width * 0.5, player.y + player.height * 0.5, 'dynamic');
    --player.shape = love.physics.newRectangleShape(player.width, player.height);
    --player.fixture = love.physics.newFixture(player.body, player.shape, 1);

    --player.body:setFixedRotation(true);
    --player.body:setInertia(0.2);

    players[idx] = player;
    world:add(players[idx], player.x, player.y, player.width, player.height)
    --table.insert(players, idx, player)
    print("Server connect: " .. idx)


    client:send("spawnPlayer", { idx, player.x, player.y, global_tick });
    for _, object in pairs(objects) do
      client:send("addObject", { object.x, object.y, object.width, object.height });
    end
  end)

  Server:on('disconnect', function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " disconnected.")
    players[idx] = nil
    --table.remove(players, idx);

    Server:sendToAll("playerDisconnected", idx);
  end)

  --Server:setSchema('playerPosition', { "x", 'y' })
  --Server:on('playerPosition', function(position, client)
  --  local idx = client:getIndex()
  --  players[idx].x = position.x;
  --  players[idx].y = position.y;
  --end)

  Server:setSchema("playerInput", { "global_index", "player_input" })
  Server:on('playerInput', function(data, client)
    local idx = client:getIndex();
    if players[idx] then
      players[idx].inputs[data.global_index] = data.player_input;
    end
  end)
end

function love.update(dt)
  --world:update(dt)
  Server:update()

  --for i, player in ipairs(players) do
  --  if player.x < 0 then
  --    player.x = 0;
  --  end
  --  if player.x > 500.0 then
  --    player.x = 500.0;
  --  end
  --  if player.y < 0 then
  --    player.y = 0;
  --  end
  --  if player.y > 500.0 then
  --    player.y = 500.0;
  --  end
  --end

  tick = tick + dt;

  if tick >= Networking.tick_rate then
    tick = tick - Networking.tick_rate;

    -- run everything from current tick
    for i, player in pairs(players) do
      player.y = player.y + 98.0 * Networking.tick_rate;
      player:input(global_tick, Networking.tick_rate);
      local new_x, new_y, cols, len = world:move(player, player.x, player.y, player:filter());
      player.x = new_x;
      player.y = new_y;
      for j = 1, len do
        --   print('collided with ' .. tostring(cols[j].other))
      end
    end

    global_tick = global_tick + 1;

    for i, player in pairs(players) do
      local x, y = player.x, player.y;
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
