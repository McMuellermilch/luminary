-- Stack-based state machine
-- Only the top state receives update and keypressed.
-- All states receive draw (bottom to top) so overlays render correctly.
--
-- Each state must implement:
--   state:enter(params)
--   state:exit()
--   state:update(dt)
--   state:draw()
--   state:keypressed(key)    (optional)
--   state:gamepadpressed(joystick, button)  (optional)

local StateManager = {}

local stack = {}

local function top()
  return stack[#stack]
end

function StateManager.push(state, params)
  assert(state, "StateManager.push: state is nil")
  stack[#stack + 1] = state
  if state.enter then state:enter(params) end
end

function StateManager.pop()
  assert(#stack > 0, "StateManager.pop: stack is empty")
  local state = table.remove(stack)
  if state.exit then state:exit() end
end

function StateManager.replace(state, params)
  if #stack > 0 then
    local old = table.remove(stack)
    if old.exit then old:exit() end
  end
  StateManager.push(state, params)
end

function StateManager.peek()
  return top()
end

function StateManager.update(dt)
  local current = top()
  if current and current.update then
    current:update(dt)
  end
end

-- Draw bottom → top so overlaid states render on top
function StateManager.draw()
  for i = 1, #stack do
    if stack[i].draw then
      stack[i]:draw()
    end
  end
end

function StateManager.keypressed(key)
  local current = top()
  if current and current.keypressed then
    current:keypressed(key)
  end
end

function StateManager.gamepadpressed(joystick, button)
  local current = top()
  if current and current.gamepadpressed then
    current:gamepadpressed(joystick, button)
  end
end

function StateManager.keyreleased(key)
  local current = top()
  if current and current.keyreleased then
    current:keyreleased(key)
  end
end

function StateManager.gamepadreleased(joystick, button)
  local current = top()
  if current and current.gamepadreleased then
    current:gamepadreleased(joystick, button)
  end
end

return StateManager
