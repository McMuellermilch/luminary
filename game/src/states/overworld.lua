-- Overworld state
-- Loads a Tiled map, runs player movement + camera, draws the world.
-- Handles warp zone detection, NPC spawning, enemy spawning and combat.

local Input          = require("src.core.input")
local MapManager     = require("src.world.mapmanager")
local Camera         = require("src.world.camera")
local Player         = require("src.entities.player")
local NPC            = require("src.entities.npc")
local Enemy          = require("src.entities.enemy")
local EnemyAI        = require("src.combat.enemyai")
local WarpSystem     = require("src.world.warpsystem")
local EntityManager  = require("src.entities.entitymanager")
local PartyManager   = require("src.creatures.partymanager")
local Events         = require("src.core.events")
local Items          = require("src.data.items")
local Inventory      = require("src.creatures.inventory")
local CaptureSystem  = require("src.systems.capturesystem")
local TrustMeter     = require("src.ui.trustmeter")

local Overworld = {}
Overworld.__index = Overworld

local DEFAULT_MAP   = "assets/maps/willowfen_town.lua"
local DEFAULT_SPAWN = "default"

-- Charge multipliers — applied to attacker atk stat
local CHARGE_MULT = { quick = 1.0, medium = 1.5, heavy = 2.5 }
local CHARGE_HB   = {
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
  return { x=hx, y=hy, w=w, h=h, raw_atk=damage, kbx=kbx, kby=kby, lifetime=3 }
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

  -- Ensure starting party exists
  PartyManager.initIfEmpty()

  local spawn = self:_loadMap(map_path, spawn_id)

  local active = PartyManager.getActive()
  local px = spawn.x + (32 - 20) / 2
  local py = spawn.y + (32 - 26) / 2
  self.player = Player.new(px, py, active and active.max_hp or 10)
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

  -- Capture state (nil when inactive)
  self._capture = nil          -- { enemy, meter, reject_msg, reject_timer }

  WarpSystem.reset()
end

-- Called by WarpSystem at fade midpoint to swap map without leaving the state.
function Overworld:_reload(map_path, spawn_id)
  local spawn = self:_loadMap(map_path, spawn_id)

  local active = PartyManager.getActive()
  local px = spawn.x + (32 - 20) / 2
  local py = spawn.y + (32 - 26) / 2
  self.player = Player.new(px, py, active and active.max_hp or 10)
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

  -- Reset capture state
  self._capture = nil

  WarpSystem.reset()
end

function Overworld:exit() end

-- -------------------------------------------------------------------------
-- Resolve a player attack hitbox against all enemies.
-- -------------------------------------------------------------------------
function Overworld:_resolvePlayerAttack(attack)
  local level  = charge_level(attack.charge)
  local hb_def = CHARGE_HB[level]
  local active = PartyManager.getActive()
  local raw_atk = (active and active.atk or 10) * CHARGE_MULT[level]
  local hb = make_player_hitbox(self.player, attack.dir,
               hb_def.w, hb_def.h, raw_atk, hb_def.kb)
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
            -- Stat-based damage: max(1, atk - def * 0.5)
            local damage = math.max(1, math.floor(hb.raw_atk - (enemy.base_def or 5) * 0.5))
            eh:damage(damage)
            enemy:onHit()
            self:_addFlash(enemy.x + enemy.w/2, enemy.y + enemy.h/2)
            self._hit_pause = HIT_PAUSE_FRAMES
            if hb.kbx ~= 0 or hb.kby ~= 0 then
              enemy:getComponent("physics"):move(hb.kbx, hb.kby,
                function(_, other) return other.type=="wall" and "slide" or "cross" end)
            end
            if eh:isDead() then
              Events.emit("enemy_defeated", {
                exp_yield   = enemy.exp_yield   or 0,
                loot_lumens = enemy.loot_lumens or 5,
              })
              enemy:destroy()
            end
            hit = true; break
          end
        end
      end
      if not hit then keep_p[#keep_p+1] = hb end
    end
  end
  self._player_hitboxes = keep_p

  -- Enemy hitboxes vs player
  local active = PartyManager.getActive()
  local player_def = active and active.def or 5
  local keep_e = {}
  for _, hb in ipairs(self._enemy_hitboxes) do
    hb.lifetime = hb.lifetime - 1
    if hb.lifetime > 0 then
      local ph = self.player:getComponent("health")
      if not ph:isDead()
      and overlaps(hb.x,hb.y,hb.w,hb.h,
                   self.player.x,self.player.y,self.player.w,self.player.h) then
        local damage = math.max(1, math.floor((hb.raw_atk or hb.damage or 2) - player_def * 0.5))
        ph:damage(damage)
        if active then active.hp = math.max(0, active.hp - damage) end
        self:_addFlash(self.player.x + self.player.w/2,
                       self.player.y + self.player.h/2)
        self._hit_pause = HIT_PAUSE_FRAMES
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
-- Find the nearest active enemy within `range` pixels of the player centre.
-- -------------------------------------------------------------------------
function Overworld:_findCaptureTarget(range)
  local pcx, pcy = self.player:center()
  local best, best_dist = nil, range * range
  for _, enemy in ipairs(self._enemies) do
    if enemy.active then
      local eh = enemy:getComponent("health")
      if not eh:isDead() then
        local ecx = enemy.x + enemy.w / 2
        local ecy = enemy.y + enemy.h / 2
        local dx  = ecx - pcx
        local dy  = ecy - pcy
        local d2  = dx * dx + dy * dy
        if d2 <= best_dist then
          best      = enemy
          best_dist = d2
        end
      end
    end
  end
  return best
end

-- Choose the best available lantern for the given enemy.
-- Prefers standard lanterns; falls back to duskglass for void types.
-- Returns item_id string, or nil if none available.
local function pick_lantern(enemy)
  if enemy.creature_type == "void" then
    if Inventory.count("duskglass_lantern") > 0 then
      return "duskglass_lantern"
    end
    return nil
  end
  if Inventory.count("warmglass_lantern") > 0 then
    return "warmglass_lantern"
  end
  if Inventory.count("lightglass_lantern") > 0 then
    return "lightglass_lantern"
  end
  return nil
end

-- Attempt to throw a lantern at the nearest enemy in range.
function Overworld:_throwLantern()
  local enemy = self:_findCaptureTarget(90)
  if not enemy then return end  -- no target in range

  local item_id = pick_lantern(enemy)
  if not item_id then
    -- Out of lanterns
    self._capture = { reject_msg = "No lanterns left!", reject_timer = 1.5 }
    return
  end

  local item = Items[item_id]
  local ok, reason = CaptureSystem.canCapture(enemy, item)
  if not ok then
    self._capture = { reject_msg = reason, reject_timer = 1.5 }
    return
  end

  -- Consume the lantern regardless of outcome
  Inventory.remove(item_id)

  local trust = CaptureSystem.calcTrust(enemy, item)
  self._capture = {
    enemy = enemy,
    meter = TrustMeter.new(trust, enemy, self.camera),
  }
end

-- Resolve a completed capture attempt.
function Overworld:_resolveCapture()
  local cap = self._capture
  self._capture = nil

  if not cap.enemy then return end   -- was a reject-message capture, nothing to resolve

  if cap.meter.success then
    -- Remove from enemy tracking list before destroy
    for i, e in ipairs(self._enemies) do
      if e == cap.enemy then table.remove(self._enemies, i); break end
    end
    CaptureSystem.finalize(cap.enemy)
    cap.enemy:destroy()
  end
  -- On failure: enemy remains, already de-paused by clearing _capture
end

-- -------------------------------------------------------------------------
function Overworld:update(dt)
  if Input.wasPressed("pause") then
    local StateManager = require("src.states.statemanager")
    StateManager.pop()
    return
  end

  -- Capture freeze: world paused while trust meter animates
  if self._capture then
    if self._capture.reject_timer then
      -- Brief reject message — just count down
      self._capture.reject_timer = self._capture.reject_timer - dt
      if self._capture.reject_timer <= 0 then self._capture = nil end
    else
      -- Animate trust meter
      self._capture.meter:update(dt)
      if self._capture.meter.done then
        self:_resolveCapture()
      end
    end
    -- Still update camera during freeze
    local cx, cy = self.player:center()
    self.camera:follow(cx, cy)
    self.camera:update(dt)
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

  -- Throw lantern (capture attempt)
  if Input.wasPressed("throw_lantern") then
    self:_throwLantern()
    if self._capture then
      -- Pause started; skip rest of update this frame
      local cx, cy = self.player:center()
      self.camera:follow(cx, cy)
      self.camera:update(dt)
      return
    end
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

  -- Capture UI (screen space, after camera detach)
  if self._capture then
    if self._capture.meter then
      self._capture.meter:draw()
    elseif self._capture.reject_msg then
      -- Brief rejection message centred on screen
      love.graphics.setColor(0.9, 0.2, 0.2, 0.9)
      love.graphics.rectangle("fill", 440, 160, 400, 28, 4, 4)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setFont(get_debug_font())
      love.graphics.printf(self._capture.reject_msg, 440, 168, 400, "center")
    end
  end

  -- Debug HUD
  local active = PartyManager.getActive()
  local lumin_str = active
    and string.format("  |  %s Lv%d  HP:%d/%d  EXP:%d/%d",
      active.data.name, active.level,
      active.hp, active.max_hp,
      active.exp, active.exp_to_next)
    or ""
  local lantern_count = Inventory.count("lightglass_lantern")
    + Inventory.count("warmglass_lantern")
    + Inventory.count("duskglass_lantern")
  local lantern_str = string.format("  |  Lanterns:%d  %dL  [Q=throw]",
    lantern_count, Inventory.lumens)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, 720, 36)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.setFont(get_debug_font())
  love.graphics.print(
    string.format("x:%.0f y:%.0f  facing:%s  [Esc=menu]%s%s",
      self.player.x, self.player.y, self.player:getFacing(), lumin_str, lantern_str),
    6, 10)
  love.graphics.setColor(1, 1, 1, 1)
end

function Overworld:keypressed(key) end

return Overworld
