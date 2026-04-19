-- CombatHUD
-- Renders HP bars, ability cooldown icons, and status text during combat.
-- All coordinates are in screen space — call after popping the arena transform.

local CombatHUD = {}

local font     = nil
local function get_font()
  if not font then font = love.graphics.newFont(11) end
  return font
end

local BAR_W = 110
local BAR_H = 10

local function draw_hp_bar(label_x, label_y, bar_x, bar_y, hp_comp, name, label_align)
  love.graphics.setFont(get_font())

  local frac = math.max(0, hp_comp.hp / hp_comp.max_hp)
  -- bar colour: green → yellow → red
  local br, bg, bb
  if frac > 0.5 then
    br, bg, bb = 0.2, 0.75, 0.2
  elseif frac > 0.25 then
    br, bg, bb = 0.9, 0.75, 0.1
  else
    br, bg, bb = 0.85, 0.15, 0.15
  end

  -- Name label
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.printf(name, label_x, label_y, BAR_W, label_align or "left")

  -- Bar background
  love.graphics.setColor(0.18, 0.18, 0.18, 0.85)
  love.graphics.rectangle("fill", bar_x, bar_y, BAR_W, BAR_H)

  -- Bar fill
  love.graphics.setColor(br, bg, bb, 0.9)
  love.graphics.rectangle("fill", bar_x, bar_y, BAR_W * frac, BAR_H)

  -- Bar border
  love.graphics.setColor(0.55, 0.55, 0.55, 0.8)
  love.graphics.rectangle("line", bar_x, bar_y, BAR_W, BAR_H)

  -- HP numbers
  love.graphics.setColor(1, 1, 1, 0.85)
  local hp_str = hp_comp.hp .. "/" .. hp_comp.max_hp
  love.graphics.printf(hp_str, bar_x, bar_y, BAR_W, "center")
end

-- Draw the full HUD.
-- player_entity   — has health + ability components
-- companion_entity — has health component (may be nil)
-- enemies          — array of enemy entities (each has health + name)
-- ability_comp     — AbilityComponent attached to the player
function CombatHUD.draw(player_entity, companion_entity, enemies, ability_comp)
  local sw = love.graphics.getWidth()
  local sh = love.graphics.getHeight()

  love.graphics.push("all")

  -- -----------------------------------------------------------------------
  -- Background panels
  -- -----------------------------------------------------------------------
  love.graphics.setColor(0, 0, 0, 0.52)
  love.graphics.rectangle("fill",  6,  6, BAR_W + 8, 38)            -- player panel
  if companion_entity then
    love.graphics.rectangle("fill", sw - BAR_W - 14,  6, BAR_W + 8, 38)  -- companion panel
  end

  -- -----------------------------------------------------------------------
  -- Player HP (top-left)
  -- -----------------------------------------------------------------------
  local p_hp = player_entity:getComponent("health")
  draw_hp_bar(10, 9, 10, 22, p_hp, player_entity.name or "Luma", "left")

  -- -----------------------------------------------------------------------
  -- Companion HP (top-right)
  -- -----------------------------------------------------------------------
  if companion_entity then
    local c_hp = companion_entity:getComponent("health")
    local cx   = sw - BAR_W - 10
    draw_hp_bar(cx, 9, cx, 22, c_hp, companion_entity.name or "Pip", "left")
  end

  -- -----------------------------------------------------------------------
  -- Frontmost alive enemy HP (top-center)
  -- -----------------------------------------------------------------------
  local front_enemy = nil
  for _, e in ipairs(enemies) do
    if not e:getComponent("health"):isDead() then
      front_enemy = e
      break
    end
  end
  if front_enemy then
    local e_hp  = front_enemy:getComponent("health")
    local ecx   = math.floor(sw / 2 - BAR_W / 2)
    love.graphics.setColor(0, 0, 0, 0.52)
    love.graphics.rectangle("fill", ecx - 4, 6, BAR_W + 8, 38)
    draw_hp_bar(ecx, 9, ecx, 22, e_hp, front_enemy.name or "Enemy", "left")
  end

  -- -----------------------------------------------------------------------
  -- Ability icons (bottom-left)
  -- -----------------------------------------------------------------------
  if ability_comp then
    local icon_sz = 34
    local pad     = 6
    local bx      = 10
    local by      = sh - icon_sz - pad - 10

    -- Panel background
    love.graphics.setColor(0, 0, 0, 0.52)
    love.graphics.rectangle("fill",
      bx - pad, by - pad,
      (icon_sz + pad) * 2 + pad, icon_sz + pad * 2)

    for slot_i = 1, 2 do
      local ix   = bx + (slot_i - 1) * (icon_sz + pad)
      local slot = ability_comp.slots[slot_i]
      local frac = ability_comp:getCooldownFraction(slot_i)

      -- Icon base
      love.graphics.setColor(0.28, 0.28, 0.28, 0.9)
      love.graphics.rectangle("fill", ix, by, icon_sz, icon_sz)

      if slot and slot.move then
        if frac > 0 then
          -- Cooldown: dark overlay from bottom up
          love.graphics.setColor(0.08, 0.08, 0.45, 0.72)
          local overlay_h = icon_sz * frac
          love.graphics.rectangle("fill",
            ix, by + icon_sz - overlay_h,
            icon_sz, overlay_h)
          love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
        else
          love.graphics.setColor(0.85, 0.65, 0.1, 0.9)
        end

        -- Slot number
        love.graphics.setFont(get_font())
        love.graphics.print(tostring(slot_i), ix + 4, by + 4)

        -- Move name (below icon)
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.printf(slot.move.name, ix, by + icon_sz + 2, icon_sz, "center")
      end

      -- Icon border
      love.graphics.setColor(0.6, 0.6, 0.6, 0.85)
      love.graphics.rectangle("line", ix, by, icon_sz, icon_sz)
    end
  end

  love.graphics.pop()
end

return CombatHUD
