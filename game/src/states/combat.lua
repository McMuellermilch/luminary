-- CombatState
-- Reserved for scripted boss fights and story encounters.
-- Regular combat happens directly in the overworld (Secret of Mana style).

local Combat = {}
Combat.__index = Combat

function Combat:enter(params) self.params = params or {} end
function Combat:exit() end
function Combat:update(dt) end
function Combat:draw() end
function Combat:keypressed(key) end

return Combat
