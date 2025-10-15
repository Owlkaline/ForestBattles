local bitser = require('lib/bitser')
local sock = require('lib/sock')

require('shared/player')
local Floor = require('shared/floor')
local Networking = require('shared/networking')

local global_tick = 0;
local tick = 0

local players = {}
local floor = {}

function love.load()
  tick = 0

  floor[0] = Floor.new()

  Server = sock.newServer("*", 22123);
  Server:setSerialization(bitser.dumps, bitser.loads)

  Server:on("connect", function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " connected.")
    local player = Player.new(10 * idx, 10 * idx);
    table.insert(players, idx, player)
    client:send("spawnPlayer", { idx, player.x, player.y, global_tick });
  end)

  Server:on('disconnect', function(data, client)
    local idx = client:getIndex();
    print("player " .. idx .. " disconnected.")
    table.remove(players, idx);
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
    players[idx].inputs[data.global_index] = data.player_input;
  end)
end

function love.update(dt)
  Server:update()

  for i, player in ipairs(players) do
    if player.x < 0 then
      player.x = 0;
    end
    if player.x > 500.0 then
      player.x = 500.0;
    end
    if player.y < 0 then
      player.y = 0;
    end
    if player.y > 500.0 then
      player.y = 500.0;
    end
  end

  tick = tick + dt;

  if tick >= Networking.tick_rate then
    tick = tick - Networking.tick_rate;

    -- run everything from current tick
    for i, player in ipairs(players) do
      player:input(global_tick, Networking.tick_rate);
    end

    global_tick = global_tick + 1;

    for i, player in ipairs(players) do
      Server:sendToAll('playerState', { global_tick, i, player.x, player.y })
    end
  end
end
