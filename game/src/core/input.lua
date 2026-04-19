-- Unified input abstraction for keyboard and gamepad
-- Usage:
--   Input.isDown("attack")      -- held this frame
--   Input.wasPressed("confirm") -- pressed exactly this frame

local Input = {}

-- Action → keyboard key bindings
local key_bindings = {
  move_up    = {"up", "w"},
  move_down  = {"down", "s"},
  move_left  = {"left", "a"},
  move_right = {"right", "d"},
  confirm    = {"z", "return"},
  cancel     = {"x", "backspace", "escape"},
  attack     = {"z"},
  ability1   = {"x"},
  ability2   = {"a"},
  swap       = {"s"},
  pause      = {"escape"},
}

-- Action → gamepad button bindings
local pad_bindings = {
  confirm  = {"a"},
  cancel   = {"b"},
  attack   = {"x"},
  ability1 = {"y"},
  ability2 = {"leftshoulder"},
  swap     = {"rightshoulder"},
  pause    = {"start"},
}

-- Gamepad axis thresholds for movement
local AXIS_THRESHOLD = 0.5

local pressed_this_frame = {}
local gamepad = nil  -- first connected gamepad

function Input.update()
  pressed_this_frame = {}
end

function Input.keypressed(key)
  pressed_this_frame[key] = true
end

function Input.gamepadpressed(joystick, button)
  pressed_this_frame["pad_" .. button] = true
end

function Input.gamepadadded(joystick)
  if not gamepad then
    gamepad = joystick
  end
end

function Input.gamepadremoved(joystick)
  if gamepad == joystick then
    gamepad = nil
  end
end

function Input.isDown(action)
  -- Keyboard
  local keys = key_bindings[action]
  if keys then
    for _, k in ipairs(keys) do
      if love.keyboard.isDown(k) then return true end
    end
  end

  -- Gamepad buttons
  if gamepad then
    local buttons = pad_bindings[action]
    if buttons then
      for _, b in ipairs(buttons) do
        if gamepad:isGamepadDown(b) then return true end
      end
    end

    -- Gamepad axes for movement
    if action == "move_left"  and gamepad:getGamepadAxis("leftx") < -AXIS_THRESHOLD then return true end
    if action == "move_right" and gamepad:getGamepadAxis("leftx") >  AXIS_THRESHOLD then return true end
    if action == "move_up"    and gamepad:getGamepadAxis("lefty") < -AXIS_THRESHOLD then return true end
    if action == "move_down"  and gamepad:getGamepadAxis("lefty") >  AXIS_THRESHOLD then return true end
  end

  return false
end

function Input.wasPressed(action)
  -- Keyboard
  local keys = key_bindings[action]
  if keys then
    for _, k in ipairs(keys) do
      if pressed_this_frame[k] then return true end
    end
  end

  -- Gamepad buttons
  if gamepad then
    local buttons = pad_bindings[action]
    if buttons then
      for _, b in ipairs(buttons) do
        if pressed_this_frame["pad_" .. b] then return true end
      end
    end
  end

  return false
end

return Input
