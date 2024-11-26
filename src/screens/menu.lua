local constants = require('src.constants')
local SettingsManager = require('src.settings.settings_manager')
local BackgroundManager = require('src.graphics.background')

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local self = setmetatable({}, Menu)
    self.options = {'Play', 'Instructions', 'Settings', 'Quit'}
    self.selected = 1
    self.using_keyboard = false  -- Track if keyboard was last used
    self.mouse_moved = false    -- Track if mouse has moved
    self.title_font = love.graphics.newFont(constants.FONT_PATH, 48)
    self.option_font = love.graphics.newFont(constants.FONT_PATH, 24)
    self.small_font = love.graphics.newFont(constants.FONT_PATH, 12)
    self.splash_font = love.graphics.newFont(constants.FONT_PATH, 10)
    self.splash_base_size = 10
    self.version = "v1.5"

    self.splash_texts = {}
    local content = love.filesystem.read("assets/data/splash_texts.txt")
    if content then
        for line in content:gmatch("[^\r\n]+") do
            table.insert(self.splash_texts, line)
        end
    else
        self.splash_texts = {"SPLASH TEXT NOT FOUND", "something went wrong", "There is an error in the splash text file."}
    end
    self.current_splash = self.splash_texts[love.math.random(#self.splash_texts)]

    self.glow_intensity = 1.0
    self.wave_offset = 0
    self.letter_spacing = 2
    self.splash_color = {170/255, 170/255, 170/255}
    
    self.settings_manager = SettingsManager.new()
    -- Create multiple hover sounds for rapid playback
    self.hover_sounds = {}
    for i = 1, 3 do  -- Create 3 sound sources
        self.hover_sounds[i] = love.audio.newSource(constants.HOVER_SOUND_PATH, "static")
    end
    self.current_sound = 1
    self:update_hover_sounds() -- Initialize sound volumes

    self.bg_manager = BackgroundManager.new()

    self.title_y_offset = 0
    self.animation_counter = 0
    self.title_scale = 1.0
    self.title_colors = {
        {1, 0.5, 0},   -- Orange
        {1, 1, 0},     -- Yellow
        {0, 1, 0},     -- Green
        {0, 1, 1},     -- Cyan
        {0, 0.5, 1},   -- Light Blue
        {0.5, 0, 1},   -- Purple
        {1, 0, 1}      -- Pink
    }
    self.color_index = 1
    self.color_transition = 0
    self.color_speed = 0.5
    self.animation_speed = 0.2
    self.hover_scale = 1.2
    self.option_scales = {}
    self.target_scales = {}
    self.option_colors = {}
    self.target_colors = {}
    
    -- Initialize scales and colors for options
    for i = 1, #self.options do
        self.option_scales[i] = 1.0
        self.target_scales[i] = 1.0
        self.option_colors[i] = {1, 1, 1}
        self.target_colors[i] = {1, 1, 1}
    end
    
    -- Set initial hover effect on Play option
    self.selected = 1  -- Play is the first option
    self.target_scales[1] = self.hover_scale
    self.target_colors[1] = {1, 1, 0}  -- Yellow hover color

    -- Initialize particles system
    self.particles = {}
    self.max_particles = 50

    -- Disable key repeat
    love.keyboard.setKeyRepeat(false)

    return self
end

function Menu:update_splash_font()
    local base_size = self.splash_base_size
    local text_length = #self.current_splash
    local size_factor = math.max(0.5, 1.0 - (text_length - 10) / 40)
    self.splash_font = love.graphics.newFont(constants.FONT_PATH, base_size * size_factor)
end

function Menu:_update_hover_effects()
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

function Menu:update_particles(dt)
    -- Update existing particles
    local new_particles = {}
    for _, particle in ipairs(self.particles) do
        particle.life = particle.life - 0.02
        if particle.life > 0 then
            particle.pos[1] = particle.pos[1] + particle.vel[1]
            particle.pos[2] = particle.pos[2] + particle.vel[2]
            particle.vel[2] = particle.vel[2] + 0.1  -- Gravity
            table.insert(new_particles, particle)
        end
    end
    
    -- Generate new particles
    while #new_particles < self.max_particles do
        local particle = {
            pos = {
                constants.WINDOW_WIDTH / 2 + love.math.random(-100, 100),
                constants.WINDOW_HEIGHT / 4 + love.math.random(-50, 50)
            },
            vel = {
                love.math.random() * 2 - 1,  -- Random velocity between -1 and 1
                love.math.random() * -2      -- Random upward velocity between -2 and 0
            },
            color = self.title_colors[love.math.random(#self.title_colors)],
            life = love.math.random() * 0.5 + 0.5  -- Random life between 0.5 and 1.0
        }
        table.insert(new_particles, particle)
    end
    
    self.particles = new_particles
end

function Menu:update(dt)
    -- Update animation counter (adjusted for dt)
    self.animation_counter = (self.animation_counter + dt * 60) % (2 * math.pi * 20)

    -- Update title animations
    self.title_y_offset = math.sin(self.animation_counter / 20) * 10
    self.title_scale = 1.0 + math.sin(self.animation_counter / 20) * 0.05
    self.wave_offset = (self.wave_offset + 2) % 360
    self.glow_intensity = 0.7 + math.sin(self.animation_counter / 20) * 0.3
    self.color_transition = self.color_transition + self.color_speed * dt
    
    if self.color_transition >= 1 then
        self.color_transition = 0
        self.color_index = (self.color_index % #self.title_colors) + 1
    end

    -- Update particles
    self:update_particles(dt)

    -- Update option scales and colors
    for i = 1, #self.options do
        self.option_scales[i] = self.option_scales[i] + 
            (self.target_scales[i] - self.option_scales[i]) * self.animation_speed
        for j = 1, 3 do
            self.option_colors[i][j] = self.option_colors[i][j] + 
                (self.target_colors[i][j] - self.option_colors[i][j]) * self.color_speed
        end
    end

    self.bg_manager:update(dt)

    -- Handle mouse hover
    self:handleMouseHover()

    -- Handle keyboard input
    if love.keyboard.isDown('return') or love.keyboard.isDown('space') then
        return self.options[self.selected]
    end
    return nil
end

function Menu:handleMouseHover()
    if self.using_keyboard then
        return  -- Skip mouse hover check if keyboard was last used
    end

    local mx, my = love.mouse.getPosition()
    local menu_spacing = 60  -- Distance between menu options
    
    for i, option in ipairs(self.options) do
        local hit_width = 200
        local option_x = constants.WINDOW_WIDTH / 2
        local option_y = constants.WINDOW_HEIGHT / 2 + (i - 1) * menu_spacing
        
        -- Calculate the top and bottom bounds to be halfway between options
        local top_bound = option_y - menu_spacing/2
        local bottom_bound = option_y + menu_spacing/2
        
        -- Adjust bounds for first and last options
        if i == 1 then
            top_bound = option_y - menu_spacing/4  -- Half distance for first option
        end
        if i == #self.options then
            bottom_bound = option_y + menu_spacing/2  -- Full spacing for last option
        end

        if mx >= option_x - hit_width/2 and mx <= option_x + hit_width/2 and
           my >= top_bound and my <= bottom_bound then
            if self.selected ~= i then
                self.selected = i
                self:play_hover_sound()
                self:_update_hover_effects()
            end
            break
        end
    end
end

function Menu:mousemoved(x, y, dx, dy)
    if dx ~= 0 or dy ~= 0 then
        self.using_keyboard = false  -- Reset keyboard mode when mouse moves
    end
end

function Menu:keypressed(key)
    if key == 'up' then
        self.using_keyboard = true  -- Mark that keyboard was used
        self.selected = ((self.selected - 2) % #self.options) + 1
        self:play_hover_sound()
        self:_update_hover_effects()
    elseif key == 'down' then
        self.using_keyboard = true  -- Mark that keyboard was used
        self.selected = (self.selected % #self.options) + 1
        self:play_hover_sound()
        self:_update_hover_effects()
    elseif key == 'return' or key == 'space' then
        return self.options[self.selected]
    end
    return nil
end

function Menu:keyreleased(key)
    if key == 'return' or key == 'space' then
        return self.options[self.selected]
    end
    return nil
end

function Menu:play_hover_sound()
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

function Menu:update_hover_sounds()
    -- Force reload settings to ensure we have the latest values
    self.settings_manager = SettingsManager.new(true)
    local volume = self.settings_manager:get_setting('sound_volume') or 70
    for _, sound in ipairs(self.hover_sounds) do
        sound:setVolume(1.4 * (volume / 100))
    end
end

function Menu:draw()
    -- Draw background
    self.bg_manager:draw()

    -- Draw particles behind the title
    for _, particle in ipairs(self.particles) do
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.life)
        love.graphics.rectangle("fill", 
            particle.pos[1] - 3/2, 
            particle.pos[2] - 3/2, 
            3, 
            3)
    end

    -- Draw title with glow effect
    love.graphics.setFont(self.title_font)
    local title_text = "PISNAKE"
    local title_width = self.title_font:getWidth(title_text)
    local title_height = self.title_font:getHeight()
    local title_x = constants.WINDOW_WIDTH / 2
    local title_y = constants.WINDOW_HEIGHT / 4 + self.title_y_offset

    -- Calculate interpolated color
    local next_index = (self.color_index % #self.title_colors) + 1
    local current_color = self.title_colors[self.color_index]
    local next_color = self.title_colors[next_index]
    local interpolated_color = {
        current_color[1] + (next_color[1] - current_color[1]) * self.color_transition,
        current_color[2] + (next_color[2] - current_color[2]) * self.color_transition,
        current_color[3] + (next_color[3] - current_color[3]) * self.color_transition
    }

    -- Draw title
    love.graphics.setColor(interpolated_color[1], interpolated_color[2], interpolated_color[3], 1)
    love.graphics.print(title_text, title_x, title_y, 0, self.title_scale, self.title_scale,
        title_width/2, title_height/2)

    -- Draw splash text with wave animation
    local splash_text = self.current_splash
    local total_width = 0
    local letter_widths = {}
    
    -- Calculate total width
    love.graphics.setFont(self.splash_font)
    local utf8 = require("utf8")
    for p, c in utf8.codes(splash_text) do
        local char = utf8.char(c)
        local width = self.splash_font:getWidth(char)
        total_width = total_width + width + self.letter_spacing
        table.insert(letter_widths, width)
    end

    -- Scale down splash text if it's wider than the title
    local max_width = title_width * self.title_scale * 0.8
    local scale = 1.0
    if total_width > max_width then
        scale = max_width / total_width
    end

    -- Draw letters with wave effect
    local current_x = constants.WINDOW_WIDTH / 2 - (total_width * scale) / 2
    local base_y = title_y + title_height/2 + 12

    local i = 1
    for p, c in utf8.codes(splash_text) do
        local char = utf8.char(c)
        local wave_y = math.sin((self.wave_offset + i * 20) * math.pi / 180) * 3
        local alpha = math.max(180/255, math.min(1, 1 - math.abs(wave_y) * 0.04))
        
        love.graphics.setColor(self.splash_color[1], self.splash_color[2], self.splash_color[3], alpha)
        love.graphics.print(char, current_x, base_y + wave_y, 0, scale, scale)
        current_x = current_x + (letter_widths[i] + self.letter_spacing) * scale
        i = i + 1
    end

    -- Draw menu options
    love.graphics.setFont(self.option_font)
    for i, option in ipairs(self.options) do
        local y = constants.WINDOW_HEIGHT / 2 + (i - 1) * 60
        local text_width = self.option_font:getWidth(option)
        local scale = self.option_scales[i]
        local x = constants.WINDOW_WIDTH / 2 - text_width * scale / 2

        -- Draw option with current color and scale
        love.graphics.setColor(
            self.option_colors[i][1],
            self.option_colors[i][2],
            self.option_colors[i][3]
        )
        love.graphics.print(option, x, y, 0, scale, scale)

        -- Draw arrows for selected option
        if i == self.selected then
            local arrow_padding = 30 * scale
            love.graphics.setColor(1, 1, 0)  -- Yellow arrows
            -- Left arrow
            love.graphics.print(">", x - arrow_padding, y, 0, scale, scale)
            -- Right arrow
            love.graphics.print("<", x + text_width * scale + arrow_padding - self.option_font:getWidth("<") * scale, y, 0, scale, scale)
        end
    end

    -- Draw version and copyright
    love.graphics.setFont(self.small_font)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)  -- Gray color
    local copyright_text = "\u{00A9} 2024 PIsnake"
    local version_width = self.small_font:getWidth(self.version)
    local copyright_width = self.small_font:getWidth(copyright_text)
    love.graphics.print(copyright_text, constants.WINDOW_WIDTH - copyright_width - 10, constants.WINDOW_HEIGHT - 40)
    love.graphics.print(self.version, constants.WINDOW_WIDTH - version_width - 10, constants.WINDOW_HEIGHT - 20)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function Menu:getSelectedOption()
    return self.options[self.selected]
end

function Menu:change_splash_text()
    -- Change to a new random splash text
    local new_splash = self.current_splash
    while new_splash == self.current_splash do
        new_splash = self.splash_texts[love.math.random(#self.splash_texts)]
    end
    self.current_splash = new_splash
    self:update_splash_font()
end

function Menu:handle_mousepressed(x, y, button)
    if button == 1 then  -- Left click
        local mx, my = x, y
        local menu_spacing = 60  -- Distance between menu options
        
        for i, option in ipairs(self.options) do
            local hit_width = 200
            local option_x = constants.WINDOW_WIDTH / 2
            local option_y = constants.WINDOW_HEIGHT / 2 + (i - 1) * menu_spacing
            
            -- Calculate the top and bottom bounds to be halfway between options
            local top_bound = option_y - menu_spacing/2
            local bottom_bound = option_y + menu_spacing/2
            
            -- Adjust bounds for first and last options
            if i == 1 then
                top_bound = option_y - menu_spacing/4  -- Half distance for first option
            end
            if i == #self.options then
                bottom_bound = option_y + menu_spacing/2  -- Full spacing for last option
            end

            if mx >= option_x - hit_width/2 and mx <= option_x + hit_width/2 and
               my >= top_bound and my <= bottom_bound then
                return self.options[i]
            end
        end
    end
    return nil
end

function Menu:mousereleased(x, y, button)
    return nil
end

function Menu:mousemoved(x, y, dx, dy)
    self.mouse_moved = true
    self.using_keyboard = false
end

function Menu:handle_settings()
    -- Settings screen is now implemented
    -- After settings are changed, update the hover sound volume
    self:update_hover_sounds()
    return nil
end

return Menu