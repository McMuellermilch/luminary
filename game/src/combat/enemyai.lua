-- EnemyAI (overworld)
-- Three-state machine: patrol → alert → attack.
-- Enemies patrol within a radius of their spawn point.
-- Called once per enemy per overworld update tick.

local EnemyAI = {}

local PATROL_WAIT_MIN = 0.8
local PATROL_WAIT_MAX = 2.2

local function random_patrol_target(ex, ey, radius)
  local angle = math.random() * math.pi * 2
  local dist  = math.random() * radius
  return ex + math.cos(angle) * dist,
         ey + math.sin(angle) * dist
end

-- Collision filter for enemy movement in the overworld bump world.
local function enemy_move_filter(item, other)
  local t = other.type
  if t == "wall" or t == "npc" or t == "enemy" then return "slide" end
  return "cross"
end

-- Initialise AI bookkeeping on an enemy entity (call once after creation).
function EnemyAI.init(enemy)
  enemy.ai_state     = "patrol"
  enemy.ai_wait      = 0
  enemy.attack_timer = 0
  enemy.ai_target_x, enemy.ai_target_y =
    random_patrol_target(enemy.spawn_x, enemy.spawn_y, enemy.patrol_radius or 80)
end

-- Update AI for one frame.
-- enemy         — the Enemy entity
-- player_entity — the player entity (for aggro / targeting)
-- dt            — delta time
--
-- Returns a hitbox table { x,y,w,h, damage, lifetime } when the enemy
-- fires an attack, otherwise nil.
function EnemyAI.update(enemy, player_entity, dt)
  local ew  = enemy.w or 16
  local eh  = enemy.h or 16
  local ecx = enemy.x + ew / 2
  local ecy = enemy.y + eh / 2
  local pcx = player_entity.x + (player_entity.w or 16) / 2
  local pcy = player_entity.y + (player_entity.h or 16) / 2
  local dx  = pcx - ecx
  local dy  = pcy - ecy
  local dist = math.sqrt(dx * dx + dy * dy)

  local aggro     = enemy.aggro_range   or 100
  local atk_range = enemy.attack_range  or 32
  local speed     = enemy.speed         or 55
  local radius    = enemy.patrol_radius or 80
  local phys      = enemy:getComponent("physics")
  local facing    = enemy:getComponent("facing")

  enemy.attack_timer = enemy.attack_timer - dt

  local hitbox = nil

  -- -----------------------------------------------------------------------
  if enemy.ai_state == "patrol" then
    if dist < aggro then
      enemy.ai_state = "alert"
    else
      local tdx   = enemy.ai_target_x - ecx
      local tdy   = enemy.ai_target_y - ecy
      local tdist = math.sqrt(tdx * tdx + tdy * tdy)

      if tdist < 6 then
        -- Reached patrol target — wait then pick a new one
        enemy.ai_wait = enemy.ai_wait - dt
        if enemy.ai_wait <= 0 then
          enemy.ai_wait = PATROL_WAIT_MIN
            + math.random() * (PATROL_WAIT_MAX - PATROL_WAIT_MIN)
          enemy.ai_target_x, enemy.ai_target_y =
            random_patrol_target(enemy.spawn_x, enemy.spawn_y, radius)
        end
        facing:set(nil, false)
      else
        local nx, ny = tdx / tdist, tdy / tdist
        phys:move(nx * speed * 0.6 * dt, ny * speed * 0.6 * dt, enemy_move_filter)
        -- Update facing
        if math.abs(tdx) >= math.abs(tdy) then
          facing:set(tdx > 0 and "right" or "left", true)
        else
          facing:set(tdy > 0 and "down" or "up", true)
        end
      end
    end   -- if dist < aggro

  -- -----------------------------------------------------------------------
  elseif enemy.ai_state == "alert" then
    if dist > aggro * 1.3 then
      enemy.ai_state = "patrol"
      enemy.ai_target_x, enemy.ai_target_y =
        random_patrol_target(enemy.spawn_x, enemy.spawn_y, radius)
    elseif dist <= atk_range then
      enemy.ai_state = "attack"
    else
      local nx, ny = dx / dist, dy / dist
      phys:move(nx * speed * dt, ny * speed * dt, enemy_move_filter)
      if math.abs(dx) >= math.abs(dy) then
        facing:set(dx > 0 and "right" or "left", true)
      else
        facing:set(dy > 0 and "down" or "up", true)
      end
    end

  -- -----------------------------------------------------------------------
  elseif enemy.ai_state == "attack" then
    if dist > atk_range * 1.8 then
      enemy.ai_state = "alert"
    elseif enemy.attack_timer <= 0 then
      enemy.attack_timer = enemy.attack_cooldown or 1.8
      -- Direction toward player
      local dir_x = (dist > 0) and (dx / dist) or 0
      local dir_y = (dist > 0) and (dy / dist) or 0
      local hw, hh = 28, 28
      hitbox = {
        x       = ecx + dir_x * (ew / 2) - hw / 2,
        y       = ecy + dir_y * (eh / 2) - hh / 2,
        w       = hw,
        h       = hh,
        raw_atk = enemy.base_atk or enemy.base_damage or 10,
        lifetime = 3,
      }
      -- Turn to face player
      if math.abs(dx) >= math.abs(dy) then
        facing:forceDirection(dx >= 0 and "right" or "left")
      else
        facing:forceDirection(dy >= 0 and "down" or "up")
      end
    else
      facing:set(nil, false)
    end
  end

  return hitbox
end

return EnemyAI
