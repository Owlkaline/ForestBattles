function SetSchemas(client_server)
  client_server:setSchema('spawnPlayer', {
    "index",
    "x",
    "y",
    "global_tick"
  })
  client_server:setSchema('playerState', {
    "global_tick",
    "index",
    "x",
    "y"
  })
  client_server:setSchema('addObject', {
    "x",
    "y",
    "width",
    "height"
  })
end
