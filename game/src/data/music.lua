-- Music stem set definitions
-- Each set lists named stems (any keys) → asset paths.
-- All stems within a set must share the same BPM and loop length.
-- Missing files are skipped gracefully by MusicManager.

return {

  willowfen_dark = {
    bass    = "assets/audio/music/willowfen_dark_bass.ogg",
    melody  = "assets/audio/music/willowfen_dark_melody.ogg",
    texture = "assets/audio/music/willowfen_dark_texture.ogg",
  },

  willowfen_lit = {
    bass    = "assets/audio/music/willowfen_lit_bass.ogg",
    melody  = "assets/audio/music/willowfen_lit_melody.ogg",
    birds   = "assets/audio/music/willowfen_lit_birds.ogg",
  },

  combat = {
    drums   = "assets/audio/music/combat_drums.ogg",
    tension = "assets/audio/music/combat_tension.ogg",
  },

}
