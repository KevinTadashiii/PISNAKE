-- Grid rendering component for the snake game
-- Handles the checkerboard pattern game board

local constants = require("src.constants")

local Grid = {}
Grid.__index = Grid

function Grid.new()
    local self = setmetatable({}, Grid)
    -- Pre-calculate grid colors for better performance
    self.colors = {
        [0] = constants.DARK_GREEN,  -- Even squares
        [1] = constants.LIGHT_GREEN  -- Odd squares
    }
    return self
end

function Grid:draw()
    -- Draw the game grid
    -- Draw only the playable area (17x17 grid)
    for y = 0, constants.GRID_HEIGHT - 1 do
        for x = 0, constants.GRID_WIDTH - 1 do
            -- Calculate actual screen position using offsets
            local rect_x = constants.OFFSET_X + (x * constants.GRID_SIZE)
            local rect_y = constants.OFFSET_Y + (y * constants.GRID_SIZE)
            
            -- Alternate colors for checkerboard pattern
            local color = self.colors[(x + y) % 2]
            
            -- Draw grid cell
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", 
                rect_x, rect_y, 
                constants.GRID_SIZE, constants.GRID_SIZE)
        end
    end
    
    -- Reset color to white
    love.graphics.setColor(1, 1, 1, 1)
end

return Grid