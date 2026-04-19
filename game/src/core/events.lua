-- Event bus — thin wrapper around hump.signal
-- Usage:
--   Events.on("beacon_relit", function(region) ... end)
--   Events.emit("beacon_relit", "willowfen")
--   Events.off("beacon_relit", handler)

local Signal = require("lib.hump.signal")

local Events = {}

function Events.on(event, callback)
  Signal.register(event, callback)
end

function Events.emit(event, ...)
  Signal.emit(event, ...)
end

function Events.off(event, callback)
  Signal.remove(event, callback)
end

return Events
