-- EntityManager
-- Maintains the list of all active entities on the current map.
-- Draws entities sorted by Y position (painter's algorithm depth order).
--
-- Usage:
--   EntityManager.add(entity)
--   EntityManager.update(dt)   -- in Overworld:update
--   EntityManager.draw()       -- between MapManager.drawBelow/drawAbove
--   EntityManager.clear()      -- on map unload

local EntityManager = {}

local entities = {}

function EntityManager.add(entity)
  entities[#entities + 1] = entity
end

function EntityManager.remove(entity)
  for i = #entities, 1, -1 do
    if entities[i] == entity then
      table.remove(entities, i)
      return
    end
  end
end

function EntityManager.update(dt)
  for i = #entities, 1, -1 do
    local e = entities[i]
    if e.active then
      e:update(dt)
    else
      table.remove(entities, i)
    end
  end
end

-- Draw all active entities sorted by Y (bottom of sprite = e.y + height).
-- Entities with a higher Y value render on top (appear closer to the viewer).
function EntityManager.draw()
  -- Stable sort by bottom edge (y + h if available, else y)
  local sorted = {}
  for _, e in ipairs(entities) do
    if e.active then sorted[#sorted + 1] = e end
  end
  table.sort(sorted, function(a, b)
    local ay = a.y + (a.h or 0)
    local by = b.y + (b.h or 0)
    return ay < by
  end)
  for _, e in ipairs(sorted) do
    e:draw()
  end
end

function EntityManager.clear()
  entities = {}
end

function EntityManager.getAll()
  return entities
end

return EntityManager
