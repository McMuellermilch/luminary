-- Inventory
-- Global item store: item_id → count.
-- Key items (type="key") have no quantity — they are present (1) or absent.
-- Lumens (currency) tracked as Inventory.lumens.
-- Serialised in Phase 11.

local Events = require("src.core.events")
local Items  = require("src.data.items")

local Inventory = {}

Inventory.items  = {}   -- { [item_id] = count }
Inventory.lumens = 0    -- currency

-- -------------------------------------------------------------------------

function Inventory.add(item_id, count)
  count = count or 1
  local def = Items[item_id]
  assert(def, "Inventory.add: unknown item '" .. tostring(item_id) .. "'")
  if def.type == "key" then
    -- Key items have no count — present or not
    Inventory.items[item_id] = 1
  else
    Inventory.items[item_id] = (Inventory.items[item_id] or 0) + count
  end
end

-- Removes `count` of item_id. Errors if not enough in inventory.
function Inventory.remove(item_id, count)
  count = count or 1
  local current = Inventory.items[item_id] or 0
  assert(current >= count,
    "Inventory.remove: not enough '" .. item_id .. "' (have " .. current .. ", need " .. count .. ")")
  local new_count = current - count
  Inventory.items[item_id] = new_count > 0 and new_count or nil
end

function Inventory.count(item_id)
  return Inventory.items[item_id] or 0
end

function Inventory.has(item_id, count)
  return Inventory.count(item_id) >= (count or 1)
end

-- Returns all items as a sorted list: { { id, def, count }, ... }
function Inventory.all()
  local result = {}
  for id, count in pairs(Inventory.items) do
    local def = Items[id]
    if def then
      result[#result + 1] = { id = id, def = def, count = count }
    end
  end
  table.sort(result, function(a, b) return a.def.name < b.def.name end)
  return result
end

-- Returns only key items: { { id, def }, ... }
function Inventory.keyItems()
  local result = {}
  for id, _ in pairs(Inventory.items) do
    local def = Items[id]
    if def and def.type == "key" then
      result[#result + 1] = { id = id, def = def }
    end
  end
  return result
end

-- -------------------------------------------------------------------------
-- Award Lumens from enemy loot drops.
-- -------------------------------------------------------------------------
Events.on("enemy_defeated", function(data)
  local lumens = data.loot_lumens or 0
  if lumens > 0 then
    Inventory.lumens = Inventory.lumens + lumens
  end
end)

return Inventory
