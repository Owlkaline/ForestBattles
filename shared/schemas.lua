function SetSchemas(client_server)
    client_server:setSchema('playerInput', {
        "client_tick",
        "player_input"
    })
    client_server:setSchema('spawnPlayer', {
        "index",
        "x",
        "y",
        "global_tick"
    })
    client_server:setSchema("worldSize", { "width", "height" })
    client_server:setSchema('playerState', {
        "global_tick",
        "index",
        "x",
        "y",
        "damage",
        "vel_x",
        "vel_y",
        "facing_left"
    })
    client_server:setSchema('addObject', {
        "idx",
        "x",
        "y",
        "width",
        "height",
        "isFloor",
        "isWall"
    })
    client_server:setSchema("playerAnimation", {
        "animation"
    });
    client_server:setSchema("animationState", {
        "idx",
        "animation"
    })
end
