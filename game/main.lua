-- Luminary — main.lua
-- Entry point. Wires Love2D callbacks to the StateManager.

local StateManager = require("src.states.statemanager")
local Input        = require("src.core.input")
local Events       = require("src.core.events")
local MainMenu     = require("src.states.mainmenu")

function love.load()
  -- Pixel-art rendering defaults
  love.graphics.setDefaultFilter("nearest", "nearest")

  -- Boot into the main menu
  StateManager.push(MainMenu)
end

function love.update(dt)
  Input.update()
  StateManager.update(dt)
end

function love.draw()
  StateManager.draw()
end

-- Keyboard
function love.keypressed(key)
  Input.keypressed(key)
  StateManager.keypressed(key)
end

function love.keyreleased(key)
  StateManager.keyreleased(key)
end

-- Gamepad
function love.gamepadpressed(joystick, button)
  Input.gamepadpressed(joystick, button)
  StateManager.gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
  StateManager.gamepadreleased(joystick, button)
end

function love.joystickadded(joystick)
  Input.gamepadadded(joystick)
end

function love.joystickremoved(joystick)
  Input.gamepadremoved(joystick)
end

-- Window resize: keep pixel art sharp by not stretching
function love.resize(w, h)
  -- States can hook this via Events if needed
  Events.emit("window_resized", w, h)
end
