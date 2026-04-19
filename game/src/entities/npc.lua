-- NPC entity
-- Placeholder colored rectangle spawned from Tiled object data.
-- Registers a solid hitbox in bump so the player cannot walk through.
-- Phase 4 will replace the rectangle with a proper sprite.

local MapManager = require("src.world.mapmanager")

local NPC = {}
NPC.__index = NPC

local WIDTH  = 20
local HEIGHT = 26

-- Placeholder colour per NPC id (cycles through a small palette)
local PALETTE = {
  {0.40, 0.65, 0.90},  -- blue
  {0.65, 0.90, 0.40},  -- green
  {0.90, 0.55, 0.35},  -- orange
  {0.80, 0.40, 0.80},  -- purple
  {0.90, 0.80, 0.30},  -- yellow
}
local _palette_index = 0

local function next_color()
  _palette_index = (_palette_index % #PALETTE) + 1
  return PALETTE[_palette_index]
end

-- data — table from MapManager.npcs:
--   { x, y, id, sprite, dialogue, facing }
function NPC.new(data)
  local self = setmetatable({}, NPC)

  -- Centre the hitbox on the Tiled object position (top-left of tile)
  self.x        = data.x + (32 - WIDTH)  / 2
  self.y        = data.y + (32 - HEIGHT) / 2
  self.w        = WIDTH
  self.h        = HEIGHT

  self.id       = data.id       or "npc"
  self.dialogue = data.dialogue or ""
  self.facing   = data.facing   or "down"
  self.color    = next_color()

  -- bump type tag — Player._interact() queries for this
  self.type     = "npc"

  -- Register solid rectangle in the shared bump world
  MapManager.world:add(self, self.x, self.y, self.w, self.h)

  return self
end

-- Called from Player:_interact() when the player faces this NPC and presses confirm.
function NPC:onInteract(player)
  -- Turn to face the player
  local px, py = player:center()
  local nx, ny = self.x + self.w / 2, self.y + self.h / 2
  local dx, dy = px - nx, py - ny

  if math.abs(dx) > math.abs(dy) then
    self.facing = dx > 0 and "right" or "left"
  else
    self.facing = dy > 0 and "down" or "up"
  end

  -- Push the dialogue state if a dialogue id is set
  if self.dialogue and self.dialogue ~= "" then
    local StateManager = require("src.states.statemanager")
    local DialogueState = require("src.states.dialogue")
    StateManager.push(DialogueState, { dialogue_id = self.dialogue })
  end
end

-- Remove this NPC from the bump world (called on map unload).
function NPC:destroy()
  if MapManager.world then
    MapManager.world:remove(self)
  end
end

function NPC:draw()
  local c = self.color
  love.graphics.setColor(c[1], c[2], c[3], 1)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 3, 3)

  -- Direction dot
  love.graphics.setColor(0.1, 0.1, 0.1, 1)
  local cx = self.x + self.w / 2
  local cy_center = self.y + self.h / 2
  local offsets = {
    up    = {0, -7},
    down  = {0,  7},
    left  = {-7, 0},
    right = { 7, 0},
  }
  local off = offsets[self.facing]
  love.graphics.circle("fill", cx + off[1], cy_center + off[2], 2.5)

  love.graphics.setColor(1, 1, 1, 1)
end

return NPC
