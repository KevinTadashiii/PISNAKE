-- GameOverScreen Module --

local constants = require("src.constants")

-- Visual configuration constants
local UI = {
    TITLE = {
        MIN_SIZE = 42,
        MAX_SIZE = 50,
        PULSE_SPEED = 5,
        SHADOW_OFFSET = 3,
        Y_POSITION = 3.4  -- Divider for screen height
    },
    SCORE = {
        PADDING = 20,
        BOX_CORNER_RADIUS = 10,
        BOX_LINE_WIDTH = 2
    },
    INSTRUCTION = {
        FADE_SPEED = 3,
        Y_POSITION = 2/3  -- Multiplier for screen height
    }
}

local GameOverScreen = {}
GameOverScreen.__index = GameOverScreen

-- Initialize a new game over screen with required fonts
function GameOverScreen.new()
    local self = setmetatable({}, GameOverScreen)
    -- Load fonts for different UI elements
    self.game_font = love.graphics.newFont(constants.FONT_PATH, 24)
    self.game_over_font = love.graphics.newFont(constants.FONT_PATH, 18)
    return self
end

-- Handle input events for the game over screen
-- Returns: bool - True if should restart the game, False otherwise
function GameOverScreen:handle_input(key)
    return key == "return"
end

-- Draw the game over screen with the final score
function GameOverScreen:draw(score)
    self:draw_overlay()
    self:draw_title()
    self:draw_score_box(score)
    self:draw_instruction()
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

-- Private helper functions

-- Draw semi-transparent dark overlay
function GameOverScreen:draw_overlay()
    love.graphics.setColor(0, 0, 0, 0.63)
    love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
end

-- Draw pulsing "GAME OVER" title with shadow
function GameOverScreen:draw_title()
    -- Calculate pulsing effect
    local pulse = (math.sin(love.timer.getTime() * UI.TITLE.PULSE_SPEED) + 1) * 0.5
    local title_size = UI.TITLE.MIN_SIZE + pulse * (UI.TITLE.MAX_SIZE - UI.TITLE.MIN_SIZE)
    local title_font = love.graphics.newFont(constants.FONT_PATH, title_size)
    love.graphics.setFont(title_font)
    
    local text_width = title_font:getWidth("GAME OVER")
    local x = constants.WINDOW_WIDTH/2 - text_width/2
    local y = constants.WINDOW_HEIGHT/UI.TITLE.Y_POSITION
    
    -- Draw shadow
    love.graphics.setColor(constants.DARK_RED)
    love.graphics.print("GAME OVER", 
        x + UI.TITLE.SHADOW_OFFSET, 
        y + UI.TITLE.SHADOW_OFFSET)
    
    -- Draw main title
    love.graphics.setColor(constants.RED)
    love.graphics.print("GAME OVER", x, y)
end

-- Draw score box with final score
function GameOverScreen:draw_score_box(score)
    love.graphics.setFont(self.game_font)
    local score_text = "Final Score: " .. score
    local score_width = self.game_font:getWidth(score_text)
    local score_height = self.game_font:getHeight()
    
    -- Calculate box dimensions
    local box_x = constants.WINDOW_WIDTH/2 - score_width/2 - UI.SCORE.PADDING
    local box_y = constants.WINDOW_HEIGHT/2 - score_height/2 - UI.SCORE.PADDING/2
    local box_width = score_width + UI.SCORE.PADDING * 2
    local box_height = score_height + UI.SCORE.PADDING
    
    -- Draw box background
    love.graphics.setColor(constants.DARK_GREEN)
    love.graphics.rectangle("fill", box_x, box_y, box_width, box_height, UI.SCORE.BOX_CORNER_RADIUS)
    
    -- Draw box border
    love.graphics.setColor(constants.SNAKE_GREEN)
    love.graphics.setLineWidth(UI.SCORE.BOX_LINE_WIDTH)
    love.graphics.rectangle("line", box_x, box_y, box_width, box_height, UI.SCORE.BOX_CORNER_RADIUS)
    
    -- Draw score text
    love.graphics.setColor(constants.YELLOW)
    love.graphics.print(score_text, 
        constants.WINDOW_WIDTH/2 - score_width/2, 
        constants.WINDOW_HEIGHT/2 - score_height/2)
end

-- Draw fading instruction text
function GameOverScreen:draw_instruction()
    love.graphics.setFont(self.game_over_font)
    local instruction_text = "Press ENTER to restart"
    local text_width = self.game_over_font:getWidth(instruction_text)
    
    -- Calculate fading effect
    local alpha = math.abs(math.sin(love.timer.getTime() * UI.INSTRUCTION.FADE_SPEED))
    love.graphics.setColor(1, 1, 1, alpha)
    
    love.graphics.print(instruction_text,
        constants.WINDOW_WIDTH/2 - text_width/2,
        constants.WINDOW_HEIGHT * UI.INSTRUCTION.Y_POSITION)
end

return GameOverScreen