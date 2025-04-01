function love.conf(t)
    t.title = "Mane Attraction"   -- The title of the window
    t.version = "11.5"      -- The LÖVE version this game was made for
    t.window.width = 1280   -- Game's screen width
    t.window.height = 720   -- Game's screen height
    t.window.vsync = 1      -- Enable vsync
    t.window.resizable = false -- Keep window size fixed

    -- Disable unused modules
    t.modules.joystick = false
    t.modules.physics = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.thread = false
end
