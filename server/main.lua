local bitser = require('lib/bitser')
local sock = require('lib/sock')

local bump = require('lib/bump')
local Attack = require('shared/attacks')
local NewAnimation = require('shared/new_animation')

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

  RegisterFunctions(bitser)
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
      object.isAttackBox,
      object.isDeath);
  end

  print("objects added")

  Server:on("connect", function(data, client)
    print("client connected")
    local idx = client:getIndex();

    local current_frame = Simulation.latest_frame(sim)

    local new_player = Players.new(0, -10, Character.Mushroom)

    local state = sim.rb.game_states[Simulation.latest_frame(sim)];
    local worldless_game_state =
    {
      objects = state.objects,
      inputs = sim.player_inputs,
      frame = state.frame,
      fixed_dt = state.fixed_dt
    }

    print(worldless_game_state.objects)
    print(worldless_game_state.inputs)
    print(worldless_game_state.frame)
    print(worldless_game_state.fixed_dt)

    print("Player " .. idx .. " connected")
    client:send("assignPlayerNumber", { idx, current_frame, worldless_game_state })

    Simulation.add_player(sim, current_frame, idx, new_player.x, new_player.y, new_player.width, new_player.height,
      new_player.velocity
      .x, new_player.velocity.y)
    Server:sendToAllBut(client, "addPlayer",
      { current_frame, idx, new_player.x, new_player.y, new_player.width, new_player.height, new_player.velocity.x,
        new_player.velocity.y })

    for _, player in pairs(Simulation.get_players(sim)) do
      client:send("addPlayer",
        { current_frame, player.index, player.x, player.y, player.width, player.height, player.velocity.x,
          player.velocity.y })
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

  love.graphics.print(
    " Current Tick: " .. Simulation.latest_frame(sim),
    5, 5)

  love.graphics.pop();
end
