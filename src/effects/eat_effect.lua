-- Eat Effect Module --

local constants = require('src.constants')

local EatEffect = {}
EatEffect.__index = EatEffect

--- Creates a new EatEffect instance
-- @return table: New EatEffect instance
function EatEffect.new()
    local self = setmetatable({}, EatEffect)
    self.particles = {}
    self.active = false
    self.duration = 0.3  -- Duration of the effect in seconds
    self.timer = 0
    return self
end

--- Triggers the eat effect at the specified position
-- @param x number: X coordinate in grid units
-- @param y number: Y coordinate in grid units
function EatEffect:trigger(x, y)
    -- Convert grid coordinates to screen coordinates
    local screen_x = constants.OFFSET_X + (x * constants.GRID_SIZE) + constants.GRID_SIZE/2
    local screen_y = constants.OFFSET_Y + (y * constants.GRID_SIZE) + constants.GRID_SIZE/2
    
    -- Create particles
    self.particles = {}
    for i = 1, 12 do  -- Create 12 particles
        local angle = (i / 12) * math.pi * 2
        local speed = love.math.random(100, 200)
        table.insert(self.particles, {
            x = screen_x,
            y = screen_y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = love.math.random(2, 4),
            color = {1, 0, 0, 1}  -- Red color with full alpha
        })
    end
    
    self.active = true
    self.timer = 0
end

--- Updates the eat effect
-- @param dt number: Delta time since last update
function EatEffect:update(dt)
    if not self.active then return end
    
    self.timer = self.timer + dt
    if self.timer >= self.duration then
        self.active = false
        return
    end
    
    -- Update particles
    for _, particle in ipairs(self.particles) do
        -- Update position
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        
        -- Fade out based on time
        particle.color[4] = 1 - (self.timer / self.duration)
        
        -- Add gravity effect
        particle.vy = particle.vy + 500 * dt
    end
end

--- Draws the eat effect
function EatEffect:draw()
    if not self.active then return end
    
    for _, particle in ipairs(self.particles) do
        love.graphics.setColor(unpack(particle.color))
        love.graphics.circle('fill', particle.x, particle.y, particle.size)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return EatEffect
