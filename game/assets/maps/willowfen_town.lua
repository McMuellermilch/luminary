-- Willowfen Town (20x15 tiles, 32px each)
-- NPCs: Elder Cerin, Mira, Bram (merchant), Pip (child)
-- Warps: north exit → willowfen_marsh (from_town_south), south exit → test_room
return {
  version      = "1.1",
  luaversion   = "5.1",
  tiledversion = "1.10.2",
  orientation  = "orthogonal",
  renderorder  = "right-down",
  width        = 20,
  height       = 15,
  tilewidth    = 32,
  tileheight   = 32,
  nextlayerid  = 6,
  nextobjectid = 20,
  properties   = {},
  tilesets = {
    {
      name       = "tileset_test",
      firstgid   = 1,
      tilewidth  = 32,
      tileheight = 32,
      spacing    = 0,
      margin     = 0,
      columns    = 3,
      image      = "tileset_test.png",
      imagewidth  = 96,
      imageheight = 32,
      tilecount   = 3,
      tileoffset  = { x = 0, y = 0 },
      tiles = {}
    }
  },
  layers = {
    -- Ground: all tiles are ground (tile 1)
    {
      type    = "tilelayer",
      name    = "ground",
      x = 0, y = 0,
      width = 20, height = 15,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
      }
    },
    -- Decoration: empty
    {
      type    = "tilelayer",
      name    = "decoration",
      x = 0, y = 0,
      width = 20, height = 15,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      }
    },
    -- Collision: walls on all edges; gap at top (col 9-10) and bottom (col 9-10) for warps
    {
      type    = "tilelayer",
      name    = "collision",
      x = 0, y = 0,
      width = 20, height = 15,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,  -- row 1: gap at col 9-10
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,  -- row 15: gap at col 9-10
      }
    },
    -- Above player: empty
    {
      type    = "tilelayer",
      name    = "above_player",
      x = 0, y = 0,
      width = 20, height = 15,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      }
    },
    -- Objects: spawns, warps, NPCs
    {
      type    = "objectgroup",
      name    = "objects",
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      objects = {
        -- Default spawn (centre of map, arriving from south/test_room)
        {
          id = 1, name = "", type = "spawn",
          shape = "rectangle",
          x = 288, y = 224, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { id = "default" }
        },
        -- Spawn near north exit (arriving from marsh)
        {
          id = 2, name = "", type = "spawn",
          shape = "rectangle",
          x = 288, y = 64, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { id = "from_marsh" }
        },
        -- Warp: north exit → willowfen_marsh (spawns at from_town_south)
        {
          id = 3, name = "", type = "warp",
          shape = "rectangle",
          x = 288, y = 0, width = 64, height = 32,
          rotation = 0, visible = true,
          properties = {
            target_map   = "assets/maps/willowfen_marsh.lua",
            target_spawn = "from_town_south",
          }
        },
        -- Warp: south exit → test_room
        {
          id = 4, name = "", type = "warp",
          shape = "rectangle",
          x = 288, y = 448, width = 64, height = 32,
          rotation = 0, visible = true,
          properties = {
            target_map   = "assets/maps/test_room.lua",
            target_spawn = "default",
          }
        },
        -- NPC: Elder Cerin (top-left area)
        {
          id = 5, name = "Elder Cerin", type = "npc",
          shape = "rectangle",
          x = 96, y = 128, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = {
            id       = "elder_cerin",
            sprite   = "cerin",
            dialogue = "cerin_intro",
            facing   = "down",
          }
        },
        -- NPC: Mira (right side)
        {
          id = 6, name = "Mira", type = "npc",
          shape = "rectangle",
          x = 480, y = 192, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = {
            id       = "mira",
            sprite   = "mira",
            dialogue = "mira_greeting",
            facing   = "left",
          }
        },
        -- NPC: Bram the merchant (bottom-right)
        {
          id = 7, name = "Bram", type = "npc",
          shape = "rectangle",
          x = 448, y = 352, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = {
            id       = "bram",
            sprite   = "bram",
            dialogue = "bram_merchant",
            facing   = "down",
          }
        },
        -- NPC: Pip the child (centre-left)
        {
          id = 8, name = "Pip", type = "npc",
          shape = "rectangle",
          x = 160, y = 288, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = {
            id       = "pip",
            sprite   = "pip",
            dialogue = "child_npc",
            facing   = "right",
          }
        },
      }
    }
  }
}
