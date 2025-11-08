local bitser = require('lib/bitser')
local sock = require('lib/sock')

local Networking = require('shared/networking')
local Simulation = require('shared/simulation')
require('shared/players')
require('shared/schemas')
require('pixel')
local Mushroom = require('shared/characters/mushroom')
local Animation = require('animation')

local green_colour = { 0, 1, 0, 1 }
local blue_colour = { 0, 0, 1, 1 }

local player_num = nil;
local simulation = {}
--local players = {}
--local objects = {}
--local tick = 0

--local global_tick = 0;
local server_tick = 0;
local world_size = 0;

local keys_down_this_tick = {}

local background = {};
local objects = {};

function love.load()
    Pixel:load();

    --SpriteSheetAnimation = Animation.new('assets/mushroom_spritesheet.png', 32)
    --Animation.add_animation(SpriteSheetAnimation, "idle", 1, 1, true);
    --Animation.add_animation(SpriteSheetAnimation, "running", 17, 26, true);
    --Animation.add_animation(SpriteSheetAnimation, "jump", 33, 52, false)
    --Animation.add_animation(SpriteSheetAnimation, "punching_first_half", 65, 67, false);
    --Animation.add_animation(SpriteSheetAnimation, "punching_second_half", 68, 70, false);
    --Animation.play_animation(SpriteSheetAnimation, "idle")

    background = love.graphics.newImage("assets/title-screen.png")

    simulation = Simulation.new(Networking.tick_rate)

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
        --players[idx] = nil
        Simulation.despawn_player(simulation, idx)
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

        Simulation.spawn_player(simulation, idx, Character.Mushroom)
        Simulation.set_player_position(simulation, x, y, idx)
        Simulation.set_tick(simulation, gt)

        Simulation.players(simulation)[idx].animation = Mushroom.animation();

        --global_tick = gt;

        player_num = idx;
        --players[idx] = Players.new(x, y)
    end);

    Client:on('playerState', function(data)
        local g_tick = data.global_tick
        -- server_tick = g_tick;
        local idx = data.index;
        --local x = data.x;
        --local y = data.y;
        --local damage = data.damage;
        --local vel_y = data.vel_y;
        --local vel_x = data.vel_x;
        --local facing_left = data.facing_left;

        if Simulation.players(simulation)[idx] then
        else
            Simulation.spawn_player(simulation, idx, Character.Mushroom)
            Simulation.players(simulation)[idx].animation = Mushroom.animation();
        end

        Simulation.update_player_state(simulation, idx, data);

        --Simulation.set_player_position(simulation, x, y, idx)
        --Simulation.set_player_damage(simulation, damage, idx)
        --Simulation.players(simulation)

        --if players[idx] then
        --  players[idx].x = x;
        --  players[idx].y = y;
        --
        --else
        --  players[idx] = Players.new(x, y);
        --end

        --players[idx].damage = damage;

        if idx == player_num then
            Pixel:followEntity(Simulation.players(simulation)[player_num], world_size);
        end
    end)

    Client:on("animationState", function(data)
        local player_idx = data.idx;
        local animation = data.animation;

        if Simulation.players(simulation)[player_idx] ~= nil then
            Animation.play_animation(Simulation.players(simulation)[player_idx].animation, animation);
        end
    end)

    Client:on("addObject", function(object)
        object.y = object.y
        objects[#objects + 1] = object;
        Simulation.spawn_object(simulation, objects[#objects])
    end);

    Client:on("finishedUpdate", function(server_data)
        server_tick = server_data.tick;
        if math.abs(server_tick - Simulation.current_tick(simulation)) > 5 then
            Simulation.set_tick(simulation, server_tick);
        end
    end);


    --Client:on("ballState", function(data)
    --  ball = data
    --end)

    Client:connect();
end

function love.update(dt)
    Client:update();

    -- Animation.update(SpriteSheetAnimation, dt)


    if player_num then
        if Client:getState() == 'connected' then
            local is_running = false;
            local jumped = false;
            local attack1 = false;
            local attack2 = false;
            --tick = tick + dt;

            --if love.keyboard.isDown("w") then
            --  keys_down_this_tick["w"] = true;
            --end
            if love.keyboard.isDown("a") then
                keys_down_this_tick["left"] = true;
                is_running = true;
            end
            --if love.keyboard.isDown("s") then
            --  keys_down_this_tick["s"] = true;
            --end
            if love.keyboard.isDown("d") then
                keys_down_this_tick["right"] = true;
                is_running = true;
            end
            if love.keyboard.isDown("space") then
                keys_down_this_tick["jump"] = true;
                jumped = true;
            end
            if love.keyboard.isDown("p") then
                keys_down_this_tick[Attacks.Attack1] = true
                attack1 = true;
            end
            if love.keyboard.isDown("o") then
                keys_down_this_tick[Attacks.Attack2] = true
                attack2 = true;
            end

            local joysticks = love.joystick.getJoysticks();
            for _, joystick in pairs(joysticks) do
                local x_axis, y_axis = joystick:getAxis(1), joystick:getAxis(2);
                if x_axis < -0.1 then
                    keys_down_this_tick['left'] = true;
                    is_running = true;
                end
                if x_axis > 0.1 then
                    keys_down_this_tick['right'] = true;
                    is_running = true;
                end
                if joystick:isGamepadDown('x') then
                    keys_down_this_tick[Attacks.Attack1] = true;
                    attack1 = true;
                end
                if joystick:isGamepadDown('b') then
                    keys_down_this_tick[Attacks.Attack2] = true;
                    attack2 = true;
                end
                if joystick:isGamepadDown('a') then
                    keys_down_this_tick['jump'] = true;
                    jumped = true;
                end
            end

            --if tick >= Networking.tick_rate then
            --tick = tick - Networking.tick_rate
            --if global_tick > server_tick then
            --  global_tick = server_tick;
            --end
            --while global_tick <= server_tick do
            --  global_tick = global_tick + 1;
            --end

            if player_num then
                -- local updated, _ = Simulation.update_tick_only(simulation, dt)

                local animation = Simulation.players(simulation)[player_num].animation
                local updated, _ = Simulation.yolo_update(simulation, dt)
                if updated then
                    for _, player in pairs(Simulation.players(simulation)) do
                        Animation.update(player.animation, Networking.tick_rate)
                    end

                    if attack1 then
                        Animation.play_animation_till_finish(animation, "punching_first_half")
                    elseif jumped then
                        Animation.play_animation(animation, "jump")
                    elseif Simulation.players(simulation)[player_num].grounded then
                        Animation.play_animation(animation, "idle")
                        if is_running then
                            Animation.play_animation(animation, "running")
                        end
                    end
                    Simulation.players(simulation)[player_num].animation = animation;

                    local current_tick = Simulation.current_tick(simulation)
                    --   Client:setSchema('playerPosition', { "x", 'y' })
                    --  Client:send('playerPosition', { players[player_num].x, players[player_num].y })
                    -- print("Sending input ")
                    --print(keys_down_this_tick ~= nil)
                    Client:send("playerInput", { current_tick - 1, keys_down_this_tick })
                    Client:send("playerAnimation",
                        { Simulation.players(simulation)[player_num].animation.current_animation })
                    Simulation.add_input(simulation, player_num, current_tick - 1, keys_down_this_tick)
                    --simulation.players()[player_num].input[global_tick] = keys_down_this_tick;
                    keys_down_this_tick = {}
                end


                Pixel:followEntity(Simulation.players(simulation)[player_num], world_size);
                --  Pixel.camera:FollowEntity(players[player_num]);
                --global_tick = global_tick + 1;
            end
        end
    end
    --  end
end

function love.draw()
    Pixel:startDraw();

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(background, -Pixel.canvas:getWidth() * 0.5, -Pixel.canvas:getHeight() * 0.5)

    for i, player in pairs(Simulation.players(simulation)) do
        if player.x == nil then
            goto continue
        end
        if i == 1 then
            love.graphics.setColor(0, 1, 0, 1)
        else
            love.graphics.setColor(1, 0, 0, 1)
        end

        Animation.draw(player.animation, player.x, player.y, player.facing_left)
        --love.graphics.draw(SpriteSheetExample, SpriteSheetFrames[CurrentFrame], player.x, player.y); --, player.width, player.height)
        --love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
        --love.graphics.rectangle("fill", player.x + player.width * 0.5, player.y - player.height, player.width,   player.height)
        ::continue::
    end

    love.graphics.setColor(0, 0, 1, 1)
    for _, object in pairs(objects) do
        love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
    end
    for _, object in pairs(Simulation.objects(simulation)) do
        love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
    end
    love.graphics.setColor(1, 1, 1, 1)

    Pixel:endDraw();

    local current_tick = Simulation.current_tick(simulation);

    love.graphics.print(
        Client:getState() .. " Current Tick: " .. current_tick .. " Difference: " .. current_tick - server_tick,
        5, 5)
    if player_num then
        love.graphics.print("Player " .. player_num, 5, 25)
        love.graphics.print("Damage " .. Simulation.players(simulation)[player_num].damage .. "%", 5, 45)
    else
        love.graphics.print("No player number assigned", 5, 25)
    end
end
