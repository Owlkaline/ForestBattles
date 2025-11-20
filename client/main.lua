local bitser = require('lib/bitser')
local sock = require('lib/sock')
local Animation = require('shared/animation')

local Networking = require('shared/networking')
local Simulation = require('shared/simulation')

local Attack = require('shared/attacks')
local NewAnimation = require('shared/new_animation')

require('shared/players')
require('shared/schemas')
require('pixel')

IsClient = true;

local Mushroom = require('shared/characters/mushroom')

local green_colour = { 0, 1, 0, 1 }
local blue_colour = { 0, 0, 1, 1 }

local player_num = nil;
local simulation = {}

--local world_size = {};
-- TODO: get from server
local world_size = { width = 320 * 2.0, height = 180 * 2.0 }

local keys_down_this_tick = {}

local background = {}
local sim = {}

function love.load()
  love.window.setTitle("ForstBattles-Client")
  Pixel:load();

  background = love.graphics.newImage("assets/title-screen.png")

  Client = sock.newClient("localhost", 22123)

  RegisterFunctions(bitser)
  Client:setSerialization(bitser.dumps, bitser.loads)

  SetSchemas(Client)

  Client:on("connect", function(data)
    print("Connected to server")

    sim = Simulation.new(1);
  end);

  Client:on("disconnect", function(data)
    print("Disconnected from server")
  end);

  Client:on("assignPlayerNumber", function(data)
    print(data.game_state.players)
    print(data.game_state.objects)
    print(data.game_state.inputs)
    print(data.game_state.frame)
    print(data.game_state.fixed_dt)
    print("got assigned number, game state starts from frame: " .. data.game_state.frame)
    player_num = data.idx

    print(data.game_state.inputs)
    sim = Simulation.new(data.game_state.frame);
    Simulation.setGameState(sim, data.game_state)
  end)

  Client:on("addInput", function(data)
    if player_num == nil then
      return
    end
    local idx = data.idx;
    Simulation.add_inputs_for_frame(sim, idx, data.frame, data.input)
  end)

  Client:on("addObject", function(object)
    if player_num == nil then
      return
    end
    Simulation.add_object_with_id(sim, object.frame, object.idx, object.x, object.y, object.width, object.height,
      object.isFloor,
      object.isWall,
      object.isAttackBox, object.isDeath);
  end)

  Client:on("addPlayer", function(new_player)
    if player_num == nil then
      return
    end

    local frame = new_player.frame;
    if Simulation.latest_frame(sim) < frame then
      frame = Simulation.latest_frame(sim)
    end

    print(" got add player: " ..
      new_player.idx .. " on frame " .. new_player.frame .. "  current frame: " .. Simulation.latest_frame(sim))
    Simulation.add_player(sim, frame, new_player.idx, new_player.x, new_player.y, new_player.width,
      new_player.height,
      new_player.vel_x,
      new_player.vel_y)
  end)

  Client:on("removePlayer", function(player)
    if player_num == nil then
      return
    end
    print("Removing player")
    Simulation.remove_player(sim, player.frame, player.idx)
  end)


  Client:connect();
end

function love.update(dt)
  Client:update();

  if player_num then
    if Client:getState() == 'connected' then
      if love.keyboard.isDown("a") then
        keys_down_this_tick[Action.Left] = true;
      end

      if love.keyboard.isDown("r") then
        Simulation.resimulate_from_frame(sim, 50);
      end

      --if love.keyboard.isDown("s") then
      --  keys_down_this_tick["s"] = true;
      --end
      if love.keyboard.isDown("d") then
        keys_down_this_tick[Action.Right] = true;
      end
      if love.keyboard.isDown("space") then
        keys_down_this_tick[Action.Jump] = true;
      end
      if love.keyboard.isDown("p") then
        keys_down_this_tick[Action.Attack1] = true
      end
      if love.keyboard.isDown("o") then
        keys_down_this_tick[Action.Attack2] = true
      end
      if love.keyboard.isDown("i") then
        keys_down_this_tick[Action.SpecialAttack] = true;
      end

      --local joysticks = love.joystick.getJoysticks();
      --for _, joystick in pairs(joysticks) do
      --  local x_axis, y_axis = joystick:getAxis(1), joystick:getAxis(2);
      --  if x_axis < -0.1 then
      --    keys_down_this_tick[Action.Left] = true;
      --  end
      --  if x_axis > 0.1 then
      --    keys_down_this_tick[Action.Right] = true;
      --  end
      --  if joystick:isGamepadDown('b') then
      --    keys_down_this_tick[Action.Attack1] = true;
      --  end
      --  if joystick:isGamepadDown('x') then
      --    keys_down_this_tick[Action.Attack2] = true;
      --  end
      --  if joystick:isGamepadDown('y') then
      --    keys_down_this_tick[Action.SpecialAttack] = true;
      --  end
      --  if joystick:isGamepadDown('a') then
      --    keys_down_this_tick[Action.Jump] = true;
      --  end
      --end

      -- Did progress t oa new frame
      if Simulation.update(sim, dt) then
        local previous_frame = Simulation.latest_frame(sim);
        -- game updates
        Simulation.add_inputs_for_frame(sim, player_num, previous_frame, keys_down_this_tick);
        Client:send("addInput", { player_num, previous_frame, keys_down_this_tick })
        keys_down_this_tick = {}
      end

      for _, player in pairs(Simulation.get_players(sim)) do
        Animation.update(player.animation, dt);
      end
    end

    local players = Simulation.get_players(sim);
    if players[player_num] ~= nil then
      Pixel:followEntity(players[player_num], world_size);
    end
  end
end

function love.draw()
  Pixel:startDraw();

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(background, -Pixel.canvas:getWidth() * 0.5, -Pixel.canvas:getHeight() * 0.5)

  if player_num == nil then
    Pixel:endDraw()
    return
  end

  for i, player in pairs(Simulation.get_players(sim)) do
    if player.x == nil then
      goto continue
    end
    if i == 1 then
      love.graphics.setColor(0.8, 1, 0.8, 1)
    else
      love.graphics.setColor(1, 0.8, 0.8, 1)
    end

    Players.draw(player)
    --love.graphics.draw(SpriteSheetExample, SpriteSheetFrames[CurrentFrame], player.x, player.y); --, player.width, player.height)
    --love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
    --love.graphics.rectangle("fill", player.x + player.width * 0.5, player.y - player.height, player.width,   player.height)
    ::continue::
  end

  love.graphics.setColor(0, 0, 1, 1)
  for i, object in pairs(Simulation.get_objects(sim)) do
    love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
  end
  love.graphics.setColor(1, 1, 1, 1)

  Pixel:endDraw();

  love.graphics.print(
    Client:getState() .. " Current Tick: " .. Simulation.latest_frame(sim),
    5, 5)
  love.graphics.print(
    Client:getState(),
    5, 5)
  if player_num then
    love.graphics.print("Player " .. player_num, 5, 25)
    love.graphics.print("Ping: " .. Client:getRoundTripTime(), 5, 45)
    love.graphics.print("Received: " .. string.format("%.2f", Client:getTotalReceivedData() / 1024) .. "kb", 5, 85);
    love.graphics.print("Sent: " .. string.format("%.2f", Client:getTotalSentData() / 1024) .. "kb", 5, 105);
    -- love.graphics.print("Damage " .. Simulation.players(simulation)[player_num].damage .. "%", 5, 45)
  else
    love.graphics.print("No player number assigned", 5, 25)
  end
end
