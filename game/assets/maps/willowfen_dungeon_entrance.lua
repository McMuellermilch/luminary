-- Willowfen Dungeon Entrance (15x12 tiles, 32px each = 480x384 pixels)
-- Guard NPC, encounter zone near entrance path
-- Warps: west → willowfen_marsh
return {
  version      = "1.1",
  luaversion   = "5.1",
  tiledversion = "1.10.2",
  orientation  = "orthogonal",
  renderorder  = "right-down",
  width        = 15,
  height       = 12,
  tilewidth    = 32,
  tileheight   = 32,
  nextlayerid  = 6,
  nextobjectid = 15,
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
    -- Ground
    {
      type    = "tilelayer",
      name    = "ground",
      x = 0, y = 0,
      width = 15, height = 12,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
      }
    },
    -- Decoration: empty
    {
      type    = "tilelayer",
      name    = "decoration",
      x = 0, y = 0,
      width = 15, height = 12,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      }
    },
    -- Collision: border walls; gap at west (col 1, row 5-6) for marsh warp
    {
      type    = "tilelayer",
      name    = "collision",
      x = 0, y = 0,
      width = 15, height = 12,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  -- row 1
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,  -- row 5: gap at west (col 1)
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,  -- row 6: gap at west
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  -- row 12
      }
    },
    -- Above player: empty
    {
      type    = "tilelayer",
      name    = "above_player",
      x = 0, y = 0,
      width = 15, height = 12,
      visible = true, opacity = 1,
      offsetx = 0, offsety = 0,
      properties = {},
      data = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
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
        -- Default spawn / from_marsh spawn (near west entrance)
        {
          id = 1, name = "", type = "spawn",
          shape = "rectangle",
          x = 64, y = 128, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { id = "default" }
        },
        {
          id = 2, name = "", type = "spawn",
          shape = "rectangle",
          x = 64, y = 128, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = { id = "from_marsh" }
        },
        -- Warp: west → willowfen_marsh (gap at row 5-6)
        {
          id = 3, name = "", type = "warp",
          shape = "rectangle",
          x = 0, y = 128, width = 32, height = 64,
          rotation = 0, visible = true,
          properties = {
            target_map   = "assets/maps/willowfen_marsh.lua",
            target_spawn = "from_dungeon",
          }
        },
        -- NPC: Guard at dungeon mouth
        {
          id = 4, name = "Guard", type = "npc",
          shape = "rectangle",
          x = 224, y = 128, width = 32, height = 32,
          rotation = 0, visible = true,
          properties = {
            id       = "dungeon_guard",
            sprite   = "guard",
            dialogue = "dungeon_guard",
            facing   = "left",
          }
        },
        -- Encounter zone: path to dungeon
        {
          id = 5, name = "dungeon_path_encounter", type = "encounter",
          shape = "rectangle",
          x = 32, y = 32, width = 160, height = 320,
          rotation = 0, visible = true,
          properties = { ["table"] = "willowfen_grass" }
        },
      }
    }
  }
}
