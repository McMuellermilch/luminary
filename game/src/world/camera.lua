-- Camera wrapper around STALKER-X
-- Usage:
--   local Camera = require("src.world.camera")
--   local cam = Camera.new()
--   cam:setBounds(0, 0, mapW, mapH)
--   cam:setFollowStyle("TOPDOWN")
--   cam:setFollowLerp(0.08)
--
--   -- In update:
--   cam:follow(player.x + player.w/2, player.y + player.h/2)
--   cam:update(dt)
--
--   -- In draw:
--   cam:attach()
--     -- draw world
--   cam:detach()
--   cam:draw()  -- flash/fade overlays

local CameraLib = require("lib.stalker-x.camera")

local Camera = {}
Camera.__index = Camera

function Camera.new()
  local w, h  = love.graphics.getDimensions()
  local inner = CameraLib(w/2, h/2, w, h)
  inner:setFollowStyle("TOPDOWN")
  inner:setFollowLerp(0.08)  -- smooth chase, not instant lock

  return setmetatable({ _cam = inner }, Camera)
end

-- Set world bounds so the camera never shows outside the map.
-- x, y = top-left of map in world coords (usually 0, 0)
-- w, h = pixel dimensions of the full map
function Camera:setBounds(x, y, w, h)
  self._cam:setBounds(x, y, w, h)
end

-- Tell the camera where to move toward this frame.
function Camera:follow(x, y)
  self._cam:follow(x, y)
end

-- Must be called every frame after follow().
function Camera:update(dt)
  self._cam:update(dt)
end

-- Call before drawing world-space content.
function Camera:attach()
  self._cam:attach()
end

-- Call after drawing world-space content.
function Camera:detach()
  self._cam:detach()
end

-- Draw screen-space overlays (flash, fade effects from STALKER-X).
function Camera:draw()
  self._cam:draw()
end

-- Trigger a screen shake.
-- intensity: pixel radius of shake (e.g. 4)
-- duration:  seconds (e.g. 0.2)
function Camera:shake(intensity, duration)
  self._cam:shake(intensity, duration, 60)
end

-- Convert a world-space position to screen-space (useful for UI anchoring).
function Camera:toScreen(wx, wy)
  return self._cam:toCameraCoords(wx, wy)
end

return Camera
