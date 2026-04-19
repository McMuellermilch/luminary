-- Main Menu state (placeholder)
-- Shows the game title and waits for the player to press Enter/Z.

local Input = require("src.core.input")
local SFX   = require("src.audio.sfx")

local MainMenu = {}
MainMenu.__index = MainMenu

local TITLE_COLOR    = {1, 0.85, 0.4, 1}   -- warm amber
local SUBTITLE_COLOR = {0.9, 0.9, 0.9, 0.7}

function MainMenu:enter()
  self.pulse_timer = 0
end

function MainMenu:exit() end

function MainMenu:update(dt)
  self.pulse_timer = self.pulse_timer + dt

  if Input.wasPressed("confirm") then
    SFX.play("menu_select")
    local StateManager = require("src.states.statemanager")
    local Overworld    = require("src.states.overworld")
    StateManager.push(Overworld)
  end
end

function MainMenu:draw()
  local w, h = love.graphics.getDimensions()

  -- Dark background
  love.graphics.setColor(0.05, 0.05, 0.1, 1)
  love.graphics.rectangle("fill", 0, 0, w, h)

  -- Title
  local pulse = 0.85 + 0.15 * math.sin(self.pulse_timer * 2)
  love.graphics.setColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3], pulse)
  love.graphics.setFont(love.graphics.newFont(64))
  love.graphics.printf("LUMINARY", 0, h * 0.35, w, "center")

  -- Subtitle
  local blink = math.floor(self.pulse_timer * 2) % 2 == 0
  love.graphics.setColor(SUBTITLE_COLOR)
  love.graphics.setFont(love.graphics.newFont(18))
  if blink then
    love.graphics.printf("Press Z or Enter to begin", 0, h * 0.58, w, "center")
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function MainMenu:keypressed(key)
  -- Handled via Input.wasPressed in update
end

return MainMenu
