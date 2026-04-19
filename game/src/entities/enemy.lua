-- Enemy entity (overworld)
-- Spawned from Tiled object layer via MapManager.enemies.
-- Patrols its spawn area; chases and attacks the player when aggroed.

local Entity    = require("src.entities.entity")
local Physics   = require("src.entities.components.physics")
local AnimComp  = require("src.entities.components.animation")
local Facing    = require("src.entities.components.facing")
local Health    = require("src.entities.components.health")
local Aseprite  = require("src.core.aseprite")
local MapManager = require("src.world.mapmanager")
local Creatures  = require("src.data.creatures")

local Enemy = setmetatable({}, { __index = Entity })
Enemy.__index = Enemy

local W, H = 20, 26

-- data: { x, y, creature_id, patrol_radius }
-- x/y is the top-left of the Tiled tile; hitbox is centred within it.
function Enemy.new(data)
  local x = data.x + (32 - W) / 2
  local y = data.y + (32 - H) / 2

  local self = Entity.new(x, y)
  setmetatable(self, Enemy)

  local def = Creatures[data.creature_id] or Creatures.gleamfin

  self.w    = W
  self.h    = H
  self.type = "enemy"
  self.name = def.name or "Enemy"

  -- AI parameters (read by EnemyAI module)
  self.spawn_x         = x
  self.spawn_y         = y
  self.patrol_radius   = data.patrol_radius    or 80
  self.speed           = def.speed             or 55
  self.aggro_range     = def.aggro_range       or 100
  self.attack_range    = def.attack_range      or 32
  self.base_atk        = def.base_atk          or def.base_damage or 10
  self.base_def        = def.base_def          or 5
  self.attack_cooldown = def.attack_cooldown   or 1.8
  self.exp_yield       = def.exp_yield         or 5

  -- Physics
  local phys = Physics.new(MapManager.world, W, H)
  self:addComponent("physics", phys)
  phys:register()

  -- Animation
  local png  = def.sprite_png  or "assets/sprites/npc_generic.png"
  local json = def.sprite_json or "assets/sprites/npc_generic.json"
  local sprite = Aseprite.load(png, json)
  local anim   = AnimComp.new(sprite.image, sprite.anims)
  self:addComponent("animation", anim)

  -- Facing
  local facing = Facing.new("down")
  self:addComponent("facing", facing)
  facing:forceDirection("down")

  -- Health
  self:addComponent("health", Health.new(def.base_hp or def.max_hp or 8))

  -- Hit flash timer (white overlay on damage)
  self._flash_timer = 0

  return self
end

-- Flash the enemy white for a moment when hit.
function Enemy:onHit()
  self._flash_timer = 0.12
end

function Enemy:update(dt)
  -- AI is driven by Overworld:_updateEnemies(); only animation runs here.
  self._flash_timer = math.max(0, self._flash_timer - dt)
  self:getComponent("animation"):update(dt)
end

function Enemy:draw()
  local anim = self:getComponent("animation")
  if self._flash_timer > 0 then
    -- Draw white silhouette (tint white)
    love.graphics.setColor(1, 1, 1, 0.7)
    anim:draw()
    love.graphics.setColor(1, 1, 1, 1)
  end
  anim:draw()

  -- HP bar (3px tall, above sprite)
  local hp   = self:getComponent("health")
  local frac = math.max(0, hp.hp / hp.max_hp)
  local bx   = self.x
  local by   = self.y - 5
  love.graphics.setColor(0.15, 0.15, 0.15, 0.85)
  love.graphics.rectangle("fill", bx, by, W, 3)
  if frac > 0.5 then
    love.graphics.setColor(0.2, 0.75, 0.2, 0.9)
  elseif frac > 0.25 then
    love.graphics.setColor(0.9, 0.75, 0.1, 0.9)
  else
    love.graphics.setColor(0.85, 0.15, 0.15, 0.9)
  end
  love.graphics.rectangle("fill", bx, by, W * frac, 3)
  love.graphics.setColor(1, 1, 1, 1)
end

function Enemy:destroy()
  self:getComponent("physics"):unregister()
  Entity.destroy(self)
end

return Enemy
