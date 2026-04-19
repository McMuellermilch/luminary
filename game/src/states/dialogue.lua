-- DialogueState
-- Pushed on top of OverworldState. The overworld remains visible behind it
-- (StateManager draws bottom→top). Only the top state receives update, so the
-- overworld pauses naturally while dialogue is active.
--
-- params:
--   dialogue_id (string) — key into src/data/dialogues.lua

local Input      = require("src.core.input")
local Events     = require("src.core.events")
local Dialogues  = require("src.data.dialogues")
local DialogueUI = require("src.ui.dialogue")

local DialogueState = {}
DialogueState.__index = DialogueState

function DialogueState:enter(params)
  params = params or {}
  self.dialogue_id = params.dialogue_id or ""

  local sequence = Dialogues[self.dialogue_id]
  assert(sequence, "DialogueState: unknown dialogue_id '" .. self.dialogue_id .. "'")

  self.sequence = sequence
  self.index    = 1
  self.box      = DialogueUI.new(self.sequence[self.index])
end

function DialogueState:exit() end

function DialogueState:update(dt)
  self.box:update(dt)

  if Input.wasPressed("confirm") then
    if not self.box:isComplete() then
      -- Skip typewriter — show full text immediately
      self.box:skip()
    else
      -- Advance to next line or close
      self.index = self.index + 1
      if self.index > #self.sequence then
        -- Dialogue finished
        local StateManager = require("src.states.statemanager")
        Events.emit("dialogue_complete", self.dialogue_id)
        StateManager.pop()
      else
        self.box = DialogueUI.new(self.sequence[self.index])
      end
    end
  end
end

function DialogueState:draw()
  -- The overworld underneath draws itself first (StateManager bottom→top).
  -- We only draw the dialogue box overlay here.
  self.box:draw()
end

function DialogueState:keypressed(key) end

return DialogueState
