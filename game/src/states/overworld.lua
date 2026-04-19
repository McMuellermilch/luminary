-- Overworld state
-- Loads a Tiled map, runs player movement + camera, draws the world.
-- Handles warp zone detection, NPC spawning, encounter zone checks.

local Input         = require("src.core.input")
local MapManager    = require("src.world.mapmanager")
local Camera        = require("src.world.camera")
local Player        = require("src.entities.player")
local NPC           = require("src.entities.npc")
local WarpSystem    = require("src.world.warpsystem")
local EntityManager = require("src.entities.entitymanager")

local Overworld = {}
Overworld.__index = Overworld

local DEFAULT_MAP   = "assets/maps/willowfen_town.lua"
local DEFAULT_SPAWN = "default"

local ENCOUNTER_CHANCE = 0.10

-- Lazily-initialised debug font
local debug_font = nil
local function get_debug_font()
  if not debug_font then debug_font = love.graphics.newFont(12) end
  return debug_font
end

-- -------------------------------------------------------------------------
local function tile_coord(px, py)
  return math.floor(px / 32), math.floor(py / 32)
end

-- -------------------------------------------------------------------------
-- Internal map loader — shared between enter() and _reload()
-- -------------------------------------------------------------------------
function Overworld:_loadMap(map_path, spawn_id)
  -- Destroy existing entities (removes from bump and marks inactive)
  if self.player then
    self.player:destroy()
  end
  EntityManager.clear()

  local spawn = MapManager.load(map_path, spawn_id)

  -- Spawn NPCs from map data
  for _, data in ipairs(MapManager.npcs) do
    local npc = NPC.new(data)
    EntityManager.add(npc)
  end

  return spawn
end

-- -------------------------------------------------------------------------
function Overworld:enter(params)
  params = params or {}
  local map_path = params.map   or DEFAULT_MAP
  local spawn_id = params.spawn or DEFAULT_SPAWN

  local spawn = self:_loadMap(map_path, spawn_id)

  local px = spawn.x + (32 - 20) / 2
  local py = spawn.y + (32 - 26) / 2
  self.player = Player.new(px, py)
  EntityManager.add(self.player)

  self.camera = Camera.new()
  self.camera:setBounds(0, 0, MapManager.pixelWidth(), MapManager.pixelHeight())
  local cx, cy = self.player:center()
  self.camera:follow(cx, cy)
  self.camera:update(0)

  self._last_tile_x, self._last_tile_y = tile_coord(self.player.x, self.player.y)

  WarpSystem.reset()
end

-- Called by WarpSystem at fade midpoint to swap map without leaving the state.
function Overworld:_reload(map_path, spawn_id)
  local spawn = self:_loadMap(map_path, spawn_id)

  local px = spawn.x + (32 - 20) / 2
  local py = spawn.y + (32 - 26) / 2
  self.player = Player.new(px, py)
  EntityManager.add(self.player)

  self.camera:setBounds(0, 0, MapManager.pixelWidth(), MapManager.pixelHeight())
  local cx, cy = self.player:center()
  self.camera:follow(cx, cy)
  self.camera:update(0)

  self._last_tile_x, self._last_tile_y = tile_coord(px, py)
  WarpSystem.reset()
end

function Overworld:exit() end

function Overworld:update(dt)
  if Input.wasPressed("pause") then
    local StateManager = require("src.states.statemanager")
    StateManager.pop()
    return
  end

  MapManager.update(dt)
  EntityManager.update(dt)   -- updates player (input + movement) and all NPCs

  WarpSystem.check(self, self.player)
  self:_checkEncounter()

  local cx, cy = self.player:center()
  self.camera:follow(cx, cy)
  self.camera:update(dt)
end

function Overworld:_checkEncounter()
  local tx, ty = tile_coord(self.player.x, self.player.y)
  if tx == self._last_tile_x and ty == self._last_tile_y then return end
  self._last_tile_x, self._last_tile_y = tx, ty

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
    EntityManager.draw()   -- draws player + NPCs, Y-sorted
    MapManager.drawAbove()
  self.camera:detach()
  self.camera:draw()

  -- Debug HUD
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, 270, 36)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.setFont(get_debug_font())
  love.graphics.print(
    string.format("x:%.0f y:%.0f  facing:%s  [Esc=menu]",
      self.player.x, self.player.y, self.player:getFacing()),
    6, 10)
  love.graphics.setColor(1, 1, 1, 1)
end

function Overworld:keypressed(key) end

return Overworld
