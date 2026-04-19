-- Overworld state
-- Loads a Tiled map, runs player movement + camera, draws the world.

local Input      = require("src.core.input")
local MapManager = require("src.world.mapmanager")
local Camera     = require("src.world.camera")
local Player     = require("src.entities.player")

local Overworld = {}
Overworld.__index = Overworld

-- Default map loaded when the state is first entered without params.
local DEFAULT_MAP  = "assets/maps/test_room.tmx"
local DEFAULT_SPAWN = "default"

function Overworld:enter(params)
  params = params or {}
  local map_path = params.map   or DEFAULT_MAP
  local spawn_id = params.spawn or DEFAULT_SPAWN

  -- Load map: returns the spawn-point position
  local spawn = MapManager.load(map_path, spawn_id)

  -- Create player at spawn position
  -- Offset so the player is centred on the spawn tile
  local px = spawn.x + (32 - 20) / 2   -- centre 20px hitbox in 32px tile
  local py = spawn.y + (32 - 26) / 2
  self.player = Player.new(px, py)

  -- Set up camera (follow style and lerp configured in Camera.new())
  self.camera = Camera.new()
  self.camera:setBounds(0, 0, MapManager.pixelWidth(), MapManager.pixelHeight())

  -- Immediately snap camera to player (no initial lerp-in)
  local cx, cy = self.player:center()
  self.camera:follow(cx, cy)
  self.camera:update(0)
end

function Overworld:exit()
  -- Future: pause music, etc.
end

function Overworld:update(dt)
  if Input.wasPressed("pause") then
    local StateManager = require("src.states.statemanager")
    StateManager.pop()
    return
  end

  MapManager.update(dt)
  self.player:update(dt)

  local cx, cy = self.player:center()
  self.camera:follow(cx, cy)
  self.camera:update(dt)
end

function Overworld:draw()
  self.camera:attach()
    MapManager.drawBelow()
    self.player:draw()
    MapManager.drawAbove()
  self.camera:detach()
  self.camera:draw()  -- flash/fade overlays from STALKER-X

  -- Debug: show facing and position in corner
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, 220, 36)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.setFont(love.graphics.newFont(12))
  love.graphics.print(
    string.format("x:%.0f y:%.0f  facing:%s  [Esc=menu]",
      self.player.x, self.player.y, self.player.facing),
    6, 10)
  love.graphics.setColor(1, 1, 1, 1)
end

function Overworld:keypressed(key) end

return Overworld
