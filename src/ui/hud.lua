-- HUD Module --

local constants = require("src.constants")

-- HUD configuration constants
local UI = {
    SCORE = {
        FONT_SIZE = 16,
        DEFAULT_POSITION = {x = 20, y = 20},
        SHADOW_OFFSET = 2,
        ANIMATION = {
            DURATION = 0.3,    -- Duration in seconds
            MAX_SCALE = 1.3    -- Maximum scale during bounce
        }
    }
}

-- Heads-Up Display class for rendering game information
local HUD = {}
HUD.__index = HUD

-- Initialize a new HUD instance with required fonts and animation state
function HUD.new()
    local self = setmetatable({}, HUD)
    -- Initialize font and animation state
    self.score_font = love.graphics.newFont(constants.FONT_PATH, UI.SCORE.FONT_SIZE)
    self.score_scale = 1.0
    self.score_animation_time = 0
    self.score_animation_duration = UI.SCORE.ANIMATION.DURATION
    return self
end

-- Update animation states based on time
function HUD:update(dt)
    self:update_score_animation(dt)
end

-- Trigger the score bounce animation
function HUD:trigger_score_animation()
    self.score_animation_time = self.score_animation_duration
end

-- Draw all HUD elements
function HUD:draw(game_data)
    self:draw_score(game_data.score)
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

-- Private helper functions

-- Update the score bounce animation state
function HUD:update_score_animation(dt)
    if self.score_animation_time > 0 then
        self.score_animation_time = math.max(0, self.score_animation_time - dt)
        local progress = self.score_animation_time / self.score_animation_duration
        -- Elastic easing out for a bouncy effect
        local bounce_scale = 1 + math.sin(progress * math.pi) * (UI.SCORE.ANIMATION.MAX_SCALE - 1)
        self.score_scale = bounce_scale
    else
        self.score_scale = 1.0
    end
end

-- Draw the score with shadow and animation effects
function HUD:draw_score(score, position)
    position = position or UI.SCORE.DEFAULT_POSITION
    local score_text = "Score: " .. score
    
    -- Calculate dimensions for centered scaling
    local text_width = self.score_font:getWidth(score_text)
    local text_height = self.score_font:getHeight()
    local center_x = position.x + text_width/2
    local center_y = position.y + text_height/2
    
    -- Set up transformation for animation
    love.graphics.push()
    love.graphics.translate(center_x, center_y)
    love.graphics.scale(self.score_scale, self.score_scale)
    love.graphics.translate(-center_x, -center_y)
    
    -- Draw text shadow
    love.graphics.setFont(self.score_font)
    love.graphics.setColor(constants.BLACK)
    love.graphics.print(score_text, 
        position.x + UI.SCORE.SHADOW_OFFSET,
        position.y + UI.SCORE.SHADOW_OFFSET)
    
    -- Draw main text
    love.graphics.setColor(constants.WHITE)
    love.graphics.print(score_text, position.x, position.y)
    
    -- Restore original transformation
    love.graphics.pop()
end

return HUD