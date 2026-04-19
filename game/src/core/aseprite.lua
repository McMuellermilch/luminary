-- Aseprite JSON Loader
-- Reads an Aseprite-exported PNG + JSON and returns a table of named anim8
-- animations keyed by the tag names defined in the Aseprite frameTags field.
--
-- Usage:
--   local Aseprite = require("src.core.aseprite")
--   local result = Aseprite.load("assets/sprites/luma.png",
--                                "assets/sprites/luma.json")
--   -- result.image    → Love2D Image
--   -- result.anims    → { walk_down = <anim8 anim>, idle_up = <anim8 anim>, ... }
--
-- JSON format expected: Aseprite array-format export
--   frames[i].frame  = { x, y, w, h }
--   frames[i].duration = ms
--   meta.frameTags[i] = { name, from, to }   (0-based frame indices)

local anim8 = require("lib.anim8.anim8")
local json  = require("lib.json")

local Aseprite = {}

-- Cache loaded results so the same file is not re-parsed on every map load.
local cache = {}

function Aseprite.load(png_path, json_path)
  local key = png_path .. "|" .. json_path
  if cache[key] then return cache[key] end

  -- ---- Load image ----
  local image = love.graphics.newImage(png_path)
  image:setFilter("nearest", "nearest")
  local iw, ih = image:getDimensions()

  -- ---- Parse JSON ----
  local raw = love.filesystem.read(json_path)
  assert(raw, "Aseprite.load: cannot read " .. json_path)
  local data = json.decode(raw)

  -- ---- Build quads array (0-based in JSON → 1-based in Lua) ----
  local quads    = {}
  local dur_secs = {}
  for _, f in ipairs(data.frames) do
    local fr = f.frame
    quads[#quads + 1]    = love.graphics.newQuad(fr.x, fr.y, fr.w, fr.h, iw, ih)
    dur_secs[#dur_secs + 1] = (f.duration or 150) / 1000
  end

  -- ---- Build named animations from frameTags ----
  local anims = {}
  for _, tag in ipairs(data.meta.frameTags) do
    -- tag.from / tag.to are 0-based indices
    local tag_quads = {}
    local tag_durs  = {}
    for i = tag["from"], tag["to"] do   -- 0-based range
      local lua_i = i + 1               -- 1-based
      tag_quads[#tag_quads + 1] = quads[lua_i]
      tag_durs[#tag_durs + 1]   = dur_secs[lua_i]
    end
    anims[tag.name] = anim8.newAnimation(tag_quads, tag_durs)
  end

  local result = { image = image, anims = anims }
  cache[key] = result
  return result
end

-- Clear the cache (call on full game restart if needed).
function Aseprite.clearCache()
  cache = {}
end

return Aseprite
