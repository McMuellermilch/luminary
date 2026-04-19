-- SaveManager
-- Handles saving, loading, and managing save slots via love.filesystem.
-- Uses the Ser library for Lua-table serialization.
-- Save files land in love.filesystem.getSaveDirectory() automatically.
--
-- Autosave fires on every warp_completed event.
-- Call SaveManager.update(dt) from love.update to track play time.

local Ser          = require("lib.ser.Ser")
local Flags        = require("src.core.flags")
local Inventory    = require("src.creatures.inventory")
local PartyManager = require("src.creatures.partymanager")
local Settings     = require("src.core.settings")
local Events       = require("src.core.events")
local Lumin        = require("src.creatures.lumin")

local SaveManager = {}

SaveManager.current_slot   = 1
SaveManager._play_time     = 0    -- cumulative seconds played this session
SaveManager._current_map   = "assets/maps/willowfen_town.lua"
SaveManager._current_spawn = "default"

local SAVE_VERSION = 1

local function slot_filename(slot)
  return "save_slot_" .. slot .. ".dat"
end

-- -------------------------------------------------------------------------
-- Lumin serialization helpers
-- -------------------------------------------------------------------------

local function serialize_lumin(lumin)
  local moves = {}
  for i, m in ipairs(lumin.moves) do moves[i] = m end
  return {
    id       = lumin.id,
    nickname = lumin.nickname,
    level    = lumin.level,
    exp      = lumin.exp,
    hp       = lumin.hp,
    moves    = moves,
    bonded   = lumin.bonded,
  }
end

local function deserialize_lumin(data)
  local inst = Lumin.new(data.id, data.level)
  inst.nickname = data.nickname
  inst.exp      = data.exp or 0
  inst.hp       = math.min(data.hp, inst.max_hp)
  inst.moves    = data.moves or inst.moves
  inst.bonded   = data.bonded or false
  return inst
end

-- -------------------------------------------------------------------------
-- Migration stub — add future transforms here
-- -------------------------------------------------------------------------

function SaveManager.migrate(save_data)
  -- v1 → v1: nothing to do
  return save_data
end

-- -------------------------------------------------------------------------
-- save(slot)
-- Collects current runtime state, serializes with Ser, writes to disk.
-- Returns true on success, false on error.
-- -------------------------------------------------------------------------

function SaveManager.save(slot)
  slot = slot or SaveManager.current_slot

  -- Deep-copy mutable module tables
  local items_copy = {}
  for k, v in pairs(Inventory.items) do items_copy[k] = v end

  local flags_copy = {}
  for k, v in pairs(Flags._store) do flags_copy[k] = v end

  local party_data = {}
  for _, lumin in ipairs(PartyManager.party) do
    party_data[#party_data + 1] = serialize_lumin(lumin)
  end

  local storage_data = {}
  for _, lumin in ipairs(PartyManager.storage) do
    storage_data[#storage_data + 1] = serialize_lumin(lumin)
  end

  local save_data = {
    version        = SAVE_VERSION,
    current_map    = SaveManager._current_map,
    spawn_id       = SaveManager._current_spawn,
    party          = party_data,
    storage        = storage_data,
    inventory      = items_copy,
    lumens         = Inventory.lumens,
    flags          = flags_copy,
    settings       = {
      music_volume = Settings.music_volume,
      sfx_volume   = Settings.sfx_volume,
    },
    play_time      = SaveManager._play_time,
    save_timestamp = os.time(),
  }

  local ok, err = pcall(function()
    love.filesystem.write(slot_filename(slot), Ser(save_data))
  end)

  if not ok then
    print("[SaveManager] Save failed (slot " .. slot .. "): " .. tostring(err))
    return false
  end

  SaveManager.current_slot = slot
  print("[SaveManager] Saved to slot " .. slot)
  return true
end

-- -------------------------------------------------------------------------
-- load(slot)
-- Reads the save file, restores all runtime state.
-- Returns ok (bool), save_data (table or nil).
-- -------------------------------------------------------------------------

function SaveManager.load(slot)
  slot = slot or SaveManager.current_slot
  local filename = slot_filename(slot)

  if not love.filesystem.getInfo(filename) then
    print("[SaveManager] No file for slot " .. slot)
    return false, nil
  end

  local ok, save_data = pcall(function()
    local contents = love.filesystem.read(filename)
    local fn = load(contents)
    assert(type(fn) == "function", "Save file parse error")
    return fn()
  end)

  if not ok or type(save_data) ~= "table" then
    print("[SaveManager] Load failed (slot " .. slot .. "): " .. tostring(save_data))
    return false, nil
  end

  save_data = SaveManager.migrate(save_data)

  -- Restore flags
  Flags._store = {}
  for k, v in pairs(save_data.flags or {}) do
    Flags._store[k] = v
  end

  -- Restore inventory
  Inventory.items  = {}
  for k, v in pairs(save_data.inventory or {}) do
    Inventory.items[k] = v
  end
  Inventory.lumens = save_data.lumens or 0

  -- Restore party
  PartyManager.party   = {}
  PartyManager.storage = {}
  for _, ld in ipairs(save_data.party or {}) do
    PartyManager.party[#PartyManager.party + 1] = deserialize_lumin(ld)
  end
  for _, ld in ipairs(save_data.storage or {}) do
    PartyManager.storage[#PartyManager.storage + 1] = deserialize_lumin(ld)
  end

  -- Restore settings
  local s = save_data.settings
  if s then
    if s.music_volume then Settings.music_volume = s.music_volume end
    if s.sfx_volume   then Settings.sfx_volume   = s.sfx_volume   end
  end

  -- Update SaveManager tracking fields
  SaveManager._play_time     = save_data.play_time or 0
  SaveManager._current_map   = save_data.current_map  or "assets/maps/willowfen_town.lua"
  SaveManager._current_spawn = save_data.spawn_id     or "default"
  SaveManager.current_slot   = slot

  print("[SaveManager] Loaded slot " .. slot)
  return true, save_data
end

-- -------------------------------------------------------------------------
-- exists(slot) / delete(slot)
-- -------------------------------------------------------------------------

function SaveManager.exists(slot)
  return love.filesystem.getInfo(slot_filename(slot)) ~= nil
end

function SaveManager.delete(slot)
  if SaveManager.exists(slot) then
    love.filesystem.remove(slot_filename(slot))
    print("[SaveManager] Deleted slot " .. slot)
  end
end

-- -------------------------------------------------------------------------
-- getMetadata(slot)
-- Reads only metadata fields without applying state to the runtime.
-- Returns { play_time, save_timestamp, map_name } or nil if no save.
-- -------------------------------------------------------------------------

function SaveManager.getMetadata(slot)
  local filename = slot_filename(slot)
  if not love.filesystem.getInfo(filename) then return nil end

  local ok, save_data = pcall(function()
    local contents = love.filesystem.read(filename)
    local fn = load(contents)
    assert(type(fn) == "function")
    return fn()
  end)

  if not ok or type(save_data) ~= "table" then return nil end

  return {
    play_time      = save_data.play_time or 0,
    save_timestamp = save_data.save_timestamp,
    map_name       = save_data.current_map or "",
  }
end

-- -------------------------------------------------------------------------
-- newGame(slot)
-- Initialises a fresh play session and writes the first save immediately.
-- -------------------------------------------------------------------------

function SaveManager.newGame(slot)
  -- Clear all runtime state
  Flags._store         = {}
  Inventory.items      = {}
  Inventory.lumens     = 0
  PartyManager.party   = {}
  PartyManager.storage = {}

  -- Starting party: Pip at level 5
  PartyManager.party[1] = Lumin.new("pip", 5)

  -- Starting inventory per game design spec
  Inventory.items["potion"]             = 3
  Inventory.items["lightglass_lantern"] = 5
  Inventory.lumens                      = 100

  -- Reset tracking
  SaveManager._play_time     = 0
  SaveManager._current_map   = "assets/maps/willowfen_town.lua"
  SaveManager._current_spawn = "default"
  SaveManager.current_slot   = slot

  -- Write initial save so slot shows up immediately
  SaveManager.save(slot)
end

-- -------------------------------------------------------------------------
-- update(dt) — call from love.update to accumulate play time
-- -------------------------------------------------------------------------

function SaveManager.update(dt)
  SaveManager._play_time = SaveManager._play_time + dt
end

-- -------------------------------------------------------------------------
-- Event hooks
-- -------------------------------------------------------------------------

-- Track the active map whenever any map loads (initial load or warp)
Events.on("map_loaded", function(data)
  if data then
    SaveManager._current_map   = data.map
    SaveManager._current_spawn = data.spawn
  end
end)

-- Autosave after every warp (map_loaded has already updated _current_map)
Events.on("warp_completed", function()
  SaveManager.save(SaveManager.current_slot)
end)

return SaveManager
