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

local Dialogue = {}
Dialogue.__index = Dialogue

local CHARS_PER_SEC = 30
local BOX_HEIGHT    = 90
local BOX_PADDING   = 14
local PORTRAIT_SIZE = 60

-- Lazily-initialised font cache (love.graphics not available at require time)
local font_name = nil
local font_text = nil

local function ensure_fonts()
  if not font_name then
    font_name = love.graphics.newFont(12)
    font_text = love.graphics.newFont(13)
  end
end

function Dialogue.new(line)
  local self = setmetatable({}, Dialogue)
  self.speaker  = line.speaker  or ""
  self.text     = line.text     or ""
  self.revealed = 0              -- number of characters currently shown
  self.elapsed  = 0
  return self
end

function Dialogue:update(dt)
  if self.revealed < #self.text then
    self.elapsed = self.elapsed + dt
    self.revealed = math.min(#self.text, math.floor(self.elapsed * CHARS_PER_SEC))
  end
end

function Dialogue:skip()
  self.revealed = #self.text
  self.elapsed  = #self.text / CHARS_PER_SEC
end

function Dialogue:isComplete()
  return self.revealed >= #self.text
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
  local shown  = string.sub(self.text, 1, self.revealed)

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
