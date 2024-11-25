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
    -- Calculate grid dimensions based on window size
    self.window_grid_width = math.floor(constants.WINDOW_WIDTH / constants.GRID_SIZE)
    self.window_grid_height = math.floor(constants.WINDOW_HEIGHT / constants.GRID_SIZE)
    
    -- Initialize timing variables
    self.move_delay = 0.2  -- Snake moves every 0.2 seconds
    self.last_move_time = love.timer.getTime()
    
    -- Initialize particles
    self.particles = {}
    self.last_particle_time = love.timer.getTime()
    self.particle_delay = 0.1
    
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
        
        -- Turn around at window edges
        if new_x < 0 or new_x >= self.window_grid_width or new_y < 0 or new_y >= self.window_grid_height then
            self.bg_snake_dir.x = -self.bg_snake_dir.x
            self.bg_snake_dir.y = -self.bg_snake_dir.y
            new_x = head.x + self.bg_snake_dir.x
            new_y = head.y + self.bg_snake_dir.y
        end
        
        -- Randomly change direction
        if love.math.random() < 0.1 then
            local next_x = new_x + self.bg_snake_dir.x
            local next_y = new_y + self.bg_snake_dir.y
            if next_x >= 0 and next_x < self.window_grid_width and 
               next_y >= 0 and next_y < self.window_grid_height then
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
        end
        
        table.insert(self.bg_snake_pos, 1, {x = new_x, y = new_y})
        table.remove(self.bg_snake_pos)
        self.last_move_time = current_time
    end
    
    -- Add new particles
    if current_time - self.last_particle_time >= self.particle_delay then
        local x = love.math.random(constants.OFFSET_X, constants.WINDOW_WIDTH - constants.OFFSET_X)
        local y = love.math.random(constants.OFFSET_Y, constants.WINDOW_HEIGHT - constants.OFFSET_Y)
        table.insert(self.particles, Particle.new(x, y))
        self.last_particle_time = current_time
    end
    
    -- Update particles
    for i = #self.particles, 1, -1 do
        if not self.particles[i]:update() then
            table.remove(self.particles, i)
        end
    end
    
    -- Update grid colors
    self.color_transition = self.color_transition + self.color_change_speed
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
    
    -- Calculate full window grid dimensions
    local full_grid_width = math.ceil(constants.WINDOW_WIDTH / constants.GRID_SIZE)
    local full_grid_height = math.ceil(constants.WINDOW_HEIGHT / constants.GRID_SIZE)
    
    -- Draw background grid
    for y = 0, full_grid_height - 1 do
        for x = 0, full_grid_width - 1 do
            local color = interpolated_colors[((x + y) % 2) + 1]
            local rect_x = x * constants.GRID_SIZE
            local rect_y = y * constants.GRID_SIZE
            
            if rect_x + constants.GRID_SIZE > 0 and rect_x < constants.WINDOW_WIDTH and 
               rect_y + constants.GRID_SIZE > 0 and rect_y < constants.WINDOW_HEIGHT then
                love.graphics.setColor(unpack(color))
                love.graphics.rectangle('fill', rect_x, rect_y,
                                     constants.GRID_SIZE, constants.GRID_SIZE)
            end
        end
    end
    
    -- Draw particles behind snake
    for _, particle in ipairs(self.particles) do
        particle:draw()
    end
    
    -- Draw snake with proper offsets
    for i, pos in ipairs(self.bg_snake_pos) do
        local color = i == 1 and {0, 100/255, 0} or {0, 80/255, 0}
        local screen_x = constants.OFFSET_X + (pos.x * constants.GRID_SIZE)
        local screen_y = constants.OFFSET_Y + (pos.y * constants.GRID_SIZE)
        love.graphics.setColor(unpack(color))
        love.graphics.rectangle('fill',
            screen_x + constants.SNAKE_PADDING,
            screen_y + constants.SNAKE_PADDING,
            constants.GRID_SIZE - 2 * constants.SNAKE_PADDING,
            constants.GRID_SIZE - 2 * constants.SNAKE_PADDING)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

return BackgroundManager