-- Central library loader
-- Usage: local Libs = require("lib")
-- Then: Libs.bump, Libs.anim8, Libs.camera, Libs.Timer, Libs.Signal, Libs.Vector

local Libs = {}

Libs.bump   = require("lib.bump.bump")
Libs.anim8  = require("lib.anim8.anim8")
Libs.camera = require("lib.stalker-x.camera")
Libs.Timer  = require("lib.hump.timer")
Libs.Signal = require("lib.hump.signal")
Libs.Vector = require("lib.hump.vector")
Libs.Ser    = require("lib.ser.Ser")
Libs.sti    = require("lib.sti.init")

return Libs
