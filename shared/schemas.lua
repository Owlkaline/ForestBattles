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
end

function RegisterFunctions(bitser)
  bitser.register("modify_player_at_start_default", ModifyPlayerAtStart)
  bitser.register("modify_player_at_end_default", ModifyPlayerAtEnd)
  bitser.register("yeet", Yeet)
  bitser.register("wait_till_top", WaitTillTop)
  bitser.register("landed", Landed)
  bitser.register("none", None)
  bitser.register("animation_modify_player_at_start_default", AnimationModifyPlayerAtStart)
  bitser.register("animation_modify_player_at_end_default", AnimationModifyPlayerAtEnd)
  bitser.register("animation_none_continous", NoneContinous)
  bitser.register("mushroom_special_start", MushroomSpecialStart)
  bitser.register("mushroom_special_end", MushroomSpecialEnd)
  bitser.register("jump_continous", JumpContinous)
end
