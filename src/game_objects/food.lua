-- Food Module --

local constants = require('src.constants')

--- Food class for snake game
local Food = {}
Food.__index = Food

--- Creates a new Food instance
-- @return table: New Food instance with randomized position
function Food.new()
    local self = setmetatable({}, Food)
    
    -- Initialize food position coordinates
    self.position = {0, 0}  -- Format: {x, y} in grid coordinates
    
    -- Set initial random position
    self:randomize_position()
    
    return self
end

--- Generates a new random position for the food
-- Ensures food appears within valid grid boundaries
function Food:randomize_position()
    self.position = {
        love.math.random(0, constants.GRID_WIDTH - 1),   -- Random X coordinate
        love.math.random(0, constants.GRID_HEIGHT - 1)   -- Random Y coordinate
    }
end

--- Renders the food object on screen
-- Converts grid coordinates to screen coordinates and draws the food
function Food:draw()
    -- Convert grid coordinates to screen coordinates
    local screen_x = constants.OFFSET_X + (self.position[1] * constants.GRID_SIZE)
    local screen_y = constants.OFFSET_Y + (self.position[2] * constants.GRID_SIZE)
    
    -- Draw food with specified color
    love.graphics.setColor(constants.FOOD_COLOR)
    love.graphics.rectangle('fill', 
        screen_x, 
        screen_y, 
        constants.GRID_SIZE, 
        constants.GRID_SIZE
    )
    
    -- Reset color to default
    love.graphics.setColor(1, 1, 1, 1)
end

--- Gets the current position of the food
-- @return table: Current position in grid coordinates {x, y}
function Food:get_position()
    return {self.position[1], self.position[2]}
end

--- Checks if food is at a specific position
-- @param x number: X coordinate to check
-- @param y number: Y coordinate to check
-- @return boolean: True if food is at specified position
function Food:is_at_position(x, y)
    return self.position[1] == x and self.position[2] == y
end

return Food