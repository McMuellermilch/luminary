-- ItemUse
-- Dispatches item use by type. Called by menus/UI (Phase 12) and combat.
--
-- target: a Lumin instance (for heal items) or nil.
-- Capture items are handled by CaptureSystem in the overworld; ItemUse
-- simply returns an informational message if attempted here.

local Items     = require("src.data.items")
local Inventory = require("src.creatures.inventory")
local Events    = require("src.core.events")

local ItemUse = {}

-- Use one of item_id on target. Returns true on success, false + reason on failure.
function ItemUse.use(item_id, target)
  local def = Items[item_id]
  if not def then return false, "Unknown item." end
  if not Inventory.has(item_id, 1) then return false, "None in inventory." end

  if def.type == "heal" then
    if not (target and target.hp ~= nil) then
      return false, "No valid target."
    end
    local restore = def.heal_amount or 30
    target.hp = math.min(target.max_hp, target.hp + restore)
    Inventory.remove(item_id)
    Events.emit("item_used", item_id, target)
    return true

  elseif def.type == "heal_full" then
    if not (target and target.hp ~= nil) then
      return false, "No valid target."
    end
    target.hp = target.max_hp
    Inventory.remove(item_id)
    Events.emit("item_used", item_id, target)
    return true

  elseif def.type == "capture" then
    -- Capture flow is driven by CaptureSystem in the overworld (press Q).
    return false, "Use a Lightglass Lantern in the overworld (press Q near an enemy)."

  elseif def.type == "key" then
    return false, "Key items cannot be used directly."

  else
    return false, "Cannot use this item."
  end
end

return ItemUse
