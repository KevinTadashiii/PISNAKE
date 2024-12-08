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
    
    -- Load apple sprite
    self.sprite = love.graphics.newImage(constants.APPLE_SPRITE_PATH)
    
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
-- Converts grid coordinates to screen coordinates and draws the food sprite
function Food:draw()
    -- Convert grid coordinates to screen coordinates
    local screen_x = constants.OFFSET_X + (self.position[1] * constants.GRID_SIZE)
    local screen_y = constants.OFFSET_Y + (self.position[2] * constants.GRID_SIZE)
    
    -- Calculate scale to fit grid size
    local desired_size = constants.GRID_SIZE * 3.2  -- 320% of grid size for better fit
    local scale_x = desired_size / self.sprite:getWidth()
    local scale_y = desired_size / self.sprite:getHeight()
    local scale = math.min(scale_x, scale_y)  -- Use smaller scale to maintain aspect ratio
    
    -- Draw apple sprite
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color to white for proper sprite rendering
    love.graphics.draw(
        self.sprite,
        screen_x + constants.GRID_SIZE/2 + 1,  -- Center X, slight offset to the right
        screen_y + constants.GRID_SIZE/2 + 2,  -- Center Y, offset up by 2 pixels
        0,                                 -- Rotation (none)
        scale,                            -- Scale X
        scale,                            -- Scale Y
        self.sprite:getWidth()/2,         -- Origin X (center)
        self.sprite:getHeight()/2         -- Origin Y (center)
    )
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