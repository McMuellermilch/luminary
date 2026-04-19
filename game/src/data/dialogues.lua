-- Dialogue data tables
-- Each entry is a sequence of lines; each line has speaker, portrait, and text.
-- Portrait is a sprite name (placeholder until Phase 4 assets).

-- Dialogue metadata fields (not line entries):
--   sets_flag  = "flag_key"   — Flags.set(key, true) when dialogue completes
--   requires   = "flag_key"   — only plays if Flags.is(key); uses fallback otherwise
--   fallback   = "dialogue_id" — played instead when requires check fails

local dialogues = {
  cerin_intro = {
    sets_flag = "cerin_intro_seen",
    { speaker = "Elder Cerin", portrait = "cerin", text = "Luma, you're late again." },
    { speaker = "Elder Cerin", portrait = "cerin", text = "Come, I need to show you something at the Tower." },
  },
  cerin_beacon = {
    requires = "cerin_intro_seen",
    fallback = "cerin_intro",
    { speaker = "Elder Cerin", portrait = "cerin", text = "The Beacon grows dimmer each passing day." },
    { speaker = "Elder Cerin", portrait = "cerin", text = "Only a Light-Carrier can rekindle it. That means you, Luma." },
  },
  mira_greeting = {
    { speaker = "Mira", portrait = "mira", text = "Morning! The marsh is beautiful today, if you ignore the gloom." },
    { speaker = "Mira", portrait = "mira", text = "Watch out for Gleamfins near the water — they bite." },
  },
  mira_after_beacon = {
    requires = "willowfen_beacon_lit",
    fallback = "mira_greeting",
    { speaker = "Mira", portrait = "mira", text = "The light is back! I haven't seen the marsh this bright in years." },
  },
  bram_merchant = {
    { speaker = "Bram", portrait = "bram", text = "Traveler! I've got supplies if you've got coin." },
    { speaker = "Bram", portrait = "bram", text = "Not much call for trade these days, with the light fading and all." },
  },
  child_npc = {
    { speaker = "Pip", portrait = "pip", text = "Are you really a Light-Carrier? Can you make the lights come back?" },
  },
  dungeon_guard = {
    { speaker = "Guard", portrait = "guard", text = "The Willowroot Dungeon lies ahead." },
    { speaker = "Guard", portrait = "guard", text = "Don't go in unless you're ready. The shadows have been strange lately." },
  },

  -- Fisherman NPC at Willowfen Marsh
  fisherman_dark = {
    { speaker = "Fisherman", portrait = "npc_generic", text = "Can't catch a thing with the marsh so dark. The light usually draws the fish." },
    { speaker = "Fisherman", portrait = "npc_generic", text = "They say something foul lurks in the old dungeon beyond the reeds. I stay well clear." },
  },
  fisherman_lit = {
    requires = "willowfen_beacon_lit",
    fallback = "fisherman_dark",
    { speaker = "Fisherman", portrait = "npc_generic", text = "The light's back! Already catching twice as many Gleamfins." },
    { speaker = "Fisherman", portrait = "npc_generic", text = "Whatever was haunting that dungeon — you sorted it, didn't you? Cheers to you, Light-Carrier." },
  },

  -- Murk Boss intro (shown when player enters the boss room)
  murk_intro = {
    { speaker = "...", portrait = "", text = "The air thickens. A vast shadow coils at the heart of the dungeon." },
    { speaker = "The Murk", portrait = "", text = "Another spark... come to flicker and fade." },
    { speaker = "Luma", portrait = "", text = "Not today." },
  },

  -- Beacon Shard obtained (shown after The Murk is defeated)
  shard_obtained = {
    sets_flag = "willowfen_shard_obtained",
    { speaker = "...", portrait = "", text = "The Murk dissolves into cold mist. A crystalline shard tumbles to the ground." },
    { speaker = "...", portrait = "", text = "It pulses with warm light — the piece torn from the Willowfen Beacon Tower." },
    { speaker = "Luma", portrait = "", text = "Obtained the Willowfen Shard." },
  },

  -- Beacon use shard (shown at tower if player has shard)
  beacon_use_shard = {
    requires = "willowfen_shard_obtained",
    fallback = "beacon_tower_no_shard",
    { speaker = "Beacon Tower", portrait = "", text = "The shard resonates with the Tower's cradle. Insert it?" },
  },

  -- Cerin after the beacon is lit
  cerin_post_beacon = {
    requires = "willowfen_beacon_lit",
    fallback = "cerin_beacon",
    { speaker = "Elder Cerin", portrait = "cerin", text = "You did it, Luma. The Beacon burns again." },
    { speaker = "Elder Cerin", portrait = "cerin", text = "Willowfen will be safe now. But the dark reaches far beyond our marsh." },
    { speaker = "Elder Cerin", portrait = "cerin", text = "Wherever the next Beacon sleeps — you will find it." },
  },

  -- Wild Lumin flavour
  wild_lumin_anxious = {
    { speaker = "...", portrait = "", text = "The Lumin shivers and skitters away from you. The darkness has made it wary." },
  },
  wild_lumin_calm = {
    { speaker = "...", portrait = "", text = "The Lumin seems calmer now. It blinks at you with soft, curious eyes." },
  },

  -- Beacon Tower (no shard) — placeholder if approached without the item
  beacon_tower_no_shard = {
    { speaker = "Beacon Tower", portrait = "", text = "The Tower stands cold and dark. Something is missing from its cradle." },
  },
}

return dialogues
