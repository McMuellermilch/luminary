-- Overworld state
-- Loads a Tiled map, runs player movement + camera, draws the world.
-- Handles warp zone detection, NPC spawning, enemy spawning and combat.

local Input          = require("src.core.input")
local MapManager     = require("src.world.mapmanager")
local Camera         = require("src.world.camera")
local Player         = require("src.entities.player")
local NPC            = require("src.entities.npc")
local Enemy          = require("src.entities.enemy")
local WildLumin      = require("src.entities.wildlumin")
local EnemyAI        = require("src.combat.enemyai")
local WarpSystem     = require("src.world.warpsystem")
local EntityManager  = require("src.entities.entitymanager")
local PartyManager   = require("src.creatures.partymanager")
local Events         = require("src.core.events")
local Items          = require("src.data.items")
local Inventory      = require("src.creatures.inventory")
local CaptureSystem  = require("src.systems.capturesystem")
local TrustMeter     = require("src.ui.trustmeter")
local RegionState    = require("src.world.regionstate")
local MusicManager   = require("src.audio.musicmanager")
local SFX            = require("src.audio.sfx")
local SaveManager    = require("src.save.savemanager")
local CombatHUD      = require("src.ui.combathud")
local HUD            = require("src.ui.hud")
local MurkAI         = require("src.combat.murkai")

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

  -- Notify RegionState so shader params snap to correct values
  RegionState.onMapLoad(MapManager.region)

  -- Notify SaveManager so it can track the current map for autosave
  Events.emit("map_loaded", { map = map_path, spawn = spawn_id })

  -- Play region music based on lit state
  local region = MapManager.region
  if region then
    local set_name = RegionState.isLit(region) and (region .. "_lit") or (region .. "_dark")
    MusicManager.play(set_name)
  end

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

  -- Spawn wild lumins
  self._wild_lumins = {}
  for _, data in ipairs(MapManager.wild_lumins) do
    local wl = WildLumin.new(data)
    EntityManager.add(wl)
    self._wild_lumins[#self._wild_lumins + 1] = wl
  end

  -- Store beacon tower and lighthouse positions (world-space)
  self._beacon_towers = MapManager.beacon_towers
  self._lighthouses   = MapManager.lighthouses

  -- Load chest data (preserve opened state across reloads if same map)
  self._chests = {}
  for _, c in ipairs(MapManager.chests) do
    self._chests[#self._chests + 1] = {
      x = c.x, y = c.y, w = c.w, h = c.h,
      item = c.item, count = c.count, id = c.id,
      opened = false,
    }
  end

  -- Load boss trigger data
  self._boss_triggers = {}
  for _, bt in ipairs(MapManager.boss_triggers) do
    self._boss_triggers[#self._boss_triggers + 1] = {
      x = bt.x, y = bt.y, w = bt.w, h = bt.h,
      boss_id = bt.boss_id,
      spawn_x = bt.spawn_x,
      spawn_y = bt.spawn_y,
    }
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

  -- Lighthouse save prompt (nil when inactive)
  self._lighthouse_prompt = nil  -- {} when asking, { timer, msg } when showing result

  -- Light Meter: 0.0–1.0, fills on hits, drains on damage
  self._light_meter = 0

  -- Boss state
  self._murk_boss    = nil    -- set to the Enemy entity when boss is spawned
  self._boss_defeated = false  -- prevents double shard award

  -- Generic popup (chest found, etc.)
  self._popup = nil  -- { msg, timer }

  -- Darkness shader (lazily loaded)
  self._dark_shader = nil

  WarpSystem.reset()

  -- Audio: warp SFX on zone trigger
  Events.on("warp_completed", function()
    SFX.play("warp")
  end)
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

  -- Reset lighthouse prompt and light meter on map change
  self._lighthouse_prompt = nil
  self._light_meter       = self._light_meter or 0  -- preserve meter across warps

  -- Reset boss and chest state on map change
  self._murk_boss    = nil
  self._boss_defeated = false
  self._popup         = nil

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
            SFX.play("attack_hit", { pitch = 0.9 + math.random() * 0.2 })
            MusicManager.setContext("combat")
            self._light_meter = math.min(1.0, self._light_meter + 0.18)  -- fill on hit
            if eh:isDead() then
              Events.emit("enemy_defeated", {
                exp_yield   = enemy.exp_yield   or 0,
                loot_lumens = enemy.loot_lumens or 5,
              })
              -- Boss defeat: award the Willowfen Beacon Shard
              if enemy == self._murk_boss and not self._boss_defeated then
                self._boss_defeated = true
                Inventory.add("beacon_shard_willowfen")
                local SM  = require("src.states.statemanager")
                local Dlg = require("src.states.dialogue")
                SM.push(Dlg, { dialogue_id = "shard_obtained" })
              end
              enemy:destroy()
              -- Return to overworld mix if no live enemies remain
              local any_alive = false
              for _, e in ipairs(self._enemies) do
                if e.active and not e:getComponent("health"):isDead() then
                  any_alive = true; break
                end
              end
              if not any_alive then MusicManager.setContext("overworld") end
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
        self._light_meter = math.max(0.0, self._light_meter - 0.22)  -- drain on damage
        -- Apply knockback to player (e.g. Tidal Pull from boss phase 3)
        if (hb.kbx or 0) ~= 0 or (hb.kby or 0) ~= 0 then
          local pphys = self.player:getComponent("physics")
          if pphys then
            pphys:move(hb.kbx, hb.kby,
              function(_, other) return other.type == "wall" and "slide" or "cross" end)
          end
        end
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
-- Darkness shader — lazily loaded once and reused.
-- -------------------------------------------------------------------------
function Overworld:_getDarkShader()
  if not self._dark_shader then
    self._dark_shader = love.graphics.newShader("assets/shaders/darkness.glsl")
  end
  return self._dark_shader
end

-- -------------------------------------------------------------------------
-- Try to open a nearby chest. Returns true if handled.
-- -------------------------------------------------------------------------
function Overworld:_tryChestInteract()
  local pcx, pcy = self.player:center()
  for _, chest in ipairs(self._chests or {}) do
    if not chest.opened then
      local cx = chest.x + (chest.w or 32) / 2
      local cy = chest.y + (chest.h or 32) / 2
      if math.abs(cx - pcx) < 48 and math.abs(cy - pcy) < 48 then
        chest.opened = true
        local item_def = chest.item and Items[chest.item]
        if item_def then
          Inventory.add(chest.item, chest.count or 1)
          local qty = (chest.count or 1)
          self._popup = {
            msg   = "Found " .. qty .. "\xC3\x97 " .. item_def.name .. "!",
            timer = 2.2,
          }
        end
        SFX.play("menu_select")
        return true
      end
    end
  end
  return false
end

-- -------------------------------------------------------------------------
-- Check whether the player has entered a boss trigger zone; spawn boss once.
-- -------------------------------------------------------------------------
function Overworld:_checkBossTriggers()
  if self._murk_boss then return end  -- already spawned
  local pcx, pcy = self.player:center()
  for _, trigger in ipairs(self._boss_triggers or {}) do
    if overlaps(pcx - 8, pcy - 8, 16, 16,
                trigger.x, trigger.y, trigger.w, trigger.h) then
      -- Spawn the boss entity
      local boss = Enemy.new({
        x           = trigger.spawn_x or (trigger.x + trigger.w / 2 - 16),
        y           = trigger.spawn_y or (trigger.y + trigger.h / 2 - 16),
        creature_id = trigger.boss_id or "murk_boss",
        patrol_radius = 256,
        is_boss     = true,
      })
      MurkAI.init(boss)
      EntityManager.add(boss)
      self._enemies[#self._enemies + 1] = boss
      self._murk_boss = boss
      -- Boss intro dialogue (world freezes while dialogue is open)
      local SM  = require("src.states.statemanager")
      local Dlg = require("src.states.dialogue")
      SM.push(Dlg, { dialogue_id = "murk_intro" })
      MusicManager.setContext("combat")
      break
    end
  end
end

-- -------------------------------------------------------------------------
-- Try to interact with a nearby beacon tower. Returns true if handled.
-- -------------------------------------------------------------------------
function Overworld:_tryBeaconInteract()
  local pcx, pcy = self.player:center()
  for _, tower in ipairs(self._beacon_towers or {}) do
    local dx = math.abs((tower.x + 16) - pcx)
    local dy = math.abs((tower.y + 16) - pcy)
    if dx < 48 and dy < 48 then
      local region = RegionState.getActiveRegion() or "willowfen"
      if RegionState.isLit(region) then return true end  -- already lit, consume event
      if not Inventory.has("beacon_shard_willowfen") then
        -- Show flavour dialogue when player lacks the shard
        local SM  = require("src.states.statemanager")
        local Dlg = require("src.states.dialogue")
        SM.push(Dlg, { dialogue_id = "beacon_tower_no_shard" })
        return true
      end
      local BeaconRekindleState = require("src.states.beaconrekindle")
      local SM = require("src.states.statemanager")
      SM.push(BeaconRekindleState, {
        overworld = self,
        region_id = region,
        tower_x   = tower.x,
        tower_y   = tower.y,
      })
      return true
    end
  end
  return false
end

-- -------------------------------------------------------------------------
-- Try to interact with a nearby lighthouse. Returns true if handled.
-- -------------------------------------------------------------------------
function Overworld:_tryLighthouseInteract()
  local pcx, pcy = self.player:center()
  for _, lh in ipairs(self._lighthouses or {}) do
    local dx = math.abs((lh.x + 16) - pcx)
    local dy = math.abs((lh.y + 16) - pcy)
    if dx < 48 and dy < 48 then
      -- Open save-confirmation prompt (world freezes while it's shown)
      self._lighthouse_prompt = {}
      return true
    end
  end
  return false
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
    SFX.play("capture_win")
    -- Remove from enemy tracking list before destroy
    for i, e in ipairs(self._enemies) do
      if e == cap.enemy then table.remove(self._enemies, i); break end
    end
    CaptureSystem.finalize(cap.enemy)
    cap.enemy:destroy()
  else
    SFX.play("capture_fail")
  end
  -- On failure: enemy remains, already de-paused by clearing _capture
end

-- -------------------------------------------------------------------------
function Overworld:update(dt)
  if Input.wasPressed("pause") then
    local StateManager = require("src.states.statemanager")
    local PauseMenu    = require("src.states.pausemenu")
    StateManager.push(PauseMenu)
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

  -- Lighthouse save prompt (freezes world while asking Y/N)
  if self._lighthouse_prompt then
    if self._lighthouse_prompt.timer then
      -- Showing result message — count down and dismiss
      self._lighthouse_prompt.timer = self._lighthouse_prompt.timer - dt
      if self._lighthouse_prompt.timer <= 0 then self._lighthouse_prompt = nil end
    else
      -- Waiting for player input
      if Input.wasPressed("confirm") then
        PartyManager.healAll()
        SaveManager.save(SaveManager.current_slot)
        SFX.play("menu_select")
        self._lighthouse_prompt = { timer = 1.5, msg = "Game Saved.  Party healed!" }
      elseif Input.wasPressed("cancel") then
        self._lighthouse_prompt = nil
      end
    end
    local cx, cy = self.player:center()
    self.camera:follow(cx, cy)
    self.camera:update(dt)
    return
  end

  -- Radiance Burst: fires when light meter is full and player presses ability2
  if self._light_meter >= 1.0 and Input.wasPressed("ability2") then
    local active    = PartyManager.getActive()
    local companion = PartyManager.getCompanion()
    if active    then active.hp    = math.min(active.max_hp,    active.hp    + 20) end
    if companion then companion.hp = math.min(companion.max_hp, companion.hp + 20) end
    self._light_meter = 0
    SFX.play("menu_select")  -- placeholder until radiance_burst SFX exists
  end

  -- Beacon tower / lighthouse / chest interactions (only one fires per confirm press)
  if Input.wasPressed("confirm") then
    if not self:_tryBeaconInteract() then
      if not self:_tryLighthouseInteract() then
        self:_tryChestInteract()
      end
    end
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

  -- Boss trigger check (every frame, before entity updates)
  self:_checkBossTriggers()

  -- Popup countdown
  if self._popup then
    self._popup.timer = self._popup.timer - dt
    if self._popup.timer <= 0 then self._popup = nil end
  end

  MapManager.update(dt)
  EntityManager.update(dt)   -- player + NPCs + enemies (animations)

  -- Enemy AI (driven here, not inside Enemy:update, so hit-pause can freeze it)
  for _, enemy in ipairs(self._enemies) do
    if enemy.active then
      local eh = enemy:getComponent("health")
      if not eh:isDead() then
        local hb
        if enemy == self._murk_boss then
          hb = MurkAI.update(enemy, self.player, dt)
        else
          hb = EnemyAI.update(enemy, self.player, dt)
        end
        if hb then self._enemy_hitboxes[#self._enemy_hitboxes+1] = hb end
      end
    end
  end

  -- Wild lumin AI (with player reference, like enemy AI)
  for _, wl in ipairs(self._wild_lumins or {}) do
    if wl.active then wl:updateAI(dt, self.player) end
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
    -- Draw chests (world space)
    for _, chest in ipairs(self._chests or {}) do
      local cw = (chest.w or 32) - 8
      local ch = (chest.h or 32) - 8
      if chest.opened then
        love.graphics.setColor(0.40, 0.35, 0.25, 0.7)
      else
        love.graphics.setColor(0.82, 0.68, 0.18, 0.95)
      end
      love.graphics.rectangle("fill", chest.x + 4, chest.y + 4, cw, ch, 3, 3)
      love.graphics.setColor(chest.opened and 0.30 or 0.55,
                             chest.opened and 0.25 or 0.45,
                             chest.opened and 0.18 or 0.14, 0.85)
      love.graphics.setLineWidth(1)
      love.graphics.rectangle("line", chest.x + 4, chest.y + 4, cw, ch, 3, 3)
    end
    -- Hit flashes (in world space, inside camera)
    love.graphics.setColor(1, 1, 1, 0.88)
    for _, f in ipairs(self._hit_flashes) do
      love.graphics.rectangle("fill", f.x, f.y, f.w, f.h)
    end
    love.graphics.setColor(1, 1, 1, 1)
    MapManager.drawAbove()
  -- Apply darkness shader when region is unlit
  local post_shader = nil
  local region = RegionState.getActiveRegion()
  if not RegionState.isLit(region) then
    local shader = self:_getDarkShader()
    local params = RegionState.shader_params
    local pcx, pcy = self.player:center()
    local sx, sy   = self.camera:toScreen(pcx, pcy)
    shader:send("desaturate_amount", params.desaturate)
    shader:send("brightness",        params.brightness)
    shader:send("player_screen_pos", {sx, sy})
    shader:send("vignette_radius",   200.0)
    post_shader = shader
  end
  self.camera:detach(post_shader)
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

  -- Lighthouse save prompt UI
  if self._lighthouse_prompt then
    local sw, sh = love.graphics.getDimensions()
    local box_w, box_h = 400, 52
    local bx = math.floor((sw - box_w) / 2)
    local by = math.floor(sh * 0.38)
    love.graphics.setColor(0.08, 0.06, 0.12, 0.93)
    love.graphics.rectangle("fill", bx, by, box_w, box_h, 6, 6)
    love.graphics.setColor(0.85, 0.75, 0.40, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bx, by, box_w, box_h, 6, 6)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(get_debug_font())
    if self._lighthouse_prompt.timer then
      love.graphics.setColor(0.55, 0.95, 0.55, 1)
      love.graphics.printf(self._lighthouse_prompt.msg or "Game Saved.", bx, by + 19, box_w, "center")
    else
      love.graphics.setColor(0.95, 0.92, 0.88, 1)
      love.graphics.printf("Save your journey here?  [Z = Yes   X = No]", bx, by + 19, box_w, "center")
    end
  end

  -- Generic popup (chest found, etc.)
  if self._popup then
    local sw, sh = love.graphics.getDimensions()
    local pw, ph = 360, 38
    local ppx = math.floor((sw - pw) / 2)
    local ppy = math.floor(sh * 0.44)
    love.graphics.setColor(0.06, 0.10, 0.04, 0.92)
    love.graphics.rectangle("fill", ppx, ppy, pw, ph, 5, 5)
    love.graphics.setColor(0.65, 0.92, 0.38, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", ppx, ppy, pw, ph, 5, 5)
    love.graphics.setFont(get_debug_font())
    love.graphics.setColor(0.95, 0.92, 0.82, 1)
    love.graphics.printf(self._popup.msg, ppx, ppy + 12, pw, "center")
  end

  -- Overworld HUD: party strip (top-right)
  HUD.draw()

  -- Combat HUD: Lumin panels, enemy HP, light meter
  local charge_frac = self.player
    and self.player:getComponent("chargering").charge or 0
  CombatHUD.draw(self._enemies, self._light_meter, charge_frac)

  -- Slim debug bar (top-left)
  local lantern_count = Inventory.count("lightglass_lantern")
    + Inventory.count("warmglass_lantern")
    + Inventory.count("duskglass_lantern")
  love.graphics.setColor(0, 0, 0, 0.42)
  love.graphics.rectangle("fill", 0, 0, 500, 22)
  love.graphics.setColor(0.72, 0.72, 0.72, 0.78)
  love.graphics.setFont(get_debug_font())
  love.graphics.print(
    string.format("x:%.0f y:%.0f  [Esc=pause  Q=throw lantern ×%d]",
      self.player.x, self.player.y, lantern_count), 6, 4)
  love.graphics.setColor(1, 1, 1, 1)
end

function Overworld:keypressed(key) end

return Overworld
