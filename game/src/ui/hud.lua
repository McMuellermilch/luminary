-- HUD
-- Minimal always-visible overworld overlay.
-- Party strip in the top-right corner: one slot per party Lumin,
-- each showing a portrait placeholder, HP bar, and bonded glow.
-- Call HUD.draw() from overworld draw (screen space, after camera detach).

local PartyManager = require("src.creatures.partymanager")

local HUD = {}

local ICON_W   = 28
local ICON_H   = 28
local BAR_H    = 5
local ENTRY_W  = ICON_W
local ENTRY_H  = ICON_H + BAR_H + 3
local GAP      = 6
local PAD      = 8

local font_tiny = nil
local function get_font()
  if not font_tiny then font_tiny = love.graphics.newFont(9) end
  return font_tiny
end

local function hp_color(frac)
  if frac > 0.5 then return 0.25, 0.82, 0.25
  elseif frac > 0.25 then return 0.90, 0.75, 0.10
  else return 0.85, 0.18, 0.18
  end
end

function HUD.draw()
  local party = PartyManager.party
  if #party == 0 then return end

  local sw = love.graphics.getWidth()
  local n  = #party

  local panel_w = n * (ENTRY_W + GAP) - GAP + PAD * 2
  local panel_h = ENTRY_H + PAD * 2
  local px = sw - panel_w - 8
  local py = 8

  love.graphics.push("all")

  -- Panel background
  love.graphics.setColor(0.05, 0.04, 0.10, 0.82)
  love.graphics.rectangle("fill", px, py, panel_w, panel_h, 4, 4)
  love.graphics.setColor(0.45, 0.40, 0.56, 0.55)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", px, py, panel_w, panel_h, 4, 4)

  local f = get_font()
  love.graphics.setFont(f)

  for i, lumin in ipairs(party) do
    local ex = px + PAD + (i - 1) * (ENTRY_W + GAP)
    local ey = py + PAD

    -- Portrait box
    local bonded = lumin.bonded
    love.graphics.setColor(
      bonded and 0.30 or 0.18,
      bonded and 0.22 or 0.14,
      bonded and 0.42 or 0.26, 1)
    love.graphics.rectangle("fill", ex, ey, ICON_W, ICON_H, 3, 3)

    -- Border (gold glow if bonded)
    if bonded then
      love.graphics.setColor(0.85, 0.75, 0.40, 0.75)
    else
      love.graphics.setColor(0.38, 0.34, 0.48, 0.55)
    end
    love.graphics.rectangle("line", ex, ey, ICON_W, ICON_H, 3, 3)

    -- Species initial as portrait placeholder
    local initial = (lumin.data and lumin.data.name or "?"):sub(1, 1)
    love.graphics.setColor(0.88, 0.84, 0.76, 0.90)
    love.graphics.printf(initial, ex, ey + ICON_H / 2 - 5, ICON_W, "center")

    -- HP bar
    local bar_y = ey + ICON_H + 3
    local frac  = lumin.max_hp > 0 and math.max(0, lumin.hp / lumin.max_hp) or 0
    local r, g, b = hp_color(frac)

    love.graphics.setColor(0.12, 0.12, 0.12, 0.92)
    love.graphics.rectangle("fill", ex, bar_y, ENTRY_W, BAR_H, 1, 1)
    love.graphics.setColor(r, g, b, 0.92)
    love.graphics.rectangle("fill", ex, bar_y, ENTRY_W * frac, BAR_H, 1, 1)
  end

  love.graphics.pop()
end

return HUD
