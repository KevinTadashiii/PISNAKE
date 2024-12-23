-- settings Manager --

local constants = require('src.constants')
local BackgroundManager = require('src.graphics.background')
local SettingsManager = require('src.settings.settings_manager')

local Settings = {}
Settings.__index = Settings

--- Creates a new Settings instance.
-- Initializes fonts, background animation, and loads settings from storage.
function Settings.new()
    local self = setmetatable({}, Settings)
    
    -- Initialize fonts for different UI elements
    self.title_font = love.graphics.newFont(constants.FONT_PATH, 36)
    self.option_font = love.graphics.newFont(constants.FONT_PATH, 24)
    self.small_font = love.graphics.newFont(constants.FONT_PATH, 16)
    
    -- Initialize background animation system
    self.bg_manager = BackgroundManager.new()
    
    -- Load and initialize settings from persistent storage
    self.settings_manager = SettingsManager.new()
    self.sound_volume = self.settings_manager:get_setting('sound_volume') or 100
    
    -- Load sound effect for volume testing
    self.test_sound = love.audio.newSource('assets/sounds/hover.mp3', 'static')
    self:update_volume(false) -- Initialize volume without playing sound
    
    -- State variables for mouse interaction
    self.is_dragging = false          -- Tracks if user is dragging the volume slider
    self.hovering_slider = false      -- Tracks if mouse is over the slider
    self.hovering_return = false      -- Tracks if mouse is over the return button
    self.last_mouse_x = 0            -- Last known mouse X position for movement detection
    self.last_mouse_y = 0            -- Last known mouse Y position for movement detection
    self.stop_time = 0               -- Timestamp when mouse stopped moving
    self.mouse_stopped = false       -- Flag indicating if mouse has stopped moving
    self.sound_played = false        -- Flag to prevent multiple sound plays
    
    return self
end

--- Updates the settings screen state.
-- Checks for return to menu and updates mouse movement timer if dragging.
function Settings:update(dt)
    if self.return_to_menu then
        return 'menu'
    end
    
    local mx, my = love.mouse.getPosition()
    
    -- Update mouse movement timer if dragging
    if self.is_dragging then
        if mx ~= self.last_mouse_x or my ~= self.last_mouse_y then
            -- Mouse moved, reset everything
            self.mouse_stopped = false
            self.sound_played = false
        else
            -- Mouse hasn't moved
            if not self.mouse_stopped then
                -- First frame mouse stopped
                self.stop_time = love.timer.getTime()
                self.mouse_stopped = true
            elseif not self.sound_played and love.timer.getTime() - self.stop_time >= 0.5 then
                -- 0.5 seconds have passed since stopping and haven't played sound yet
                self:play_test_sound()
                self.sound_played = true
            end
        end
    end
    
    self.last_mouse_x = mx
    self.last_mouse_y = my
    
    -- Update background
    self.bg_manager:update(dt)
    return nil
end

--- Draws the settings screen.
-- Draws animated background, title, volume control, and return message.
function Settings:draw()
    -- Draw animated background
    self.bg_manager:draw()
    
    -- Draw title with shadow effect
    self:draw_title()
    
    -- Draw volume control section
    self:draw_volume_control()
    
    -- Draw return message with pulsing animation
    self:draw_return_message()
    
    -- Reset color to default
    love.graphics.setColor(1, 1, 1, 1)
end

--- Draws the title with shadow effect.
function Settings:draw_title()
    love.graphics.setFont(self.title_font)
    local title_text = 'SETTINGS'
    local title_width = self.title_font:getWidth(title_text)
    local title_x = constants.WINDOW_WIDTH/2 - title_width/2
    
    -- Draw shadow
    love.graphics.setColor(constants.DARK_GREEN)
    love.graphics.print(title_text, title_x + 4, constants.WINDOW_HEIGHT/4 + 4)
    -- Draw main text
    love.graphics.setColor(constants.SNAKE_GREEN)
    love.graphics.print(title_text, title_x, constants.WINDOW_HEIGHT/4)
end

--- Draws the volume control section.
function Settings:draw_volume_control()
    -- Draw volume label
    love.graphics.setFont(self.option_font)
    love.graphics.setColor(constants.WHITE)
    local volume_text = 'Sound Volume:'
    local volume_width = self.option_font:getWidth(volume_text)
    love.graphics.print(volume_text, constants.WINDOW_WIDTH/2 - volume_width/2, constants.WINDOW_HEIGHT/2 - 30)
    
    -- Calculate slider dimensions and position
    local slider_width = 200
    local slider_height = 10
    local slider_x = constants.WINDOW_WIDTH/2 - slider_width/2
    local slider_y = constants.WINDOW_HEIGHT/2 + 10
    
    -- Draw slider background
    if self.hovering_slider then
        love.graphics.setColor(constants.LIGHT_GREEN)
    else
        love.graphics.setColor(constants.GRAY)
    end
    love.graphics.rectangle('fill', slider_x, slider_y, slider_width, slider_height)
    
    -- Draw slider fill based on volume
    love.graphics.setColor(constants.SNAKE_GREEN)
    love.graphics.rectangle('fill', slider_x, slider_y, slider_width * self.sound_volume / 100, slider_height)
    
    -- Draw slider handle with hover effect
    if self.hovering_slider or self.is_dragging then
        love.graphics.setColor(constants.YELLOW)
    else
        love.graphics.setColor(constants.WHITE)
    end
    love.graphics.rectangle('fill', slider_x + (slider_width * self.sound_volume / 100) - 5, slider_y - 5, 10, 20)
    
    -- Draw volume percentage
    love.graphics.setFont(self.small_font)
    love.graphics.setColor(constants.WHITE)
    local percent_text = string.format("%d%%", self.sound_volume)
    local percent_width = self.small_font:getWidth(percent_text)
    love.graphics.print(percent_text, constants.WINDOW_WIDTH/2 - percent_width/2, slider_y + 30)
end

--- Draws the return message with pulsing animation.
function Settings:draw_return_message()
    love.graphics.setFont(self.option_font)
    local return_text = "Press ENTER to return"
    local return_width = self.option_font:getWidth(return_text)
    local alpha = math.abs(math.sin(love.timer.getTime() * 3))
    love.graphics.setColor(self.hovering_return and {1, 1, 0, alpha} or {0, 1, 0, alpha})
    love.graphics.printf(return_text, 0, constants.WINDOW_HEIGHT - 100, constants.WINDOW_WIDTH, "center")
end

--- Updates the hover states for interactive elements.
function Settings:update_hover_states(x, y)
    -- Calculate slider bounds with increased hit area
    local slider_width = 200
    local slider_height = 20
    local slider_x = constants.WINDOW_WIDTH/2 - slider_width/2
    local slider_y = constants.WINDOW_HEIGHT/2 + 10 - slider_height/2

    self.hovering_slider = x >= slider_x and x <= slider_x + slider_width and
                          y >= slider_y and y <= slider_y + slider_height

    -- Calculate return button bounds
    local return_text = "Press ENTER to return"
    local return_width = self.option_font:getWidth(return_text)
    local return_height = self.option_font:getHeight()
    local return_x = constants.WINDOW_WIDTH/2 - return_width/2
    local return_y = constants.WINDOW_HEIGHT - 100

    self.hovering_return = x >= return_x and x <= return_x + return_width and
                          y >= return_y and y <= return_y + return_height
end

--- Handles mouse movement events.
-- Updates hover states and volume if dragging the slider.
function Settings:mousemoved(x, y, dx, dy)
    -- Update hover states for interactive elements
    self:update_hover_states(x, y)
    
    -- Update volume if dragging the slider
    if self.is_dragging then
        local slider_x = constants.WINDOW_WIDTH/2 - 100
        local rel_x = x - slider_x
        self.sound_volume = math.max(0, math.min(100, math.floor(rel_x / 200 * 100)))
        self:update_volume(false) -- Update without playing test sound
    end
end

--- Handles mouse press events.
-- Starts dragging the slider or returns to menu if clicking the return button.
function Settings:mousepressed(x, y, button)
    if button == 1 then  -- Left click
        if self.hovering_slider then
            self.is_dragging = true
            -- Update volume based on click position
            local slider_x = constants.WINDOW_WIDTH/2 - 100
            local rel_x = x - slider_x
            self.sound_volume = math.max(0, math.min(100, math.floor(rel_x / 200 * 100)))
            self:update_volume(true) -- Play sound on initial click
        elseif self.hovering_return then
            return true
        end
    end
    return false
end

--- Handles mouse release events.
-- Stops dragging the slider and saves the volume setting.
function Settings:mousereleased(x, y, button)
    if button == 1 then  -- Left click release
        self.is_dragging = false
        -- Save settings when done dragging
        self.settings_manager:set_setting('sound_volume', self.sound_volume)
    end
end

--- Handles key press events.
-- Changes volume or returns to menu based on key presses.
function Settings:keypressed(key)
    if key == 'return' then
        return true
    elseif key == 'left' then
        self.sound_volume = math.max(0, self.sound_volume - 10)
        self:update_volume(true) -- Play sound on key press
    elseif key == 'right' then
        self.sound_volume = math.min(100, self.sound_volume + 10)
        self:update_volume(true) -- Play sound on key press
    end
    return false
end

--- Updates the volume setting and plays the test sound if requested.
function Settings:update_volume(play_sound)
    -- Update volume for test sound
    local volume = self.sound_volume / 100
    self.test_sound:setVolume(volume)
    
    -- Save the volume setting
    self.settings_manager:set_setting('sound_volume', self.sound_volume)
    
    -- Play test sound if requested
    if play_sound then
        self:play_test_sound()
    end
end

--- Plays the test sound.
function Settings:play_test_sound()
    self.test_sound:stop()
    self.test_sound:play()
end

--- Returns the current sound volume.
function Settings:get_volume()
    return self.sound_volume
end

return Settings