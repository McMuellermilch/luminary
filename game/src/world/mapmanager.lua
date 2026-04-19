-- MapManager
-- Loads Tiled maps via STI, extracts collision tiles into bump.lua,
-- exposes object layer data, and controls draw order so entities
-- appear between the decoration and above_player layers.
--
-- Layer convention (must match every .tmx file):
--   ground       — base ground tiles
--   decoration   — non-blocking detail tiles
--   collision    — invisible solid tiles (never rendered)
--   above_player — rendered on top of entities (tree canopies, etc.)
--   objects      — Tiled object layer (spawns, warps, NPCs, encounters)

local STI  = require("lib.sti.init")
local bump = require("lib.bump.bump")

local MapManager = {}
MapManager.__index = MapManager

-- The shared bump collision world. Other systems (Player, NPCs) use this.
MapManager.world = nil
-- The currently loaded STI map.
MapManager.map   = nil
-- Parsed objects from the objects layer, keyed by type.
MapManager.spawns        = {}
MapManager.warps         = {}
MapManager.npcs          = {}
MapManager.encounters    = {}
MapManager.enemies       = {}
MapManager.beacon_towers = {}   -- { x, y } world positions
MapManager.lighthouses   = {}   -- { x, y } world positions
MapManager.wild_lumins   = {}   -- { x, y, creature_id }
MapManager.region        = nil  -- region id from map-level properties

-- Internal list of bump items representing wall tiles (for cleanup on unload).
local wall_items = {}

-- -------------------------------------------------------------------------
-- Load a map from a .tmx path and position the player at the given spawn id.
-- Returns the spawn position {x, y} so the caller can place the player.
-- -------------------------------------------------------------------------
function MapManager.load(map_path, spawn_id)
  -- Clear previous map state
  MapManager.map           = nil
  MapManager.spawns        = {}
  MapManager.warps         = {}
  MapManager.npcs          = {}
  MapManager.encounters    = {}
  MapManager.enemies       = {}
  MapManager.beacon_towers = {}
  MapManager.lighthouses   = {}
  MapManager.wild_lumins   = {}
  MapManager.region        = nil

  -- Reset bump world
  MapManager.world = bump.newWorld(32)
  wall_items = {}

  -- Load map
  local map = STI(map_path)
  MapManager.map = map

  -- Read map-level region property
  MapManager.region = (map.properties and map.properties.region) or nil

  -- Collision layer is rendered as visible wall tiles AND handled by bump.
  -- Keep visible = true (the default) so wall tiles show on screen.

  -- Register collision tiles into bump
  MapManager._buildCollision(map)

  -- Parse object layer
  MapManager._parseObjects(map)

  -- Find the requested spawn point
  local spawn = MapManager.spawns[spawn_id] or MapManager.spawns["default"]
  assert(spawn, "MapManager.load: no spawn point found for id '" .. tostring(spawn_id) .. "' in " .. map_path)

  return { x = spawn.x, y = spawn.y }
end

-- -------------------------------------------------------------------------
-- Build bump rectangles from the collision tile layer.
-- -------------------------------------------------------------------------
function MapManager._buildCollision(map)
  local layer = map.layers["collision"]
  if not layer then return end

  for y = 1, map.height do
    for x = 1, map.width do
      local tile = layer.data[y] and layer.data[y][x]
      if tile then
        local wx = (x - 1) * map.tilewidth
        local wy = (y - 1) * map.tileheight
        local item = { type = "wall" }
        MapManager.world:add(item, wx, wy, map.tilewidth, map.tileheight)
        wall_items[#wall_items + 1] = item
      end
    end
  end
end

-- -------------------------------------------------------------------------
-- Parse the objects layer into typed lookup tables.
-- -------------------------------------------------------------------------
function MapManager._parseObjects(map)
  local layer = map.layers["objects"]
  if not layer then return end

  for _, obj in ipairs(layer.objects) do
    local props = obj.properties or {}

    if obj.type == "spawn" then
      local id = props.id or "default"
      MapManager.spawns[id] = { x = obj.x, y = obj.y }

    elseif obj.type == "warp" then
      MapManager.warps[#MapManager.warps + 1] = {
        x = obj.x, y = obj.y, w = obj.width, h = obj.height,
        target_map   = props.target_map,
        target_spawn = props.target_spawn,
      }

    elseif obj.type == "npc" then
      MapManager.npcs[#MapManager.npcs + 1] = {
        x = obj.x, y = obj.y,
        id       = props.id,
        sprite   = props.sprite,
        dialogue = props.dialogue,
        shop     = props.shop,
        facing   = props.facing or "down",
      }

    elseif obj.type == "encounter" then
      MapManager.encounters[#MapManager.encounters + 1] = {
        x = obj.x, y = obj.y, w = obj.width, h = obj.height,
        table_id = props["table"],
      }

    elseif obj.type == "enemy" then
      MapManager.enemies[#MapManager.enemies + 1] = {
        x             = obj.x,
        y             = obj.y,
        creature_id   = props.creature_id or "gleamfin",
        patrol_radius = props.patrol_radius or 80,
      }

    elseif obj.type == "beacon_tower" then
      MapManager.beacon_towers[#MapManager.beacon_towers + 1] = {
        x = obj.x, y = obj.y,
      }

    elseif obj.type == "lighthouse" then
      MapManager.lighthouses[#MapManager.lighthouses + 1] = {
        x = obj.x, y = obj.y,
      }

    elseif obj.type == "wild_lumin" then
      MapManager.wild_lumins[#MapManager.wild_lumins + 1] = {
        x           = obj.x,
        y           = obj.y,
        creature_id = props.creature_id or "gleamfin",
      }
    end
  end
end

-- -------------------------------------------------------------------------
-- Update animated tiles each frame.
-- -------------------------------------------------------------------------
function MapManager.update(dt)
  if MapManager.map then
    MapManager.map:update(dt)
  end
end

-- -------------------------------------------------------------------------
-- Draw the map in the correct order.
-- Entities should be drawn between drawBelow() and drawAbove() calls.
--
-- Usage in your state's draw():
--   MapManager.drawBelow()
--   -- draw player, NPCs, etc.
--   MapManager.drawAbove()
-- -------------------------------------------------------------------------
function MapManager.drawBelow()
  local map = MapManager.map
  if not map then return end

  local ground_layer     = map.layers["ground"]
  local deco_layer       = map.layers["decoration"]
  local collision_layer  = map.layers["collision"]

  -- STI sets layer.draw as a plain function (not a method), so use dot call
  if ground_layer     then ground_layer.draw()     end
  if deco_layer       then deco_layer.draw()       end
  if collision_layer  then collision_layer.draw()  end
end

function MapManager.drawAbove()
  local map = MapManager.map
  if not map then return end

  local above_layer = map.layers["above_player"]
  if above_layer then above_layer.draw() end
end

-- -------------------------------------------------------------------------
-- Convenience: pixel dimensions of the loaded map.
-- -------------------------------------------------------------------------
function MapManager.pixelWidth()
  if not MapManager.map then return 0 end
  return MapManager.map.width  * MapManager.map.tilewidth
end

function MapManager.pixelHeight()
  if not MapManager.map then return 0 end
  return MapManager.map.height * MapManager.map.tileheight
end

return MapManager
