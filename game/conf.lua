function love.conf(t)
  t.title        = "Luminary"
  t.version      = "11.4"
  t.window.width  = 1280
  t.window.height = 720
  t.window.resizable = true
  t.window.minwidth  = 640
  t.window.minheight = 360
  t.window.msaa   = 0  -- pixel art, no anti-aliasing

  t.modules.joystick = true
  t.modules.gamepad  = true
  t.modules.audio    = true
end
