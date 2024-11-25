--[[
Input handling component for the snake game.
Manages keyboard input and game state transitions.
]]

local constants = require('src.constants')
local EasterEggs = require('src.input.easter_eggs')

local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler.new(game_state)
    -- Initialize the input handler.
    -- Args:
    --     game_state: Reference to the game state to modify based on input
    local self = setmetatable({}, InputHandler)
    self.game_state = game_state
    self.easter_eggs = EasterEggs.new()
    return self
end

function InputHandler:handle_snake_movement(key)
    -- Handle snake movement input
    if key == 'up' then
        self.game_state.snake:setDirection({0, -1})
    elseif key == 'down' then
        self.game_state.snake:setDirection({0, 1})
    elseif key == 'left' then
        self.game_state.snake:setDirection({-1, 0})
    elseif key == 'right' then
        self.game_state.snake:setDirection({1, 0})
    end
end

function InputHandler:handle_mousepressed(x, y, button)
    -- Handle mouse input
    if self.game_state.paused then
        local result = self.game_state.pause_menu:handle_input(x, y, button)
        if result == 'Resume' then
            self.game_state.paused = false
        elseif result == 'Main Menu' then
            return true -- Return to menu
        end
    end
    return false
end

function InputHandler:handle_keypressed(key)
    -- Handle keyboard input
    -- Returns:
    --     bool: True if should return to menu, False otherwise
    
    -- Handle easter egg detection (should work even when paused)
    if self.easter_eggs:handle_input(key, self.game_state) then
        return false
    end
    
    -- Handle pause menu input
    if self.game_state.paused then
        local result = self.game_state.pause_menu:handle_input(key)
        if result == 'Resume' then
            self.game_state.paused = false
        elseif result == 'Main Menu' then
            return true
        end
        return false
    end
    
    -- Toggle pause (only when game is not over)
    if key == 'escape' and not self.game_state.game_over then
        self.game_state.paused = not self.game_state.paused  -- Toggle pause state
        return false
    end
    
    -- Handle game over input
    if self.game_state.game_over then
        if self.game_state.game_over_screen:handle_input(key, self.game_state) then
            return false -- Restart the game
        end
        return false
    end
    
    -- Handle snake movement
    if not self.game_state.paused and not self.game_state.game_over then
        self:handle_snake_movement(key)
    end
    
    -- Handle game over space to restart
    if self.game_state.game_over and key == 'space' then
        self.game_state.reset_game()
        self.easter_eggs:reset() -- Reset easter eggs when game resets
    end
    
    return false
end

function InputHandler:handle_quit()
    -- Handle quit event
    love.event.quit()
end

return InputHandler