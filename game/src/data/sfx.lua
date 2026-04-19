-- SFX registry
-- Maps logical sound names → asset paths.
-- Missing files are skipped gracefully by the SFX module.

return {
  attack_hit        = "assets/audio/sfx/attack_hit.ogg",
  capture_win       = "assets/audio/sfx/capture_win.ogg",
  capture_fail      = "assets/audio/sfx/capture_fail.ogg",
  level_up          = "assets/audio/sfx/level_up.ogg",
  beacon_rekindle   = "assets/audio/sfx/beacon_rekindle.ogg",
  warp              = "assets/audio/sfx/warp.ogg",
  menu_select       = "assets/audio/sfx/menu_select.ogg",
  -- dialogue_blip is generated synthetically in src/audio/sfx.lua
}
