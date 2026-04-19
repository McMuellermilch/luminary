-- Main Menu
-- Shows game title and lets the player start a new game or continue a saved one.
-- Three save slots with metadata display. Confirms before overwriting.

local Input       = require("src.core.input")
local SFX         = require("src.audio.sfx")
local SaveManager = require("src.save.savemanager")

local MainMenu = {}
MainMenu.__index = MainMenu

local TITLE_COLOR  = {1, 0.85, 0.4,  1}
local SELECT_COLOR = {1, 0.90, 0.50, 1}
local DIM_COLOR    = {0.6, 0.6, 0.6, 0.8}
local EMPTY_COLOR  = {0.4, 0.4, 0.4, 0.6}
local HINT_COLOR   = {0.9, 0.9, 0.9, 0.55}

local MAIN_ITEMS = { "New Game", "Continue" }

-- -------------------------------------------------------------------------
-- Helpers
-- -------------------------------------------------------------------------

local function format_playtime(secs)
  secs = secs or 0
  local h = math.floor(secs / 3600)
  local m = math.floor((secs % 3600) / 60)
  if h > 0 then return string.format("%dh %02dm", h, m)
  else           return string.format("%dm", m) end
end

local function map_display(path)
  if not path or path == "" then return "???" end
  local name = path:match("([^/]+)%.lua$") or path
  return name:gsub("_", " ")
end

local function format_timestamp(ts)
  if not ts then return "" end
  return os.date("%Y-%m-%d %H:%M", ts)
end

-- -------------------------------------------------------------------------
function MainMenu:enter()
  self.pulse_timer = 0
  self._screen     = "main"   -- "main" | "new_game_slots" | "continue_slots" | "confirm_overwrite"
  self._cursor     = 1
  self._slot       = nil      -- slot chosen before confirm_overwrite
  self._fonts      = nil      -- lazily created
  self:_refreshMetadata()
end

function MainMenu:exit() end

function MainMenu:_refreshMetadata()
  self._metadata = {}
  for i = 1, 3 do
    self._metadata[i] = SaveManager.getMetadata(i)
  end
end

function MainMenu:_firstFilledSlot()
  for i = 1, 3 do
    if self._metadata[i] then return i end
  end
  return nil
end

-- -------------------------------------------------------------------------
-- Update
-- -------------------------------------------------------------------------

function MainMenu:update(dt)
  self.pulse_timer = self.pulse_timer + dt

  if self._screen == "main" then
    self:_updateMain()
  elseif self._screen == "new_game_slots" then
    self:_updateSlots("new_game")
  elseif self._screen == "continue_slots" then
    self:_updateSlots("continue")
  elseif self._screen == "confirm_overwrite" then
    self:_updateConfirm()
  end
end

function MainMenu:_updateMain()
  if Input.wasPressed("move_up") then
    self._cursor = self._cursor > 1 and self._cursor - 1 or #MAIN_ITEMS
    SFX.play("menu_select")
  elseif Input.wasPressed("move_down") then
    self._cursor = self._cursor < #MAIN_ITEMS and self._cursor + 1 or 1
    SFX.play("menu_select")
  elseif Input.wasPressed("confirm") then
    SFX.play("menu_select")
    if self._cursor == 1 then
      self._screen = "new_game_slots"
      self._cursor = 1
    else
      -- Continue: jump to first filled slot or slot 1
      self._screen = "continue_slots"
      self._cursor = self:_firstFilledSlot() or 1
    end
  end
end

function MainMenu:_updateSlots(mode)
  if Input.wasPressed("move_up") then
    self._cursor = self._cursor > 1 and self._cursor - 1 or 3
    SFX.play("menu_select")
  elseif Input.wasPressed("move_down") then
    self._cursor = self._cursor < 3 and self._cursor + 1 or 1
    SFX.play("menu_select")
  elseif Input.wasPressed("confirm") then
    SFX.play("menu_select")
    if mode == "new_game" then
      self._slot = self._cursor
      if self._metadata[self._slot] then
        -- Occupied slot — confirm overwrite
        self._screen = "confirm_overwrite"
        self._cursor = 2  -- default cursor on "No"
      else
        self:_startNewGame(self._slot)
      end
    else
      -- Continue: only proceed if slot has data
      if self._metadata[self._cursor] then
        self:_loadGame(self._cursor)
      end
    end
  elseif Input.wasPressed("cancel") then
    SFX.play("menu_select")
    self._screen = "main"
    self._cursor = 1
  end
end

function MainMenu:_updateConfirm()
  if Input.wasPressed("move_left") or Input.wasPressed("move_right") then
    self._cursor = self._cursor == 1 and 2 or 1
    SFX.play("menu_select")
  elseif Input.wasPressed("confirm") then
    SFX.play("menu_select")
    if self._cursor == 1 then
      self:_startNewGame(self._slot)
    else
      -- Cancel — return to slot picker
      self._screen = "new_game_slots"
      self._cursor = self._slot
    end
  elseif Input.wasPressed("cancel") then
    SFX.play("menu_select")
    self._screen = "new_game_slots"
    self._cursor = self._slot
  end
end

-- -------------------------------------------------------------------------
-- Transitions
-- -------------------------------------------------------------------------

function MainMenu:_startNewGame(slot)
  SaveManager.newGame(slot)
  local StateManager = require("src.states.statemanager")
  local Overworld    = require("src.states.overworld")
  StateManager.replace(Overworld, {
    map   = SaveManager._current_map,
    spawn = SaveManager._current_spawn,
  })
end

function MainMenu:_loadGame(slot)
  local ok, data = SaveManager.load(slot)
  if not ok then return end
  local StateManager = require("src.states.statemanager")
  local Overworld    = require("src.states.overworld")
  StateManager.replace(Overworld, {
    map   = data.current_map,
    spawn = data.spawn_id,
  })
end

-- -------------------------------------------------------------------------
-- Draw
-- -------------------------------------------------------------------------

function MainMenu:draw()
  local w, h = love.graphics.getDimensions()
  local f    = self:_ensureFonts()

  -- Background
  love.graphics.setColor(0.05, 0.05, 0.1, 1)
  love.graphics.rectangle("fill", 0, 0, w, h)

  -- Pulsing title
  local pulse = 0.85 + 0.15 * math.sin(self.pulse_timer * 2)
  love.graphics.setColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3], pulse)
  love.graphics.setFont(f.title)
  love.graphics.printf("LUMINARY", 0, h * 0.12, w, "center")

  if self._screen == "main" then
    self:_drawMain(w, h, f)
  elseif self._screen == "new_game_slots" then
    self:_drawSlots(w, h, f, "new_game")
  elseif self._screen == "continue_slots" then
    self:_drawSlots(w, h, f, "continue")
  elseif self._screen == "confirm_overwrite" then
    self:_drawSlots(w, h, f, "new_game")   -- show slots underneath
    self:_drawConfirm(w, h, f)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function MainMenu:_ensureFonts()
  if not self._fonts then
    self._fonts = {
      title  = love.graphics.newFont(64),
      big    = love.graphics.newFont(22),
      normal = love.graphics.newFont(16),
      small  = love.graphics.newFont(12),
    }
  end
  return self._fonts
end

function MainMenu:_drawMain(w, h, f)
  local base_y = h * 0.44
  love.graphics.setFont(f.big)
  for i, label in ipairs(MAIN_ITEMS) do
    local y = base_y + (i - 1) * 46
    if i == self._cursor then
      love.graphics.setColor(SELECT_COLOR)
      love.graphics.printf("► " .. label, 0, y, w, "center")
    else
      love.graphics.setColor(DIM_COLOR)
      love.graphics.printf(label, 0, y, w, "center")
    end
  end
end

function MainMenu:_drawSlots(w, h, f, mode)
  local heading = mode == "new_game" and "Choose a Save Slot" or "Continue"
  love.graphics.setColor(HINT_COLOR)
  love.graphics.setFont(f.big)
  love.graphics.printf(heading, 0, h * 0.33, w, "center")

  local box_w  = math.floor(w * 0.68)
  local box_x  = math.floor((w - box_w) / 2)
  local box_h  = 62
  local gap    = 12
  local base_y = math.floor(h * 0.43)

  for i = 1, 3 do
    local bx   = box_x
    local by   = base_y + (i - 1) * (box_h + gap)
    local meta = self._metadata[i]
    local sel  = (i == self._cursor) and self._screen ~= "confirm_overwrite"

    -- Box fill
    love.graphics.setColor(sel and 0.20 or 0.10,
                           sel and 0.16 or 0.08,
                           sel and 0.28 or 0.15,
                           sel and 0.95 or 0.85)
    love.graphics.rectangle("fill", bx, by, box_w, box_h, 6, 6)

    -- Box border
    if sel then
      love.graphics.setColor(SELECT_COLOR)
      love.graphics.setLineWidth(2)
    else
      love.graphics.setColor(0.40, 0.35, 0.50, 0.6)
      love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("line", bx, by, box_w, box_h, 6, 6)
    love.graphics.setLineWidth(1)

    -- Slot number
    love.graphics.setFont(f.normal)
    love.graphics.setColor(sel and SELECT_COLOR or DIM_COLOR)
    love.graphics.print("Slot " .. i, bx + 12, by + 8)

    if meta then
      -- Map name
      love.graphics.setColor(sel and {0.95, 0.92, 0.88, 1} or DIM_COLOR)
      love.graphics.setFont(f.small)
      love.graphics.print(map_display(meta.map_name), bx + 12, by + 32)
      -- Play time (right-aligned)
      love.graphics.print(format_playtime(meta.play_time), bx + box_w - 90, by + 8)
      -- Timestamp
      love.graphics.setColor(HINT_COLOR)
      love.graphics.print(format_timestamp(meta.save_timestamp), bx + box_w - 150, by + 32)
      -- Overwrite warning for new_game mode
      if mode == "new_game" and sel then
        love.graphics.setColor(1, 0.55, 0.30, 0.9)
        love.graphics.setFont(f.small)
        love.graphics.printf("will overwrite", bx, by + 32, box_w - 10, "right")
      end
    else
      -- Empty slot
      love.graphics.setColor(EMPTY_COLOR)
      love.graphics.setFont(f.normal)
      love.graphics.printf("--- Empty ---", bx, by + 20, box_w, "center")
    end
  end

  -- Hint
  love.graphics.setColor(HINT_COLOR)
  love.graphics.setFont(f.small)
  love.graphics.printf("X / Esc  —  Back", 0, h - 28, w, "center")
end

function MainMenu:_drawConfirm(w, h, f)
  -- Semi-transparent overlay
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, w, h)

  local box_w = 320
  local box_h = 96
  local bx    = math.floor((w - box_w) / 2)
  local by    = math.floor(h / 2 - box_h / 2)

  love.graphics.setColor(0.12, 0.09, 0.18, 0.97)
  love.graphics.rectangle("fill", bx, by, box_w, box_h, 8, 8)
  love.graphics.setColor(SELECT_COLOR)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", bx, by, box_w, box_h, 8, 8)
  love.graphics.setLineWidth(1)

  love.graphics.setColor(0.95, 0.92, 0.88, 1)
  love.graphics.setFont(f.normal)
  love.graphics.printf("Overwrite Slot " .. (self._slot or "?") .. "?",
    bx, by + 14, box_w, "center")

  -- Yes / No buttons
  local labels = { "Yes", "No" }
  local offsets = { 60, box_w - 110 }
  for i, label in ipairs(labels) do
    local ox = bx + offsets[i]
    if i == self._cursor then
      love.graphics.setColor(SELECT_COLOR)
      love.graphics.setFont(f.big)
      love.graphics.print("► " .. label, ox, by + 54)
    else
      love.graphics.setColor(DIM_COLOR)
      love.graphics.setFont(f.big)
      love.graphics.print(label, ox + 16, by + 54)
    end
  end
end

function MainMenu:keypressed(key)
  -- Handled via Input.wasPressed in update
end

return MainMenu
