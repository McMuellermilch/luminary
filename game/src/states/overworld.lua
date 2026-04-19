-- Overworld state
-- Loads a Tiled map, runs player movement + camera, draws the world.
-- Handles warp zone detection, NPC spawning, enemy spawning and combat.

local Input         = require("src.core.input")
local MapManager    = require("src.world.mapmanager")
local Camera        = require("src.world.camera")
local Player        = require("src.entities.player")
local NPC           = require("src.entities.npc")
local Enemy         = require("src.entities.enemy")
local EnemyAI       = require("src.combat.enemyai")
local WarpSystem    = require("src.world.warpsystem")
local EntityManager = require("src.entities.entitymanager")

local Overworld = {}
Overworld.__index = Overworld

local DEFAULT_MAP   = "assets/maps/willowfen_town.lua"
local DEFAULT_SPAWN = "default"

-- Hitbox dimensions per charge level
local CHARGE_DMG = { quick = 3, medium = 5, heavy = 9 }
local CHARGE_HB  = {
  quick  = { w = 28, h = 28, kb = 0  },
  medium = { w = 38, h = 38, kb = 30 },
  heavy  = { w = 52, h = 52, kb = 70 },
}

local HIT_PAUSE_FRAMES = 4

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

local function charge_level(frac)
  if frac < 0.3 then return "quick"
  elseif frac < 0.7 then return "medium"
  else return "heavy" end
end

local function overlaps(ax,ay,aw,ah, bx,by,bw,bh)
  return ax < bx+bw and ax+aw > bx and ay < by+bh and ay+ah > by
end

-- Build a world-space hitbox in front of the player.
local function make_player_hitbox(player, dir, w, h, damage, kb)
  local px = player.x + player.w / 2
  local py = player.y + player.h / 2
  local hx, hy, kbx, kby = px - w/2, py - h/2, 0, 0
  if     dir == "up"    then hy = py - player.h/2 - h; kby = -kb
  elseif dir == "down"  then hy = py + player.h/2;     kby =  kb
  elseif dir == "left"  then hx = px - player.w/2 - w; kbx = -kb
  elseif dir == "right" then hx = px + player.w/2;     kbx =  kb
  end
  return { x=hx, y=hy, w=w, h=h, damage=damage, kbx=kbx, kby=kby, lifetime=3 }
end

-- -------------------------------------------------------------------------
-- Internal map loader — shared between enter() and _reload()
-- -------------------------------------------------------------------------
function Overworld:_loadMap(map_path, spawn_id)
  if self.player then self.player:destroy() end
  EntityManager.clear()

  local spawn = MapManager.load(map_path, spawn_id)

  -- Spawn NPCs
  for _, data in ipairs(MapManager.npcs) do
    local npc = NPC.new(data)
    EntityManager.add(npc)
  end

  -- Spawn enemies and initialise their AI
  self._enemies = {}
  for _, data in ipairs(MapManager.enemies) do
    local enemy = Enemy.new(data)
    EnemyAI.init(enemy)
    EntityManager.add(enemy)
    self._enemies[#self._enemies + 1] = enemy
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

  -- Combat state
  self._hit_pause     = 0
  self._player_hitboxes = {}   -- { x,y,w,h,damage,kbx,kby,lifetime }
  self._enemy_hitboxes  = {}   -- { x,y,w,h,damage,lifetime }
  self._hit_flashes     = {}   -- { x,y,w,h,timer } — brief white rectangles

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

  -- Reset combat state
  self._hit_pause       = 0
  self._player_hitboxes = {}
  self._enemy_hitboxes  = {}
  self._hit_flashes     = {}

  WarpSystem.reset()
end

function Overworld:exit() end

-- -------------------------------------------------------------------------
-- Resolve a player attack hitbox against all enemies.
-- -------------------------------------------------------------------------
function Overworld:_resolvePlayerAttack(attack)
  local level = charge_level(attack.charge)
  local def   = CHARGE_HB[level]
  local hb    = make_player_hitbox(self.player, attack.dir,
                  def.w, def.h, CHARGE_DMG[level], def.kb)
  self._player_hitboxes[#self._player_hitboxes + 1] = hb
end

-- -------------------------------------------------------------------------
-- Process all active hitboxes — check overlaps, apply damage, knock back.
-- -------------------------------------------------------------------------
function Overworld:_resolveHitboxes()
  -- Player hitboxes vs enemies
  local keep_p = {}
  for _, hb in ipairs(self._player_hitboxes) do
    hb.lifetime = hb.lifetime - 1
    if hb.lifetime > 0 then
      local hit = false
      for _, enemy in ipairs(self._enemies) do
        if enemy.active then
          local eh = enemy:getComponent("health")
          if not eh:isDead()
          and overlaps(hb.x,hb.y,hb.w,hb.h, enemy.x,enemy.y,enemy.w,enemy.h) then
            eh:damage(hb.damage)
            enemy:onHit()
            self:_addFlash(enemy.x + enemy.w/2, enemy.y + enemy.h/2)
            self._hit_pause = HIT_PAUSE_FRAMES
            -- Knockback enemy
            if hb.kbx ~= 0 or hb.kby ~= 0 then
              local ep = enemy:getComponent("physics")
              ep:move(hb.kbx, hb.kby, function(_, other)
                return other.type == "wall" and "slide" or "cross"
              end)
            end
            -- Remove dead enemies
            if eh:isDead() then enemy:destroy() end
            hit = true; break
          end
        end
      end
      if not hit then keep_p[#keep_p+1] = hb end
    end
  end
  self._player_hitboxes = keep_p

  -- Enemy hitboxes vs player
  local keep_e = {}
  for _, hb in ipairs(self._enemy_hitboxes) do
    hb.lifetime = hb.lifetime - 1
    if hb.lifetime > 0 then
      local ph = self.player:getComponent("health")
      if not ph:isDead()
      and overlaps(hb.x,hb.y,hb.w,hb.h,
                   self.player.x,self.player.y,self.player.w,self.player.h) then
        ph:damage(hb.damage)
        self:_addFlash(self.player.x + self.player.w/2,
                       self.player.y + self.player.h/2)
        self._hit_pause = HIT_PAUSE_FRAMES
        -- (Defeat handling can be added in Phase 6)
      else
        keep_e[#keep_e+1] = hb
      end
    end
  end
  self._enemy_hitboxes = keep_e
end

function Overworld:_addFlash(cx, cy)
  self._hit_flashes[#self._hit_flashes+1] = {
    x=cx-8, y=cy-8, w=16, h=16, timer=0.10
  }
end

-- -------------------------------------------------------------------------
function Overworld:update(dt)
  if Input.wasPressed("pause") then
    local StateManager = require("src.states.statemanager")
    StateManager.pop()
    return
  end

  -- Hit-pause: freeze entity logic for a few frames on a successful hit
  if self._hit_pause > 0 then
    self._hit_pause = self._hit_pause - 1
    -- Still update camera so it doesn't stutter
    local cx, cy = self.player:center()
    self.camera:follow(cx, cy)
    self.camera:update(dt)
    return
  end

  MapManager.update(dt)
  EntityManager.update(dt)   -- player + NPCs + enemies (animations)

  -- Enemy AI (driven here, not inside Enemy:update, so hit-pause can freeze it)
  for _, enemy in ipairs(self._enemies) do
    if enemy.active then
      local eh = enemy:getComponent("health")
      if not eh:isDead() then
        local hb = EnemyAI.update(enemy, self.player, dt)
        if hb then self._enemy_hitboxes[#self._enemy_hitboxes+1] = hb end
      end
    end
  end

  -- Consume player pending attack
  if self.player.pending_attack then
    self:_resolvePlayerAttack(self.player.pending_attack)
    self.player.pending_attack = nil
  end

  self:_resolveHitboxes()

  -- Decay hit flashes
  local live = {}
  for _, f in ipairs(self._hit_flashes) do
    f.timer = f.timer - dt
    if f.timer > 0 then live[#live+1] = f end
  end
  self._hit_flashes = live

  WarpSystem.check(self, self.player)

  local cx, cy = self.player:center()
  self.camera:follow(cx, cy)
  self.camera:update(dt)
end

-- -------------------------------------------------------------------------
function Overworld:draw()
  self.camera:attach()
    MapManager.drawBelow()
    EntityManager.draw()   -- player + NPCs + enemies, Y-sorted
    -- Hit flashes (in world space, inside camera)
    love.graphics.setColor(1, 1, 1, 0.88)
    for _, f in ipairs(self._hit_flashes) do
      love.graphics.rectangle("fill", f.x, f.y, f.w, f.h)
    end
    love.graphics.setColor(1, 1, 1, 1)
    MapManager.drawAbove()
  self.camera:detach()
  self.camera:draw()

  -- Debug HUD
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, 300, 36)
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
