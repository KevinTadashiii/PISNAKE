local Transition = {}

function Transition.new()
    local self = {
        active = false,
        timer = 0,
        duration = 0.8,
        fade_out = true,
        callback = nil,
        cells = {},
        hex_size = 30,  -- Size of hexagonal cells
        canvas = nil,
        canvas_opacity = 0,
        colors = {
            {0.2, 0.8, 0.2},  -- Light green
            {0.1, 0.6, 0.1},  -- Medium green
            {0.05, 0.4, 0.05} -- Dark green
        }
    }
    
    -- Create canvas for smooth transitions
    self.canvas = love.graphics.newCanvas()
    
    -- Calculate hex grid dimensions
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    local hex_width = self.hex_size * 1.732  -- sqrt(3)
    local hex_height = self.hex_size * 2
    local rows = math.ceil(screen_height / (hex_height * 0.75)) + 2
    local cols = math.ceil(screen_width / hex_width) + 2
    
    -- Initialize hex grid
    for row = 0, rows do
        for col = 0, cols do
            local x = col * hex_width + (row % 2) * (hex_width / 2)
            local y = row * (hex_height * 0.75)
            table.insert(self.cells, {
                x = x - hex_width,  -- Offset to cover screen edges
                y = y - hex_height,
                size = self.hex_size,
                active = false,
                alpha = 0,
                color = love.math.random(1, #self.colors),
                scale = 0
            })
        end
    end

    -- Function to draw a single hexagon
    local function drawHexagon(x, y, size)
        local vertices = {}
        for i = 0, 5 do
            local angle = (i * 60 + 30) * math.pi / 180
            table.insert(vertices, x + size * math.cos(angle))
            table.insert(vertices, y + size * math.sin(angle))
        end
        love.graphics.polygon('fill', vertices)
    end

    function self:start_transition(callback)
        self.active = true
        self.timer = 0
        self.fade_out = true
        self.callback = callback
        self.canvas_opacity = 1
        
        -- Reset all cells
        for _, cell in ipairs(self.cells) do
            cell.active = false
            cell.alpha = 0
            cell.scale = 0
            cell.color = love.math.random(1, #self.colors)
        end
        
        -- Activate center cell
        local center_cell = self.cells[math.floor(#self.cells / 2)]
        center_cell.active = true
        center_cell.alpha = 0
        center_cell.scale = 0
    end

    function self:update(dt)
        if not self.active then return end

        self.timer = self.timer + dt
        local progress = math.min(self.timer / self.duration, 1)

        -- Update cells
        local screen_center_x = love.graphics.getWidth() / 2
        local screen_center_y = love.graphics.getHeight() / 2

        for _, cell in ipairs(self.cells) do
            if cell.active then
                if self.fade_out then
                    -- Scale and fade in
                    cell.scale = math.min(1, cell.scale + dt * 8)
                    cell.alpha = math.min(1, cell.alpha + dt * 4)
                    
                    -- Activate neighboring cells when this cell is partially scaled
                    if cell.scale > 0.3 then
                        for _, other in ipairs(self.cells) do
                            if not other.active then
                                local dx = other.x - cell.x
                                local dy = other.y - cell.y
                                local dist = math.sqrt(dx * dx + dy * dy)
                                if dist < self.hex_size * 2.5 then
                                    other.active = true
                                end
                            end
                        end
                    end
                else
                    -- Scale and fade out from edges to center
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
        end

        if progress >= 1 then
            if self.fade_out then
                self.fade_out = false
                self.timer = 0
                if self.callback then
                    self.callback()
                end
            else
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

    function self:draw()
        if not self.active then return end

        love.graphics.setCanvas(self.canvas)
        love.graphics.clear()

        -- Draw all active cells
        for _, cell in ipairs(self.cells) do
            if cell.active and cell.alpha > 0 then
                local color = self.colors[cell.color]
                love.graphics.setColor(color[1], color[2], color[3], cell.alpha)
                drawHexagon(cell.x + self.hex_size, cell.y + self.hex_size, 
                          self.hex_size * cell.scale)
            end
        end

        love.graphics.setCanvas()
        
        -- Draw the canvas
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.canvas, 0, 0)
        
        -- Reset graphics state
        love.graphics.setColor(1, 1, 1, 1)
    end

    return self
end

return Transition
