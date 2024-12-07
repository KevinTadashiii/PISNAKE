-- Menu Module --

local constants = require('src.constants')
local SettingsManager = require('src.settings.settings_manager')
local BackgroundManager = require('src.graphics.background')

-- Game state enumeration
local States = {
    MENU = "menu",
    PLAYING = "playing",
    INSTRUCTIONS = "instructions",
    SETTINGS = "settings"
}

-- Menu configuration
local CONFIG = {
    FONTS = {
        TITLE = { size = 48 },
        OPTION = { size = 24 },
        SMALL = { size = 12 },
        SPLASH = { base_size = 10 }
    },
    ANIMATION = {
        SPEED = 0.2,
        COLOR_SPEED = 0.5,
        HOVER_SCALE = 1.2,
        WAVE_SPEED = 2,
        PARTICLE_MAX = 50
    },
    COLORS = {
        TITLE = {
            {1, 0.5, 0},   -- Orange
            {1, 1, 0},     -- Yellow
            {0, 1, 0},     -- Green
            {0, 1, 1},     -- Cyan
            {0, 0.5, 1},   -- Light Blue
            {0.5, 0, 1},   -- Purple
            {1, 0, 1}      -- Pink
        },
        SPLASH = {170/255, 170/255, 170/255},
        OPTION_NORMAL = {1, 1, 1},
        OPTION_HOVER = {1, 1, 0},
        COPYRIGHT = {0.5, 0.5, 0.5, 1}
    },
    LAYOUT = {
        MENU_SPACING = 60,
        LETTER_SPACING = 2,
        ARROW_PADDING = 30,
        OPTION_HIT_WIDTH = 200
    }
}

local Menu = {}
Menu.__index = Menu

--- Creates a new Menu instance
function Menu.new()
    local self = setmetatable({}, Menu)
    
    -- Initialize menu state
    self:init_menu_state()
    
    -- Initialize visual components
    self:init_fonts()
    self:init_splash_text()
    self:init_particles()
    self:init_sound()
    self:init_background()
    
    -- Disable key repeat for better control
    love.keyboard.setKeyRepeat(false)
    
    return self
end

--- Initialize core menu state
function Menu:init_menu_state()
    self.options = {'Play', 'Instructions', 'Settings', 'Quit'}
    self.selected = 1
    self.using_keyboard = false
    self.mouse_moved = false
    self.version = "v1.0"
    
    -- Animation state
    self.animation_counter = 0
    self.title_y_offset = 0
    self.title_scale = 1.0
    self.wave_offset = 0
    self.glow_intensity = 1.0
    self.color_index = 1
    self.color_transition = 0
    
    -- Option animations
    self.option_scales = {}
    self.target_scales = {}
    self.option_colors = {}
    self.target_colors = {}
    
    for i = 1, #self.options do
        self.option_scales[i] = 1.0
        self.target_scales[i] = 1.0
        self.option_colors[i] = {1, 1, 1}
        self.target_colors[i] = {1, 1, 1}
    end
    
    -- Set initial hover effect
    self.target_scales[1] = CONFIG.ANIMATION.HOVER_SCALE
    self.target_colors[1] = CONFIG.COLORS.OPTION_HOVER
end

--- Initialize fonts
function Menu:init_fonts()
    self.title_font = love.graphics.newFont(constants.FONT_PATH, CONFIG.FONTS.TITLE.size)
    self.option_font = love.graphics.newFont(constants.FONT_PATH, CONFIG.FONTS.OPTION.size)
    self.small_font = love.graphics.newFont(constants.FONT_PATH, CONFIG.FONTS.SMALL.size)
    self.splash_font = love.graphics.newFont(constants.FONT_PATH, CONFIG.FONTS.SPLASH.base_size)
end

--- Initialize splash text system
function Menu:init_splash_text()
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
end

--- Initialize particle system
function Menu:init_particles()
    self.particles = {}
    self.max_particles = CONFIG.ANIMATION.PARTICLE_MAX
end

--- Initialize sound system
function Menu:init_sound()
    self.hover_sounds = {}
    for i = 1, 3 do
        self.hover_sounds[i] = love.audio.newSource(constants.HOVER_SOUND_PATH, "static")
    end
    self.current_sound = 1
    self:update_hover_sounds()
end

--- Initialize background
function Menu:init_background()
    self.bg_manager = BackgroundManager.new()
end

--- Update menu state
function Menu:update(dt)
    self:update_animations(dt)
    self:update_particles(dt)
    self:update_option_effects(dt)
    self.bg_manager:update(dt)
    self:handle_mouse_hover()
    
    if love.keyboard.isDown('return') or love.keyboard.isDown('space') then
        return self.options[self.selected]
    end
    return nil
end

--- Update menu animations
function Menu:update_animations(dt)
    self.animation_counter = (self.animation_counter + dt * 60) % (2 * math.pi * 20)
    self.title_y_offset = math.sin(self.animation_counter / 20) * 10
    self.title_scale = 1.0 + math.sin(self.animation_counter / 20) * 0.05
    self.wave_offset = (self.wave_offset + CONFIG.ANIMATION.WAVE_SPEED) % 360
    self.glow_intensity = 0.7 + math.sin(self.animation_counter / 20) * 0.3
    
    -- Update color transition
    self.color_transition = self.color_transition + CONFIG.ANIMATION.COLOR_SPEED * dt
    if self.color_transition >= 1 then
        self.color_transition = 0
        self.color_index = (self.color_index % #CONFIG.COLORS.TITLE) + 1
    end
end

--- Update particles
function Menu:update_particles(dt)
    local new_particles = {}
    
    -- Update existing particles
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
        table.insert(new_particles, self:create_particle())
    end
    
    self.particles = new_particles
end

--- Create a new particle
function Menu:create_particle()
    return {
        pos = {
            constants.WINDOW_WIDTH / 2 + love.math.random(-100, 100),
            constants.WINDOW_HEIGHT / 4 + love.math.random(-50, 50)
        },
        vel = {
            love.math.random() * 2 - 1,
            love.math.random() * -2
        },
        color = CONFIG.COLORS.TITLE[love.math.random(#CONFIG.COLORS.TITLE)],
        life = love.math.random() * 0.5 + 0.5
    }
end

--- Update option animations and effects
function Menu:update_option_effects(dt)
    for i = 1, #self.options do
        -- Update scales with smooth interpolation
        self.option_scales[i] = self.option_scales[i] + 
            (self.target_scales[i] - self.option_scales[i]) * CONFIG.ANIMATION.SPEED
        
        -- Update colors with smooth interpolation
        for j = 1, 3 do
            self.option_colors[i][j] = self.option_colors[i][j] + 
                (self.target_colors[i][j] - self.option_colors[i][j]) * CONFIG.ANIMATION.COLOR_SPEED
        end
    end
end

--- Handle mouse hover
function Menu:handle_mouse_hover()
    if self.using_keyboard then
        return  -- Skip mouse hover check if keyboard was last used
    end

    local mx, my = love.mouse.getPosition()
    local menu_spacing = CONFIG.LAYOUT.MENU_SPACING  -- Distance between menu options
    
    for i, option in ipairs(self.options) do
        local hit_width = CONFIG.LAYOUT.OPTION_HIT_WIDTH
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

--- Update hover effects
function Menu:_update_hover_effects()
    for i = 1, #self.options do
        if i == self.selected then
            self.target_scales[i] = CONFIG.ANIMATION.HOVER_SCALE
            self.target_colors[i] = CONFIG.COLORS.OPTION_HOVER
        else
            self.target_scales[i] = 1.0
            self.target_colors[i] = CONFIG.COLORS.OPTION_NORMAL
        end
    end
end

--- Play hover sound
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

--- Update hover sound volume
function Menu:update_hover_sounds()
    -- Force reload settings to ensure we have the latest values
    self.settings_manager = SettingsManager.new(true)
    local volume = self.settings_manager:get_setting('sound_volume') or 70
    for _, sound in ipairs(self.hover_sounds) do
        sound:setVolume(1.4 * (volume / 100))
    end
end

--- Draw menu
function Menu:draw()
    self.bg_manager:draw()
    self:draw_particles()
    self:draw_title()
    self:draw_splash_text()
    self:draw_menu_options()
    self:draw_version_info()
end

--- Draw particle effects
function Menu:draw_particles()
    for _, particle in ipairs(self.particles) do
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.life)
        love.graphics.rectangle("fill", 
            particle.pos[1] - 3/2, 
            particle.pos[2] - 3/2, 
            3, 
            3)
    end
end

--- Draw title
function Menu:draw_title()
    love.graphics.setFont(self.title_font)
    local title_text = "PISNAKE"
    local title_width = self.title_font:getWidth(title_text)
    local title_height = self.title_font:getHeight()
    local title_x = constants.WINDOW_WIDTH / 2
    local title_y = constants.WINDOW_HEIGHT / 4 + self.title_y_offset

    -- Calculate interpolated color
    local next_index = (self.color_index % #CONFIG.COLORS.TITLE) + 1
    local current_color = CONFIG.COLORS.TITLE[self.color_index]
    local next_color = CONFIG.COLORS.TITLE[next_index]
    local interpolated_color = {
        current_color[1] + (next_color[1] - current_color[1]) * self.color_transition,
        current_color[2] + (next_color[2] - current_color[2]) * self.color_transition,
        current_color[3] + (next_color[3] - current_color[3]) * self.color_transition
    }

    -- Draw title
    love.graphics.setColor(interpolated_color[1], interpolated_color[2], interpolated_color[3], 1)
    love.graphics.print(title_text, title_x, title_y, 0, self.title_scale, self.title_scale,
        title_width/2, title_height/2)
end

--- Draw splash text
function Menu:draw_splash_text()
    local splash_text = self.current_splash
    local total_width = 0
    local letter_widths = {}
    
    -- Calculate total width
    love.graphics.setFont(self.splash_font)
    local utf8 = require("utf8")
    for p, c in utf8.codes(splash_text) do
        local char = utf8.char(c)
        local width = self.splash_font:getWidth(char)
        total_width = total_width + width + CONFIG.LAYOUT.LETTER_SPACING
        table.insert(letter_widths, width)
    end

    -- Scale down splash text if it's wider than the title
    local max_width = self.title_font:getWidth("PISNAKE") * self.title_scale * 0.8
    local scale = 1.0
    if total_width > max_width then
        scale = max_width / total_width
    end

    -- Draw letters with wave effect
    local current_x = constants.WINDOW_WIDTH / 2 - (total_width * scale) / 2
    local base_y = constants.WINDOW_HEIGHT / 4 + self.title_font:getHeight()/2 + 12

    local i = 1
    for p, c in utf8.codes(splash_text) do
        local char = utf8.char(c)
        local wave_y = math.sin((self.wave_offset + i * 20) * math.pi / 180) * 3
        local alpha = math.max(180/255, math.min(1, 1 - math.abs(wave_y) * 0.04))
        
        love.graphics.setColor(CONFIG.COLORS.SPLASH[1], CONFIG.COLORS.SPLASH[2], CONFIG.COLORS.SPLASH[3], alpha)
        love.graphics.print(char, current_x, base_y + wave_y, 0, scale, scale)
        current_x = current_x + (letter_widths[i] + CONFIG.LAYOUT.LETTER_SPACING) * scale
        i = i + 1
    end
end

--- Draw menu options
function Menu:draw_menu_options()
    love.graphics.setFont(self.option_font)
    for i, option in ipairs(self.options) do
        local y = constants.WINDOW_HEIGHT / 2 + (i - 1) * CONFIG.LAYOUT.MENU_SPACING
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
            local arrow_padding = CONFIG.LAYOUT.ARROW_PADDING * scale
            love.graphics.setColor(1, 1, 0)  -- Yellow arrows
            -- Left arrow
            love.graphics.print(">", x - arrow_padding, y, 0, scale, scale)
            -- Right arrow
            love.graphics.print("<", x + text_width * scale + arrow_padding - self.option_font:getWidth("<") * scale, y, 0, scale, scale)
        end
    end
end

--- Draw version and copyright
function Menu:draw_version_info()
    love.graphics.setFont(self.small_font)
    love.graphics.setColor(CONFIG.COLORS.COPYRIGHT[1], CONFIG.COLORS.COPYRIGHT[2], CONFIG.COLORS.COPYRIGHT[3], CONFIG.COLORS.COPYRIGHT[4])
    local copyright_text = "\u{00A9} 2024 PIsnake"
    local version_width = self.small_font:getWidth(self.version)
    local copyright_width = self.small_font:getWidth(copyright_text)
    love.graphics.print(copyright_text, constants.WINDOW_WIDTH - copyright_width - 10, constants.WINDOW_HEIGHT - 40)
    love.graphics.print(self.version, constants.WINDOW_WIDTH - version_width - 10, constants.WINDOW_HEIGHT - 20)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

--- Handle mouse press
function Menu:handle_mousepressed(x, y, button)
    if button == 1 then  -- Left click
        local mx, my = x, y
        local menu_spacing = CONFIG.LAYOUT.MENU_SPACING  -- Distance between menu options
        
        for i, option in ipairs(self.options) do
            local hit_width = CONFIG.LAYOUT.OPTION_HIT_WIDTH
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

--- Handle mouse move
function Menu:mousemoved(x, y, dx, dy)
    self.mouse_moved = true
    self.using_keyboard = false
end

--- Handle key press
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

--- Handle key release
function Menu:keyreleased(key)
    if key == 'return' or key == 'space' then
        return self.options[self.selected]
    end
    return nil
end

--- Handle menu option selection
function Menu:play_option(index)
    if self.options[index] == 'Play' then
        return States.PLAYING
    elseif self.options[index] == 'Instructions' then
        return States.INSTRUCTIONS
    elseif self.options[index] == 'Settings' then
        return States.SETTINGS
    elseif self.options[index] == 'Quit' then
        love.event.quit()
    end
    return nil
end

--- Handle mouse button release events
function Menu:mousereleased(x, y, button)
    if button == 1 and self.selected then  -- Left click
        -- Play the menu option based on what's selected
        if self.options[self.selected] then
            return self:play_option(self.selected)
        end
    end
    return nil
end

return Menu