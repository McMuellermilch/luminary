-- WildLumin
-- Decorative ambient Lumin entity that wanders overworld maps.
-- In dark regions: flees player when nearby.
-- In lit regions:  wanders calmly; may pause and face the player curiously.
-- No health or combat. Interacting opens flavour dialogue.

local Entity      = require("src.entities.entity")
local Physics     = require("src.entities.components.physics")
local AnimComp    = require("src.entities.components.animation")
local Facing      = require("src.entities.components.facing")
local Aseprite    = require("src.core.aseprite")
local MapManager  = require("src.world.mapmanager")
local Creatures   = require("src.data.creatures")
local RegionState = require("src.world.regionstate")

local WildLumin = setmetatable({}, { __index = Entity })
WildLumin.__index = WildLumin

local W, H          = 20, 26
local WANDER_SPEED  = 32
local FLEE_SPEED    = 75
local FLEE_RANGE    = 96     -- pixels — flee threshold in dark regions
local WANDER_MIN    = 2.0
local WANDER_MAX    = 5.0

local function rand_target(ox, oy, radius)
  local a = math.random() * math.pi * 2
  local d = math.random() * radius
  return ox + math.cos(a) * d, oy + math.sin(a) * d
end

local function move_filter(item, other)
  local t = other.type
  if t == "wall" or t == "npc" then return "slide" end
  return "cross"
end

-- data: { x, y, creature_id }  (from MapManager.wild_lumins)
function WildLumin.new(data)
  local x = data.x + (32 - W) / 2
  local y = data.y + (32 - H) / 2
  local self = Entity.new(x, y)
  setmetatable(self, WildLumin)

  local def = Creatures[data.creature_id] or Creatures.gleamfin

  self.w           = W
  self.h           = H
  self.type        = "npc"          -- treated as solid by player/bump; enables interact
  self.creature_id = data.creature_id or "gleamfin"
  self.spawn_x     = x
  self.spawn_y     = y

  local phys = Physics.new(MapManager.world, W, H)
  self:addComponent("physics", phys)
  phys:register()

  local png  = def.sprite_png  or "assets/sprites/npc_generic.png"
  local json = def.sprite_json or "assets/sprites/npc_generic.json"
  local sprite = Aseprite.load(png, json)
  self:addComponent("animation", AnimComp.new(sprite.image, sprite.anims))
  self:addComponent("facing", Facing.new("down"))

  self._wander_timer = math.random() * WANDER_MAX
  self._target_x, self._target_y = rand_target(x, y, 64)

  return self
end

-- Called each frame by Overworld (with player reference), not via EntityManager.
function WildLumin:updateAI(dt, player)
  local phys   = self:getComponent("physics")
  local facing = self:getComponent("facing")
  local cx, cy = phys:center()
  local is_lit = RegionState.isLit(RegionState.getActiveRegion())

  -- In dark regions, flee from nearby player
  if not is_lit and player then
    local pdx  = cx - (player.x + player.w / 2)
    local pdy  = cy - (player.y + player.h / 2)
    local dist = math.sqrt(pdx * pdx + pdy * pdy)
    if dist < FLEE_RANGE and dist > 0 then
      local nx, ny = pdx / dist, pdy / dist
      phys:move(nx * FLEE_SPEED * dt, ny * FLEE_SPEED * dt, move_filter)
      facing:set(pdx > 0 and "right" or "left", true)
      return
    end
  end

  -- Wander toward current target
  self._wander_timer = self._wander_timer - dt
  local tdx   = self._target_x - cx
  local tdy   = self._target_y - cy
  local tdist = math.sqrt(tdx * tdx + tdy * tdy)

  if tdist < 8 or self._wander_timer <= 0 then
    self._wander_timer = WANDER_MIN + math.random() * (WANDER_MAX - WANDER_MIN)
    self._target_x, self._target_y = rand_target(self.spawn_x, self.spawn_y, 64)
    -- In lit region, occasionally pause to face the player curiously
    if is_lit and player and math.random() < 0.3 then
      local px = player.x + player.w / 2
      local py = player.y + player.h / 2
      if math.abs(px - cx) >= math.abs(py - cy) then
        facing:set(px > cx and "right" or "left", false)
      else
        facing:set(py > cy and "down" or "up", false)
      end
    else
      facing:set(nil, false)
    end
  else
    local nx, ny = tdx / tdist, tdy / tdist
    phys:move(nx * WANDER_SPEED * dt, ny * WANDER_SPEED * dt, move_filter)
    if math.abs(tdx) >= math.abs(tdy) then
      facing:set(tdx > 0 and "right" or "left", true)
    else
      facing:set(tdy > 0 and "down" or "up", true)
    end
  end
end

-- Entity:update — only runs animation (AI driven by Overworld)
function WildLumin:update(dt)
  self:getComponent("animation"):update(dt)
end

function WildLumin:draw()
  self:getComponent("animation"):draw()
end

-- Called by Player:_interact when the player presses Z facing this entity.
function WildLumin:onInteract(player)
  local is_lit    = RegionState.isLit(RegionState.getActiveRegion())
  local dlg_id    = is_lit and "wild_lumin_calm" or "wild_lumin_anxious"
  local SM        = require("src.states.statemanager")
  local DlgState  = require("src.states.dialogue")
  SM.push(DlgState, { dialogue_id = dlg_id })
end

function WildLumin:destroy()
  self:getComponent("physics"):unregister()
  Entity.destroy(self)
end

return WildLumin
