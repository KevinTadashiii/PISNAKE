-- Grid Module --

local constants = require("src.constants")

-- Grid configuration constants
local GRID = {
    COLORS = {
        [0] = constants.DARK_GREEN,   -- Even squares
        [1] = constants.LIGHT_GREEN   -- Odd squares
    }
}

-- Grid class for rendering the game board checkerboard pattern
local Grid = {}
Grid.__index = Grid

-- Initialize a new grid instance
function Grid.new()
    local self = setmetatable({}, Grid)
    self.colors = GRID.COLORS  -- Use pre-calculated colors for performance
    return self
end

-- Draw the game grid with alternating colors
function Grid:draw()
    self:draw_checkerboard()
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

-- Private helper functions

-- Draw the checkerboard pattern for the playable area
function Grid:draw_checkerboard()
    for y = 0, constants.GRID_HEIGHT - 1 do
        for x = 0, constants.GRID_WIDTH - 1 do
            -- Calculate screen position
            local rect_x = constants.OFFSET_X + (x * constants.GRID_SIZE)
            local rect_y = constants.OFFSET_Y + (y * constants.GRID_SIZE)
            
            -- Select color based on position parity
            love.graphics.setColor(self.colors[(x + y) % 2])
            
            -- Draw grid cell
            love.graphics.rectangle("fill", 
                rect_x, rect_y, 
                constants.GRID_SIZE, constants.GRID_SIZE)
        end
    end
end

return Grid