-- SFX
-- One-shot sound effects with optional volume and pitch control.
-- dialogue_blip is generated synthetically (no asset required).
-- All other sounds reference paths from src/data/sfx.lua;
-- missing files are skipped gracefully.

local SFXData  = require("src.data.sfx")
local Settings = require("src.core.settings")
local Events   = require("src.core.events")

local SFX = {}

-- Loaded sources: { [name] = love.Source (static) }
SFX._sources = {}

-- Pre-generated blip SoundData (reused every call)
SFX._blip_data = nil

-- -------------------------------------------------------------------------
local function make_blip()
  local rate     = 44100
  local duration = 0.045          -- seconds
  local samples  = math.floor(rate * duration)
  local sd       = love.sound.newSoundData(samples, rate, 16, 1)
  for i = 0, samples - 1 do
    local t     = i / rate
    local fade  = 1.0 - (i / samples)   -- linear decay
    local wave  = math.sin(2 * math.pi * 880 * t)
    sd:setSample(i, wave * fade * 0.35)
  end
  return sd
end

-- -------------------------------------------------------------------------
function SFX.load()
  -- Synthetic blip
  SFX._blip_data = make_blip()

  -- Real SFX
  for name, path in pairs(SFXData) do
    if love.filesystem.getInfo(path) then
      local ok, src = pcall(love.audio.newSource, path, "static")
      if ok then
        SFX._sources[name] = src
      else
        print("[SFX] Failed to load: " .. path)
      end
    else
      print("[SFX] Missing audio file (skipped): " .. path)
    end
  end
end

-- -------------------------------------------------------------------------
-- Play a named sound effect.
-- opts (optional): { volume = 0..1, pitch = 0..2 }
-- -------------------------------------------------------------------------
function SFX.play(name, opts)
  local base = SFX._sources[name]
  if not base then return end

  opts = opts or {}
  local vol   = (opts.volume or 1.0) * Settings.sfx_volume
  local pitch = opts.pitch or 1.0

  -- Clone so multiple overlapping plays work
  local src = base:clone()
  src:setVolume(math.max(0, vol))
  src:setPitch(math.max(0.1, pitch))
  src:play()
  -- Static clones are released automatically by LÖVE when finished
end

-- -------------------------------------------------------------------------
-- Play the typewriter blip at a given pitch (default 1.0).
-- -------------------------------------------------------------------------
function SFX.playBlip(pitch)
  if not SFX._blip_data then return end
  local src = love.audio.newSource(SFX._blip_data)
  src:setVolume(Settings.sfx_volume * 0.4)
  src:setPitch(math.max(0.5, pitch or 1.0))
  src:play()
end

-- -------------------------------------------------------------------------
-- Global event hooks (fire-and-forget)
-- -------------------------------------------------------------------------
Events.on("lumin_leveled_up", function()
  SFX.play("level_up")
end)

return SFX
