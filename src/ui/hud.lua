-- Heads-Up Display (HUD) implementation for the snake game
-- Handles score display and other HUD elements

local constants = require("src.constants")

local HUD = {}
HUD.__index = HUD

function HUD.new()
    local self = setmetatable({}, HUD)
    -- Load font
    self.score_font = love.graphics.newFont(constants.FONT_PATH, 16)
    -- Score animation
    self.score_scale = 1.0
    self.score_animation_time = 0
    self.score_animation_duration = 0.3  -- Duration in seconds
    return self
end

function HUD:update(dt)
    -- Update score animation
    if self.score_animation_time > 0 then
        self.score_animation_time = math.max(0, self.score_animation_time - dt)
        local progress = self.score_animation_time / self.score_animation_duration
        -- Elastic easing out for a bouncy effect
        local scale = 1 + math.sin(progress * math.pi) * 0.3
        self.score_scale = scale
    else
        self.score_scale = 1.0
    end
end

function HUD:trigger_score_animation()
    self.score_animation_time = self.score_animation_duration
end

function HUD:draw_score(score, position)
    -- Draw the score with a shadow effect at the specified position
    position = position or {x = 20, y = 20}  -- Default position
    local score_text = "Score: " .. score
    
    -- Calculate scaled dimensions
    local text_width = self.score_font:getWidth(score_text)
    local text_height = self.score_font:getHeight()
    local scale_x = self.score_scale
    local scale_y = self.score_scale
    
    -- Calculate center position for scaling
    local center_x = position.x + text_width/2
    local center_y = position.y + text_height/2
    
    -- Save current transform
    love.graphics.push()
    
    -- Move to center, scale, then move back
    love.graphics.translate(center_x, center_y)
    love.graphics.scale(scale_x, scale_y)
    love.graphics.translate(-center_x, -center_y)
    
    -- Draw shadow
    love.graphics.setFont(self.score_font)
    love.graphics.setColor(constants.BLACK)
    love.graphics.print(score_text, 
        position.x + 2,  -- Shadow offset x
        position.y + 2)  -- Shadow offset y
    
    -- Draw main text
    love.graphics.setColor(constants.WHITE)
    love.graphics.print(score_text, position.x, position.y)
    
    -- Restore transform
    love.graphics.pop()
end

function HUD:draw(game_data)
    -- Draw all HUD elements
    -- Args:
    --     game_data: Table containing game information (score, etc.)
    self:draw_score(game_data.score)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return HUD