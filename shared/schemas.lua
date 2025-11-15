function SetSchemas(client_server)
  client_server:setSchema('addObject', {
    "frame",
    "idx",
    "x",
    "y",
    "width",
    "height",
    "isFloor",
    "isWall",
    "isAttackBox",
    "isDeath"
  })
  client_server:setSchema("assignPlayerNumber", { "idx", "current_frame", "game_state" })
  client_server:setSchema('addPlayer', {
    "frame",
    "idx",
    "x",
    "y",
    "width",
    "height",
    "vel_x",
    "vel_y"
  })
  client_server:setSchema('removePlayer', {
    "frame",
    "idx",
  })
  client_server:setSchema('addInput', {
    "idx",
    "frame",
    "input",
  })
  client_server:setSchema('updatePosition', {
    "idx",
    "frame",
    "x",
    "y"
  })

  --client_server:setSchema('playerInput', {
  --    "client_tick",
  --    "player_input"
  --})
  --client_server:setSchema('spawnPlayer', {
  --    "index",
  --    "x",
  --    "y",
  --    "global_tick"
  --})
  --client_server:setSchema("worldSize", { "width", "height" })
  --client_server:setSchema('playerState', {
  --    "global_tick",
  --    "index",
  --    "x",
  --    "y",
  --    "damage",
  --    "vel_x",
  --    "vel_y",
  --    "facing_left"
  --})
  --client_server:setSchema('addObject', {
  --    "idx",
  --    "x",
  --    "y",
  --    "width",
  --    "height",
  --    "isFloor",
  --    "isWall"
  --})
  --client_server:setSchema("playerAnimation", {
  --    "animation"
  --});
  --client_server:setSchema("animationState", {
  --    "idx",
  --    "animation"
  --})
end
