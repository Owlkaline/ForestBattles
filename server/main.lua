local bitser = require('lib/bitser')
local sock = require('lib/sock')

local bump = require('lib/bump')

require('shared/useful')
require('shared/players')
require('shared/schemas')
local Floor = require('shared/floor')
local Bounce = require('shared/bounce')
local Networking = require('shared/networking')
local Simulation = require('shared/simulation')

local world_size = { width = 320 * 2.0, height = 180 * 2.0 }

local simulation = {};

--local global_tick = 0;
--local tick = 0

--local objects = {}
--local players = {}
--local world = {}
--local attack_boxs = {}

--local hurt = function(world, col, x, y, w, h, goalX, goalY, filter)
--  local atk_box = col.item.isAttackBox and col.item or col.other
--  local player = col.item.isAttackBox and col.other or col.item
--
--  if SetContains(atk_box.players_hit, player) == false then
--    player.damage = player.damage + atk_box.damage;
--    print("Damge dealt!")
--    table.insert(atk_box.players_hit, player);
--  end
--end

function love.load()
  tick = 0

  Server = sock.newServer("*", 22123);
  Server:setSerialization(bitser.dumps, bitser.loads)
  print("Server started.")
  SetSchemas(Server);

  --world = bump.newWorld();
  --world:addResponse('push', push)
  --world:addResponse('velocity_bounce', velocity_bounce)

  simulation = Simulation.new(Networking.tick_rate)

  print("world created")

  local objects = {};

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
    Simulation.spawn_object(simulation, object)
  end

  Server:on("connect", function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " connected.")
    local x, y = Simulation.spawn_player(simulation, idx, Character.Mushroom)
    local tick = Simulation.current_tick(simulation);
    --local player = Players.new(0 * (idx * 10), -10.0, Character.Mushroom);

    --player.index = idx;
    --players[idx] = player;
    --world:add(players[idx], player.x, player.y, player.width, player.height)
    print("Server connect: " .. idx)

    client:send("spawnPlayer", { idx, x, y, tick });
    client:send("worldSize", { world_size.width, world_size.height })
    for i, object in pairs(Simulation.objects(simulation)) do
      client:send("addObject", { i, object.x, object.y, object.width, object.height });
    end
  end)

  Server:on('disconnect', function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " disconnected.")
    Simulation.despawn_player(simulation, idx)
    --world:remove(players[idx]);
    --players[idx] = nil

    Server:sendToAll("playerDisconnected", idx);
  end)

  Server:on('playerInput', function(data, client)
    local idx = client:getIndex();
    local tick_idx = data.client_tick;
    Simulation.add_input(simulation, idx, tick_idx, data.player_input)
    --if players[idx] then
    --  players[idx].inputs[data.global_index] = data.player_input;
    --end
  end)
end

local function send_player_states()
  local current_tick = Simulation.current_tick(simulation);
  for _, player in pairs(Simulation.players(simulation)) do
    local x, y, idx = player.x, player.y, player.index;
    Server:sendToAll('playerState', { current_tick, idx, x, y, player.damage })
  end
end

function love.update(dt)
  Server:update()

  local did_update, new_objects = Simulation.lockstep_update(simulation, dt);
  --local did_update, new_objects = Simulation.yolo_update(simulation, dt);

  if did_update then
    -- print("sending player data")
    for _, box in pairs(new_objects) do
      Server:sendToAll("addObject", { 99999, box.x, box.y, box.width, box.height });
    end
    send_player_states()
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
