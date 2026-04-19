-- Camera — canvas-based 2× pixel-art zoom + STALKER-X follow
--
-- Renders the world to a 640×360 logical canvas, then scales it 2× to fill
-- the 1280×720 window. This gives pixel-perfect output and correct bounds.
--
-- Usage:
--   local Camera = require("src.world.camera")
--   local cam = Camera.new()
--   cam:setBounds(0, 0, mapPixelW, mapPixelH)
--
--   -- update:
--   cam:follow(px, py)
--   cam:update(dt)
--
--   -- draw:
--   cam:attach()          -- redirect draw calls to logical canvas
--     MapManager.drawBelow()
--     player:draw()
--     MapManager.drawAbove()
--   cam:detach()          -- flush canvas to screen at 2×
--   cam:draw()            -- STALKER-X flash/fade overlays

local CameraLib = require("lib.stalker-x.camera")

-- Logical resolution (world pixels visible at once).
-- At SCALE=2 this fills a 1280×720 window exactly.
local SCALE   = 2
local LOGI_W  = 640   -- love.graphics.getWidth()  / SCALE
local LOGI_H  = 360   -- love.graphics.getHeight() / SCALE

local Camera = {}
Camera.__index = Camera

function Camera.new()
  local canvas = love.graphics.newCanvas(LOGI_W, LOGI_H)
  canvas:setFilter("nearest", "nearest")   -- pixel-perfect upscale

  -- STALKER-X camera sized to the logical canvas (no internal scale)
  local inner = CameraLib(LOGI_W/2, LOGI_H/2, LOGI_W, LOGI_H)
  inner:setFollowStyle("TOPDOWN")
  inner:setFollowLerp(0.08)

  return setmetatable({
    _cam    = inner,
    _canvas = canvas,
  }, Camera)
end

-- Set world bounds in logical (world) pixels.
function Camera:setBounds(x, y, w, h)
  self._cam:setBounds(x, y, w, h)
end

function Camera:follow(x, y)
  self._cam:follow(x, y)
end

function Camera:update(dt)
  self._cam:update(dt)
end

-- Begin rendering to the logical canvas.
function Camera:attach()
  love.graphics.setCanvas(self._canvas)
  love.graphics.clear()
  self._cam:attach()
end

-- Stop rendering to canvas, draw it scaled to the window.
function Camera:detach()
  self._cam:detach()
  love.graphics.setCanvas()   -- back to screen

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self._canvas, 0, 0, 0, SCALE, SCALE)
end

-- STALKER-X screen-space overlays (flash, fade). Drawn at full window size.
function Camera:draw()
  self._cam:draw()
end

function Camera:shake(intensity, duration)
  self._cam:shake(intensity, duration, 60)
end

-- Convert a world position to screen (window) coordinates.
function Camera:toScreen(wx, wy)
  local cx, cy = self._cam:toCameraCoords(wx, wy)
  return cx * SCALE, cy * SCALE
end

-- Expose logical dimensions for external use (e.g. UI layout).
Camera.logicalWidth  = LOGI_W
Camera.logicalHeight = LOGI_H
Camera.scale         = SCALE

return Camera
