local bitser = require('lib/bitser')
local sock = require('lib/sock')

local bump = require('lib/bump')

require('shared/useful')
require('shared/players')
require('shared/schemas')
local Map = require('shared/map')
local Floor = require('shared/floor')
local Bounce = require('shared/bounce')
local Networking = require('shared/networking')
local Simulation = require('shared/simulation')

local world_size = { width = 320 * 2.0, height = 180 * 2.0 }

local sim = {};


function love.load()
  love.window.setTitle("ForstBattles-Server")
  Server = sock.newServer("*", 22123);
  Server:setSerialization(bitser.dumps, bitser.loads)
  print("Server started.")
  SetSchemas(Server);

  sim = Simulation.new(1);
  Simulation.debug(sim, true)
  print("simlation created")
  local objects = Map.get_objects(world_size)
  local start_frame = Simulation.latest_frame(sim)

  for _, object in pairs(objects) do
    Simulation.add_object(sim, start_frame, object.x, object.y, object.width, object.height, object.isFloor,
      object.isWall,
      object.isAttackBox);
  end

  print("objects added")

  --= local new_player = Players.new(0, -10, Character.Mushroom)
  --= Simulation.add_player(sim, 1, 1, new_player.x, new_player.y, new_player.width, new_player.height,
  --=   new_player.velocity
  --=   .x, new_player.velocity.y)

  Server:on("connect", function(data, client)
    print("client connected")
    local idx = client:getIndex();

    local current_frame = Simulation.latest_frame(sim)

    local new_player = Players.new(0, -10, Character.Mushroom)

    print("Player " .. idx .. " connected")
    client:send("assignPlayerNumber", { idx, current_frame })

    Simulation.add_player(sim, current_frame, idx, new_player.x, new_player.y, new_player.width, new_player.height,
      new_player.velocity
      .x, new_player.velocity.y)
    Server:sendToAll("addPlayer",
      { current_frame, idx, new_player.x, new_player.y, new_player.width, new_player.height, new_player.velocity.x,
        new_player.velocity.y })

    for frame, events in pairs(Simulation.events(sim)) do
      for _, event in pairs(events) do
        print("Event: " .. tostring(event))
        print("frame " .. frame .. " :" .. " " .. tostring(event.idx) .. " " .. tostring(event.type))
        if event.type == Events.AddObject then
          print("Event idx: " .. event.idx)
          local object = Simulation.get_object_from_frame(sim, frame, event.idx)
          client:send("addObject",
            { frame, event.idx, object.x, object.y, object.width, object.height, object.isFloor, object.isWall, object
                .isAttackBox });
        elseif event.type == Events.AddPlayer then
          local player = Simulation.get_player_from_frame(sim, frame, event.idx)
          client:send("addPlayer",
            { frame, idx, player.x, player.y, player.width, player.height, player.velocity.x, player
                .velocity.y })
        elseif event.type == Events.RemovePlayer then
          client:send("removePlayer", { frame, idx })
        end
      end
    end
    local all_inputs = Simulation.get_all_inputs(sim);
    for player_idx, inputs_per_player in pairs(all_inputs) do
      for frame, inputs_on_frame in pairs(inputs_per_player) do
        client:send("addInput", { player_idx, frame, inputs_on_frame })
      end
    end
  end)

  Server:on('disconnect', function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " disconnected.")
    local current_frame = Simulation.latest_frame(sim)
    Simulation.remove_player(sim, current_frame, idx)

    Server:sendToAll("removePlayer", { current_frame, idx });
  end)

  Server:on("addInput", function(data, client)
    local idx = client:getIndex();

    Simulation.add_inputs_for_frame(sim, idx, data.frame, data.input)

    Server:sendToAllBut(client, "addInput", { idx, data.frame, data.input })
  end)
end

function love.update(dt)
  Server:update()

  local new_input = false;
  local keys_down_this_tick = {}
  if love.keyboard.isDown("space") then
    keys_down_this_tick[3] = true;
    new_input = true;
  end

  if love.keyboard.isDown("a") then
    keys_down_this_tick[1] = true;
    new_input = true;
  end

  Simulation.add_inputs_for_frame(sim, 1, Simulation.latest_frame(sim) - 1, keys_down_this_tick)

  Simulation.update(sim, dt)
end

function love.draw()
  love.graphics.push();
  --love.graphics.scale(0.5);
  love.graphics.translate(world_size.width * 0.5, world_size.height * 0.5)

  love.graphics.setColor(0, 0, 1, 1)

  local frame = Simulation.latest_frame(sim);
  for i, player in pairs(sim.rb.game_states[frame].players) do
    if player.x == nil then
      goto continue
    end
    if i == 1 then
      love.graphics.setColor(0, 1, 0, 1)
    else
      love.graphics.setColor(1, 0, 0, 1)
    end

    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
    ::continue::
  end

  for _, object in pairs(sim.rb.game_states[frame].objects) do
    love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
  end
  love.graphics.setColor(1, 1, 1, 1)

  love.graphics.pop();
end

--function love.load()
--    tick = 0
--
--    Server = sock.newServer("*", 22123);
--    Server:setSerialization(bitser.dumps, bitser.loads)
--    print("Server started.")
--    SetSchemas(Server);
--
--    --world = bump.newWorld();
--    --world:addResponse('push', push)
--    --world:addResponse('velocity_bounce', velocity_bounce)
--
--    simulation = Simulation.new(Networking.tick_rate)
--
--    print("world created")
--
--    local objects = {};
--
--    local floor_height = 10;
--    local floor_width = 160.0;
--    local floor_x = -floor_width * 0.5;
--    local floor_y = -floor_height;
--    objects[0] = Floor.new(floor_x, floor_y, floor_width, floor_height);
--
--    local bounds_thickness = 5.0;
--    local width = world_size.width;
--    local height = world_size.height;
--    local half_height = height * 0.5
--    local half_width = width * 0.5
--    local half_thickness = bounds_thickness * 0.5;
--    local bottom = half_height;
--    local top = -half_height;
--    local left = -half_width;
--    local right = half_width;
--    -- left wall
--    objects[1] = Bounce.new(left - bounds_thickness, -half_height, bounds_thickness, height);
--    -- top
--    -- player underneath
--    -- height 180 -16 = 164
--    -- top top 164+5 = 169
--    objects[2] = Bounce.new(left, top - bounds_thickness, width, bounds_thickness);
--    -- right
--    objects[3] = Bounce.new(right, -half_height, bounds_thickness, height);
--
--    -- 640 x 360
--    -- x = -320
--    -- width = 640
--    -- y = 180
--    -- height = 5
--    -- bottom
--    objects[4] = Bounce.new(left, bottom, width, bounds_thickness);
--
--    for _, object in pairs(objects) do
--        Simulation.spawn_object(simulation, object)
--    end
--
--    Server:on("connect", function(data, client)
--        local idx = client:getIndex();
--        print("player " .. idx .. " connected.")
--        local x, y = Simulation.spawn_player(simulation, idx, Character.Mushroom)
--        local tick = Simulation.current_tick(simulation);
--        --local player = Players.new(0 * (idx * 10), -10.0, Character.Mushroom);
--
--        --player.index = idx;
--        --players[idx] = player;
--        --world:add(players[idx], player.x, player.y, player.width, player.height)
--        print("Server connect: " .. idx)
--
--        client:send("spawnPlayer", { idx, x, y, tick });
--        client:send("worldSize", { world_size.width, world_size.height })
--        for i, object in pairs(Simulation.objects(simulation)) do
--            --client.send("addObject", { object })
--            client:send("addObject",
--                { i, object.x, object.y, object.width, object.height, object.isFloor, object.isWall });
--        end
--    end)
--
--    Server:on('disconnect', function(data, client)
--        local idx = client:getIndex();
--        print("player " .. idx .. " disconnected.")
--        Simulation.despawn_player(simulation, idx)
--        --world:remove(players[idx]);
--        --players[idx] = nil
--
--        Server:sendToAll("playerDisconnected", idx);
--    end)
--
--    Server:on("playerAnimation", function(data, client)
--        local idx = client:getIndex();
--        Server:sendToAllBut(client, "animationState", { idx, data.animation })
--    end);
--
--    Server:on('playerInput', function(data, client)
--        local idx = client:getIndex();
--        local tick_idx = data.client_tick;
--        Simulation.add_input(simulation, idx, tick_idx, data.player_input)
--        --if players[idx] then
--        --  players[idx].inputs[data.global_index] = data.player_input;
--        --end
--    end)
--end
--
--local function send_player_states()
--    local current_tick = Simulation.current_tick(simulation);
--    for _, player in pairs(Simulation.players(simulation)) do
--        local x, y, idx = player.x, player.y, player.index;
--        Server:sendToAll('playerState',
--            { current_tick, idx, x, y, player.damage, player.velocity.x, player.velocity.y, player.facing_left })
--    end
--end
--
--function love.update(dt)
--    Server:update()
--
--    local did_update, new_objects = Simulation.lockstep_update(simulation, dt);
--    --local did_update, new_objects = Simulation.yolo_update(simulation, dt);
--
--    if did_update then
--        -- print("sending player data")
--        --for _, box in pairs(new_objects) do
--        --    Server:sendToAll("addObject", { 99999, box.x, box.y, box.width, box.height, box.isFloor, box.isWall });
--        --end
--        send_player_states()
--        local new_tick = Simulation.current_tick(simulation)
--        Server:sendToAll("finishedUpdate", { tick = new_tick });
--    end
--end
--
--function love.draw()
--    --for _, player in pairs(players) do
--    --  love.graphics.polygon("fill", player.body:getWorldPoints(
--    --    player.shape:getPoints()))
--    --end
--    --for _, object in pairs(objects) do
--    --  love.graphics.polygon("fill", object.body:getWorldPoints(
--    --    object.shape:getPoints()))
--    --end
--
--    love.graphics.push();
--    --love.graphics.scale(0.5);
--    love.graphics.translate(world_size.width * 0.5, world_size.height * 0.5)
--
--    love.graphics.setColor(0, 0, 1, 1)
--
--    for i, player in pairs(Simulation.players(simulation)) do
--        if player.x == nil then
--            goto continue
--        end
--        if i == 1 then
--            love.graphics.setColor(0, 1, 0, 1)
--        else
--            love.graphics.setColor(1, 0, 0, 1)
--        end
--
--        love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
--        ::continue::
--    end
--
--    for _, object in pairs(Simulation.objects(simulation)) do
--        love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
--    end
--    love.graphics.setColor(1, 1, 1, 1)
--
--    love.graphics.pop();
--end
