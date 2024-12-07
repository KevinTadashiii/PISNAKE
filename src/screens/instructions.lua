-- Instructions Module --

local constants = require('src.constants')
local BackgroundManager = require('src.graphics.background')

-- Style definitions for different text elements
-- Each style contains font size and color information
local STYLES = {
    MAIN_TITLE = {
        font_size = 24,
        color = {1, 1, 0},  -- Yellow for main headings
        shadow_color = {0, 0.3, 0},  -- Dark green shadow for depth
        shadow_offset = 2
    },
    TITLE = {
        font_size = 16,
        color = {1, 1, 0}  -- Yellow for section headings
    },
    NORMAL = {
        font_size = 14,
        color = {1, 1, 1}  -- White for regular text
    },
    RETURN = {
        font_size = 16,
        color_normal = {0, 1, 0},  -- Green for return text
        color_hover = {1, 1, 0}  -- Yellow on hover
    }
}

-- Instructions screen class
local Instructions = {}
Instructions.__index = Instructions

--- Creates a new Instructions screen instance
-- Initializes fonts, background, scroll state, and instruction content
-- @return Instructions The new instructions screen object
function Instructions.new()
    local self = setmetatable({}, Instructions)
    
    -- Initialize fonts for different text styles
    self.fonts = {
        title = love.graphics.newFont(constants.FONT_PATH, STYLES.MAIN_TITLE.font_size),
        instruction = love.graphics.newFont(constants.FONT_PATH, STYLES.TITLE.font_size),
        small = love.graphics.newFont(constants.FONT_PATH, STYLES.NORMAL.font_size)
    }
    
    -- Create background manager for visual effects
    self.bg_manager = BackgroundManager.new()
    
    -- Scroll state configuration
    self.scroll = {
        y = 0,              -- Current scroll position
        speed = 30,         -- Pixels per scroll step
        line_height = 25    -- Height of each line of text
    }
    
    -- UI interaction state
    self.hovering_return = false  -- Tracks if mouse is over return button
    
    -- Load instruction content
    self:init_instructions()
    
    return self
end

--- Initializes the instruction content with all game information
-- Organizes content into sections: Controls, Gameplay, and Tips
function Instructions:init_instructions()
    self.instructions = {
        {text = "HOW TO PLAY", style = "main_title"},
        {text = "", style = "normal"},  -- Spacing
        {text = "CONTROLS", style = "title"},
        {text = "↑ Up Arrow - Move Up", style = "normal"},
        {text = "↓ Down Arrow - Move Down", style = "normal"},
        {text = "← Left Arrow - Move Left", style = "normal"},
        {text = "→ Right Arrow - Move Right", style = "normal"},
        {text = "ESC - Pause Game", style = "normal"},
        {text = "", style = "normal"},  -- Section spacing
        {text = "GAMEPLAY", style = "title"},
        {text = "Eat food to grow longer", style = "normal"},
        {text = "Avoid hitting walls", style = "normal"},
        {text = "Don't collide with yourself", style = "normal"},
        {text = "", style = "normal"},  -- Section spacing
        {text = "TIPS", style = "title"},
        {text = "Plan your path ahead", style = "normal"},
        {text = "Use screen edges wisely", style = "normal"},
        {text = "Watch your tail length", style = "normal"},
        {text = "", style = "normal"},  -- Bottom spacing
        {text = "Press ENTER to return", style = "return"}
    }
end

--- Updates the instructions screen state
-- Handles background animation and mouse hover effects
-- @param dt number Delta time since last update
function Instructions:update(dt)
    self.bg_manager:update(dt)
    local mx, my = love.mouse.getPosition()
    self:handle_mouse_move(mx, my)
end

--- Handles mouse movement for hover effects on the return button
-- Updates hovering state based on mouse position
-- @param x number Mouse X position
-- @param y number Mouse Y position
function Instructions:handle_mouse_move(x, y)
    local return_text = "Press ENTER to return"
    local text_width = self.fonts.instruction:getWidth(return_text)
    local text_height = self.fonts.instruction:getHeight()
    
    -- Calculate return button hitbox position
    local y_offset = 50 + self.scroll.y
    for _, instruction in ipairs(self.instructions) do
        if instruction.style == "return" then
            -- Check if mouse is within return button bounds
            self.hovering_return = x >= constants.WINDOW_WIDTH/2 - text_width/2 and 
                                 x <= constants.WINDOW_WIDTH/2 + text_width/2 and
                                 y >= y_offset and 
                                 y <= y_offset + text_height
            break
        end
        y_offset = y_offset + self.scroll.line_height
    end
end

--- Handles mouse wheel movement for content scrolling
-- Adjusts scroll position based on wheel direction and content bounds
-- @param x number Horizontal scroll amount (unused)
-- @param y number Vertical scroll amount
function Instructions:wheelmoved(x, y)
    if y > 0 then  -- Scroll up
        -- Limit scrolling up to original position
        self.scroll.y = math.min(0, self.scroll.y + self.scroll.speed)
    elseif y < 0 then  -- Scroll down
        -- Calculate total content height
        local content_height = #self.instructions * self.scroll.line_height + 50
        if content_height > constants.WINDOW_HEIGHT then
            -- Limit scrolling down based on content height
            local max_scroll = -(content_height - constants.WINDOW_HEIGHT)
            self.scroll.y = math.max(max_scroll, self.scroll.y - self.scroll.speed)
        end
    end
end

--- Handles mouse button press events
-- Specifically handles clicking on the return button
-- @param x number Mouse X position
-- @param y number Mouse Y position
-- @param button number Button that was pressed
-- @return boolean True if should return to menu
function Instructions:mousepressed(x, y, button)
    if button == 1 then  -- Left click
        -- Check if click is within return button bounds
        local return_text = "Press ENTER to return"
        local text_width = self.fonts.instruction:getWidth(return_text)
        local text_height = self.fonts.instruction:getHeight()
        
        local y_offset = 50 + self.scroll.y
        for _, instruction in ipairs(self.instructions) do
            if instruction.style == "return" then
                if x >= constants.WINDOW_WIDTH/2 - text_width/2 and 
                   x <= constants.WINDOW_WIDTH/2 + text_width/2 and
                   y >= y_offset and 
                   y <= y_offset + text_height then
                    return true
                end
                break
            end
            y_offset = y_offset + self.scroll.line_height
        end
    end
    return false
end

--- Handles keyboard input
-- Currently only handles the return key
-- @param key string Key that was pressed
-- @return boolean True if should return to menu
function Instructions:keypressed(key)
    return key == 'return'
end

--- Draws text with specific style and effects
-- Handles different text styles including shadows and hover effects
-- @param text string Text to draw
-- @param style string Style name from STYLES table
-- @param y_offset number Vertical position to draw text
local function draw_styled_text(self, text, style, y_offset)
    if style == "main_title" then
        love.graphics.setFont(self.fonts.title)
        -- Draw shadow effect for main title
        love.graphics.setColor(STYLES.MAIN_TITLE.shadow_color)
        love.graphics.printf(text, STYLES.MAIN_TITLE.shadow_offset, 
                           y_offset + STYLES.MAIN_TITLE.shadow_offset, 
                           constants.WINDOW_WIDTH, "center")
        -- Draw main title text
        love.graphics.setColor(STYLES.MAIN_TITLE.color)
        love.graphics.printf(text, 0, y_offset, constants.WINDOW_WIDTH, "center")
        
    elseif style == "title" then
        -- Draw section titles
        love.graphics.setFont(self.fonts.instruction)
        love.graphics.setColor(STYLES.TITLE.color)
        love.graphics.printf(text, 0, y_offset, constants.WINDOW_WIDTH, "center")
        
    elseif style == "return" then
        -- Draw return button with hover effect
        love.graphics.setFont(self.fonts.instruction)
        local alpha = math.abs(math.sin(love.timer.getTime() * 3))  -- Pulsing effect
        local color = self.hovering_return and STYLES.RETURN.color_hover or STYLES.RETURN.color_normal
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.printf(text, 0, y_offset, constants.WINDOW_WIDTH, "center")
        
    else  -- normal style
        -- Draw regular instruction text
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(STYLES.NORMAL.color)
        love.graphics.printf(text, 0, y_offset, constants.WINDOW_WIDTH, "center")
    end
end

--- Draws the complete instructions screen
-- Renders background and all instruction text with appropriate styling
function Instructions:draw()
    -- Draw animated background
    self.bg_manager:draw()
    
    -- Draw all instruction text with scroll offset
    local y_offset = 50 + self.scroll.y
    
    for _, instruction in ipairs(self.instructions) do
        -- Only draw text if it's within visible area
        if -50 <= y_offset and y_offset <= constants.WINDOW_HEIGHT + 50 then
            draw_styled_text(self, instruction.text, instruction.style, y_offset)
        end
        y_offset = y_offset + self.scroll.line_height
    end
    
    -- Reset color to default
    love.graphics.setColor(1, 1, 1)
end

return Instructions
