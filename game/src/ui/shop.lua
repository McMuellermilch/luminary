-- ShopState
-- Pushed on top of OverworldState via StateManager.push.
-- The overworld remains visible behind it (StateManager draws bottom→top).
--
-- params: { shop_id = "willowfen_shop" }
--
-- Controls:
--   ← →       switch between Buy / Sell panel
--   ↑ ↓       navigate items
--   Z/confirm  buy (or sell) selected item
--   X/cancel   close shop

local Input     = require("src.core.input")
local Items     = require("src.data.items")
local Shops     = require("src.data.shops")
local Inventory = require("src.creatures.inventory")

local ShopState = {}
ShopState.__index = ShopState

local PANEL_BUY  = "buy"
local PANEL_SELL = "sell"

-- Lazily initialised fonts
local font_lg, font_sm
local function get_fonts()
  if not font_lg then
    font_lg = love.graphics.newFont(16)
    font_sm = love.graphics.newFont(12)
  end
  return font_lg, font_sm
end

-- Colour palette
local CLR = {
  overlay   = {0.04, 0.05, 0.12, 0.90},
  panel     = {0.10, 0.11, 0.22, 1.00},
  sel_row   = {0.95, 0.80, 0.20, 0.22},
  title     = {1.00, 0.85, 0.40, 1.00},
  active_hd = {1.00, 0.85, 0.40, 1.00},
  idle_hd   = {0.50, 0.50, 0.60, 1.00},
  text      = {0.92, 0.92, 0.92, 1.00},
  dim       = {0.50, 0.50, 0.55, 1.00},
  gold      = {1.00, 0.82, 0.10, 1.00},
  cant      = {0.60, 0.30, 0.30, 1.00},
  ok_msg    = {0.60, 1.00, 0.55, 1.00},
  err_msg   = {1.00, 0.35, 0.35, 1.00},
}
local function clr(c) love.graphics.setColor(c) end

-- -------------------------------------------------------------------------
function ShopState:enter(params)
  params       = params or {}
  local shop_id = params.shop_id or "willowfen_shop"
  self.stock   = Shops[shop_id]
  assert(self.stock, "ShopState: unknown shop_id '" .. shop_id .. "'")

  self.panel    = PANEL_BUY
  self.buy_idx  = 1
  self.sell_idx = 1
  self.message  = nil
  self.msg_ok   = true
  self.msg_t    = 0
end

function ShopState:exit() end

-- -------------------------------------------------------------------------
function ShopState:_sellList()
  local result = {}
  for _, entry in ipairs(Inventory.all()) do
    if entry.def.type ~= "key" then
      result[#result + 1] = entry
    end
  end
  return result
end

function ShopState:_sellPrice(item_id)
  for _, s in ipairs(self.stock) do
    if s.item == item_id then
      return math.max(1, math.floor(s.price / 2))
    end
  end
  return 10   -- base sell price for items not in shop stock
end

function ShopState:_msg(text, ok)
  self.message = text
  self.msg_ok  = ok
  self.msg_t   = 2.2
end

-- -------------------------------------------------------------------------
function ShopState:update(dt)
  if self.msg_t > 0 then
    self.msg_t = self.msg_t - dt
    if self.msg_t <= 0 then self.message = nil end
  end

  -- Switch panels
  if Input.wasPressed("move_left") then
    self.panel = PANEL_BUY
  elseif Input.wasPressed("move_right") then
    self.panel = PANEL_SELL
  end

  local sell_list = self:_sellList()

  -- Navigate
  if self.panel == PANEL_BUY then
    if Input.wasPressed("move_up") then
      self.buy_idx = math.max(1, self.buy_idx - 1)
    elseif Input.wasPressed("move_down") then
      self.buy_idx = math.min(#self.stock, self.buy_idx + 1)
    end
  else
    local max_idx = math.max(1, #sell_list)
    if Input.wasPressed("move_up") then
      self.sell_idx = math.max(1, self.sell_idx - 1)
    elseif Input.wasPressed("move_down") then
      self.sell_idx = math.min(max_idx, self.sell_idx + 1)
    end
  end

  -- Confirm
  if Input.wasPressed("confirm") then
    if self.panel == PANEL_BUY then
      self:_buy()
    else
      self:_sell(sell_list)
    end
  end

  -- Close
  if Input.wasPressed("cancel") then
    local StateManager = require("src.states.statemanager")
    StateManager.pop()
  end
end

function ShopState:_buy()
  local entry = self.stock[self.buy_idx]
  if not entry then return end
  local def = Items[entry.item]
  if not def then return end
  if Inventory.lumens < entry.price then
    self:_msg("Not enough Lumens! (need " .. entry.price .. " L)", false)
    return
  end
  Inventory.lumens = Inventory.lumens - entry.price
  Inventory.add(entry.item, 1)
  self:_msg("Bought " .. def.name .. "!", true)
end

function ShopState:_sell(sell_list)
  if #sell_list == 0 then return end
  local entry = sell_list[self.sell_idx]
  if not entry then return end
  local price = self:_sellPrice(entry.id)
  Inventory.remove(entry.id, 1)
  Inventory.lumens = Inventory.lumens + price
  -- Clamp cursor after removal
  local new_list = self:_sellList()
  self.sell_idx = math.min(self.sell_idx, math.max(1, #new_list))
  self:_msg("Sold " .. entry.def.name .. " for " .. price .. " L", true)
end

-- -------------------------------------------------------------------------
function ShopState:draw()
  -- Overworld renders below us (StateManager draws bottom→top).
  local fl, fs = get_fonts()
  local W, H   = 1280, 720
  local ITEM_H = 54

  -- Semi-transparent full-screen overlay
  clr(CLR.overlay)
  love.graphics.rectangle("fill", 0, 0, W, H)

  -- Title
  clr(CLR.title)
  love.graphics.setFont(fl)
  love.graphics.printf("~ Shop ~", 0, 20, W, "center")

  -- Lumens balance (top-left)
  clr(CLR.gold)
  love.graphics.print(string.format("Lumens: %d L", Inventory.lumens), 40, 20)

  -- Panels
  local sell_list = self:_sellList()
  local PANEL_Y, PANEL_H = 70, 570
  self:_drawBuyPanel (40,  PANEL_Y, 580, PANEL_H, ITEM_H, fl, fs)
  self:_drawSellPanel(660, PANEL_Y, 580, PANEL_H, ITEM_H, fl, fs, sell_list)

  -- Message
  if self.message then
    clr(self.msg_ok and CLR.ok_msg or CLR.err_msg)
    love.graphics.setFont(fl)
    love.graphics.printf(self.message, 0, H - 70, W, "center")
  end

  -- Controls hint
  clr(CLR.dim)
  love.graphics.setFont(fs)
  love.graphics.printf("← Buy   → Sell   ↑↓ Navigate   Z Confirm   X Close", 0, H - 30, W, "center")

  love.graphics.setColor(1, 1, 1, 1)
end

function ShopState:_drawBuyPanel(px, py, pw, ph, item_h, fl, fs)
  local active = self.panel == PANEL_BUY

  clr(CLR.panel)
  love.graphics.rectangle("fill", px, py, pw, ph, 6, 6)

  clr(active and CLR.active_hd or CLR.idle_hd)
  love.graphics.setFont(fl)
  love.graphics.print("Buy", px + 16, py + 10)

  local row_y = py + 46
  for i, entry in ipairs(self.stock) do
    local def = Items[entry.item]
    if def then
      local iy      = row_y + (i - 1) * item_h
      local afford  = Inventory.lumens >= entry.price

      if active and i == self.buy_idx then
        clr(CLR.sel_row)
        love.graphics.rectangle("fill", px + 6, iy - 2, pw - 12, item_h - 2, 4, 4)
      end

      clr(afford and CLR.text or CLR.cant)
      love.graphics.setFont(fl)
      love.graphics.print(def.name, px + 18, iy + 4)

      clr(afford and CLR.gold or CLR.cant)
      love.graphics.setFont(fl)
      love.graphics.print(tostring(entry.price) .. " L", px + pw - 90, iy + 4)

      if def.description then
        clr(CLR.dim)
        love.graphics.setFont(fs)
        love.graphics.printf(def.description, px + 18, iy + 28, pw - 36)
      end
    end
  end
end

function ShopState:_drawSellPanel(px, py, pw, ph, item_h, fl, fs, sell_list)
  local active = self.panel == PANEL_SELL

  clr(CLR.panel)
  love.graphics.rectangle("fill", px, py, pw, ph, 6, 6)

  clr(active and CLR.active_hd or CLR.idle_hd)
  love.graphics.setFont(fl)
  love.graphics.print("Sell", px + 16, py + 10)

  if #sell_list == 0 then
    clr(CLR.dim)
    love.graphics.setFont(fs)
    love.graphics.print("(nothing to sell)", px + 18, py + 56)
    return
  end

  local row_y = py + 46
  for i, entry in ipairs(sell_list) do
    local iy    = row_y + (i - 1) * item_h
    local price = self:_sellPrice(entry.id)

    if active and i == self.sell_idx then
      clr(CLR.sel_row)
      love.graphics.rectangle("fill", px + 6, iy - 2, pw - 12, item_h - 2, 4, 4)
    end

    clr(CLR.text)
    love.graphics.setFont(fl)
    love.graphics.print(entry.def.name, px + 18, iy + 4)

    clr(CLR.dim)
    love.graphics.setFont(fs)
    love.graphics.print("x" .. entry.count, px + 18, iy + 28)

    clr(CLR.gold)
    love.graphics.setFont(fl)
    love.graphics.print(tostring(price) .. " L", px + pw - 90, iy + 4)
  end
end

function ShopState:keypressed(key) end

return ShopState
