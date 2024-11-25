local constants = require('src.constants')
local BackgroundManager = require('src.graphics.background')

local Instructions = {}
Instructions.__index = Instructions

function Instructions.new()
    local self = setmetatable({}, Instructions)
    
    -- Initialize fonts
    self.title_font = love.graphics.newFont(constants.FONT_PATH, 24)
    self.instruction_font = love.graphics.newFont(constants.FONT_PATH, 16)
    self.small_font = love.graphics.newFont(constants.FONT_PATH, 14)
    
    -- Initialize background manager
    self.bg_manager = BackgroundManager.new()
    
    -- Initialize scroll position and hover state
    self.scroll_y = 0
    self.scroll_speed = 30
    self.hovering_return = false
    
    -- Instructions text
    self.instructions = {
        {text = "HOW TO PLAY", style = "main_title"},
        {text = "", style = "normal"},
        {text = "CONTROLS", style = "title"},
        {text = "↑ Up Arrow - Move Up", style = "normal"},
        {text = "↓ Down Arrow - Move Down", style = "normal"},
        {text = "← Left Arrow - Move Left", style = "normal"},
        {text = "→ Right Arrow - Move Right", style = "normal"},
        {text = "ESC - Pause Game", style = "normal"},
        {text = "", style = "normal"},
        {text = "GAMEPLAY", style = "title"},
        {text = "Eat food to grow longer", style = "normal"},
        {text = "Avoid hitting walls", style = "normal"},
        {text = "Don't collide with yourself", style = "normal"},
        {text = "", style = "normal"},
        {text = "TIPS", style = "title"},
        {text = "Plan your path ahead", style = "normal"},
        {text = "Use screen edges wisely", style = "normal"},
        {text = "Watch your tail length", style = "normal"},
        {text = "", style = "normal"},
        {text = "Press ENTER to return", style = "return"}
    }
    
    return self
end

function Instructions:update(dt)
    self.bg_manager:update(dt)
    
    -- Handle mouse position for return button hover
    local mx, my = love.mouse.getPosition()
    self:handle_mouse_move(mx, my)
end

function Instructions:handle_mouse_move(x, y)
    -- Handle mouse movement for hover effects
    local return_text = "Press ENTER to return"
    local text_width = self.instruction_font:getWidth(return_text)
    local text_height = self.instruction_font:getHeight()
    
    -- Find the y position of the return text
    local y_offset = 50 + self.scroll_y
    for _, instruction in ipairs(self.instructions) do
        if instruction.style == "return" then
            -- Match the exact position where text is drawn with printf
            self.hovering_return = x >= constants.WINDOW_WIDTH/2 - text_width/2 and 
                                 x <= constants.WINDOW_WIDTH/2 + text_width/2 and
                                 y >= y_offset and 
                                 y <= y_offset + text_height
            break
        end
        y_offset = y_offset + 25
    end
end

function Instructions:wheelmoved(x, y)
    if y > 0 then  -- Mouse wheel up
        self.scroll_y = math.min(0, self.scroll_y + self.scroll_speed)
    elseif y < 0 then  -- Mouse wheel down
        -- Calculate content height
        local content_height = #self.instructions * 25 + 50  -- 25 pixels per line, 50 pixels initial offset
        if content_height > constants.WINDOW_HEIGHT then
            local max_scroll = -(content_height - constants.WINDOW_HEIGHT)
            self.scroll_y = math.max(max_scroll, self.scroll_y - self.scroll_speed)
        end
    end
end

function Instructions:mousepressed(x, y, button)
    if button == 1 then  -- Left click
        -- Use same hitbox calculation as hover
        local return_text = "Press ENTER to return"
        local text_width = self.instruction_font:getWidth(return_text)
        local text_height = self.instruction_font:getHeight()
        
        -- Find the y position of the return text
        local y_offset = 50 + self.scroll_y
        for _, instruction in ipairs(self.instructions) do
            if instruction.style == "return" then
                -- Match the exact position where text is drawn with printf
                if x >= constants.WINDOW_WIDTH/2 - text_width/2 and 
                   x <= constants.WINDOW_WIDTH/2 + text_width/2 and
                   y >= y_offset and 
                   y <= y_offset + text_height then
                    return true  -- Signal to return to menu
                end
                break
            end
            y_offset = y_offset + 25
        end
    end
    return false
end

function Instructions:keypressed(key)
    if key == 'return' then
        return true  -- Signal to return to menu
    end
    return false
end

function Instructions:draw()
    -- Draw background
    self.bg_manager:draw()
    
    -- Draw instructions with scroll offset
    local y_offset = 50 + self.scroll_y
    
    for _, instruction in ipairs(self.instructions) do
        if -50 <= y_offset and y_offset <= constants.WINDOW_HEIGHT + 50 then
            if instruction.style == "main_title" then
                -- Draw shadow for main title
                love.graphics.setFont(self.title_font)
                love.graphics.setColor(0, 0.3, 0)  -- Dark green
                love.graphics.printf(instruction.text, 2, y_offset + 2, constants.WINDOW_WIDTH, "center")
                
                -- Draw main text
                love.graphics.setColor(1, 1, 0)  -- Yellow
                love.graphics.printf(instruction.text, 0, y_offset, constants.WINDOW_WIDTH, "center")
                
            elseif instruction.style == "title" then
                love.graphics.setFont(self.instruction_font)
                love.graphics.setColor(1, 1, 0)  -- Yellow
                love.graphics.printf(instruction.text, 0, y_offset, constants.WINDOW_WIDTH, "center")
                
            elseif instruction.style == "return" then
                love.graphics.setFont(self.instruction_font)
                local alpha = math.abs(math.sin(love.timer.getTime() * 3))
                if self.hovering_return then
                    love.graphics.setColor(1, 1, 0, alpha)  -- Yellow with alpha
                else
                    love.graphics.setColor(0, 1, 0, alpha)  -- Green with alpha
                end
                love.graphics.printf(instruction.text, 0, y_offset, constants.WINDOW_WIDTH, "center")
                
            else
                love.graphics.setFont(self.small_font)
                love.graphics.setColor(1, 1, 1)  -- White
                love.graphics.printf(instruction.text, 0, y_offset, constants.WINDOW_WIDTH, "center")
            end
        end
        y_offset = y_offset + 25
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

return Instructions
