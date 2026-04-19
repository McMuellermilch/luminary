-- NPC entity
-- Inherits from Entity. Uses Physics, Animation, and Facing components.
-- Spawned from Tiled object layer data via Overworld:_loadMap().

local Entity   = require("src.entities.entity")
local Physics  = require("src.entities.components.physics")
local AnimComp = require("src.entities.components.animation")
local Facing   = require("src.entities.components.facing")
local Aseprite = require("src.core.aseprite")
local MapManager = require("src.world.mapmanager")

local NPC = setmetatable({}, { __index = Entity })
NPC.__index = NPC

local W = 20
local H = 26

-- Per-NPC sprite override: if a named sprite sheet exists, use it.
-- Otherwise fall back to npc_generic.
local SPRITE_MAP = {
  pip   = "assets/sprites/pip",
}
local GENERIC_PNG  = "assets/sprites/npc_generic.png"
local GENERIC_JSON = "assets/sprites/npc_generic.json"

local function sprite_paths(sprite_name)
  local s = SPRITE_MAP[sprite_name]
  if s then
    return s .. ".png", s .. ".json"
  end
  return GENERIC_PNG, GENERIC_JSON
end

-- data — table from MapManager.npcs: { x, y, id, sprite, dialogue, facing }
function NPC.new(data)
  -- Tiled object x/y is the top-left of the tile; centre the hitbox within it.
  local x = data.x + (32 - W) / 2
  local y = data.y + (32 - H) / 2

  local self = Entity.new(x, y)
  setmetatable(self, NPC)

  self.w        = W
  self.h        = H
  self.type     = "npc"           -- bump tag used by player interaction + collision
  self.id       = data.id or "npc"
  self.dialogue = data.dialogue or ""
  self.shop     = data.shop or nil   -- shop_id; if set, opens ShopState on interact

  -- Physics — solid hitbox in bump world
  local phys = Physics.new(MapManager.world, W, H)
  self:addComponent("physics", phys)
  phys:register()

  -- Animation
  local png, json_path = sprite_paths(data.sprite)
  local sprite = Aseprite.load(png, json_path)
  local anim   = AnimComp.new(sprite.image, sprite.anims)
  self:addComponent("animation", anim)

  -- Facing — sets initial idle animation
  local facing = Facing.new(data.facing or "down")
  self:addComponent("facing", facing)
  facing:set(nil, false)   -- force idle state sync

  return self
end

-- Called from Player:_interact() when the player faces this NPC and presses confirm.
function NPC:onInteract(player)
  -- Turn to face the player
  local phys = self:getComponent("physics")
  local cx, cy = phys:center()
  local pcx, pcy = player:center()
  local dx, dy = pcx - cx, pcy - cy

  local dir
  if math.abs(dx) > math.abs(dy) then
    dir = dx > 0 and "right" or "left"
  else
    dir = dy > 0 and "down" or "up"
  end
  self:getComponent("facing"):forceDirection(dir)

  -- Push shop state if this NPC is a shopkeeper, otherwise push dialogue
  local StateManager = require("src.states.statemanager")
  if self.shop then
    local ShopState = require("src.ui.shop")
    StateManager.push(ShopState, { shop_id = self.shop })
  elseif self.dialogue and self.dialogue ~= "" then
    local DialogueState = require("src.states.dialogue")
    StateManager.push(DialogueState, { dialogue_id = self.dialogue })
  end
end

function NPC:update(dt)
  self:getComponent("animation"):update(dt)
end

function NPC:draw()
  self:getComponent("animation"):draw()
end

function NPC:destroy()
  self:getComponent("physics"):unregister()
  Entity.destroy(self)
end

return NPC
