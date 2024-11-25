function love.conf(t)
    t.window.title = "PIsnake"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.touch = false
    
    t.version = "11.4"
    t.console = true
    
    t.window.vsync = true
    t.window.msaa = 0
    t.window.display = 1
    t.window.minwidth = 800
    t.window.minheight = 600
end
