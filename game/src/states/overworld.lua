-- Overworld state
-- Loads a Tiled map, runs player movement + camera, draws the world.
-- Handles warp zone detection, NPC spawning, and encounter zone checks.

local Input       = require("src.core.input")
local MapManager  = require("src.world.mapmanager")
local Camera      = require("src.world.camera")
local Player      = require("src.entities.player")
local NPC         = require("src.entities.npc")
local WarpSystem  = require("src.world.warpsystem")

local Overworld = {}
Overworld.__index = Overworld

-- Default map loaded when the state is first entered without params.
local DEFAULT_MAP   = "assets/maps/willowfen_town.lua"
local DEFAULT_SPAWN = "default"

-- Lazily-initialised debug font (love.graphics not available at require time)
local debug_font = nil
local function get_debug_font()
  if not debug_font then debug_font = love.graphics.newFont(12) end
  return debug_font
end

-- Encounter chance per tile entered (0.0–1.0)
local ENCOUNTER_CHANCE = 0.10

-- -------------------------------------------------------------------------
-- Helpers
-- -------------------------------------------------------------------------

local function tile_coord(px, py)
  return math.floor(px / 32), math.floor(py / 32)
end

-- -------------------------------------------------------------------------
-- Internal map loader (shared between enter and _reload)
-- -------------------------------------------------------------------------
function Overworld:_loadMap(map_path, spawn_id)
  -- Destroy any live NPCs (removes them from bump)
  if self.npcs then
    for _, npc in ipairs(self.npcs) do npc:destroy() end
  end

  local spawn = MapManager.load(map_path, spawn_id)
  self.npcs = {}

  -- Spawn NPCs from map object data
  for _, data in ipairs(MapManager.npcs) do
    self.npcs[#self.npcs + 1] = NPC.new(data)
  end

  return spawn
end

-- -------------------------------------------------------------------------
-- Public API
-- -------------------------------------------------------------------------
function Overworld:enter(params)
  params = params or {}
  local map_path = params.map   or DEFAULT_MAP
  local spawn_id = params.spawn or DEFAULT_SPAWN

  local spawn = self:_loadMap(map_path, spawn_id)

  -- Create player at spawn position (centre 20px hitbox in 32px tile)
  local px = spawn.x + (32 - 20) / 2
  local py = spawn.y + (32 - 26) / 2
  self.player = Player.new(px, py)

  -- Set up camera
  self.camera = Camera.new()
  self.camera:setBounds(0, 0, MapManager.pixelWidth(), MapManager.pixelHeight())
  local cx, cy = self.player:center()
  self.camera:follow(cx, cy)
  self.camera:update(0)

  -- Encounter zone state
  self._last_tile_x, self._last_tile_y = tile_coord(self.player.x, self.player.y)

  WarpSystem.reset()
end

-- Called by WarpSystem at fade midpoint to swap the map without leaving the state.
function Overworld:_reload(map_path, spawn_id)
  -- Remove old player from bump before MapManager resets the world
  if MapManager.world and self.player then
    MapManager.world:remove(self.player)
  end

  local spawn = self:_loadMap(map_path, spawn_id)

  local px = spawn.x + (32 - 20) / 2
  local py = spawn.y + (32 - 26) / 2
  self.player.x = px
  self.player.y = py
  MapManager.world:add(self.player, px, py, self.player.w, self.player.h)

  -- Update camera for new map bounds
  self.camera:setBounds(0, 0, MapManager.pixelWidth(), MapManager.pixelHeight())
  local cx, cy = self.player:center()
  self.camera:follow(cx, cy)
  self.camera:update(0)

  self._last_tile_x, self._last_tile_y = tile_coord(px, py)
  WarpSystem.reset()
end

function Overworld:exit()
  -- Future: pause music, etc.
end

function Overworld:update(dt)
  if Input.wasPressed("pause") then
    local StateManager = require("src.states.statemanager")
    StateManager.pop()
    return
  end

  MapManager.update(dt)
  self.player:update(dt)

  -- Warp detection (after player movement)
  WarpSystem.check(self, self.player)

  -- Encounter zone detection (per tile entered)
  self:_checkEncounter()

  local cx, cy = self.player:center()
  self.camera:follow(cx, cy)
  self.camera:update(dt)
end

function Overworld:_checkEncounter()
  local tx, ty = tile_coord(self.player.x, self.player.y)
  if tx == self._last_tile_x and ty == self._last_tile_y then return end

  self._last_tile_x, self._last_tile_y = tx, ty

  -- Check if new tile is inside any encounter zone
  local px, py = self.player:center()
  for _, zone in ipairs(MapManager.encounters) do
    if px >= zone.x and px <= zone.x + zone.w and
       py >= zone.y and py <= zone.y + zone.h then
      if math.random() < ENCOUNTER_CHANCE then
        local StateManager = require("src.states.statemanager")
        local Combat = require("src.states.combat")
        StateManager.push(Combat, { table_id = zone.table_id })
      end
      return
    end
  end
end

function Overworld:draw()
  self.camera:attach()
    MapManager.drawBelow()
    -- Draw NPCs and player between layers
    for _, npc in ipairs(self.npcs) do
      npc:draw()
    end
    self.player:draw()
    MapManager.drawAbove()
  self.camera:detach()
  self.camera:draw()  -- flash/fade overlays from STALKER-X

  -- Debug HUD
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, 260, 36)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.setFont(get_debug_font())
  love.graphics.print(
    string.format("x:%.0f y:%.0f  facing:%s  [Esc=menu]",
      self.player.x, self.player.y, self.player.facing),
    6, 10)
  love.graphics.setColor(1, 1, 1, 1)
end

function Overworld:keypressed(key) end

return Overworld
