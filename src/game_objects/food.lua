local constants = require('src.constants')

local Food = {}
Food.__index = Food

function Food.new()
    local self = setmetatable({}, Food)
    self.position = {0, 0}
    self:randomize_position()
    return self
end

function Food:randomize_position()
    -- Randomize the food position within the grid boundaries
    self.position = {
        love.math.random(0, constants.GRID_WIDTH - 1),
        love.math.random(0, constants.GRID_HEIGHT - 1)
    }
end

function Food:draw()
    -- Calculate actual screen position using offsets
    local x = constants.OFFSET_X + (self.position[1] * constants.GRID_SIZE)
    local y = constants.OFFSET_Y + (self.position[2] * constants.GRID_SIZE)
    
    -- Draw food rectangle
    love.graphics.setColor(constants.FOOD_COLOR)
    love.graphics.rectangle('fill', x, y, constants.GRID_SIZE, constants.GRID_SIZE)
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

return Food