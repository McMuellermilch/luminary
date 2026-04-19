-- WarpSystem
-- Each frame, checks whether the player's centre point is inside any warp zone.
-- On overlap: pushes a TransitionState whose midpoint callback reloads the Overworld
-- in-place (new map, repositioned player) so the fade-out reveals the new map.
-- Emits Events.emit("warp_completed") at midpoint for future autosave hooks.

local MapManager = require("src.world.mapmanager")
local Events     = require("src.core.events")

local WarpSystem = {}

-- Prevent re-triggering while a transition is in progress.
WarpSystem._triggered = false

function WarpSystem.reset()
  WarpSystem._triggered = false
end

-- Call every frame from Overworld:update(), after player movement.
-- overworld — the OverworldState instance (to reload in-place at midpoint)
-- player    — Player instance (needs :center() → cx, cy)
function WarpSystem.check(overworld, player)
  if WarpSystem._triggered then return end

  local cx, cy = player:center()

  for _, warp in ipairs(MapManager.warps) do
    if cx >= warp.x and cx <= warp.x + warp.w and
       cy >= warp.y and cy <= warp.y + warp.h then
      WarpSystem._trigger(overworld, warp)
      return
    end
  end
end

function WarpSystem._trigger(overworld, warp)
  WarpSystem._triggered = true

  local StateManager = require("src.states.statemanager")
  local Transition   = require("src.states.transition")

  StateManager.push(Transition, {
    on_midpoint_callback = function()
      -- Reload the overworld in-place so fade-out reveals the new map
      overworld:_reload(warp.target_map, warp.target_spawn)
      Events.emit("warp_completed")
      print("[WarpSystem] warp_completed → " .. tostring(warp.target_map))
    end,
  })
end

return WarpSystem
