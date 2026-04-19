-- RegionState
-- Tracks which regions are lit or dark and holds the current darkness
-- shader parameters so they can be animated during rekindling.
-- Serialised in Phase 11.

local Flags  = require("src.core.flags")
local Events = require("src.core.events")

local RegionState = {}

-- Region id of the currently loaded map (e.g. "willowfen").
RegionState.active_region = nil

-- Current shader parameters — read by Overworld.draw() each frame.
-- Animated by BeaconRekindleState during the cutscene.
RegionState.shader_params = {
  desaturate = 0.70,   -- 0.0 = full colour, 0.7 = heavy grey
  brightness = 0.55,   -- 1.0 = normal, 0.55 = dim
}

-- -------------------------------------------------------------------------

function RegionState.isLit(region_id)
  if not region_id then return false end
  return Flags.is(region_id .. "_beacon_lit")
end

function RegionState.getActiveRegion()
  return RegionState.active_region
end

-- Call whenever a new map is loaded so the active region and shader snap correctly.
function RegionState.onMapLoad(region_id)
  RegionState.active_region = region_id
  if RegionState.isLit(region_id) then
    RegionState.shader_params.desaturate = 0.0
    RegionState.shader_params.brightness = 1.0
  else
    RegionState.shader_params.desaturate = 0.70
    RegionState.shader_params.brightness = 0.55
  end
end

-- Set the region as lit. Also snaps shader params to fully lit.
-- Called by BeaconRekindleState at the midpoint of the cutscene.
function RegionState.rekindle(region_id)
  Flags.set(region_id .. "_beacon_lit", true)
  RegionState.shader_params.desaturate = 0.0
  RegionState.shader_params.brightness = 1.0
  Events.emit("beacon_relit", region_id)
  print(string.format("[RegionState] %s beacon rekindled!", region_id))
end

return RegionState
