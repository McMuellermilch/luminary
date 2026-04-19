-- TransitionState
-- Fades the screen to black (0→1), calls a midpoint callback, then fades back (1→0).
-- Pops itself from the state stack when the full transition is complete.
--
-- params:
--   duration            (number)   seconds for each half (default 0.4)
--   on_midpoint_callback (function) called at full-black; triggers map load etc.

local TimerClass = require("lib.hump.timer")

local Transition = {}
Transition.__index = Transition

local DEFAULT_DURATION = 0.4

function Transition:enter(params)
  params = params or {}
  local duration        = params.duration             or DEFAULT_DURATION
  local on_midpoint     = params.on_midpoint_callback or function() end

  self.alpha   = 0
  self.done    = false
  self.timer   = TimerClass.new()

  -- Fade in to black, then call midpoint, then fade out
  self.timer:tween(duration, self, { alpha = 1 }, "linear", function()
    on_midpoint()
    self.timer:tween(duration, self, { alpha = 0 }, "linear", function()
      self.done = true
    end)
  end)
end

function Transition:exit()
  self.timer:clear()
end

function Transition:update(dt)
  self.timer:update(dt)

  if self.done then
    local StateManager = require("src.states.statemanager")
    StateManager.pop()
  end
end

function Transition:draw()
  local w, h = love.graphics.getDimensions()
  love.graphics.setColor(0, 0, 0, self.alpha)
  love.graphics.rectangle("fill", 0, 0, w, h)
  love.graphics.setColor(1, 1, 1, 1)
end

function Transition:keypressed(key) end

return Transition
