-- Willowfen Dungeon — Floor 1 (40×14 tiles, 32px each = 1280×448 pixels)
-- Five rooms separated by internal walls with 2-tile doorways at rows 7-8.
-- Dividing walls at cols 8, 15, 23, 31.
-- West exit (rows 7-8, col 1 open) → willowfen_marsh (from_dungeon spawn).
-- Boss room is Room 5 (cols 32-39), triggered by a boss_trigger object.
return {
  version      = "1.1",
  luaversion   = "5.1",
  tiledversion = "1.10.2",
  orientation  = "orthogonal",
  renderorder  = "right-down",
  width        = 40,
  height       = 14,
  tilewidth    = 32,
  tileheight   = 32,
  nextlayerid  = 6,
  nextobjectid = 30,
  properties   = { region = "willowfen" },
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
    -- Ground: all floor tiles
    {
      type    = "tilelayer",
      name    = "ground",
      x = 0, y = 0,
      width = 40, height = 14,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
      }
    },
    -- Decoration: empty
    {
      type    = "tilelayer",
      name    = "decoration",
      x = 0, y = 0,
      width = 40, height = 14,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      }
    },
    -- Collision:
    --   Row 1, Row 14: full walls.
    --   Rows 2-6, 9-13: col 1=wall, cols 8/15/23/31=divider walls, col 40=wall, rest open.
    --   Rows 7-8 (doorway rows): col 1=open (west exit), dividers=open, col 40=wall.
    {
      type    = "tilelayer",
      name    = "collision",
      x = 0, y = 0,
      width = 40, height = 14,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        -- Row 1: full top wall
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        -- Row 2
        2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,
        -- Row 3
        2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,
        -- Row 4
        2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,
        -- Row 5
        2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,
        -- Row 6
        2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,
        -- Row 7: doorway row — col 1 open (west exit), dividers open, col 40 solid
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        -- Row 8: doorway row — same as row 7
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        -- Row 9
        2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,
        -- Row 10
        2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,
        -- Row 11
        2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,
        -- Row 12
        2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,
        -- Row 13
        2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,
        -- Row 14: full bottom wall
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
      }
    },
    -- Above player: empty
    {
      type    = "tilelayer",
      name    = "above_player",
      x = 0, y = 0,
      width = 40, height = 14,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      }
    },
    -- Objects
    {
      type    = "objectgroup",
      name    = "objects",
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      objects = {

        -- ── Spawns ─────────────────────────────────────────────────────────
        -- Arriving from the marsh (west exit, tile col 3 row 7 → pixel 64,192)
        {
          id = 1, name = "", type = "spawn",
          shape = "rectangle",
          x = 64, y = 192, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { id = "from_marsh" }
        },
        {
          id = 2, name = "", type = "spawn",
          shape = "rectangle",
          x = 64, y = 192, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { id = "default" }
        },

        -- ── Warp ───────────────────────────────────────────────────────────
        -- West exit back to the marsh (gap at col 1, rows 7-8 → x=0, y=192)
        {
          id = 3, name = "", type = "warp",
          shape = "rectangle",
          x = 0, y = 192, width = 32, height = 64,
          rotation = 0, visible = true,
          properties = {
            target_map   = "assets/maps/willowfen_marsh.lua",
            target_spawn = "from_dungeon",
          }
        },

        -- ── Room 2 enemies (cols 9-14) ────────────────────────────────────
        -- bogsprite_1: col 11, row 5 → x=320, y=128
        {
          id = 4, name = "bogsprite_1", type = "enemy",
          shape = "rectangle",
          x = 320, y = 128, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { creature_id = "bogsprite", patrol_radius = 100 }
        },
        -- twycandl_1: col 13, row 9 → x=384, y=256
        {
          id = 5, name = "twycandl_1", type = "enemy",
          shape = "rectangle",
          x = 384, y = 256, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { creature_id = "twycandl", patrol_radius = 80 }
        },

        -- ── Room 3 wild lumins ────────────────────────────────────────────
        -- wild gleamfin: col 5, row 10 → x=128, y=288
        {
          id = 7, name = "wild_gleamfin_dungeon", type = "wild_lumin",
          shape = "rectangle",
          x = 128, y = 288, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { creature_id = "gleamfin" }
        },
        -- wild twycandl: col 18, row 4 → x=544, y=96
        {
          id = 8, name = "wild_twycandl_dungeon", type = "wild_lumin",
          shape = "rectangle",
          x = 544, y = 96, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { creature_id = "twycandl" }
        },

        -- ── Room 4 pre-boss area (cols 24-30) ────────────────────────────
        -- Chest with Full Restore: col 27, row 7 → x=832, y=192
        {
          id = 15, name = "chest_prebs", type = "chest",
          shape = "rectangle",
          x = 832, y = 192, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { item = "full_restore", count = 1, id = "dungeon_chest_02" }
        },
        -- murk_spawn_1: col 26, row 5 → x=800, y=128
        {
          id = 9, name = "murk_spawn_1", type = "enemy",
          shape = "rectangle",
          x = 800, y = 128, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { creature_id = "murk_spawn", patrol_radius = 110 }
        },
        -- murk_spawn_2: col 28, row 9 → x=864, y=256
        {
          id = 10, name = "murk_spawn_2", type = "enemy",
          shape = "rectangle",
          x = 864, y = 256, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { creature_id = "murk_spawn", patrol_radius = 110 }
        },
        -- crystick_1: col 25, row 10 → x=768, y=288
        {
          id = 11, name = "crystick_1", type = "enemy",
          shape = "rectangle",
          x = 768, y = 288, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { creature_id = "crystick", patrol_radius = 60 }
        },

        -- ── Room 5 boss trigger (cols 32-39) ─────────────────────────────
        -- Boss trigger zone covering most of room 5
        -- col 33 row 2 → x=1024, y=32; spans cols 33-39, rows 2-13 = w=224, h=384
        -- Boss spawns at col 36, row 7 → x=1120, y=192
        {
          id = 12, name = "murk_boss_trigger", type = "boss_trigger",
          shape = "rectangle",
          x = 1024, y = 32, width = 224, height = 384,
          rotation = 0, visible = true,
          properties = {
            boss_id = "murk_boss",
            spawn_x = 1120,
            spawn_y = 192,
          }
        },

        -- ── Encounter zones ───────────────────────────────────────────────
        -- Room 2 (cols 9-14): x=256, y=32, w=192, h=384
        {
          id = 13, name = "enc_room2", type = "encounter",
          shape = "rectangle",
          x = 256, y = 32, width = 192, height = 384,
          rotation = 0, visible = true,
          properties = { ["table"] = "willowfen_dungeon" }
        },
        -- Room 4 (cols 24-30): x=736, y=32, w=224, h=384
        {
          id = 14, name = "enc_room4", type = "encounter",
          shape = "rectangle",
          x = 736, y = 32, width = 224, height = 384,
          rotation = 0, visible = true,
          properties = { ["table"] = "willowfen_dungeon" }
        },

      }
    }
  }
}
