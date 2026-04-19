-- Overworld state (placeholder)
-- Renders a placeholder screen. Full implementation in Phase 2.

local Input = require("src.core.input")

local Overworld = {}
Overworld.__index = Overworld

function Overworld:enter()
  self.timer = 0
end

function Overworld:exit() end

function Overworld:update(dt)
  self.timer = self.timer + dt

  if Input.wasPressed("pause") then
    local StateManager = require("src.states.statemanager")
    StateManager.pop()
  end
end

function Overworld:draw()
  local w, h = love.graphics.getDimensions()

  -- Placeholder: dark green world colour
  love.graphics.setColor(0.1, 0.18, 0.12, 1)
  love.graphics.rectangle("fill", 0, 0, w, h)

  love.graphics.setColor(0.7, 0.9, 0.7, 0.9)
  love.graphics.setFont(love.graphics.newFont(24))
  love.graphics.printf("OVERWORLD (placeholder)", 0, h * 0.45, w, "center")

  love.graphics.setFont(love.graphics.newFont(14))
  love.graphics.setColor(0.5, 0.7, 0.5, 0.7)
  love.graphics.printf("Press Escape to return to main menu", 0, h * 0.55, w, "center")

  love.graphics.setColor(1, 1, 1, 1)
end

function Overworld:keypressed(key) end

return Overworld
