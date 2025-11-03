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
    "damage"
  })
  client_server:setSchema('addObject', {
    "idx",
    "x",
    "y",
    "width",
    "height"
  })
end
