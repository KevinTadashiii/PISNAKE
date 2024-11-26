local constants = require('src.constants')

local Particle = {}
Particle.__index = Particle

function Particle.new(x, y)
    local self = setmetatable({}, Particle)
    self.x = x
    self.y = y
    self.size = love.math.random(2, 4)
    self.color = {0, love.math.random(50, 150) / 255, 0}
    self.speed = love.math.random() * 1.5 + 0.5  -- random between 0.5 and 2
    self.angle = love.math.random() * math.pi * 2
    self.lifetime = love.math.random(30, 90)
    self.alpha = 1.0  -- LÖVE uses 0-1 for alpha
    return self
end

function Particle:update()
    self.x = self.x + math.cos(self.angle) * self.speed
    self.y = self.y + math.sin(self.angle) * self.speed
    self.lifetime = self.lifetime - 1
    self.alpha = self.lifetime / 90
    return self.lifetime > 0
end

function Particle:draw()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)
    love.graphics.circle('fill', self.x, self.y, self.size)
end

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

local instance = nil

function BackgroundManager.new()
    if instance then
        return instance
    end

    local self = setmetatable({}, BackgroundManager)
    
    -- Initialize background snake
    self.bg_snake_pos = {}
    -- Calculate exact grid dimensions to fit window
    self.window_grid_width = math.floor(constants.WINDOW_WIDTH / constants.GRID_SIZE)
    self.window_grid_height = math.floor(constants.WINDOW_HEIGHT / constants.GRID_SIZE)
    
    -- Initialize timing variables
    self.move_delay = 0.2  -- Snake moves every 0.2 seconds
    self.last_move_time = love.timer.getTime()
    
    -- Initialize particles
    self.particles = {}
    self.last_particle_time = love.timer.getTime()
    self.particle_delay = 0.1
    
    -- Border visibility flag
    self.show_border = false
    
    for i = 1, 5 do
        table.insert(self.bg_snake_pos, {
            x = love.math.random(0, self.window_grid_width - 1),
            y = love.math.random(0, self.window_grid_height - 1)
        })
    end
    
    self.bg_snake_dir = {x = 1, y = 0}
    
    -- Dynamic grid colors
    self.grid_colors = {
        {
            {20/255, 40/255, 20/255},
            {30/255, 50/255, 30/255}
        },
        {
            {15/255, 35/255, 15/255},
            {25/255, 45/255, 25/255}
        }
    }
    self.current_grid_colors = 1
    self.color_transition = 0
    self.color_change_speed = 0.02
    
    instance = self
    return self
end

function BackgroundManager:update(dt)
    local current_time = love.timer.getTime()
    
    -- Update snake position
    if current_time - self.last_move_time >= self.move_delay then
        local head = self.bg_snake_pos[1]
        local new_x = head.x + self.bg_snake_dir.x
        local new_y = head.y + self.bg_snake_dir.y
        
        -- Wrap around screen edges
        if new_x < 0 then
            new_x = self.window_grid_width - 1
        elseif new_x >= self.window_grid_width then
            new_x = 0
        end
        
        if new_y < 0 then
            new_y = self.window_grid_height - 1
        elseif new_y >= self.window_grid_height then
            new_y = 0
        end
        
        -- Randomly change direction (but don't check boundaries since we wrap)
        if love.math.random() < 0.1 then
            local possible_dirs = {
                {x = 0, y = 1}, {x = 0, y = -1},
                {x = 1, y = 0}, {x = -1, y = 0}
            }
            -- Remove opposite direction
            for i, dir in ipairs(possible_dirs) do
                if dir.x == -self.bg_snake_dir.x and dir.y == -self.bg_snake_dir.y then
                    table.remove(possible_dirs, i)
                    break
                end
            end
            local new_dir = possible_dirs[love.math.random(#possible_dirs)]
            self.bg_snake_dir = new_dir
        end
        
        -- Add new head position
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
    
    -- Update particles
    for i = #self.particles, 1, -1 do
        if not self.particles[i]:update() then
            table.remove(self.particles, i)
        end
    end
    
    -- Update grid color transition
    self.color_transition = self.color_transition + dt * self.color_change_speed
    if self.color_transition >= 1 then
        self.color_transition = 0
        self.current_grid_colors = (self.current_grid_colors % #self.grid_colors) + 1
    end
end

function BackgroundManager:draw()
    -- Fill background
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
    
    -- Calculate interpolated grid colors
    local next_colors = self.grid_colors[(self.current_grid_colors % #self.grid_colors) + 1]
    local current_colors = self.grid_colors[self.current_grid_colors]
    
    local interpolated_colors = {}
    for i = 1, 2 do
        interpolated_colors[i] = {}
        for j = 1, 3 do
            interpolated_colors[i][j] = current_colors[i][j] + 
                (next_colors[i][j] - current_colors[i][j]) * self.color_transition
        end
    end
    
    -- Draw background grid exactly fitting window dimensions
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
    
    -- Draw border around the grid if enabled
    if self.show_border then
        local border_thickness = 2
        love.graphics.setColor(constants.SNAKE_GREEN)
        -- Top border
        love.graphics.rectangle('fill', 0, 0, 
                              constants.WINDOW_WIDTH, border_thickness)
        -- Bottom border
        love.graphics.rectangle('fill', 0, constants.WINDOW_HEIGHT - border_thickness, 
                              constants.WINDOW_WIDTH, border_thickness)
        -- Left border
        love.graphics.rectangle('fill', 0, 0, 
                              border_thickness, constants.WINDOW_HEIGHT)
        -- Right border
        love.graphics.rectangle('fill', constants.WINDOW_WIDTH - border_thickness, 0, 
                              border_thickness, constants.WINDOW_HEIGHT)
    end
    
    -- Draw particles behind snake
    for _, particle in ipairs(self.particles) do
        particle:draw()
    end
    
    -- Draw snake
    for i, pos in ipairs(self.bg_snake_pos) do
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
    
    love.graphics.setColor(1, 1, 1, 1)
end

function BackgroundManager:toggle_border()
    self.show_border = not self.show_border
    return self.show_border
end

return BackgroundManager