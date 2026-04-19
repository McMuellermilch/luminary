-- MusicManager
-- Layered stem crossfading system.
-- All stems in a set play simultaneously; only volumes change.
-- Missing audio files are skipped — the system works silently until
-- assets are placed in assets/audio/music/.

local Timer    = require("lib.hump.timer")
local MusicDef = require("src.data.music")
local Settings = require("src.core.settings")
local Events   = require("src.core.events")

local MusicManager = {}

-- Active stem entries: { source, volume (current), target_volume }
MusicManager._active  = {}    -- { [stem_key] = { source, volume, target } }
MusicManager._set     = nil   -- name of current set
MusicManager._context = "overworld"
MusicManager._timer   = Timer.new()

-- Context-specific volume multipliers per stem name.
-- Stems not listed default to 1.0 in overworld, 0.5 in combat.
local CONTEXT_VOLUMES = {
  overworld = { bass = 1.0, melody = 1.0, texture = 0.5, birds = 1.0,
                drums = 0.0, tension = 0.0 },
  combat    = { bass = 0.8, melody = 0.3, texture = 0.0, birds = 0.0,
                drums = 1.0, tension = 1.0 },
}

-- -------------------------------------------------------------------------
local function try_load(path)
  if not love.filesystem.getInfo(path) then
    print("[MusicManager] Missing audio file (skipped): " .. path)
    return nil
  end
  local ok, src = pcall(love.audio.newSource, path, "stream")
  if not ok then
    print("[MusicManager] Failed to load: " .. path)
    return nil
  end
  src:setLooping(true)
  return src
end

local function stem_target(stem_key)
  local ctx = CONTEXT_VOLUMES[MusicManager._context] or {}
  return ctx[stem_key] ~= nil and ctx[stem_key] or 1.0
end

-- -------------------------------------------------------------------------
-- Load and crossfade to a new stem set.
-- transition_duration: seconds to crossfade (default 1.5)
-- -------------------------------------------------------------------------
function MusicManager.play(set_name, transition_duration)
  local def = MusicDef[set_name]
  if not def then
    print("[MusicManager] Unknown music set: " .. tostring(set_name))
    return
  end
  if MusicManager._set == set_name then return end

  transition_duration = transition_duration or 1.5
  MusicManager._set = set_name

  -- Fade out all current stems
  for key, entry in pairs(MusicManager._active) do
    MusicManager._timer:tween(transition_duration, entry, { volume = 0 }, "linear",
      function()
        if entry.source then
          entry.source:stop()
          entry.source:release()
        end
        MusicManager._active[key] = nil
      end)
  end

  -- Load and fade in new stems
  for stem_key, path in pairs(def) do
    local src = try_load(path)
    if src then
      local entry = { source = src, volume = 0, target = stem_target(stem_key) }
      MusicManager._active[stem_key] = entry
      src:setVolume(0)
      src:play()
      MusicManager._timer:tween(transition_duration, entry, { volume = entry.target }, "linear")
    end
  end
end

-- -------------------------------------------------------------------------
-- Switch context (overworld / combat / beacon_rekindle).
-- Adjusts stem volumes without changing the loaded set.
-- -------------------------------------------------------------------------
function MusicManager.setContext(context, duration)
  if MusicManager._context == context then return end
  MusicManager._context = context
  duration = duration or 1.0
  for stem_key, entry in pairs(MusicManager._active) do
    local target = stem_target(stem_key)
    MusicManager._timer:tween(duration, entry, { volume = target }, "linear")
  end
end

-- -------------------------------------------------------------------------
-- Call once per frame from main.lua love.update().
-- -------------------------------------------------------------------------
function MusicManager.update(dt)
  MusicManager._timer:update(dt)
  -- Sync source volumes (tween updates entry.volume, we push to source)
  local mv = Settings.music_volume
  for _, entry in pairs(MusicManager._active) do
    if entry.source then
      entry.source:setVolume(math.max(0, entry.volume) * mv)
    end
  end
end

-- -------------------------------------------------------------------------
-- Stop all music immediately.
-- -------------------------------------------------------------------------
function MusicManager.stop()
  for _, entry in pairs(MusicManager._active) do
    if entry.source then entry.source:stop() end
  end
  MusicManager._active = {}
  MusicManager._set    = nil
end

-- -------------------------------------------------------------------------
-- Switch to lit music when the beacon is rekindled.
-- -------------------------------------------------------------------------
Events.on("beacon_relit", function(region_id)
  MusicManager.play(region_id .. "_lit", 3.0)
end)

return MusicManager
