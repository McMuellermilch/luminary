-- CombatHUD
-- Full in-game overlay: active Lumin panel (bottom-left), companion panel (bottom-right),
-- enemy HP (top-center), Light Meter with Radiance Burst prompt (bottom-center).
-- Pulls party data directly from PartyManager — no party args needed.
--
-- Usage:
--   CombatHUD.draw(enemies, light_meter, charge_frac)
--     enemies     — array of enemy entities (each with :getComponent("health"), .name)
--     light_meter — 0.0–1.0 (fills on hits, drains on damage)
--     charge_frac — 0.0–1.0 (current ChargeRing charge, for HUD arc)

local PartyManager = require("src.creatures.partymanager")
local Moves        = require("src.data.moves")

local CombatHUD = {}

local font_sm = nil
local font_md = nil
local function ensure_fonts()
  if not font_sm then
    font_sm = love.graphics.newFont(10)
    font_md = love.graphics.newFont(11)
  end
end

local PANEL_W  = 180   -- active Lumin panel width
local PANEL_H  = 82    -- active Lumin panel height
local COMP_W   = 150   -- companion panel width
local COMP_H   = 48    -- companion panel height
local BAR_H    = 8
local MOVE_W   = 54    -- width of each move slot
local MOVE_H   = 20    -- height of each move slot
local PAD      = 10

local function hp_color(frac)
  if frac > 0.5 then return 0.25, 0.82, 0.25
  elseif frac > 0.25 then return 0.90, 0.75, 0.10
  else return 0.85, 0.18, 0.18
  end
end

-- Draw one named HP bar. bar_x, bar_y are left edge of the bar.
local function draw_hp_bar(bar_x, bar_y, bar_w, hp, max_hp)
  local frac = max_hp > 0 and math.max(0, hp / max_hp) or 0
  local r, g, b = hp_color(frac)
  love.graphics.setColor(0.14, 0.14, 0.14, 0.92)
  love.graphics.rectangle("fill", bar_x, bar_y, bar_w, BAR_H)
  love.graphics.setColor(r, g, b, 0.92)
  love.graphics.rectangle("fill", bar_x, bar_y, bar_w * frac, BAR_H)
  love.graphics.setColor(0.48, 0.48, 0.48, 0.72)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", bar_x, bar_y, bar_w, BAR_H)
  -- HP numbers centred on bar
  love.graphics.setFont(font_sm)
  love.graphics.setColor(1, 1, 1, 0.88)
  love.graphics.printf(hp .. "/" .. max_hp, bar_x, bar_y, bar_w, "center")
end

-- Draw a move slot box at (sx, sy). move_id may be nil.
local function draw_move_slot(sx, sy, move_id)
  love.graphics.setColor(0.14, 0.12, 0.20, 0.92)
  love.graphics.rectangle("fill", sx, sy, MOVE_W, MOVE_H, 3, 3)
  love.graphics.setColor(0.50, 0.44, 0.60, 0.70)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", sx, sy, MOVE_W, MOVE_H, 3, 3)
  if move_id then
    local def = Moves[move_id]
    local name = def and def.name or move_id
    love.graphics.setFont(font_sm)
    love.graphics.setColor(0.90, 0.85, 0.70, 0.95)
    love.graphics.printf(name, sx + 2, sy + MOVE_H / 2 - 6, MOVE_W - 4, "center")
  else
    love.graphics.setColor(0.35, 0.35, 0.35, 0.60)
    love.graphics.printf("---", sx, sy + MOVE_H / 2 - 6, MOVE_W, "center")
  end
end

-- -------------------------------------------------------------------------
-- Main draw entry point.
-- -------------------------------------------------------------------------

function CombatHUD.draw(enemies, light_meter, charge_frac)
  local sw, sh     = love.graphics.getDimensions()
  local active     = PartyManager.getActive()
  local companion  = PartyManager.getCompanion()
  light_meter  = math.max(0, math.min(1, light_meter or 0))
  charge_frac  = math.max(0, math.min(1, charge_frac or 0))

  love.graphics.push("all")
  ensure_fonts()

  -- -----------------------------------------------------------------------
  -- Active Lumin panel — bottom-left
  -- -----------------------------------------------------------------------
  if active then
    local px = PAD
    local py = sh - PANEL_H - PAD

    -- Background
    love.graphics.setColor(0.06, 0.04, 0.10, 0.88)
    love.graphics.rectangle("fill", px, py, PANEL_W, PANEL_H, 5, 5)
    love.graphics.setColor(0.55, 0.48, 0.65, 0.72)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", px, py, PANEL_W, PANEL_H, 5, 5)

    -- Name + level row
    love.graphics.setFont(font_md)
    love.graphics.setColor(1, 1, 1, 0.94)
    love.graphics.printf(active.data and active.data.name or "???", px + 8, py + 6, PANEL_W - 50, "left")
    love.graphics.setFont(font_sm)
    love.graphics.setColor(0.78, 0.78, 0.78, 0.82)
    love.graphics.printf("Lv" .. active.level, px, py + 7, PANEL_W - 8, "right")

    -- HP bar
    draw_hp_bar(px + 8, py + 22, PANEL_W - 16, active.hp, active.max_hp)

    -- Charge arc indicator (mirrors the world-space ring, for player convenience)
    if charge_frac > 0 then
      local arc_x   = px + PANEL_W - 14
      local arc_y   = py + 14
      local arc_r   = 10
      local steps   = math.max(3, math.floor(charge_frac * 24))
      local start_a = -math.pi / 2
      local end_a   = start_a + charge_frac * 2 * math.pi
      love.graphics.setColor(0.20, 0.20, 0.20, 0.60)
      love.graphics.circle("line", arc_x, arc_y, arc_r)
      local t = charge_frac
      local cr = t < 0.3 and 0.8 or (t < 0.7 and 1.0 or 1.0)
      local cg = t < 0.3 and 0.8 or (t < 0.7 and 0.75 or 1.0)
      local cb = t < 0.3 and 0.2 or (t < 0.7 and 0.0 or 0.55)
      love.graphics.setColor(cr, cg, cb, 0.90)
      local verts = { arc_x, arc_y }
      for i = 0, steps do
        local a = start_a + (end_a - start_a) * i / steps
        verts[#verts + 1] = arc_x + math.cos(a) * arc_r
        verts[#verts + 1] = arc_y + math.sin(a) * arc_r
      end
      if #verts >= 6 then love.graphics.polygon("fill", verts) end
    end

    -- Move slots (first 2 moves)
    local move1 = active.moves and active.moves[1]
    local move2 = active.moves and active.moves[2]
    draw_move_slot(px + 8,              py + PANEL_H - MOVE_H - 8, move1)
    draw_move_slot(px + 8 + MOVE_W + 6, py + PANEL_H - MOVE_H - 8, move2)
  end

  -- -----------------------------------------------------------------------
  -- Companion panel — bottom-right (smaller, no move slots)
  -- -----------------------------------------------------------------------
  if companion then
    local cx = sw - COMP_W - PAD
    local cy = sh - COMP_H - PAD

    love.graphics.setColor(0.06, 0.04, 0.10, 0.82)
    love.graphics.rectangle("fill", cx, cy, COMP_W, COMP_H, 5, 5)
    love.graphics.setColor(0.45, 0.40, 0.56, 0.65)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", cx, cy, COMP_W, COMP_H, 5, 5)

    love.graphics.setFont(font_md)
    love.graphics.setColor(1, 1, 1, 0.90)
    love.graphics.printf(companion.data and companion.data.name or "???", cx + 8, cy + 6, COMP_W - 44, "left")
    love.graphics.setFont(font_sm)
    love.graphics.setColor(0.78, 0.78, 0.78, 0.78)
    love.graphics.printf("Lv" .. companion.level, cx, cy + 7, COMP_W - 8, "right")

    draw_hp_bar(cx + 8, cy + 24, COMP_W - 16, companion.hp, companion.max_hp)
  end

  -- -----------------------------------------------------------------------
  -- Enemy HP — top-center
  -- -----------------------------------------------------------------------
  local front = nil
  local alive_count = 0
  for _, e in ipairs(enemies or {}) do
    if e.active and not e:getComponent("health"):isDead() then
      alive_count = alive_count + 1
      if not front then front = e end
    end
  end

  if front then
    local e_hp  = front:getComponent("health")
    local ew, eh = 160, 38
    local ex    = math.floor(sw / 2 - ew / 2)
    local ey    = PAD

    love.graphics.setColor(0.06, 0.04, 0.10, 0.88)
    love.graphics.rectangle("fill", ex, ey, ew, eh, 4, 4)
    love.graphics.setColor(0.45, 0.40, 0.56, 0.65)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", ex, ey, ew, eh, 4, 4)

    love.graphics.setFont(font_sm)
    love.graphics.setColor(1, 1, 1, 0.90)
    local ename = front.name or "Enemy"
    if alive_count > 1 then ename = ename .. "  (×" .. alive_count .. ")" end
    love.graphics.printf(ename, ex, ey + 4, ew, "center")

    draw_hp_bar(ex + 8, ey + 22, ew - 16, e_hp.hp, e_hp.max_hp)
  end

  -- -----------------------------------------------------------------------
  -- Light Meter — bottom-center between panels
  -- -----------------------------------------------------------------------
  local lm_w = 130
  local lm_h = 12
  local lm_x = math.floor(sw / 2 - lm_w / 2)
  local lm_y = sh - lm_h - PAD - 4

  -- Container
  love.graphics.setColor(0.06, 0.04, 0.10, 0.88)
  love.graphics.rectangle("fill", lm_x - 8, lm_y - 18, lm_w + 16, lm_h + 26, 4, 4)

  -- Label
  love.graphics.setFont(font_sm)
  love.graphics.setColor(0.85, 0.76, 0.42, 0.88)
  love.graphics.printf("LIGHT", lm_x, lm_y - 14, lm_w, "center")

  -- Bar background
  love.graphics.setColor(0.14, 0.14, 0.14, 0.92)
  love.graphics.rectangle("fill", lm_x, lm_y, lm_w, lm_h, 2, 2)

  -- Bar fill (amber glow)
  local fill = light_meter * lm_w
  if fill > 0 then
    love.graphics.setColor(0.95, 0.80, 0.22, 0.92)
    love.graphics.rectangle("fill", lm_x, lm_y, fill, lm_h, 2, 2)
  end

  love.graphics.setColor(0.62, 0.54, 0.32, 0.72)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", lm_x, lm_y, lm_w, lm_h, 2, 2)

  -- Radiance Burst prompt when full
  if light_meter >= 1.0 then
    local pulse = 0.65 + 0.35 * math.abs(math.sin(love.timer.getTime() * 4))
    love.graphics.setFont(font_sm)
    love.graphics.setColor(1.0, 0.95, 0.50, pulse)
    love.graphics.printf("▶ RADIANCE BURST  [A]", lm_x - 40, lm_y - 30, lm_w + 80, "center")
  end

  love.graphics.pop()
end

return CombatHUD
