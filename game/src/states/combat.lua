-- Combat state (placeholder)
-- Full implementation in Phase 5.

local Input = require("src.core.input")

local Combat = {}
Combat.__index = Combat

function Combat:enter(params)
  self.params = params or {}
end

function Combat:exit() end

function Combat:update(dt)
  if Input.wasPressed("cancel") then
    local StateManager = require("src.states.statemanager")
    StateManager.pop()
  end
end

function Combat:draw()
  local w, h = love.graphics.getDimensions()

  love.graphics.setColor(0.08, 0.04, 0.12, 1)
  love.graphics.rectangle("fill", 0, 0, w, h)

  love.graphics.setColor(0.9, 0.5, 0.9, 0.9)
  love.graphics.setFont(love.graphics.newFont(28))
  love.graphics.printf("COMBAT (placeholder)", 0, h * 0.45, w, "center")

  love.graphics.setFont(love.graphics.newFont(14))
  love.graphics.setColor(0.6, 0.4, 0.6, 0.7)
  love.graphics.printf("Press X to return", 0, h * 0.55, w, "center")

  love.graphics.setColor(1, 1, 1, 1)
end

function Combat:keypressed(key) end

return Combat
