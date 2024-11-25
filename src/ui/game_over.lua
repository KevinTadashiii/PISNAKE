-- Game over screen implementation for the snake game

local constants = require("src.constants")

local GameOverScreen = {}
GameOverScreen.__index = GameOverScreen

function GameOverScreen.new()
    local self = setmetatable({}, GameOverScreen)
    -- Load fonts
    self.game_font = love.graphics.newFont(constants.FONT_PATH, 24)
    self.game_over_font = love.graphics.newFont(constants.FONT_PATH, 18)
    return self
end

function GameOverScreen:handle_input(key)
    -- Handle game over screen input events
    -- Returns: bool - True if should restart the game, False otherwise
    if key == "return" then
        return true  -- Signal to restart the game
    end
    return false
end

function GameOverScreen:draw(score)
    -- Create semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.63)  -- 160/255 ≈ 0.63 alpha
    love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
    
    -- Calculate pulsing effect for title
    local pulse = (math.sin(love.timer.getTime() * 5) + 1) * 0.5  -- Creates a value between 0 and 1
    local title_size = 42 + pulse * 8  -- Size varies between 42 and 50
    local title_font = love.graphics.newFont(constants.FONT_PATH, title_size)
    
    -- Draw "GAME OVER" title with shadow effect
    love.graphics.setFont(title_font)
    
    -- Draw shadow
    love.graphics.setColor(constants.DARK_RED)
    local shadow_offset = 3
    love.graphics.print("GAME OVER", 
        constants.WINDOW_WIDTH/2 - title_font:getWidth("GAME OVER")/2 + shadow_offset, 
        constants.WINDOW_HEIGHT/3.4 + shadow_offset)
    
    -- Draw main title
    love.graphics.setColor(constants.RED)
    love.graphics.print("GAME OVER", 
        constants.WINDOW_WIDTH/2 - title_font:getWidth("GAME OVER")/2, 
        constants.WINDOW_HEIGHT/3.4)
    
    -- Draw final score with box
    love.graphics.setFont(self.game_font)
    local score_text = "Final Score: " .. score
    local score_width = self.game_font:getWidth(score_text)
    local score_height = self.game_font:getHeight()
    
    -- Draw score box
    local padding = 20
    local box_x = constants.WINDOW_WIDTH/2 - score_width/2 - padding
    local box_y = constants.WINDOW_HEIGHT/2 - score_height/2 - padding/2
    local box_width = score_width + padding * 2
    local box_height = score_height + padding
    
    -- Fill
    love.graphics.setColor(constants.DARK_GREEN)
    love.graphics.rectangle("fill", box_x, box_y, box_width, box_height, 10)
    
    -- Border
    love.graphics.setColor(constants.SNAKE_GREEN)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", box_x, box_y, box_width, box_height, 10)
    
    -- Score text
    love.graphics.setColor(constants.YELLOW)
    love.graphics.print(score_text, 
        constants.WINDOW_WIDTH/2 - score_width/2, 
        constants.WINDOW_HEIGHT/2 - score_height/2)
    
    -- Draw instruction text with fade effect
    love.graphics.setFont(self.game_over_font)
    local instruction_text = "Press ENTER to restart"
    local alpha = math.abs(math.sin(love.timer.getTime() * 3)) -- Creates a fading effect
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print(instruction_text,
        constants.WINDOW_WIDTH/2 - self.game_over_font:getWidth(instruction_text)/2,
        constants.WINDOW_HEIGHT * 2/3)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return GameOverScreen