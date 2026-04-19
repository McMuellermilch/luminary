-- Dialogue data tables
-- Each entry is a sequence of lines; each line has speaker, portrait, and text.
-- Portrait is a sprite name (placeholder until Phase 4 assets).

local dialogues = {
  cerin_intro = {
    { speaker = "Elder Cerin", portrait = "cerin", text = "Luma, you're late again." },
    { speaker = "Elder Cerin", portrait = "cerin", text = "Come, I need to show you something at the Tower." },
  },
  cerin_beacon = {
    { speaker = "Elder Cerin", portrait = "cerin", text = "The Beacon grows dimmer each passing day." },
    { speaker = "Elder Cerin", portrait = "cerin", text = "Only a Light-Carrier can rekindle it. That means you, Luma." },
  },
  mira_greeting = {
    { speaker = "Mira", portrait = "mira", text = "Morning! The marsh is beautiful today, if you ignore the gloom." },
    { speaker = "Mira", portrait = "mira", text = "Watch out for Gleamfins near the water — they bite." },
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
}

return dialogues
