local bitser = require('lib/bitser')
local sock = require('lib/sock')

local Networking = require('shared/networking')
require('shared/player')
require('shared/schemas')
require('pixel')

local green_colour = { 0, 1, 0, 1 }
local blue_colour = { 0, 0, 1, 1 }

local player_num = nil;
local players = {}
local objects = {}
local tick = 0

local global_tick = 0;
local server_tick = 0;
local world_size = 0;

local keys_down_this_tick = {}

local background = {};

function love.load()
  Pixel:load();

  background = love.graphics.newImage("assets/title-screen.png")

  Client = sock.newClient("localhost", 22123)
  --Client = sock.newClient("owlkaline.com", 22123);
  Client:setSerialization(bitser.dumps, bitser.loads)
  SetSchemas(Client)

  Client:on("connect", function(data)
    print("Connected to server")
  end);

  Client:on("disconnect", function(data)
    print("Disconnected from server")
  end);

  Client:on("playerDisconnected", function(idx)
    print("Player " .. idx .. " Disconnected!")
    players[idx] = nil
  end);

  Client:on("worldSize", function(actualWorldSize)
    print("world size: " .. actualWorldSize.width)
    world_size = actualWorldSize;
  end);

  Client:on("spawnPlayer", function(data)
    local idx = data.index;
    print("Client SpawnPlayer: " .. data.index)
    local x = data.x;
    local y = data.y;
    local gt = data.global_tick;
    global_tick = gt;

    player_num = idx;
    players[idx] = Player.new(x, y)
  end);

  Client:on('playerState', function(data)
    local g_tick = data.global_tick
    server_tick = g_tick;
    local idx = data.index;
    local x = data.x;
    local y = data.y;

    if players[idx] then
      players[idx].x = x;
      players[idx].y = y;
    else
      players[idx] = Player.new(x, y);
    end

    if idx == player_num then
      Pixel:followEntity(players[player_num], world_size);
    end
  end)

  Client:on("addObject", function(object)
    local idx = object.idx;
    objects[idx] = {}
    print(object.x)
    print(object.y)
    print(object.width)
    print(object.height)
    objects[idx] = object;
  end);


  --Client:on("ballState", function(data)
  --  ball = data
  --end)

  Client:connect();
end

function love.update(dt)
  Client:update();

  if player_num then
    if Client:getState() == 'connected' then
      tick = tick + dt;

      --if love.keyboard.isDown("w") then
      --  keys_down_this_tick["w"] = true;
      --end
      if love.keyboard.isDown("a") then
        keys_down_this_tick["left"] = true;
      end
      --if love.keyboard.isDown("s") then
      --  keys_down_this_tick["s"] = true;
      --end
      if love.keyboard.isDown("d") then
        keys_down_this_tick["right"] = true;
      end
      if love.keyboard.isDown("space") then
        keys_down_this_tick["jump"] = true;
      end

      local joysticks = love.joystick.getJoysticks();
      for _, joystick in pairs(joysticks) do
        local x_axis, y_axis = joystick:getAxis(1), joystick:getAxis(2);
        if x_axis < -0.1 then
          keys_down_this_tick['left'] = true;
        end
        if x_axis > 0.1 then
          keys_down_this_tick['right'] = true;
        end
        if joystick:isGamepadDown('a') then
          keys_down_this_tick['jump'] = true;
        end
      end

      if tick >= Networking.tick_rate then
        tick = tick - Networking.tick_rate
        global_tick = global_tick + 1;
        if global_tick > server_tick then
          global_tick = server_tick;
        end
        while global_tick <= server_tick do
          global_tick = global_tick + 1;
        end

        if player_num then
          --   Client:setSchema('playerPosition', { "x", 'y' })
          --  Client:send('playerPosition', { players[player_num].x, players[player_num].y })
          Client:send("playerInput", { global_tick, keys_down_this_tick })
          keys_down_this_tick = {}

          Pixel:followEntity(players[player_num], world_size);
          --  Pixel.camera:FollowEntity(players[player_num]);
        end
      end
    end
  end
end

function love.draw()
  Pixel:startDraw();

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(background, -Pixel.canvas:getWidth() * 0.5, -Pixel.canvas:getHeight() * 0.5)

  for i, player in pairs(players) do
    if player.x == nil then
      goto continue
    end
    if i == 1 then
      love.graphics.setColor(0, 1, 0, 1)
    else
      love.graphics.setColor(1, 0, 0, 1)
    end
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
    --love.graphics.rectangle("fill", player.x + player.width * 0.5, player.y - player.height, player.width,   player.height)
    ::continue::
  end

  love.graphics.setColor(0, 0, 1, 1)
  for _, object in pairs(objects) do
    love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
  end
  love.graphics.setColor(1, 1, 1, 1)

  Pixel:endDraw();

  love.graphics.print(
    Client:getState() .. " Gloal Tick: " .. global_tick .. " Difference: " .. global_tick - server_tick,
    5, 5)
  if player_num then
    love.graphics.print("Player " .. player_num, 5, 25)
  else
    love.graphics.print("No player number assigned", 5, 25)
  end
end
