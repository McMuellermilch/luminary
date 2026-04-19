-- Flags
-- Global key-value store for story and world state.
-- Values persist within a play session; serialised in Phase 11.
--
-- Naming convention: "region_event_detail"
-- Examples:
--   willowfen_beacon_lit   — Beacon Tower relit
--   cerin_intro_seen       — Cerin's intro dialogue completed
--   murk_defeated          — Umbral Guardian beaten
--   willowfen_shard_found  — Beacon Shard recovered

local Flags = {}

Flags._store = {}

function Flags.set(key, value)
  Flags._store[key] = value
end

function Flags.get(key)
  return Flags._store[key]
end

-- Returns true only if the flag is explicitly true.
function Flags.is(key)
  return Flags._store[key] == true
end

return Flags
