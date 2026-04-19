-- PauseMenu state
-- Pushed on top of OverworldState. Overworld remains visible, dimmed.
-- Tabs: Party | Bag | Journal | Settings
-- Navigation:
--   move_left / move_right — switch tabs
--   move_up / move_down    — navigate list items
--   confirm                — select / enter sub-screen
--   cancel                 — go back one level / close menu

local Input        = require("src.core.input")
local SFX          = require("src.audio.sfx")
local PartyManager = require("src.creatures.partymanager")
local Inventory    = require("src.creatures.inventory")
local Items        = require("src.data.items")
local ItemUse      = require("src.creatures.itemuse")
local Settings     = require("src.core.settings")
local MusicManager = require("src.audio.musicmanager")
local Lumin        = require("src.creatures.lumin")

local PauseMenu = {}
PauseMenu.__index = PauseMenu

-- Tab indices
local TAB_PARTY    = 1
local TAB_BAG      = 2
local TAB_JOURNAL  = 3
local TAB_SETTINGS = 4
local TAB_NAMES    = { "Party", "Bag", "Journal", "Settings" }

-- Panel geometry (recomputed each draw from screen dimensions)
local PANEL_MARGIN = 60
local TAB_H        = 34

-- Colours
local COL_BG      = {0.06, 0.04, 0.10, 0.97}
local COL_BORDER  = {0.55, 0.48, 0.65, 0.75}
local COL_SELECT  = {1.00, 0.90, 0.50, 1.00}
local COL_DIM     = {0.60, 0.60, 0.60, 0.80}
local COL_HINT    = {0.88, 0.88, 0.88, 0.50}
local COL_TEXT    = {0.95, 0.92, 0.88, 1.00}

local function hp_color(frac)
  if frac > 0.5 then return 0.25, 0.82, 0.25
  elseif frac > 0.25 then return 0.90, 0.75, 0.10
  else return 0.85, 0.18, 0.18
  end
end

-- -------------------------------------------------------------------------
function PauseMenu:enter()
  self._tab             = TAB_PARTY
  self._cursor          = 1
  -- sub-screens:
  --   "tabs"           — main tab content
  --   "party_action"   — action picker for a selected Lumin
  --   "party_swap"     — pick a swap target
  --   "bag_target"     — pick a Lumin target for an item
  --   "confirm_quit"   — quit to main menu confirmation
  --   "slider"         — settings slider being edited
  self._screen          = "tabs"
  self._selected_slot   = nil   -- party slot index chosen in party_action
  self._selected_item   = nil   -- item_id chosen in bag
  self._quit_cursor     = 2     -- 1=Yes, 2=No (default No)
  self._feedback        = nil   -- { msg, timer } brief status message
  self._fonts           = nil
end

function PauseMenu:exit() end

-- -------------------------------------------------------------------------
-- Helpers
-- -------------------------------------------------------------------------

function PauseMenu:_ensureFonts()
  if not self._fonts then
    self._fonts = {
      title  = love.graphics.newFont(20),
      normal = love.graphics.newFont(15),
      small  = love.graphics.newFont(12),
      tiny   = love.graphics.newFont(10),
    }
  end
  return self._fonts
end

local function format_playtime(secs)
  local h = math.floor(secs / 3600)
  local m = math.floor((secs % 3600) / 60)
  if h > 0 then return string.format("%dh %02dm", h, m)
  else           return string.format("%dm", m) end
end

-- Returns a flat list of inventory items that match a type filter (nil = all).
local function inventory_list(type_filter)
  local result = {}
  for _, entry in ipairs(Inventory.all()) do
    if not type_filter or entry.def.type == type_filter then
      result[#result + 1] = entry
    end
  end
  return result
end

-- Returns list of all inventory items grouped: heal, capture, key
local function bag_items()
  local list = {}
  local types = { "heal", "heal_full", "capture", "key" }
  local seen  = {}
  for _, t in ipairs(types) do
    for _, entry in ipairs(Inventory.all()) do
      if entry.def.type == t and not seen[entry.id] then
        seen[entry.id] = true
        list[#list + 1] = entry
      end
    end
  end
  return list
end

function PauseMenu:_setFeedback(msg)
  self._feedback = { msg = msg, timer = 1.8 }
end

-- -------------------------------------------------------------------------
-- Update
-- -------------------------------------------------------------------------

function PauseMenu:update(dt)
  if self._feedback then
    self._feedback.timer = self._feedback.timer - dt
    if self._feedback.timer <= 0 then self._feedback = nil end
  end

  if self._screen == "tabs" then
    self:_updateTabs()
  elseif self._screen == "party_action" then
    self:_updatePartyAction()
  elseif self._screen == "party_swap" then
    self:_updatePartySwap()
  elseif self._screen == "bag_target" then
    self:_updateBagTarget()
  elseif self._screen == "confirm_quit" then
    self:_updateConfirmQuit()
  end
end

function PauseMenu:_updateTabs()
  -- Tab navigation
  if Input.wasPressed("move_left") then
    self._tab    = self._tab > 1 and self._tab - 1 or #TAB_NAMES
    self._cursor = 1
    SFX.play("menu_select")
    return
  elseif Input.wasPressed("move_right") then
    self._tab    = self._tab < #TAB_NAMES and self._tab + 1 or 1
    self._cursor = 1
    SFX.play("menu_select")
    return
  end

  -- Close
  if Input.wasPressed("cancel") then
    local SM = require("src.states.statemanager")
    SM.pop()
    return
  end

  -- Tab-specific navigation
  if self._tab == TAB_PARTY then
    self:_navParty()
  elseif self._tab == TAB_BAG then
    self:_navBag()
  elseif self._tab == TAB_SETTINGS then
    self:_navSettings()
  end
  -- Journal has no interactive items
end

-- Party tab navigation
function PauseMenu:_navParty()
  local party = PartyManager.party
  if #party == 0 then return end

  if Input.wasPressed("move_up") then
    self._cursor = self._cursor > 1 and self._cursor - 1 or #party
    SFX.play("menu_select")
  elseif Input.wasPressed("move_down") then
    self._cursor = self._cursor < #party and self._cursor + 1 or 1
    SFX.play("menu_select")
  elseif Input.wasPressed("confirm") then
    if party[self._cursor] then
      SFX.play("menu_select")
      self._selected_slot = self._cursor
      self._screen        = "party_action"
      self._cursor        = 1
    end
  end
end

-- Bag tab navigation
function PauseMenu:_navBag()
  local items = bag_items()
  if #items == 0 then return end

  if Input.wasPressed("move_up") then
    self._cursor = self._cursor > 1 and self._cursor - 1 or #items
    SFX.play("menu_select")
  elseif Input.wasPressed("move_down") then
    self._cursor = self._cursor < #items and self._cursor + 1 or 1
    SFX.play("menu_select")
  elseif Input.wasPressed("confirm") then
    local entry = items[self._cursor]
    if entry then
      local def = entry.def
      if def.type == "heal" or def.type == "heal_full" then
        SFX.play("menu_select")
        self._selected_item = entry.id
        self._screen        = "bag_target"
        self._cursor        = 1
      else
        self:_setFeedback("Cannot use this here.")
      end
    end
  end
end

-- Settings tab navigation
local SETTINGS_ITEMS = { "Music Volume", "SFX Volume", "Return to Main Menu" }

function PauseMenu:_navSettings()
  if Input.wasPressed("move_up") then
    self._cursor = self._cursor > 1 and self._cursor - 1 or #SETTINGS_ITEMS
    SFX.play("menu_select")
  elseif Input.wasPressed("move_down") then
    self._cursor = self._cursor < #SETTINGS_ITEMS and self._cursor + 1 or 1
    SFX.play("menu_select")
  elseif self._cursor == 1 then
    -- Music volume slider
    if Input.wasPressed("move_left") or Input.wasPressed("move_right") then
      local delta = Input.wasPressed("move_left") and -0.05 or 0.05
      Settings.music_volume = math.max(0, math.min(1, Settings.music_volume + delta))
      MusicManager.update(0)  -- immediate effect via next tween frame
      SFX.play("menu_select")
    end
  elseif self._cursor == 2 then
    -- SFX volume slider
    if Input.wasPressed("move_left") or Input.wasPressed("move_right") then
      local delta = Input.wasPressed("move_left") and -0.05 or 0.05
      Settings.sfx_volume = math.max(0, math.min(1, Settings.sfx_volume + delta))
      SFX.play("menu_select")
    end
  elseif self._cursor == 3 then
    -- Return to main menu
    if Input.wasPressed("confirm") then
      SFX.play("menu_select")
      self._screen       = "confirm_quit"
      self._quit_cursor  = 2  -- default: No
    end
  end
end

-- Party action sub-screen
local PARTY_ACTIONS = { "Summary", "Switch Position", "Give Item" }

function PauseMenu:_updatePartyAction()
  if Input.wasPressed("move_up") then
    self._cursor = self._cursor > 1 and self._cursor - 1 or #PARTY_ACTIONS
    SFX.play("menu_select")
  elseif Input.wasPressed("move_down") then
    self._cursor = self._cursor < #PARTY_ACTIONS and self._cursor + 1 or 1
    SFX.play("menu_select")
  elseif Input.wasPressed("confirm") then
    SFX.play("menu_select")
    if self._cursor == 1 then
      -- Summary: return to tabs (summary is shown in the same screen for MVP)
      self._screen = "tabs"
      self._cursor = self._selected_slot
      self._tab    = TAB_PARTY
    elseif self._cursor == 2 then
      -- Switch Position
      self._screen = "party_swap"
      self._cursor = 1
    elseif self._cursor == 3 then
      -- Give Item: go to bag_target sub-flow from party context
      self._screen = "bag_target"
      self._cursor = 1
      self._selected_item = nil  -- will pick item first (handled differently)
      -- For simplicity: treat Give Item as picking from bag first
      self._screen = "tabs"
      self._tab    = TAB_BAG
      self._cursor = 1
      self:_setFeedback("Select an item from the Bag to use.")
    end
  elseif Input.wasPressed("cancel") then
    SFX.play("menu_select")
    self._screen = "tabs"
    self._cursor = self._selected_slot
    self._tab    = TAB_PARTY
  end
end

-- Party swap sub-screen
function PauseMenu:_updatePartySwap()
  local party = PartyManager.party
  if Input.wasPressed("move_up") then
    self._cursor = self._cursor > 1 and self._cursor - 1 or #party
    SFX.play("menu_select")
  elseif Input.wasPressed("move_down") then
    self._cursor = self._cursor < #party and self._cursor + 1 or 1
    SFX.play("menu_select")
  elseif Input.wasPressed("confirm") then
    local target = self._cursor
    if target ~= self._selected_slot and party[target] then
      PartyManager.swap(self._selected_slot, target)
      SFX.play("menu_select")
      self:_setFeedback("Party order updated.")
    end
    self._screen = "tabs"
    self._cursor = self._selected_slot
    self._tab    = TAB_PARTY
  elseif Input.wasPressed("cancel") then
    SFX.play("menu_select")
    self._screen = "party_action"
    self._cursor = 2
  end
end

-- Bag target sub-screen: pick a Lumin to use the selected item on
function PauseMenu:_updateBagTarget()
  local party = PartyManager.party
  if #party == 0 or not self._selected_item then
    self._screen = "tabs"
    return
  end

  if Input.wasPressed("move_up") then
    self._cursor = self._cursor > 1 and self._cursor - 1 or #party
    SFX.play("menu_select")
  elseif Input.wasPressed("move_down") then
    self._cursor = self._cursor < #party and self._cursor + 1 or 1
    SFX.play("menu_select")
  elseif Input.wasPressed("confirm") then
    local target = party[self._cursor]
    if target then
      local ok, reason = ItemUse.use(self._selected_item, target)
      if ok then
        SFX.play("menu_select")
        local def = Items[self._selected_item]
        self:_setFeedback((def and def.name or self._selected_item) .. " used!")
      else
        self:_setFeedback(reason or "Cannot use.")
      end
    end
    self._selected_item = nil
    self._screen = "tabs"
    self._cursor = 1
    self._tab    = TAB_BAG
  elseif Input.wasPressed("cancel") then
    SFX.play("menu_select")
    self._selected_item = nil
    self._screen = "tabs"
    self._cursor = 1
    self._tab    = TAB_BAG
  end
end

-- Confirm quit sub-screen
function PauseMenu:_updateConfirmQuit()
  if Input.wasPressed("move_left") or Input.wasPressed("move_right") then
    self._quit_cursor = self._quit_cursor == 1 and 2 or 1
    SFX.play("menu_select")
  elseif Input.wasPressed("confirm") then
    if self._quit_cursor == 1 then
      -- Yes — pop PauseMenu then Overworld, push MainMenu
      local SM      = require("src.states.statemanager")
      local MainMenu = require("src.states.mainmenu")
      SM.pop()                          -- pop PauseMenu
      if SM.peek() then SM.pop() end    -- pop Overworld
      SM.push(MainMenu)
    else
      -- No — back to settings
      SFX.play("menu_select")
      self._screen = "tabs"
      self._tab    = TAB_SETTINGS
      self._cursor = 3
    end
  elseif Input.wasPressed("cancel") then
    SFX.play("menu_select")
    self._screen = "tabs"
    self._tab    = TAB_SETTINGS
    self._cursor = 3
  end
end

-- -------------------------------------------------------------------------
-- Draw
-- -------------------------------------------------------------------------

function PauseMenu:draw()
  local sw, sh = love.graphics.getDimensions()
  local f      = self:_ensureFonts()

  -- Dim overlay over everything beneath
  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.rectangle("fill", 0, 0, sw, sh)

  -- Main panel
  local px = PANEL_MARGIN
  local py = PANEL_MARGIN
  local pw = sw - PANEL_MARGIN * 2
  local ph = sh - PANEL_MARGIN * 2

  love.graphics.setColor(COL_BG)
  love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)
  love.graphics.setColor(COL_BORDER)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", px, py, pw, ph, 8, 8)
  love.graphics.setLineWidth(1)

  -- Tab bar
  self:_drawTabBar(px, py, pw, f)

  -- Content area
  local content_y = py + TAB_H + 12
  local content_h = ph - TAB_H - 24

  if self._screen == "tabs" then
    if self._tab == TAB_PARTY then
      self:_drawParty(px + 16, content_y, pw - 32, content_h, f)
    elseif self._tab == TAB_BAG then
      self:_drawBag(px + 16, content_y, pw - 32, content_h, f)
    elseif self._tab == TAB_JOURNAL then
      self:_drawJournal(px + 16, content_y, pw - 32, content_h, f)
    elseif self._tab == TAB_SETTINGS then
      self:_drawSettings(px + 16, content_y, pw - 32, content_h, f)
    end
  elseif self._screen == "party_action" then
    self:_drawPartyAction(px + 16, content_y, pw - 32, content_h, f)
  elseif self._screen == "party_swap" then
    self:_drawPartySwap(px + 16, content_y, pw - 32, content_h, f)
  elseif self._screen == "bag_target" then
    self:_drawBagTarget(px + 16, content_y, pw - 32, content_h, f)
  elseif self._screen == "confirm_quit" then
    self:_drawSettings(px + 16, content_y, pw - 32, content_h, f)
    self:_drawConfirmQuit(sw, sh, f)
  end

  -- Feedback message
  if self._feedback then
    local msg_w = 340
    local mx    = math.floor(sw / 2 - msg_w / 2)
    local my    = sh - PANEL_MARGIN - 40
    love.graphics.setColor(0.12, 0.10, 0.18, 0.94)
    love.graphics.rectangle("fill", mx, my, msg_w, 28, 4, 4)
    love.graphics.setColor(COL_SELECT)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", mx, my, msg_w, 28, 4, 4)
    love.graphics.setFont(f.small)
    love.graphics.setColor(COL_TEXT)
    love.graphics.printf(self._feedback.msg, mx, my + 7, msg_w, "center")
  end

  -- Navigation hint
  love.graphics.setFont(f.tiny)
  love.graphics.setColor(COL_HINT)
  love.graphics.printf("◄ ► switch tab   ▲ ▼ navigate   Z confirm   X back", px, py + ph - 18, pw, "center")

  love.graphics.setColor(1, 1, 1, 1)
end

function PauseMenu:_drawTabBar(px, py, pw, f)
  local tab_w = math.floor(pw / #TAB_NAMES)
  love.graphics.setFont(f.normal)

  for i, name in ipairs(TAB_NAMES) do
    local tx = px + (i - 1) * tab_w
    local ty = py + 4

    if i == self._tab then
      love.graphics.setColor(0.20, 0.16, 0.30, 1)
      love.graphics.rectangle("fill", tx + 2, ty, tab_w - 4, TAB_H - 4, 4, 4)
      love.graphics.setColor(COL_SELECT)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", tx + 2, ty, tab_w - 4, TAB_H - 4, 4, 4)
      love.graphics.setLineWidth(1)
      love.graphics.setColor(COL_SELECT)
    else
      love.graphics.setColor(COL_DIM)
    end

    love.graphics.printf(name, tx, ty + 6, tab_w, "center")
  end

  -- Separator line
  love.graphics.setColor(COL_BORDER)
  love.graphics.setLineWidth(1)
  love.graphics.line(px + 8, py + TAB_H + 4, px + pw - 8, py + TAB_H + 4)
end

-- -------------------------------------------------------------------------
-- Party tab
-- -------------------------------------------------------------------------

function PauseMenu:_drawParty(cx, cy, cw, ch, f)
  local party  = PartyManager.party
  local slot_h = 90
  local gap    = 10

  if #party == 0 then
    love.graphics.setFont(f.normal)
    love.graphics.setColor(COL_DIM)
    love.graphics.printf("No Lumins in party.", cx, cy + 40, cw, "center")
    return
  end

  for i, lumin in ipairs(party) do
    local by  = cy + (i - 1) * (slot_h + gap)
    local sel = (i == self._cursor)

    -- Slot background
    love.graphics.setColor(sel and 0.18 or 0.10,
                           sel and 0.14 or 0.07,
                           sel and 0.26 or 0.15,
                           sel and 0.95 or 0.80)
    love.graphics.rectangle("fill", cx, by, cw, slot_h, 5, 5)
    love.graphics.setColor(sel and COL_SELECT or COL_BORDER)
    love.graphics.setLineWidth(sel and 2 or 1)
    love.graphics.rectangle("line", cx, by, cw, slot_h, 5, 5)
    love.graphics.setLineWidth(1)

    -- Cursor arrow
    if sel then
      love.graphics.setFont(f.normal)
      love.graphics.setColor(COL_SELECT)
      love.graphics.print("►", cx + 6, by + slot_h / 2 - 8)
    end

    -- Portrait box placeholder
    love.graphics.setColor(0.22, 0.17, 0.32, 1)
    love.graphics.rectangle("fill", cx + 24, by + 8, 60, 60, 4, 4)
    love.graphics.setColor(lumin.bonded and COL_SELECT or COL_BORDER)
    love.graphics.rectangle("line", cx + 24, by + 8, 60, 60, 4, 4)
    love.graphics.setFont(f.title)
    love.graphics.setColor(COL_TEXT)
    local initial = (lumin.data and lumin.data.name or "?"):sub(1, 1)
    love.graphics.printf(initial, cx + 24, by + 22, 60, "center")

    -- Info
    local info_x = cx + 96
    love.graphics.setFont(f.normal)
    love.graphics.setColor(sel and COL_TEXT or COL_DIM)
    love.graphics.print(Lumin.displayName(lumin), info_x, by + 8)
    love.graphics.setFont(f.small)
    love.graphics.setColor(COL_DIM)
    love.graphics.print("Lv " .. lumin.level, info_x, by + 28)
    if lumin.data and lumin.data.type then
      love.graphics.print(lumin.data.type, info_x + 50, by + 28)
    end

    -- HP bar
    local bar_x = info_x
    local bar_y = by + 46
    local bar_w = cw - info_x + cx - 16
    local frac  = lumin.max_hp > 0 and math.max(0, lumin.hp / lumin.max_hp) or 0
    local r, g, b = hp_color(frac)
    love.graphics.setColor(0.14, 0.14, 0.14, 0.90)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w, 9)
    love.graphics.setColor(r, g, b, 0.90)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w * frac, 9)
    love.graphics.setColor(COL_HINT)
    love.graphics.setFont(f.tiny)
    love.graphics.printf("HP  " .. lumin.hp .. "/" .. lumin.max_hp, bar_x, bar_y, bar_w, "center")

    -- EXP bar
    local exp_frac = lumin.exp_to_next > 0 and (lumin.exp / lumin.exp_to_next) or 0
    love.graphics.setColor(0.14, 0.14, 0.14, 0.90)
    love.graphics.rectangle("fill", bar_x, bar_y + 14, bar_w, 6)
    love.graphics.setColor(0.30, 0.55, 0.90, 0.88)
    love.graphics.rectangle("fill", bar_x, bar_y + 14, bar_w * exp_frac, 6)
    love.graphics.setColor(COL_HINT)
    love.graphics.printf("EXP  " .. lumin.exp .. "/" .. lumin.exp_to_next, bar_x, bar_y + 18, bar_w, "right")

    -- Moves
    local moves_x = info_x + math.floor(bar_w * 0.55)
    if lumin.moves and #lumin.moves > 0 then
      love.graphics.setFont(f.tiny)
      love.graphics.setColor(COL_DIM)
      for mi, mid in ipairs(lumin.moves) do
        if mi <= 4 then
          love.graphics.print("• " .. mid, moves_x + ((mi - 1) % 2) * 80,
            by + 8 + math.floor((mi - 1) / 2) * 14)
        end
      end
    end
  end
end

-- -------------------------------------------------------------------------
-- Party action sub-screen
-- -------------------------------------------------------------------------

function PauseMenu:_drawPartyAction(cx, cy, cw, ch, f)
  local party = PartyManager.party
  local lumin = party[self._selected_slot]
  if not lumin then return end

  -- Lumin info header
  love.graphics.setFont(f.title)
  love.graphics.setColor(COL_SELECT)
  love.graphics.print(Lumin.displayName(lumin) .. "  Lv" .. lumin.level, cx, cy)

  love.graphics.setFont(f.small)
  love.graphics.setColor(COL_DIM)
  love.graphics.print("HP " .. lumin.hp .. "/" .. lumin.max_hp, cx, cy + 28)

  -- Action list
  love.graphics.setFont(f.normal)
  for i, action in ipairs(PARTY_ACTIONS) do
    local ay = cy + 60 + (i - 1) * 36
    if i == self._cursor then
      love.graphics.setColor(COL_SELECT)
      love.graphics.print("► " .. action, cx + 10, ay)
    else
      love.graphics.setColor(COL_DIM)
      love.graphics.print("  " .. action, cx + 10, ay)
    end
  end
end

-- -------------------------------------------------------------------------
-- Party swap sub-screen
-- -------------------------------------------------------------------------

function PauseMenu:_drawPartySwap(cx, cy, cw, ch, f)
  love.graphics.setFont(f.normal)
  love.graphics.setColor(COL_TEXT)
  love.graphics.print("Choose a party slot to swap with:", cx, cy)

  local party = PartyManager.party
  love.graphics.setFont(f.normal)
  for i, lumin in ipairs(party) do
    local ay  = cy + 40 + (i - 1) * 40
    local sel = (i == self._cursor)

    love.graphics.setColor(sel and COL_SELECT or COL_DIM)
    local prefix = ""
    if i == self._selected_slot then prefix = "★ "
    elseif sel then prefix = "► "
    else prefix = "  " end

    love.graphics.print(prefix .. "Slot " .. i .. ":  " ..
      Lumin.displayName(lumin) .. "  Lv" .. lumin.level, cx + 10, ay)
  end
end

-- -------------------------------------------------------------------------
-- Bag tab
-- -------------------------------------------------------------------------

function PauseMenu:_drawBag(cx, cy, cw, ch, f)
  local items = bag_items()

  -- Lumens display
  love.graphics.setFont(f.small)
  love.graphics.setColor(COL_SELECT)
  love.graphics.printf("Lumens: " .. Inventory.lumens, cx, cy + ch - 20, cw, "right")

  if #items == 0 then
    love.graphics.setFont(f.normal)
    love.graphics.setColor(COL_DIM)
    love.graphics.printf("Bag is empty.", cx, cy + 40, cw, "center")
    return
  end

  local row_h = 44
  love.graphics.setFont(f.normal)

  for i, entry in ipairs(items) do
    local by  = cy + (i - 1) * row_h
    local sel = (i == self._cursor)

    love.graphics.setColor(sel and 0.16 or 0.08,
                           sel and 0.12 or 0.06,
                           sel and 0.24 or 0.12,
                           0.88)
    love.graphics.rectangle("fill", cx, by, cw, row_h - 4, 4, 4)
    love.graphics.setColor(sel and COL_SELECT or COL_BORDER)
    love.graphics.setLineWidth(sel and 2 or 1)
    love.graphics.rectangle("line", cx, by, cw, row_h - 4, 4, 4)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(f.normal)
    love.graphics.setColor(sel and COL_TEXT or COL_DIM)
    love.graphics.print((sel and "► " or "  ") .. entry.def.name, cx + 8, by + 6)

    -- Count
    if entry.def.type ~= "key" then
      love.graphics.setColor(COL_HINT)
      love.graphics.printf("×" .. entry.count, cx, by + 6, cw - 10, "right")
    else
      love.graphics.setColor(0.75, 0.65, 0.30, 0.80)
      love.graphics.printf("KEY", cx, by + 6, cw - 10, "right")
    end

    -- Description (small, if selected)
    if sel then
      love.graphics.setFont(f.tiny)
      love.graphics.setColor(COL_HINT)
      love.graphics.print(entry.def.description or "", cx + 12, by + 25)
    end
  end
end

-- -------------------------------------------------------------------------
-- Bag target sub-screen: pick Lumin to use item on
-- -------------------------------------------------------------------------

function PauseMenu:_drawBagTarget(cx, cy, cw, ch, f)
  local def = self._selected_item and Items[self._selected_item]
  love.graphics.setFont(f.normal)
  love.graphics.setColor(COL_SELECT)
  love.graphics.print("Use " .. (def and def.name or "item") .. " on:", cx, cy)

  local party = PartyManager.party
  for i, lumin in ipairs(party) do
    local ay  = cy + 44 + (i - 1) * 40
    local sel = (i == self._cursor)
    local hp_pct = lumin.max_hp > 0 and lumin.hp / lumin.max_hp or 0

    love.graphics.setFont(f.normal)
    love.graphics.setColor(sel and COL_SELECT or COL_DIM)
    love.graphics.print((sel and "► " or "  ") ..
      Lumin.displayName(lumin) .. "  Lv" .. lumin.level ..
      "   HP " .. lumin.hp .. "/" .. lumin.max_hp, cx + 10, ay)
  end
end

-- -------------------------------------------------------------------------
-- Journal tab
-- -------------------------------------------------------------------------

function PauseMenu:_drawJournal(cx, cy, cw, ch, f)
  love.graphics.setFont(f.normal)
  love.graphics.setColor(COL_SELECT)
  love.graphics.print("Current Objective", cx, cy)

  love.graphics.setFont(f.small)
  love.graphics.setColor(COL_TEXT)
  love.graphics.printf(
    "Find the Beacon Tower in Willowfen Marsh and rekindle it.\n\n" ..
    "Speak with Elder Cerin in Willowfen Town for more information.\n\n" ..
    "Collect a Beacon Shard to restore the Willowfen Beacon.",
    cx, cy + 30, cw, "left")

  love.graphics.setFont(f.tiny)
  love.graphics.setColor(COL_HINT)
  love.graphics.printf("(Journal is updated as you progress.)", cx, cy + ch - 20, cw, "center")
end

-- -------------------------------------------------------------------------
-- Settings tab
-- -------------------------------------------------------------------------

function PauseMenu:_drawSettings(cx, cy, cw, ch, f)
  local items_y = { cy, cy + 56, cy + 112 }

  local function draw_setting_row(idx, label, value_str, slider_frac)
    local ry  = items_y[idx]
    local sel = (idx == self._cursor) and self._screen == "tabs"

    love.graphics.setFont(f.normal)
    love.graphics.setColor(sel and COL_SELECT or COL_DIM)
    love.graphics.print((sel and "► " or "  ") .. label, cx + 8, ry + 8)

    if slider_frac ~= nil then
      local bar_x = cx + 200
      local bar_w = cw - 220
      local bar_h = 12
      local bar_y = ry + 10

      love.graphics.setColor(0.14, 0.14, 0.14, 0.90)
      love.graphics.rectangle("fill", bar_x, bar_y, bar_w, bar_h, 2, 2)
      love.graphics.setColor(sel and COL_SELECT or {0.50, 0.46, 0.60, 0.85})
      love.graphics.rectangle("fill", bar_x, bar_y, bar_w * slider_frac, bar_h, 2, 2)
      love.graphics.setColor(COL_BORDER)
      love.graphics.setLineWidth(1)
      love.graphics.rectangle("line", bar_x, bar_y, bar_w, bar_h, 2, 2)

      love.graphics.setFont(f.small)
      love.graphics.setColor(COL_TEXT)
      love.graphics.printf(value_str, bar_x, bar_y, bar_w, "center")
    end
  end

  draw_setting_row(1, "Music Volume",
    math.floor(Settings.music_volume * 100) .. "%", Settings.music_volume)
  draw_setting_row(2, "SFX Volume",
    math.floor(Settings.sfx_volume * 100) .. "%", Settings.sfx_volume)

  -- Return to Main Menu row
  local sel3 = (self._cursor == 3) and (self._screen == "tabs" or self._screen == "confirm_quit")
  love.graphics.setFont(f.normal)
  love.graphics.setColor(sel3 and COL_SELECT or COL_DIM)
  love.graphics.print((sel3 and "► " or "  ") .. SETTINGS_ITEMS[3], cx + 8, items_y[3] + 8)

  -- Hint for sliders
  if (self._cursor == 1 or self._cursor == 2) and self._screen == "tabs" then
    love.graphics.setFont(f.tiny)
    love.graphics.setColor(COL_HINT)
    love.graphics.printf("◄ / ► to adjust", cx, items_y[self._cursor] + 28, cw, "left")
  end
end

-- -------------------------------------------------------------------------
-- Confirm quit overlay
-- -------------------------------------------------------------------------

function PauseMenu:_drawConfirmQuit(sw, sh, f)
  love.graphics.setColor(0, 0, 0, 0.60)
  love.graphics.rectangle("fill", 0, 0, sw, sh)

  local bw, bh = 340, 104
  local bx = math.floor(sw / 2 - bw / 2)
  local by = math.floor(sh / 2 - bh / 2)

  love.graphics.setColor(COL_BG)
  love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)
  love.graphics.setColor(COL_SELECT)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", bx, by, bw, bh, 8, 8)
  love.graphics.setLineWidth(1)

  love.graphics.setFont(f.normal)
  love.graphics.setColor(COL_TEXT)
  love.graphics.printf("Return to Main Menu?", bx, by + 16, bw, "center")
  love.graphics.setFont(f.tiny)
  love.graphics.setColor(COL_HINT)
  love.graphics.printf("Progress since last save will be lost.", bx, by + 38, bw, "center")

  local opts    = { "Yes", "No" }
  local offsets = { 70, bw - 120 }
  for i, label in ipairs(opts) do
    if i == self._quit_cursor then
      love.graphics.setFont(f.normal)
      love.graphics.setColor(COL_SELECT)
      love.graphics.print("► " .. label, bx + offsets[i], by + 64)
    else
      love.graphics.setFont(f.normal)
      love.graphics.setColor(COL_DIM)
      love.graphics.print("  " .. label, bx + offsets[i], by + 64)
    end
  end
end

function PauseMenu:keypressed(key) end

return PauseMenu
