local constants = require('src.constants')

local BackgroundEffect = {}

-- Leaf shape vertices (relative to center point)
local LEAF_VERTICES = {
    0, -10,    -- top point
    5, -5,     -- right top
    8, 0,      -- right middle
    5, 5,      -- right bottom
    0, 10,     -- bottom point
    -5, 5,     -- left bottom
    -8, 0,     -- left middle
    -5, -5     -- left top
}

function BackgroundEffect.new()
    local self = {
        leaves = {},
        time = 0,
        spawn_timer = 0,
        spawn_rate = 0.3,  -- Spawn a new leaf every 0.3 seconds
        colors = {
            {0.180, 0.545, 0.341, 1},  -- Dark green
            {0.565, 0.933, 0.565, 1},   -- Light green
            {0.2, 0.8, 0.2, 1}          -- Medium green
        }
    }

    -- Function to create a new leaf
    local function create_leaf()
        -- Only spawn in the non-playable areas (left and right of the game area)
        local side = love.math.random() < 0.5 and 1 or 2  -- 1 = left side, 2 = right side
        local x
        if side == 1 then
            x = love.math.random(0, constants.OFFSET_X - 20)  -- Left side
        else
            x = love.math.random(constants.OFFSET_X + constants.PLAYABLE_WIDTH + 20, constants.WINDOW_WIDTH)  -- Right side
        end

        return {
            x = x,
            y = -20,  -- Start above screen
            rotation = love.math.random() * math.pi * 2,
            spin_speed = love.math.random(-2, 2),
            fall_speed = love.math.random(50, 100),
            sway_speed = love.math.random(1, 3),
            sway_amount = love.math.random(20, 40),
            initial_x = x,
            size = love.math.random(0.8, 1.2),
            color = love.math.random(1, #self.colors),
            opacity = 1,
            fading = false
        }
    end

    -- Create initial leaves
    for i = 1, 20 do
        local leaf = create_leaf()
        leaf.y = love.math.random(0, constants.WINDOW_HEIGHT)  -- Distribute initial leaves across screen
        table.insert(self.leaves, leaf)
    end

    function self:update(dt)
        self.time = self.time + dt
        self.spawn_timer = self.spawn_timer + dt

        -- Spawn new leaves
        if self.spawn_timer >= self.spawn_rate then
            self.spawn_timer = 0
            table.insert(self.leaves, create_leaf())
        end

        -- Update leaves
        for i = #self.leaves, 1, -1 do
            local leaf = self.leaves[i]
            
            -- Update position
            leaf.y = leaf.y + leaf.fall_speed * dt
            leaf.x = leaf.initial_x + math.sin(self.time * leaf.sway_speed) * leaf.sway_amount
            leaf.rotation = leaf.rotation + leaf.spin_speed * dt

            -- Start fading when leaf touches ground
            if leaf.y >= constants.WINDOW_HEIGHT - 10 and not leaf.fading then
                leaf.fading = true
            end

            -- Update opacity for fading leaves
            if leaf.fading then
                leaf.opacity = leaf.opacity - dt
                if leaf.opacity <= 0 then
                    table.remove(self.leaves, i)
                end
            end
        end
    end

    function self:draw()
        -- Fill the non-playable area with the base background color first
        love.graphics.stencil(function()
            -- Draw inverse of playable area
            love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", 
                constants.OFFSET_X, 
                constants.OFFSET_Y, 
                constants.PLAYABLE_WIDTH, 
                constants.PLAYABLE_HEIGHT
            )
        end, "replace", 1)
        love.graphics.setStencilTest("equal", 1)

        -- Fill with base background color
        love.graphics.setColor(unpack(constants.BACKGROUND_COLOR))
        love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)

        -- Draw leaves
        for _, leaf in ipairs(self.leaves) do
            local color = self.colors[leaf.color]
            love.graphics.setColor(color[1], color[2], color[3], leaf.opacity)
            
            love.graphics.push()
            love.graphics.translate(leaf.x, leaf.y)
            love.graphics.rotate(leaf.rotation)
            love.graphics.scale(leaf.size, leaf.size)
            love.graphics.polygon("fill", LEAF_VERTICES)
            love.graphics.pop()
        end

        -- Reset stencil test and color
        love.graphics.setStencilTest()
        love.graphics.setColor(1, 1, 1, 1)
    end

    return self
end

return BackgroundEffect
