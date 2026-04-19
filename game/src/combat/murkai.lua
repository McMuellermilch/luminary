-- MurkAI — 3-phase Murk boss combat AI
--
-- Phase 1 (HP > 66 %): slow advance, standard attack.
-- Phase 2 (HP 33–66 %): faster, bigger hitbox, shorter cooldown.
-- Phase 3 (HP < 33 %): Tidal Pull — large hitbox pulls player toward boss.
--
-- Returns a hitbox table on attack (compatible with Overworld._enemy_hitboxes).
-- The hitbox may include kbx/kby for knockback applied to the player.

local MurkAI = {}

-- -------------------------------------------------------------------------
-- Initialise boss bookkeeping (call once after Enemy.new).
-- -------------------------------------------------------------------------
function MurkAI.init(boss)
  boss.ai_state    = "alert"
  boss.attack_timer = 0
  boss.murk_phase  = 1
end

-- -------------------------------------------------------------------------
local function current_phase(boss)
  local eh = boss:getComponent("health")
  local frac = eh.max_hp > 0 and (eh.hp / eh.max_hp) or 0
  if frac > 0.66 then return 1
  elseif frac > 0.33 then return 2
  else return 3 end
end

local function boss_move_filter(item, other)
  if other.type == "wall" then return "slide" end
  return "cross"
end

-- -------------------------------------------------------------------------
-- Per-frame update. Returns hitbox or nil.
-- -------------------------------------------------------------------------
function MurkAI.update(boss, player, dt)
  local eh = boss:getComponent("health")
  if eh:isDead() then return nil end

  boss.murk_phase = current_phase(boss)

  local ew  = boss.w or 20
  local eh_h = boss.h or 26
  local ecx = boss.x + ew  / 2
  local ecy = boss.y + eh_h / 2
  local pcx = player.x + (player.w or 20) / 2
  local pcy = player.y + (player.h or 26) / 2
  local dx   = pcx - ecx
  local dy   = pcy - ecy
  local dist = math.sqrt(dx * dx + dy * dy)

  local phys   = boss:getComponent("physics")
  local facing = boss:getComponent("facing")

  boss.attack_timer = boss.attack_timer - dt

  -- Phase parameters
  local speed, cooldown, atk_range, hb_w, hb_h
  local phase = boss.murk_phase
  if phase == 1 then
    speed = 42; cooldown = 2.4; atk_range = 64;  hb_w = 52; hb_h = 52
  elseif phase == 2 then
    speed = 62; cooldown = 1.7; atk_range = 72;  hb_w = 68; hb_h = 68
  else
    speed = 78; cooldown = 1.2; atk_range = 84;  hb_w = 86; hb_h = 86
  end

  -- Always advance toward the player
  if dist > 4 then
    local nx, ny = dx / dist, dy / dist
    phys:move(nx * speed * dt, ny * speed * dt, boss_move_filter)
    if math.abs(dx) >= math.abs(dy) then
      facing:set(dx > 0 and "right" or "left", true)
    else
      facing:set(dy > 0 and "down" or "up", true)
    end
  end

  -- Attack when in range and cooldown elapsed
  local hitbox = nil
  if dist <= atk_range and boss.attack_timer <= 0 then
    boss.attack_timer = cooldown

    local dir_x = dist > 0 and (dx / dist) or 0
    local dir_y = dist > 0 and (dy / dist) or 0

    -- Phase 3 Tidal Pull: negative knockback (pulls player toward boss)
    local kbx, kby = 0, 0
    if phase == 3 then
      kbx = -dir_x * 72
      kby = -dir_y * 72
    end

    hitbox = {
      x        = ecx + dir_x * (ew  / 2) - hb_w / 2,
      y        = ecy + dir_y * (eh_h / 2) - hb_h / 2,
      w        = hb_w,
      h        = hb_h,
      raw_atk  = (boss.base_atk or 18) * (phase == 3 and 1.4 or 1),
      kbx      = kbx,
      kby      = kby,
      lifetime = 3,
    }

    if math.abs(dx) >= math.abs(dy) then
      facing:forceDirection(dx >= 0 and "right" or "left")
    else
      facing:forceDirection(dy >= 0 and "down" or "up")
    end
  end

  return hitbox
end

return MurkAI
