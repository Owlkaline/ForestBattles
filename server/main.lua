local bitser = require('lib/bitser')
local sock = require('lib/sock')

require('shared/player')
local Floor = require('shared/floor')
local Networking = require('shared/networking')

local world_size = {width = 320, height = 180}

local global_tick = 0;
local tick = 0

local players = {}
local floor = {}

function love.load()
  love.physics.setMeter(180) --the height of a meter our worlds will be 64px
  world = love.physics.newWorld(0, 9.81 * 64, true)
  --objects.ground.body = love.physics.newBody(world, 320 / 2, 180 - 10 / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
  --objects.ground.shape = love.physics.newRectangleShape(320, 10)           --make a rectangle with a width of 650 and a height of 50
  --objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape)

  tick = 0

  Server = sock.newServer("*", 22123);
  Server:setSerialization(bitser.dumps, bitser.loads)

  local floor_height = 10;
  local floor_width = world_size.width;
  local floor_x = 0.0;
  local floor_y = world_size.height - floor_height;
  objects = {}
  objects.ground = Floor.new(floor_x, floor_y, floor_width, floor_height);
  --objects.ground:AddPhysicsBody();

  objects.ground.body = love.physics.newBody(world, floor_x+floor_width*0.5, floor_y + floor_height*0.5) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
  objects.ground.shape = love.physics.newRectangleShape(floor_width, floor_height)           --make a rectangle with a width of 650 and a height of 50
  objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape)

  Server:on("connect", function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " connected.")
    local player = Player.new(10 * idx, 10 * idx);
    player.body = love.physics.newBody(world, player.x, player.y, 'dynamic');
    player.shape = love.physics.newRectangleShape(player.width * 0.5, player.height * 0.5);
    player.fixture = love.physics.newFixture(player.body, player.shape, 1);

    player.body:setFixedRotation(true);
    player.body:setInertia(0.2);

    players[idx] = player;
    --table.insert(players, idx, player)
    print("Server connect: " .. idx)
    client:send("spawnPlayer", { idx, x=player.x, y=player.y, global_tick=global_tick });
    client:send("AddObject", { x=objects.ground.x, y=objects.ground.y, width=objects.ground.width, height=objects.ground.height });
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
  world:update(dt)
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
      player:input(global_tick, Networking.tick_rate);
    end

    global_tick = global_tick + 1;

    for i, player in pairs(players) do
      local x, y = player.body:getX(), player.body:getY();
      Server:sendToAll('playerState', { global_tick = global_tick, index=i, x=x, y=y })
    end
  end
end
