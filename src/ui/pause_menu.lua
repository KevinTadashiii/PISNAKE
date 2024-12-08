-- PauseMenu Module --

local constants = require("src.constants")
local SettingsManager = require("src.settings.settings_manager")

-- Menu configuration constants
local UI = {
    MENU = {
        OPTIONS = {'Resume', 'Main Menu'},
        SPACING = 60,
        HIT_WIDTH = 200,
        BASE_FONT_SIZE = 24,
        ARROW_PADDING = 20
    },
    TITLE = {
        FONT_SIZE = 36,
        Y_POSITION = 1/4,  -- Fraction of screen height
        SHADOW_OFFSET = 2,
        PULSE_SPEED = 2,  -- Speed of the pulsing animation
        PULSE_AMOUNT = 0.1  -- Amount of scale variation
    },
    SCORE = {
        FONT_SIZE = 16,
        Y_POSITION = 1/2,  -- Fraction of screen height
        FADE_SPEED = 2  -- Speed of the fade animation
    },
    ANIMATION = {
        HOVER_SCALE = 1.2,
        SCALE_SPEED = 0.2,
        COLOR_SPEED = 0.1,
        HOVER_SOUNDS = 3,  -- Number of sound sources for hover effect
        SOUND_VOLUME_MULT = 1.4,
        WAVE_SPEED = 3,  -- Speed of the wave animation
        WAVE_AMOUNT = 5  -- Amount of vertical wave movement
    },
}

local PauseMenu = {}
PauseMenu.__index = PauseMenu

-- Initialize a new pause menu instance
function PauseMenu.new()
    local self = setmetatable({}, PauseMenu)
    
    -- Menu state
    self.options = UI.MENU.OPTIONS
    self.selected = 1
    self.using_keyboard = false
    self.mouse_interacting = false
    self.keyboard_priority = false
    self.last_mx = nil
    self.last_my = nil
    
    -- Animation state
    self.time = 0
    self.wave_offset = 0
    self.title_scale = 1.0
    self.score_alpha = 1.0
    
    -- Load fonts
    self.title_font = love.graphics.newFont(constants.FONT_PATH, UI.TITLE.FONT_SIZE)
    self.option_font = love.graphics.newFont(constants.FONT_PATH, UI.MENU.BASE_FONT_SIZE)
    self.score_font = love.graphics.newFont(constants.FONT_PATH, UI.SCORE.FONT_SIZE)
    
    -- Initialize animation arrays
    self.option_scales = {}
    self.option_colors = {}
    self.target_scales = {}
    self.target_colors = {}
    
    for i = 1, #self.options do
        self.option_scales[i] = 1.0
        self.option_colors[i] = {1, 1, 1} 
        self.target_scales[i] = 1.0
        self.target_colors[i] = {1, 1, 1}
    end
    
    -- Animation properties
    self.hover_scale = UI.ANIMATION.HOVER_SCALE
    self.animation_speed = UI.ANIMATION.SCALE_SPEED
    self.color_speed = UI.ANIMATION.COLOR_SPEED
    
    -- Initialize sound effects
    self:init_sound_effects()
    
    -- Set initial hover effect
    self:_update_hover_effects()
    
    -- Disable key repeat for menu navigation
    love.keyboard.setKeyRepeat(false)
    
    return self
end

-- Initialize sound effects for menu interaction
function PauseMenu:init_sound_effects()
    self.settings_manager = SettingsManager.new()
    self.hover_sounds = {}
    
    local volume = self.settings_manager:get_setting('sound_volume') or 70
    local adjusted_volume = UI.ANIMATION.SOUND_VOLUME_MULT * (volume / 100)
    
    for i = 1, UI.ANIMATION.HOVER_SOUNDS do
        self.hover_sounds[i] = love.audio.newSource(constants.HOVER_SOUND_PATH, "static")
        self.hover_sounds[i]:setVolume(adjusted_volume)
    end
    self.current_sound = 1
end

-- Update hover effects for menu options
function PauseMenu:_update_hover_effects()
    if terminal and terminal.active then return end
    
    for i = 1, #self.options do
        if i == self.selected then
            self.target_scales[i] = self.hover_scale
            self.target_colors[i] = {1, 1, 0}
        else
            self.target_scales[i] = 1.0
            self.target_colors[i] = {1, 1, 1}
        end
    end
end

-- Handle keyboard input for menu navigation
function PauseMenu:handle_input(key)
    if not key then return nil end
    
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
    return nil
end

-- Play hover sound effect with multiple sound sources
function PauseMenu:play_hover_sound()
    if terminal and terminal.active then return end
    
    local found = false
    local start = self.current_sound
    repeat
        if not self.hover_sounds[self.current_sound]:isPlaying() then
            found = true
        else
            self.current_sound = (self.current_sound % #self.hover_sounds) + 1
        end
    until found or self.current_sound == start
    
    if found then
        self.hover_sounds[self.current_sound]:play()
        self.current_sound = (self.current_sound % #self.hover_sounds) + 1
    end
end

-- Handle mouse movement and hover effects
function PauseMenu:handle_mouse(mx, my)
    self:update_mouse_position(mx, my)
    if terminal and terminal.active then return nil end
    
    local is_over_menu = false
    for i, option in ipairs(self.options) do
        local option_y = constants.WINDOW_HEIGHT / 2 + 60 + (i - 1) * UI.MENU.SPACING
        local bounds = self:get_option_bounds(i, option_y)
        
        if self:is_mouse_over_option(mx, my, bounds) then
            is_over_menu = true
            if not self.keyboard_priority then
                self:handle_option_hover(i)
            end
            break
        end
    end
    
    self.mouse_interacting = is_over_menu
    return nil
end

-- Update stored mouse position
function PauseMenu:update_mouse_position(mx, my)
    if not self.last_mx then
        self.last_mx = mx
        self.last_my = my
    end
    
    if math.abs(mx - self.last_mx) > 1 or math.abs(my - self.last_my) > 1 then
        self.keyboard_priority = false
    end
    
    self.last_mx = mx
    self.last_my = my
end

-- Calculate bounds for a menu option
function PauseMenu:get_option_bounds(index, y)
    local top = y - UI.MENU.SPACING/2
    local bottom = y + UI.MENU.SPACING/2
    
    if index == 1 then
        top = y - UI.MENU.SPACING/4
    elseif index == #self.options then
        bottom = y + UI.MENU.SPACING/2
    end
    
    return {
        top = top,
        bottom = bottom,
        left = constants.WINDOW_WIDTH/2 - UI.MENU.HIT_WIDTH/2,
        right = constants.WINDOW_WIDTH/2 + UI.MENU.HIT_WIDTH/2
    }
end

-- Check if mouse is over a menu option
function PauseMenu:is_mouse_over_option(mx, my, bounds)
    return mx >= bounds.left and mx <= bounds.right and
           my >= bounds.top and my <= bounds.bottom
end

-- Handle hover effect for a menu option
function PauseMenu:handle_option_hover(index)
    self.mouse_interacting = true
    self.using_keyboard = false
    
    if self.selected ~= index then
        self.selected = index
        self:_update_hover_effects()
        self:play_hover_sound()
    end
end

-- Handle mouse click events
function PauseMenu:mousepressed(x, y, button)
    if self.last_mx and (math.abs(x - self.last_mx) > 1 or math.abs(y - self.last_my) > 1) then
        self.keyboard_priority = false
    end

    if button == 1 and not self.keyboard_priority then
        for i, option in ipairs(self.options) do
            local option_y = constants.WINDOW_HEIGHT/2 + 60 + (i-1) * UI.MENU.SPACING
            local bounds = self:get_option_bounds(i, option_y)
            
            if self:is_mouse_over_option(x, y, bounds) then
                self.mouse_interacting = true
                self.using_keyboard = false
                return self.options[i]
            end
        end
    end
    return nil
end

-- Handle mouse movement events
function PauseMenu:mousemoved(x, y, dx, dy)
    self:handle_mouse(x, y)
end

-- Update menu animations
function PauseMenu:update(dt)
    -- Update animation time
    self.time = self.time + dt
    
    -- Update title pulsing
    self.title_scale = 1.0 + math.sin(self.time * UI.TITLE.PULSE_SPEED) * UI.TITLE.PULSE_AMOUNT
    
    -- Update wave animation
    self.wave_offset = self.wave_offset + UI.ANIMATION.WAVE_SPEED * dt
    
    -- Update score fade
    self.score_alpha = 0.7 + math.sin(self.time * UI.SCORE.FADE_SPEED) * 0.3
    
    -- Update option animations
    for i = 1, #self.options do
        -- Scale animation
        local scale_diff = self.target_scales[i] - self.option_scales[i]
        self.option_scales[i] = self.option_scales[i] + scale_diff * self.animation_speed
        
        -- Color animation
        for j = 1, 3 do
            local color_diff = self.target_colors[i][j] - self.option_colors[i][j]
            self.option_colors[i][j] = self.option_colors[i][j] + color_diff * self.color_speed
        end
    end
end

-- Draw the pause menu
function PauseMenu:draw(score)
    self:draw_overlay()
    
    if not (terminal and terminal.active) then
        local mx, my = love.mouse.getPosition()
        self:handle_mouse(mx, my)
    end
    
    self:draw_title()
    self:draw_score(score)
    self:draw_menu_options()
    
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

-- Draw semi-transparent overlay
function PauseMenu:draw_overlay()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
end

-- Draw the "PAUSED" title
function PauseMenu:draw_title()
    love.graphics.setFont(self.title_font)
    local text = 'PAUSED'
    local x = constants.WINDOW_WIDTH/2 - self.title_font:getWidth(text)/2 * self.title_scale
    local y = constants.WINDOW_HEIGHT * UI.TITLE.Y_POSITION
    
    -- Draw shadow with pulsing effect
    love.graphics.setColor(constants.DARK_GREEN)
    love.graphics.print(text, x + UI.TITLE.SHADOW_OFFSET, y + UI.TITLE.SHADOW_OFFSET, 0, self.title_scale, self.title_scale)
    
    -- Draw main text with pulsing effect
    love.graphics.setColor(constants.SNAKE_GREEN)
    love.graphics.print(text, x, y, 0, self.title_scale, self.title_scale)
end

-- Draw the current score
function PauseMenu:draw_score(score)
    love.graphics.setFont(self.score_font)
    love.graphics.setColor(1, 1, 1, self.score_alpha)
    local text = "Score: " .. score
    love.graphics.print(text,
        constants.WINDOW_WIDTH/2 - self.score_font:getWidth(text)/2,
        constants.WINDOW_HEIGHT * UI.SCORE.Y_POSITION)
end

-- Draw menu options with animations
function PauseMenu:draw_menu_options()
    for i = 1, #self.options do
        local scale = self.option_scales[i]
        local scaled_size = math.floor(UI.MENU.BASE_FONT_SIZE * scale)
        local scaled_font = love.graphics.newFont(constants.FONT_PATH, scaled_size)
        
        love.graphics.setFont(scaled_font)
        love.graphics.setColor(self.option_colors[i])
        
        local text = self.options[i]
        local text_width = scaled_font:getWidth(text)
        local base_y = constants.WINDOW_HEIGHT/2 + 60 + (i-1) * UI.MENU.SPACING
        local wave_offset = math.sin(self.wave_offset + i * 0.5) * UI.ANIMATION.WAVE_AMOUNT
        local x = constants.WINDOW_WIDTH/2 - text_width/2
        local y = base_y + wave_offset
        
        -- Draw selection arrows with wave effect
        if i == self.selected then
            local arrow_padding = UI.MENU.ARROW_PADDING * scale
            love.graphics.print(">", x - arrow_padding - scaled_font:getWidth(">"), y)
            love.graphics.print("<", x + text_width + arrow_padding, y)
        end
        
        -- Draw option text with wave effect
        love.graphics.print(text, x, y)
    end
end

return PauseMenu