-- Pause menu implementation for the snake game

local constants = require("src.constants")
local SettingsManager = require("src.settings.settings_manager")

local PauseMenu = {}
PauseMenu.__index = PauseMenu

function PauseMenu.new()
    local self = setmetatable({}, PauseMenu)
    self.options = {'Resume', 'Main Menu'}
    self.selected = 1  -- Lua uses 1-based indexing
    self.using_keyboard = false  -- Track if keyboard was last used
    self.mouse_interacting = false  -- Track if mouse is actually interacting with menu
    self.keyboard_priority = false  -- Track if keyboard should have priority
    self.last_mx = nil  -- Track last mouse x position
    self.last_my = nil  -- Track last mouse y position
    
    -- Load fonts
    self.title_font = love.graphics.newFont(constants.FONT_PATH, 36)
    self.option_font = love.graphics.newFont(constants.FONT_PATH, 24)
    self.score_font = love.graphics.newFont(constants.FONT_PATH, 16)
    
    -- Dynamic menu properties
    self.option_scales = {}
    self.option_colors = {}
    self.target_scales = {}
    self.target_colors = {}
    
    -- Initialize arrays
    for i = 1, #self.options do
        self.option_scales[i] = 1.0
        self.option_colors[i] = {1, 1, 1}  -- WHITE in LÖVE uses values from 0 to 1
        self.target_scales[i] = 1.0
        self.target_colors[i] = {1, 1, 1}
    end
    
    self.hover_scale = 1.2  -- Maximum scale when hovering
    self.animation_speed = 0.2  -- Speed of scale animation
    self.color_speed = 0.1  -- Speed of color transition
    
    -- Load sound effects
    self.settings_manager = SettingsManager.new()
    -- Create multiple hover sounds for rapid playback
    self.hover_sounds = {}
    for i = 1, 3 do  -- Create 3 sound sources
        self.hover_sounds[i] = love.audio.newSource(constants.HOVER_SOUND_PATH, "static")
        local volume = self.settings_manager:get_setting('sound_volume') or 70
        self.hover_sounds[i]:setVolume(1.4 * (volume / 100))
    end
    self.current_sound = 1
    
    -- Initialize hover effect for the first selected item
    self:_update_hover_effects()
    
    -- Disable key repeat
    love.keyboard.setKeyRepeat(false)
    
    return self
end

function PauseMenu:_update_hover_effects()
    -- Skip hover effects if terminal is active
    if terminal and terminal.active then
        return
    end

    -- Update hover effects for menu options
    for i = 1, #self.options do
        if i == self.selected then
            self.target_scales[i] = self.hover_scale
            self.target_colors[i] = {1, 1, 0}  -- Yellow in LÖVE2D
        else
            self.target_scales[i] = 1.0
            self.target_colors[i] = {1, 1, 1}  -- White in LÖVE2D
        end
    end
end

function PauseMenu:handle_input(key)
    -- Handle keyboard input
    if key then
        -- Switch to keyboard mode and give it priority
        self.using_keyboard = true
        self.mouse_interacting = false
        self.keyboard_priority = true
        
        if key == "escape" then
            return 'Resume'
        elseif key == "up" then
            self.selected = ((self.selected - 2) % #self.options) + 1
            self:_update_hover_effects()
            self:play_hover_sound()
        elseif key == "down" then
            self.selected = (self.selected % #self.options) + 1
            self:_update_hover_effects()
            self:play_hover_sound()
        elseif key == "return" then
            return self.options[self.selected]
        end
    end
    return nil
end

function PauseMenu:play_hover_sound()
    -- Skip playing sound if terminal is active
    if terminal and terminal.active then
        return
    end
    
    -- Find the next available (not playing) sound source
    local found = false
    local start = self.current_sound
    repeat
        if not self.hover_sounds[self.current_sound]:isPlaying() then
            found = true
        else
            self.current_sound = (self.current_sound % #self.hover_sounds) + 1
        end
    until found or self.current_sound == start

    -- If we found a free sound source, play it
    if found then
        self.hover_sounds[self.current_sound]:play()
        self.current_sound = (self.current_sound % #self.hover_sounds) + 1
    end
end

function PauseMenu:handle_mouse(mx, my)
    -- Track mouse movement to reset keyboard priority
    if not self.last_mx then
        self.last_mx = mx
        self.last_my = my
    end
    
    -- Reset keyboard priority if mouse has moved significantly
    if math.abs(mx - self.last_mx) > 1 or math.abs(my - self.last_my) > 1 then
        self.keyboard_priority = false
    end
    
    self.last_mx = mx
    self.last_my = my

    -- Skip hover effects if terminal is active
    if terminal and terminal.active then
        return nil
    end

    -- Handle mouse movement and clicks
    local menu_spacing = 60
    local old_selected = self.selected
    local is_over_menu = false
    
    for i, option in ipairs(self.options) do
        local hit_width = 200
        local option_x = constants.WINDOW_WIDTH / 2
        local option_y = constants.WINDOW_HEIGHT / 2 + 60 + (i - 1) * menu_spacing
        
        -- Calculate bounds
        local top_bound = option_y - menu_spacing/2
        local bottom_bound = option_y + menu_spacing/2
        
        -- Adjust bounds for first and last options
        if i == 1 then
            top_bound = option_y - menu_spacing/4
        elseif i == #self.options then
            bottom_bound = option_y + menu_spacing/2
        end
        
        -- Check if mouse is within the hit area
        if mx >= option_x - hit_width/2 and mx <= option_x + hit_width/2 and
           my >= top_bound and my <= bottom_bound then
            is_over_menu = true
            if not self.keyboard_priority then  -- Only interact if keyboard doesn't have priority
                self.mouse_interacting = true
                self.using_keyboard = false
                
                if self.selected ~= i then
                    self.selected = i
                    self:_update_hover_effects()
                    self:play_hover_sound()
                end
            end
            break
        end
    end
    
    -- If mouse moved away from menu, stop mouse interaction
    if not is_over_menu then
        self.mouse_interacting = false
    end
    
    return nil
end

function PauseMenu:mousepressed(x, y, button)
    -- Reset keyboard priority if mouse has moved significantly
    if self.last_mx and (math.abs(x - self.last_mx) > 1 or math.abs(y - self.last_my) > 1) then
        self.keyboard_priority = false
    end

    if button == 1 and not self.keyboard_priority then  -- Left click and no keyboard priority
        -- Handle mouse movement and clicks
        local menu_spacing = 60
        
        for i, option in ipairs(self.options) do
            local hit_width = 200
            local option_x = constants.WINDOW_WIDTH / 2
            local option_y = constants.WINDOW_HEIGHT / 2 + 60 + (i-1) * menu_spacing
            
            -- Calculate bounds
            local top_bound = option_y - menu_spacing/2
            local bottom_bound = option_y + menu_spacing/2
            
            -- Adjust bounds for first and last options
            if i == 1 then
                top_bound = option_y - menu_spacing/4
            elseif i == #self.options then
                bottom_bound = option_y + menu_spacing/2
            end
            
            -- Check if mouse is within the hit area
            if x >= option_x - hit_width/2 and x <= option_x + hit_width/2 and
               y >= top_bound and y <= bottom_bound then
                self.mouse_interacting = true
                self.using_keyboard = false
                return self.options[i]
            end
        end
    end
    return nil
end

function PauseMenu:mousemoved(x, y, dx, dy)
    self:handle_mouse(x, y)
end

function PauseMenu:update(dt)
    -- Update option scales with smooth animation
    for i = 1, #self.options do
        -- Scale animation
        if self.option_scales[i] ~= self.target_scales[i] then
            local diff = self.target_scales[i] - self.option_scales[i]
            self.option_scales[i] = self.option_scales[i] + diff * self.animation_speed
        end
        
        -- Color animation
        for j = 1, 3 do
            if self.option_colors[i][j] ~= self.target_colors[i][j] then
                local diff = self.target_colors[i][j] - self.option_colors[i][j]
                self.option_colors[i][j] = self.option_colors[i][j] + diff * self.color_speed
            end
        end
    end
end

function PauseMenu:draw(score)
    -- Create semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
    
    -- Only handle mouse if terminal is not active
    if not (terminal and terminal.active) then
        local mx, my = love.mouse.getPosition()
        self:handle_mouse(mx, my)
    end
    
    -- Draw "PAUSED" title with shadow
    love.graphics.setFont(self.title_font)
    -- Shadow
    love.graphics.setColor(constants.DARK_GREEN)
    love.graphics.print('PAUSED',
        constants.WINDOW_WIDTH/2 - self.title_font:getWidth('PAUSED')/2 + 2,
        constants.WINDOW_HEIGHT/4 + 2)
    -- Main text
    love.graphics.setColor(constants.SNAKE_GREEN)
    love.graphics.print('PAUSED',
        constants.WINDOW_WIDTH/2 - self.title_font:getWidth('PAUSED')/2,
        constants.WINDOW_HEIGHT/4)
    
    -- Draw score
    love.graphics.setFont(self.score_font)
    love.graphics.setColor(1, 1, 1)
    local score_text = "Score: " .. score
    love.graphics.print(score_text,
        constants.WINDOW_WIDTH/2 - self.score_font:getWidth(score_text)/2,
        constants.WINDOW_HEIGHT/2)
    
    -- Draw menu options
    for i = 1, #self.options do
        local base_size = 24
        local scale = self.option_scales[i]
        local scaled_size = math.floor(base_size * scale)
        local scaled_font = love.graphics.newFont(constants.FONT_PATH, scaled_size)
        
        love.graphics.setFont(scaled_font)
        love.graphics.setColor(self.option_colors[i])
        
        local text = self.options[i]
        local text_width = scaled_font:getWidth(text)
        local text_x = constants.WINDOW_WIDTH/2 - text_width/2
        local text_y = constants.WINDOW_HEIGHT/2 + 60 + (i-1) * 60
        
        -- Draw selection arrows if this option is selected
        if i == self.selected then
            local arrow_padding = 20 * scale
            local arrow_left = ">"
            local arrow_right = "<"
            
            love.graphics.print(arrow_left,
                text_x - arrow_padding - scaled_font:getWidth(arrow_left),
                text_y)
            love.graphics.print(arrow_right,
                text_x + text_width + arrow_padding,
                text_y)
        end
        
        -- Draw the menu option text
        love.graphics.print(text, text_x, text_y)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return PauseMenu