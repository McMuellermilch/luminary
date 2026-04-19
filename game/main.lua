-- Luminary — main.lua
-- Entry point. Wires Love2D callbacks to the StateManager.

local StateManager   = require("src.states.statemanager")
local Input          = require("src.core.input")
local Events         = require("src.core.events")
local MainMenu       = require("src.states.mainmenu")
local MusicManager   = require("src.audio.musicmanager")
local SFX            = require("src.audio.sfx")

function love.load()
  -- Pixel-art rendering defaults
  love.graphics.setDefaultFilter("nearest", "nearest")

  -- Load all sound effects (missing files are skipped gracefully)
  SFX.load()

  -- Boot into the main menu
  StateManager.push(MainMenu)
end

function love.update(dt)
  MusicManager.update(dt)  -- advance music tween timers
  StateManager.update(dt)  -- reads Input.wasPressed first
  Input.update()           -- then clear pressed_this_frame for next frame
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
