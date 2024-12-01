-- Transition Module --

local Transition = {}

-- Mathematical and visual constants
local SQRT3 = 1.732  -- Square root of 3, used for hexagon width calculations
local DEFAULT_DURATION = 0.8  -- Duration of the transition animation in seconds
local DEFAULT_HEX_SIZE = 30  -- Base size of each hexagonal cell in pixels

-- Color palette for the hexagonal cells
-- Uses different shades of green to match the snake theme
local COLORS = {
    {0.2, 0.8, 0.2},  -- Light green: Creates a vibrant outer layer
    {0.1, 0.6, 0.1},  -- Medium green: Provides visual depth
    {0.05, 0.4, 0.05} -- Dark green: Forms the base layer
}

--[[
    Draws a single hexagonal cell on the screen.
    Uses LÖVE2D's polygon drawing function to create a hexagon
    from six vertices arranged in a regular hexagon pattern.
    
    @param x (number) Center X coordinate of the hexagon
    @param y (number) Center Y coordinate of the hexagon
    @param size (number) Distance from center to any vertex
]]
local function drawHexagon(x, y, size)
    local vertices = {}
    for i = 0, 5 do
        local angle = (i * 60 + 30) * math.pi / 180  -- 30° offset for flat-top orientation
        table.insert(vertices, x + size * math.cos(angle))
        table.insert(vertices, y + size * math.sin(angle))
    end
    love.graphics.polygon('fill', vertices)
end

--[[
    Creates a new hexagonal cell with default properties.
    Each cell is part of the transition grid and can be individually
    animated with scaling and fade effects.
    
    @param x (number) X position of the cell in the grid
    @param y (number) Y position of the cell in the grid
    @param size (number) Base size of the hexagon
    @return (table) New cell object with default properties
]]
local function createHexCell(x, y, size)
    return {
        x = x,
        y = y,
        size = size,
        active = false,     -- Whether this cell is currently part of the animation
        alpha = 0,          -- Transparency value (0 = invisible, 1 = solid)
        color = love.math.random(1, #COLORS),  -- Randomly assigned color from palette
        scale = 0          -- Current scale factor for size animation
    }
end

--[[
    Initializes the complete hexagonal grid used for the transition effect.
    Creates a grid large enough to cover the entire screen plus some padding
    to ensure smooth transitions at the edges.
    
    @param screen_width (number) Width of the game window
    @param screen_height (number) Height of the game window
    @param hex_size (number) Base size of each hexagonal cell
    @return (table) Array of hex cells forming the complete grid
]]
local function initializeHexGrid(screen_width, screen_height, hex_size)
    local cells = {}
    local hex_width = hex_size * SQRT3  -- Width of a hexagon
    local hex_height = hex_size * 2     -- Height of a hexagon
    -- Add extra rows/columns to ensure full screen coverage
    local rows = math.ceil(screen_height / (hex_height * 0.75)) + 2
    local cols = math.ceil(screen_width / hex_width) + 2
    
    for row = 0, rows do
        for col = 0, cols do
            -- Offset every other row by half a hexagon width for proper tiling
            local x = col * hex_width + (row % 2) * (hex_width / 2)
            local y = row * (hex_height * 0.75)  -- Overlap rows by 1/4 to create tight pattern
            table.insert(cells, createHexCell(
                x - hex_width,  -- Offset to cover screen edges
                y - hex_height,
                hex_size
            ))
        end
    end
    
    return cells
end

function Transition.new()
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    
    -- Initialize the transition object with default properties
    local self = {
        active = false,          -- Whether transition is currently running
        timer = 0,              -- Tracks animation progress
        duration = DEFAULT_DURATION,
        fade_out = true,        -- true = fading out, false = fading in
        callback = nil,         -- Function to call when fade-out completes
        hex_size = DEFAULT_HEX_SIZE,
        canvas = love.graphics.newCanvas(),  -- For efficient rendering
        canvas_opacity = 0,
        cells = initializeHexGrid(screen_width, screen_height, DEFAULT_HEX_SIZE)
    }
    
    --[[
        Updates a single cell's animation state during the transition.
        Handles both fade-in and fade-out animations with scaling effects.
        
        @param cell (table) The cell to update
        @param dt (number) Delta time since last frame
        @param screen_center_x (number) X coordinate of screen center
        @param screen_center_y (number) Y coordinate of screen center
        @param progress (number) Overall transition progress (0-1)
    ]]
    local function updateCell(cell, dt, screen_center_x, screen_center_y, progress)
        if not cell.active then return end
        
        if self.fade_out then
            -- Fade-out animation: cells grow and become more opaque
            cell.scale = math.min(1, cell.scale + dt * 8)
            cell.alpha = math.min(1, cell.alpha + dt * 4)
            
            -- Activate neighboring cells when this cell is partially scaled
            if cell.scale > 0.3 then
                self:activateNeighbors(cell)
            end
        else
            -- Fade-in animation: cells shrink and fade based on distance from center
            local dx = cell.x + self.hex_size - screen_center_x
            local dy = cell.y + self.hex_size - screen_center_y
            local dist_to_center = math.sqrt(dx * dx + dy * dy)
            local max_dist = math.sqrt(screen_width * screen_width + screen_height * screen_height) / 2
            local fade_start = (1 - progress) * max_dist
            
            if dist_to_center > fade_start then
                cell.alpha = math.max(0, cell.alpha - dt * 4)
                cell.scale = math.max(0, cell.scale - dt * 4)
            end
        end
    end
    
    --[[
        Activates neighboring cells within a certain radius.
        Used during fade-out to create the spreading effect.
        
        @param cell (table) The cell whose neighbors should be activated
    ]]
    function self:activateNeighbors(cell)
        for _, other in ipairs(self.cells) do
            if not other.active then
                local dx = other.x - cell.x
                local dy = other.y - cell.y
                local dist = math.sqrt(dx * dx + dy * dy)
                -- Activate if within 2.5 cell widths for smooth spreading
                if dist < self.hex_size * 2.5 then
                    other.active = true
                end
            end
        end
    end

    --[[
        Starts a new transition animation.
        
        @param callback (function) Optional function to call when fade-out completes
    ]]
    function self:start_transition(callback)
        self.active = true
        self.timer = 0
        self.fade_out = true
        self.callback = callback
        self.canvas_opacity = 1
        
        -- Reset all cells to initial state
        for _, cell in ipairs(self.cells) do
            cell.active = false
            cell.alpha = 0
            cell.scale = 0
            cell.color = love.math.random(1, #COLORS)
        end
        
        -- Start animation from center cell
        local center_cell = self.cells[math.floor(#self.cells / 2)]
        center_cell.active = true
    end

    --[[
        Updates the transition animation state.
        Called every frame while the transition is active.
        
        @param dt (number) Delta time since last frame
    ]]
    function self:update(dt)
        if not self.active then return end

        self.timer = self.timer + dt
        local progress = math.min(self.timer / self.duration, 1)
        local screen_center_x = love.graphics.getWidth() / 2
        local screen_center_y = love.graphics.getHeight() / 2

        -- Update all cells
        for _, cell in ipairs(self.cells) do
            updateCell(cell, dt, screen_center_x, screen_center_y, progress)
        end

        -- Handle transition phase changes
        if progress >= 1 then
            if self.fade_out then
                -- Switch to fade-in phase
                self.fade_out = false
                self.timer = 0
                if self.callback then
                    self.callback()
                end
            else
                -- Check if all cells have faded
                local all_faded = true
                for _, cell in ipairs(self.cells) do
                    if cell.alpha > 0 then
                        all_faded = false
                        break
                    end
                end
                if all_faded then
                    self.active = false
                end
            end
        end
    end

    --[[
        Checks if the transition is currently active.
        @return (boolean) True if transition is running, false otherwise
    ]]
    function self:isActive()
        return self.active
    end

    --[[
        Renders the transition effect to the screen.
        Uses a canvas for efficient rendering of all active cells.
    ]]
    function self:draw()
        if not self.active then return end

        -- Draw to canvas for better performance
        love.graphics.setCanvas(self.canvas)
        love.graphics.clear()

        -- Draw all active cells
        for _, cell in ipairs(self.cells) do
            if cell.active and cell.alpha > 0 then
                local color = COLORS[cell.color]
                love.graphics.setColor(color[1], color[2], color[3], cell.alpha)
                drawHexagon(cell.x + self.hex_size, cell.y + self.hex_size, 
                          self.hex_size * cell.scale)
            end
        end

        -- Draw canvas to screen
        love.graphics.setCanvas()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.canvas, 0, 0)
        
        -- Reset graphics state
        love.graphics.setColor(1, 1, 1, 1)
    end

    return self
end

return Transition
