-- Heads-Up Display (HUD) implementation for the snake game
-- Handles score display and other HUD elements

local constants = require("src.constants")

local HUD = {}
HUD.__index = HUD

function HUD.new()
    local self = setmetatable({}, HUD)
    -- Load font
    self.score_font = love.graphics.newFont(constants.FONT_PATH, 16)
    return self
end

function HUD:draw_score(score, position)
    -- Draw the score with a shadow effect at the specified position
    position = position or {x = 20, y = 20}  -- Default position
    local score_text = "Score: " .. score
    
    -- Draw shadow
    love.graphics.setFont(self.score_font)
    love.graphics.setColor(constants.BLACK)
    love.graphics.print(score_text, 
        position.x + 2,  -- Shadow offset x
        position.y + 2)  -- Shadow offset y
    
    -- Draw main text
    love.graphics.setColor(constants.WHITE)
    love.graphics.print(score_text, position.x, position.y)
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