-- Dialogue box renderer
-- Draws a fixed box at the bottom of the screen with:
--   - Speaker name on a tab above the box
--   - Portrait placeholder on the left
--   - Typewriter text that reveals ~30 chars/sec
--
-- Usage:
--   local box = Dialogue.new(line)       -- line = { speaker, portrait, text }
--   box:update(dt)
--   box:draw()
--   box:skip()                           -- instantly show full text
--   box:isComplete() → bool             -- true when all chars shown

local SFX = require("src.audio.sfx")

local Dialogue = {}
Dialogue.__index = Dialogue

local CHARS_PER_SEC = 30
local BOX_HEIGHT    = 90
local BOX_PADDING   = 14
local PORTRAIT_SIZE = 60

-- UTF-8-safe helpers (pure byte iteration; no external library required).
-- UTF-8 leading bytes: 0x00–0x7F (1-byte) and 0xC0–0xFF (multi-byte start).
-- Continuation bytes are 0x80–0xBF and are skipped when counting characters.

local function utf8_len(s)
  local n = 0
  for i = 1, #s do
    local b = string.byte(s, i)
    if b < 0x80 or b >= 0xC0 then n = n + 1 end
  end
  return n
end

local function utf8_sub(s, n_chars)
  if n_chars <= 0 then return "" end
  local count = 0
  for i = 1, #s do
    local b = string.byte(s, i)
    if b < 0x80 or b >= 0xC0 then
      count = count + 1
      if count > n_chars then return string.sub(s, 1, i - 1) end
    end
  end
  return s
end

-- Lazily-initialised font cache (love.graphics not available at require time)
local font_name = nil
local font_text = nil

local function ensure_fonts()
  if not font_name then
    font_name = love.graphics.newFont(12)
    font_text = love.graphics.newFont(13)
  end
end

-- Speaker → blip pitch mapping
local SPEAKER_PITCH = {
  ["Elder Cerin"] = 0.75,
  ["Mira"]        = 1.10,
  ["Lumin"]       = 1.30,
}
local DEFAULT_PITCH = 1.0

-- Blip fires at most every N characters to avoid rapid-fire noise
local BLIP_INTERVAL = 3

function Dialogue.new(line)
  local self = setmetatable({}, Dialogue)
  self.speaker       = line.speaker  or ""
  self.text          = line.text     or ""
  self._len          = utf8_len(self.text)  -- character count, not byte count
  self.revealed      = 0              -- number of UTF-8 characters currently shown
  self.elapsed       = 0
  self._blip_pitch   = SPEAKER_PITCH[self.speaker] or DEFAULT_PITCH
  self._last_blip_at = 0              -- revealed count at last blip
  return self
end

function Dialogue:update(dt)
  if self.revealed < self._len then
    self.elapsed       = self.elapsed + dt
    local prev         = self.revealed
    self.revealed      = math.min(self._len, math.floor(self.elapsed * CHARS_PER_SEC))
    -- Fire blip whenever enough new characters have appeared
    if self.revealed > prev and
       (self.revealed - self._last_blip_at) >= BLIP_INTERVAL then
      self._last_blip_at = self.revealed
      SFX.playBlip(self._blip_pitch)
    end
  end
end

function Dialogue:skip()
  self.revealed = self._len
  self.elapsed  = self._len / CHARS_PER_SEC
end

function Dialogue:isComplete()
  return self.revealed >= self._len
end

function Dialogue:draw()
  ensure_fonts()
  local sw, sh = love.graphics.getDimensions()
  local box_y  = sh - BOX_HEIGHT - 10
  local box_w  = sw - 20

  -- Box background
  love.graphics.setColor(0.08, 0.06, 0.12, 0.92)
  love.graphics.rectangle("fill", 10, box_y, box_w, BOX_HEIGHT, 6, 6)

  -- Box border
  love.graphics.setColor(0.85, 0.75, 0.40, 0.9)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", 10, box_y, box_w, BOX_HEIGHT, 6, 6)

  -- Speaker name tab
  if self.speaker and self.speaker ~= "" then
    local name_w = font_name:getWidth(self.speaker) + 20
    love.graphics.setColor(0.85, 0.75, 0.40, 0.9)
    love.graphics.rectangle("fill", 10, box_y - 22, name_w, 24, 4, 4)
    love.graphics.setColor(0.08, 0.06, 0.12, 1)
    love.graphics.setFont(font_name)
    love.graphics.print(self.speaker, 20, box_y - 19)
  end

  -- Portrait placeholder
  love.graphics.setColor(0.20, 0.16, 0.28, 1)
  love.graphics.rectangle("fill",
    10 + BOX_PADDING,
    box_y + (BOX_HEIGHT - PORTRAIT_SIZE) / 2,
    PORTRAIT_SIZE, PORTRAIT_SIZE, 4, 4)
  love.graphics.setColor(0.50, 0.42, 0.60, 0.6)
  love.graphics.rectangle("line",
    10 + BOX_PADDING,
    box_y + (BOX_HEIGHT - PORTRAIT_SIZE) / 2,
    PORTRAIT_SIZE, PORTRAIT_SIZE, 4, 4)

  -- Dialogue text (revealed portion only)
  local text_x = 10 + BOX_PADDING + PORTRAIT_SIZE + BOX_PADDING
  local text_w = box_w - (PORTRAIT_SIZE + BOX_PADDING * 3)
  local shown  = utf8_sub(self.text, self.revealed)

  love.graphics.setColor(0.95, 0.92, 0.88, 1)
  love.graphics.setFont(font_text)
  love.graphics.printf(shown, text_x, box_y + BOX_PADDING, text_w, "left")

  -- "More" indicator when text is fully shown
  if self:isComplete() then
    love.graphics.setColor(0.85, 0.75, 0.40, math.abs(math.sin(love.timer.getTime() * 3)))
    love.graphics.print("▼", sw - 30, box_y + BOX_HEIGHT - 20)
  end

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setLineWidth(1)
end

return Dialogue
