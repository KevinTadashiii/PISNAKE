-- Background Module --

local constants = require('src.constants')

--- Particle class for background effects
local Particle = {}
Particle.__index = Particle

--- Creates a new particle with random properties
-- @param x number: X coordinate of the particle
-- @param y number: Y coordinate of the particle
-- @return table: New particle instance
function Particle.new(x, y)
    local self = setmetatable({}, Particle)
    self.x = x
    self.y = y
    self.size = love.math.random(2, 5)        -- Particle size range
    self.color = {0, love.math.random(50, 150) / 255, 0}  -- Random green shade
    self.speed = love.math.random() * 0.5 + 0.2  -- Random movement speed
    self.angle = love.math.random() * math.pi * 2  -- Random direction
    self.lifetime = love.math.random(60, 120)    -- Random lifetime duration
    self.alpha = 0.7                           -- Initial opacity
    return self
end

--- Updates particle position and lifetime
-- @return boolean: True if particle is still alive
function Particle:update()
    -- Update position based on angle and speed
    self.x = self.x + math.cos(self.angle) * self.speed
    self.y = self.y + math.sin(self.angle) * self.speed
    
    -- Update lifetime and fade out
    self.lifetime = self.lifetime - 1
    self.alpha = self.lifetime / 120
    
    return self.lifetime > 0
end

--- Draws the particle
function Particle:draw()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)
    love.graphics.circle('fill', self.x, self.y, self.size)
end

--- Background Manager singleton class
local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

local instance = nil  -- Singleton instance

--- Creates or returns existing BackgroundManager instance
-- @return table: BackgroundManager instance
function BackgroundManager.new()
    if instance then
        return instance  -- Return existing instance (singleton pattern)
    end

    local self = setmetatable({}, BackgroundManager)
    
    -- Initialize background snake properties
    self.bg_snake_pos = {}
    self.window_grid_width = math.floor(constants.WINDOW_WIDTH / constants.GRID_SIZE)
    self.window_grid_height = math.floor(constants.WINDOW_HEIGHT / constants.GRID_SIZE)
    
    -- Timing controls
    self.move_delay = 0.2        -- Snake movement interval
    self.last_move_time = love.timer.getTime()
    self.particle_delay = 0.3    -- Particle spawn interval
    self.last_particle_time = love.timer.getTime()
    
    -- Visual settings
    self.show_border = false
    self.particles = {}
    
    -- Initialize background snake segments
    for i = 1, 5 do
        table.insert(self.bg_snake_pos, {
            x = love.math.random(0, self.window_grid_width - 1),
            y = love.math.random(0, self.window_grid_height - 1)
        })
    end
    
    -- Initial snake direction
    self.bg_snake_dir = {x = 1, y = 0}
    
    -- Grid color configuration
    self:_init_grid_colors()
    
    instance = self
    return self
end

--- Initializes grid color patterns and transition state
function BackgroundManager:_init_grid_colors()
    -- Define color patterns for checkerboard
    self.grid_colors = {
        {
            {20/255, 40/255, 20/255},  -- Dark green pattern
            {30/255, 50/255, 30/255}
        },
        {
            {15/255, 35/255, 15/255},  -- Darker green pattern
            {25/255, 45/255, 25/255}
        }
    }
    self.current_grid_colors = 1
    self.color_transition = 0
    self.color_change_speed = 0.1
end

--- Updates the background snake's direction randomly
function BackgroundManager:_update_snake_direction()
    if love.math.random() < 0.1 then  -- 10% chance to change direction
        local possible_dirs = {
            {x = 0, y = 1}, {x = 0, y = -1},
            {x = 1, y = 0}, {x = -1, y = 0}
        }
        
        -- Remove opposite direction to prevent 180° turns
        for i, dir in ipairs(possible_dirs) do
            if dir.x == -self.bg_snake_dir.x and dir.y == -self.bg_snake_dir.y then
                table.remove(possible_dirs, i)
                break
            end
        end
        
        -- Select new random direction
        self.bg_snake_dir = possible_dirs[love.math.random(#possible_dirs)]
    end
end

--- Updates snake position and wraps around screen edges
-- @param current_time number: Current game time
function BackgroundManager:_update_snake_position(current_time)
    if current_time - self.last_move_time >= self.move_delay then
        local head = self.bg_snake_pos[1]
        local new_x = head.x + self.bg_snake_dir.x
        local new_y = head.y + self.bg_snake_dir.y
        
        -- Wrap around screen edges
        new_x = new_x < 0 and self.window_grid_width - 1 or new_x % self.window_grid_width
        new_y = new_y < 0 and self.window_grid_height - 1 or new_y % self.window_grid_height
        
        -- Update snake direction and position
        self:_update_snake_direction()
        
        -- Update snake segments
        table.insert(self.bg_snake_pos, 1, {x = new_x, y = new_y})
        table.remove(self.bg_snake_pos)
        
        -- Create particle at new position
        if current_time - self.last_particle_time >= self.particle_delay then
            table.insert(self.particles, Particle.new(
                new_x * constants.GRID_SIZE,
                new_y * constants.GRID_SIZE
            ))
            self.last_particle_time = current_time
        end
        
        self.last_move_time = current_time
    end
end

--- Updates particle system
-- @param current_time number: Current game time
function BackgroundManager:_update_particles(current_time)
    -- Update existing particles
    for i = #self.particles, 1, -1 do
        if not self.particles[i]:update() then
            table.remove(self.particles, i)
        end
    end
    
    -- Spawn new particles
    if current_time - self.last_particle_time >= self.particle_delay then
        -- Spawn particle at snake head
        if self.bg_snake_pos[1] then
            table.insert(self.particles, Particle.new(
                self.bg_snake_pos[1].x * constants.GRID_SIZE,
                self.bg_snake_pos[1].y * constants.GRID_SIZE
            ))
        end
        
        -- Spawn random particle
        table.insert(self.particles, Particle.new(
            love.math.random() * constants.WINDOW_WIDTH,
            love.math.random() * constants.WINDOW_HEIGHT
        ))
        
        self.last_particle_time = current_time
    end
end

--- Updates background animation state
-- @param dt number: Delta time since last update
function BackgroundManager:update(dt)
    local current_time = love.timer.getTime()
    
    -- Update components
    self:_update_snake_position(current_time)
    self:_update_particles(current_time)
    
    -- Update color transition
    self.color_transition = self.color_transition + self.color_change_speed * dt
    if self.color_transition >= 1 then
        self.color_transition = 0
        self.current_grid_colors = (self.current_grid_colors % #self.grid_colors) + 1
    end
end

--- Draws the checkerboard pattern
-- @param interpolated_colors table: Current interpolated color set
function BackgroundManager:_draw_grid(interpolated_colors)
    for y = 0, self.window_grid_height - 1 do
        for x = 0, self.window_grid_width - 1 do
            local color = interpolated_colors[((x + y) % 2) + 1]
            local rect_x = x * constants.GRID_SIZE
            local rect_y = y * constants.GRID_SIZE
            
            love.graphics.setColor(unpack(color))
            love.graphics.rectangle('fill', rect_x, rect_y,
                                 constants.GRID_SIZE, constants.GRID_SIZE)
        end
    end
end

--- Draws the border around the grid
function BackgroundManager:_draw_border()
    if not self.show_border then return end
    
    local border_thickness = 2
    love.graphics.setColor(constants.SNAKE_GREEN)
    
    -- Draw border rectangles
    love.graphics.rectangle('fill', 0, 0, 
                          constants.WINDOW_WIDTH, border_thickness)
    love.graphics.rectangle('fill', 0, constants.WINDOW_HEIGHT - border_thickness, 
                          constants.WINDOW_WIDTH, border_thickness)
    love.graphics.rectangle('fill', 0, 0, 
                          border_thickness, constants.WINDOW_HEIGHT)
    love.graphics.rectangle('fill', constants.WINDOW_WIDTH - border_thickness, 0, 
                          border_thickness, constants.WINDOW_HEIGHT)
end

--- Draws the background snake
function BackgroundManager:_draw_snake()
    for i, pos in ipairs(self.bg_snake_pos) do
        -- Head is slightly brighter than body
        local color = i == 1 and {0, 100/255, 0} or {0, 80/255, 0}
        local screen_x = pos.x * constants.GRID_SIZE
        local screen_y = pos.y * constants.GRID_SIZE
        
        love.graphics.setColor(unpack(color))
        love.graphics.rectangle('fill',
            screen_x + constants.SNAKE_PADDING,
            screen_y + constants.SNAKE_PADDING,
            constants.GRID_SIZE - 2 * constants.SNAKE_PADDING,
            constants.GRID_SIZE - 2 * constants.SNAKE_PADDING)
    end
end

--- Draws the background
function BackgroundManager:draw()
    -- Clear background
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
    
    -- Calculate color interpolation
    local next_colors = self.grid_colors[(self.current_grid_colors % #self.grid_colors) + 1]
    local current_colors = self.grid_colors[self.current_grid_colors]
    
    -- Interpolate between current and next colors
    local interpolated_colors = {}
    for i = 1, 2 do
        interpolated_colors[i] = {}
        for j = 1, 3 do
            interpolated_colors[i][j] = current_colors[i][j] + 
                (next_colors[i][j] - current_colors[i][j]) * self.color_transition
        end
    end
    
    -- Draw visual elements in order
    self:_draw_grid(interpolated_colors)
    self:_draw_border()
    
    -- Draw particles behind snake
    for _, particle in ipairs(self.particles) do
        particle:draw()
    end
    
    self:_draw_snake()
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

--- Toggles border visibility
-- @return boolean: New border visibility state
function BackgroundManager:toggle_border()
    self.show_border = not self.show_border
    return self.show_border
end

return BackgroundManager