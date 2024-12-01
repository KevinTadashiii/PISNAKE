-- BackgroundEffect Module --

local constants = require('src.constants')

local BackgroundEffect = {}

-- Constants for leaf customization
local LEAF = {
    -- Leaf shape vertices (relative to center point)
    VERTICES = {
        0, -10,    -- top point
        5, -5,     -- right top
        8, 0,      -- right middle
        5, 5,     -- right bottom
        0, 10,     -- bottom point
        -5, 5,     -- left bottom
        -8, 0,     -- left middle
        -5, -5     -- left top
    },
    -- Color palette for leaves (R, G, B, A)
    COLORS = {
        {0.180, 0.545, 0.341, 1},  -- Dark green
        {0.565, 0.933, 0.565, 1},  -- Light green
        {0.2, 0.8, 0.2, 1}         -- Medium green
    },
    -- Spawn settings
    SPAWN_RATE = 0.3,              -- New leaf every 0.3 seconds
    INITIAL_COUNT = 20,            -- Number of leaves to start with
    -- Movement settings
    MIN_FALL_SPEED = 50,
    MAX_FALL_SPEED = 100,
    MIN_SWAY_SPEED = 1,
    MAX_SWAY_SPEED = 3,
    MIN_SWAY_AMOUNT = 20,
    MAX_SWAY_AMOUNT = 40,
    -- Size settings
    MIN_SIZE = 0.8,
    MAX_SIZE = 1.2
}

--[[
    Creates a new leaf with randomized properties.
    Returns: Table containing leaf properties
]]
local function create_leaf()
    -- Determine spawn side (left or right of play area)
    local side = love.math.random() < 0.5 and 1 or 2
    local x
    if side == 1 then
        x = love.math.random(0, constants.OFFSET_X - 20)  -- Left side
    else
        x = love.math.random(constants.OFFSET_X + constants.PLAYABLE_WIDTH + 20, constants.WINDOW_WIDTH)  -- Right side
    end

    return {
        x = x,
        y = -20,                                          -- Start above screen
        rotation = love.math.random() * math.pi * 2,      -- Random initial rotation
        spin_speed = love.math.random(-2, 2),            -- Rotation speed
        fall_speed = love.math.random(LEAF.MIN_FALL_SPEED, LEAF.MAX_FALL_SPEED),
        sway_speed = love.math.random(LEAF.MIN_SWAY_SPEED, LEAF.MAX_SWAY_SPEED),
        sway_amount = love.math.random(LEAF.MIN_SWAY_AMOUNT, LEAF.MAX_SWAY_AMOUNT),
        initial_x = x,                                    -- Reference point for swaying
        size = love.math.random(LEAF.MIN_SIZE, LEAF.MAX_SIZE),
        color = love.math.random(1, #LEAF.COLORS),
        opacity = 1,
        fading = false
    }
end

--[[
    Creates a new BackgroundEffect instance.
    Returns: BackgroundEffect object with update and draw methods
]]
function BackgroundEffect.new()
    local self = {
        leaves = {},
        time = 0,
        spawn_timer = 0,
        spawn_rate = LEAF.SPAWN_RATE,
        colors = LEAF.COLORS
    }

    -- Initialize with starting leaves
    for i = 1, LEAF.INITIAL_COUNT do
        local leaf = create_leaf()
        leaf.y = love.math.random(0, constants.WINDOW_HEIGHT)  -- Distribute across screen
        table.insert(self.leaves, leaf)
    end

    --[[
        Updates leaf positions, rotations, and handles spawning/removal.
        Parameters:
            dt: Delta time since last update
            snake_dx: Snake's horizontal velocity (optional)
            snake_dy: Snake's vertical velocity (optional)
    ]]
    function self:update(dt, snake_dx, snake_dy)
        self.time = self.time + dt
        self.spawn_timer = self.spawn_timer + dt

        -- Spawn new leaves
        if self.spawn_timer >= self.spawn_rate then
            self.spawn_timer = 0
            table.insert(self.leaves, create_leaf())
        end

        -- Calculate snake movement influence
        local movement_influence = snake_dx and snake_dy and (math.abs(snake_dx) + math.abs(snake_dy)) or 0

        -- Update each leaf
        for i = #self.leaves, 1, -1 do
            local leaf = self.leaves[i]
            
            -- Update vertical position
            leaf.y = leaf.y + leaf.fall_speed * dt
            
            -- Calculate sway effect
            local base_sway = math.sin(self.time * leaf.sway_speed) * leaf.sway_amount
            local movement_sway = movement_influence * 30 * math.sin(self.time * 10 + leaf.y * 0.1)
            leaf.x = leaf.initial_x + base_sway + movement_sway
            
            -- Update rotation with movement influence
            leaf.rotation = leaf.rotation + leaf.spin_speed * dt + 
                          movement_influence * math.sin(self.time * 5) * 2

            -- Handle leaf fading when reaching bottom
            if leaf.y >= constants.WINDOW_HEIGHT - 10 and not leaf.fading then
                leaf.fading = true
            end

            if leaf.fading then
                leaf.opacity = leaf.opacity - dt
                if leaf.opacity <= 0 then
                    table.remove(self.leaves, i)
                end
            end
        end
    end

    --[[
        Renders all leaves and handles background masking.
    ]]
    function self:draw()
        -- Create stencil for non-playable areas
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

        -- Draw background
        love.graphics.setColor(unpack(constants.BACKGROUND_COLOR))
        love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)

        -- Draw all leaves
        for _, leaf in ipairs(self.leaves) do
            local color = self.colors[leaf.color]
            love.graphics.setColor(color[1], color[2], color[3], leaf.opacity)
            
            love.graphics.push()
            love.graphics.translate(leaf.x, leaf.y)
            love.graphics.rotate(leaf.rotation)
            love.graphics.scale(leaf.size, leaf.size)
            love.graphics.polygon("fill", LEAF.VERTICES)
            love.graphics.pop()
        end

        -- Reset graphics state
        love.graphics.setStencilTest()
        love.graphics.setColor(1, 1, 1, 1)
    end

    return self
end

return BackgroundEffect
