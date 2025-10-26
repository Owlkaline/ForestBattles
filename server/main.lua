local bitser = require('lib/bitser')
local sock = require('lib/sock')

local bump = require('lib/bump')

require('shared/useful')
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
  end)

  print("world created")

  local floor_height = 10;
  local floor_width = world_size.width * 0.5;
  local floor_x = 0.0;
  local floor_y = world_size.height - floor_height;
  objects[0] = Floor.new(floor_x, floor_y, floor_width, floor_height);

  world:add(objects[0], floor_x, floor_y, floor_width, floor_height);

  Server:on("connect", function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " connected.")
    local player = Player.new(10 * idx, 10 * idx);

    player.index = idx;
    players[idx] = player;
    world:add(players[idx], player.x, player.y, player.width, player.height)
    print("Server connect: " .. idx)


    client:send("spawnPlayer", { idx, player.x, player.y, global_tick });
    for _, object in pairs(objects) do
      client:send("addObject", { object.x, object.y, object.width, object.height });
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
