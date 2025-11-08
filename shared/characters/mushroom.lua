local Mushroom = {};

local Animation = require('client/animation')

function Mushroom.animation()
    local spriteSheetAnimation = Animation.new('assets/mushroom_spritesheet.png', 32)
    Animation.add_animation(spriteSheetAnimation, "idle", 1, 1, true);
    Animation.add_animation(spriteSheetAnimation, "running", 17, 26, true);
    Animation.add_animation(spriteSheetAnimation, "jump", 33, 52, false)
    Animation.add_animation(spriteSheetAnimation, "punching_first_half", 65, 67, false);
    Animation.add_animation(spriteSheetAnimation, "punching_second_half", 68, 70, false);
    Animation.play_animation(spriteSheetAnimation, "idle")

    return spriteSheetAnimation;
end

function Mushroom.attack(player, inputs)
    local new_attack_box = {}

    if inputs[Attacks.Attack2] and (player.timers[Attacks.Attack1] or 0) <= 0 then
        --print("player attacking")
        new_attack_box[#new_attack_box + 1] = {};

        local knockback_force = 5.5;
        local duration = 0.5;

        local width = 15.0;
        local height = 15.0;

        local x = player.x + player.width;
        local y = player.y + player.height * 0.5 - width * 0.5

        local direction = { x = 1, y = 0 };
        if player.facing_left then
            x = player.x - width
            direction.x = direction.x * -1.0;
        end

        new_attack_box[#new_attack_box] = AttackBox.new(player, duration, direction, knockback_force, x, y, width, height)
        player.timers[Attacks.Attack1] = 0.5
    end

    if inputs[Attacks.Attack1] and (player.timers[Attacks.Attack1] or 0) <= 0 then
        --print("player attacking")
        new_attack_box[#new_attack_box + 1] = {};

        local width = 5.0;
        local height = 5.0;

        local knockback_force = 0.5;
        local duration = 0.5;
        local x = player.x + player.width;
        local y = player.y + player.height * 0.5 - width * 0.5

        local direction = { x = 1, y = 0 };
        if player.facing_left then
            x = player.x - width
            direction.x = direction.x * -1.0;
        end

        new_attack_box[#new_attack_box] = AttackBox.new(player, duration, direction, knockback_force, x, y, width, height)
        player.timers[Attacks.Attack1] = 0.5
    end

    return new_attack_box
end

return Mushroom
