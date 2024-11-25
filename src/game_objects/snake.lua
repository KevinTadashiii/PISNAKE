local constants = require('src.constants')

local Snake = {}
Snake.__index = Snake

function Snake.new()
    local self = setmetatable({}, Snake)
    self.positions = {{math.floor(constants.GRID_WIDTH / 2), math.floor(constants.GRID_HEIGHT / 2)}}
    self.direction = {1, 0}
    self.next_direction = {1, 0}
    self.length = 1
    self.rainbow_mode = false
    self.rainbow_time = 0  -- Time accumulator for rainbow animation
    self.rainbow_speed = 2  -- Speed of color cycling
    self.grow_pending = false
    self.last_move_time = 0
    self.move_delay = constants.MOVE_DELAY
    self.score = 0
    return self
end

function Snake:getHeadPosition()
    return self.positions[1]
end

function Snake:getRainbowColor(index)
    -- Simple RGB wave effect
    local t = self.rainbow_time
    local offset = index * 0.3
    
    -- Create a simple repeating pattern: Red -> Green -> Blue -> Red
    local pos = (t + offset) % 3
    
    if pos < 1 then
        -- Red to Green
        local g = pos
        return {1, g, 0}
    elseif pos < 2 then
        -- Green to Blue
        local g = 2 - pos
        local b = pos - 1
        return {0, g, b}
    else
        -- Blue to Red
        local b = 3 - pos
        local r = pos - 2
        return {r, 0, b}
    end
end

function Snake:update(dt)
    -- Update rainbow animation
    if self.rainbow_mode then
        self.rainbow_time = self.rainbow_time + dt * 2 -- Adjusted wave speed
    end
    
    -- dt is in seconds, so no need to multiply by 1000
    self.last_move_time = self.last_move_time + dt
    
    if self.last_move_time >= self.move_delay/1000 then  -- Convert move_delay to seconds
        self.direction = self.next_direction
        
        local cur = self:getHeadPosition()
        local new_x = cur[1] + self.direction[1]
        local new_y = cur[2] + self.direction[2]
        local new = {new_x, new_y}

        if new_x < 0 or new_x >= constants.GRID_WIDTH or 
           new_y < 0 or new_y >= constants.GRID_HEIGHT then
            return false
        end
        
        for i = 2, #self.positions do
            local pos = self.positions[i]
            if new[1] == pos[1] and new[2] == pos[2] then
                return false
            end
        end

        table.insert(self.positions, 1, new)
        if #self.positions > self.length then
            table.remove(self.positions)
        end
        
        self.last_move_time = 0
        return true
    end
    return true
end

function Snake:draw()
    for i, pos in ipairs(self.positions) do
        local screen_x = constants.OFFSET_X + (pos[1] * constants.GRID_SIZE) + constants.SNAKE_PADDING
        local screen_y = constants.OFFSET_Y + (pos[2] * constants.GRID_SIZE) + constants.SNAKE_PADDING
        local width = constants.GRID_SIZE - (2 * constants.SNAKE_PADDING)
        local height = constants.GRID_SIZE - (2 * constants.SNAKE_PADDING)
        
        local color
        if self.rainbow_mode then
            color = self:getRainbowColor(i)
        else
            color = i == 1 and constants.SNAKE_HEAD_COLOR or constants.SNAKE_COLOR
        end
        
        love.graphics.setColor(unpack(color))
        love.graphics.rectangle('fill', screen_x, screen_y, width, height)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Snake:drawRetro()
    for i, pos in ipairs(self.positions) do
        local x = constants.OFFSET_X + (pos[1] * constants.GRID_SIZE) + constants.SNAKE_PADDING
        local y = constants.OFFSET_Y + (pos[2] * constants.GRID_SIZE) + constants.SNAKE_PADDING
        local width = constants.GRID_SIZE - (2 * constants.SNAKE_PADDING)
        local height = constants.GRID_SIZE - (2 * constants.SNAKE_PADDING)
        
        love.graphics.setColor(i == 1 and {1, 1, 1} or {0.8, 0.8, 0.8})
        love.graphics.rectangle('fill', x, y, width, height)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Snake:grow()
    self.length = self.length + 1
    self.score = self.score + 10
    self.move_delay = math.max(50, constants.MOVE_DELAY - math.floor(self.score / 50) * 5)
end

function Snake:setDirection(new_dir)
    -- Prevent 180-degree turns
    if (self.direction[1] ~= -new_dir[1] or self.direction[2] ~= -new_dir[2]) then
        self.next_direction = new_dir
    end
end

function Snake:reset()
    self.positions = {{math.floor(constants.GRID_WIDTH / 2), math.floor(constants.GRID_HEIGHT / 2)}}
    self.direction = {1, 0}
    self.next_direction = {1, 0}
    self.length = 1
    self.rainbow_mode = false
    self.rainbow_time = 0
    self.score = 0
    self.move_delay = constants.MOVE_DELAY
    self.last_move_time = 0
end

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

function Snake:contains_position(pos)
    for _, snake_pos in ipairs(self.positions) do
        if snake_pos[1] == pos[1] and snake_pos[2] == pos[2] then
            return true
        end
    end
    return false
end

return Snake