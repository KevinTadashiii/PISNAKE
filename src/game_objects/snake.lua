-- Snake Module --

local constants = require('src.constants')

--- Snake class representing the player-controlled snake
local Snake = {}
Snake.__index = Snake

--- Creates a new Snake instance
-- @return table: New Snake instance with default properties
function Snake.new()
    local self = setmetatable({}, Snake)
    
    -- Position and movement
    self.positions = {{
        math.floor(constants.GRID_WIDTH / 2),   -- Start at center X
        math.floor(constants.GRID_HEIGHT / 2)   -- Start at center Y
    }}
    self.direction = {1, 0}        -- Initial direction (right)
    self.next_direction = {1, 0}   -- Buffered next direction
    
    -- Snake properties
    self.length = 1               -- Initial length
    self.score = 0               -- Starting score
    self.grow_pending = false    -- Growth flag
    
    -- Movement timing
    self.last_move_time = 0                -- Time since last move
    self.move_delay = constants.MOVE_DELAY -- Current move interval
    
    -- Visual effects
    self.rainbow_mode = false     -- Rainbow color mode flag
    self.rainbow_time = 0         -- Time accumulator for rainbow effect
    self.rainbow_speed = 2        -- Rainbow color cycle speed
    
    return self
end

--- Calculates rainbow color for snake segments
-- @param index number: Segment index (1 is head)
-- @return table: RGB color values {r, g, b}
function Snake:getRainbowColor(index)
    local t = self.rainbow_time
    local offset = index * 0.3  -- Offset for each segment
    local pos = (t + offset) % 3  -- Create 3-phase cycle
    
    -- Generate smooth color transitions
    if pos < 1 then
        -- Red to Green transition
        return {1, pos, 0}
    elseif pos < 2 then
        -- Green to Blue transition
        return {0, 2 - pos, pos - 1}
    else
        -- Blue to Red transition
        return {pos - 2, 0, 3 - pos}
    end
end

--- Updates snake position and state
-- @param dt number: Delta time since last update
-- @return boolean: False if collision occurred, true otherwise
function Snake:update(dt)
    -- Update rainbow effect if active
    if self.rainbow_mode then
        self.rainbow_time = self.rainbow_time + dt * self.rainbow_speed
    end
    
    -- Accumulate movement time
    self.last_move_time = self.last_move_time + dt
    
    -- Check if it's time to move
    if self.last_move_time >= self.move_delay/1000 then
        -- Apply buffered direction change
        self.direction = self.next_direction
        
        -- Calculate new head position
        if not self:_updatePosition() then
            return false  -- Collision occurred
        end
        
        self.last_move_time = 0
    end
    return true
end

--- Updates snake's position and checks for collisions
-- @return boolean: False if collision occurred, true otherwise
function Snake:_updatePosition()
    local cur = self:getHeadPosition()
    local new_x = cur[1] + self.direction[1]
    local new_y = cur[2] + self.direction[2]
    
    -- Check wall collisions
    if new_x < 0 or new_x >= constants.GRID_WIDTH or 
       new_y < 0 or new_y >= constants.GRID_HEIGHT then
        return false
    end
    
    -- Check self-collision
    local new_pos = {new_x, new_y}
    for i = 2, #self.positions do
        local pos = self.positions[i]
        if new_pos[1] == pos[1] and new_pos[2] == pos[2] then
            return false
        end
    end
    
    -- Update snake segments
    table.insert(self.positions, 1, new_pos)
    if #self.positions > self.length then
        table.remove(self.positions)
    end
    
    return true
end

--- Draws the snake on screen
function Snake:draw()
    for i, pos in ipairs(self.positions) do
        -- Calculate screen coordinates with padding
        local screen_x = constants.OFFSET_X + (pos[1] * constants.GRID_SIZE) + constants.SNAKE_PADDING
        local screen_y = constants.OFFSET_Y + (pos[2] * constants.GRID_SIZE) + constants.SNAKE_PADDING
        local width = constants.GRID_SIZE - (2 * constants.SNAKE_PADDING)
        local height = constants.GRID_SIZE - (2 * constants.SNAKE_PADDING)
        
        -- Determine segment color
        local color
        if self.rainbow_mode then
            color = self:getRainbowColor(i)
        else
            color = i == 1 and constants.SNAKE_HEAD_COLOR or constants.SNAKE_COLOR
        end
        
        -- Draw snake segment
        love.graphics.setColor(unpack(color))
        love.graphics.rectangle('fill', screen_x, screen_y, width, height)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

--- Gets the current head position
-- @return table: Head position {x, y}
function Snake:getHeadPosition()
    return self.positions[1]
end

--- Checks if snake contains a specific position
-- @param pos table: Position to check {x, y}
-- @return boolean: True if position is part of snake
function Snake:contains_position(pos)
    for _, snake_pos in ipairs(self.positions) do
        if snake_pos[1] == pos[1] and snake_pos[2] == pos[2] then
            return true
        end
    end
    return false
end

--- Resets snake to initial state
function Snake:reset()
    -- Reset position and direction
    self.positions = {{
        math.floor(constants.GRID_WIDTH / 2),
        math.floor(constants.GRID_HEIGHT / 2)
    }}
    self.direction = {1, 0}
    self.next_direction = {1, 0}
    
    -- Reset properties
    self.length = 1
    self.score = 0
    self.rainbow_mode = false
    self.move_delay = constants.MOVE_DELAY
    self.last_move_time = 0
end

--- Increases snake length and updates score
function Snake:grow()
    self.length = self.length + 1
    self.score = self.score + 10
    
    -- Increase speed based on score
    self.move_delay = math.max(50, constants.MOVE_DELAY - math.floor(self.score / 50) * 5)
end

--- Sets the snake's direction
-- @param new_dir table: New direction vector {x, y}
function Snake:setDirection(new_dir)
    -- Prevent 180-degree turns
    if (self.direction[1] ~= -new_dir[1] or self.direction[2] ~= -new_dir[2]) then
        self.next_direction = new_dir
    end
end

--- Checks for collision with self
-- @return boolean: True if snake collided with itself
function Snake:checkCollision()
    local head = self.positions[1]
    for i = 2, #self.positions do
        local pos = self.positions[i]
        if head[1] == pos[1] and head[2] == pos[2] then
            return true
        end
    end
    return false
end

return Snake