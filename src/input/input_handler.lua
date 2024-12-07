-- Input_handler Module --

local constants = require('src.constants')
local EasterEggs = require('src.input.easter_eggs')

local InputHandler = {}
InputHandler.__index = InputHandler

--- Creates a new InputHandler instance
-- @param game_state table: Reference to the game state to modify based on input
-- @return table: New InputHandler instance
function InputHandler.new(game_state)
    local self = setmetatable({}, InputHandler)
    self.game_state = game_state
    self.easter_eggs = EasterEggs.new()
    return self
end

--- Handles directional input for snake movement
-- @param key string: The directional key that was pressed
function InputHandler:handle_snake_movement(key)
    local direction_map = {
        up = {0, -1},
        down = {0, 1},
        left = {-1, 0},
        right = {1, 0}
    }
    
    if direction_map[key] then
        self.game_state.snake:setDirection(direction_map[key])
    end
end

--- Handles mouse input events
-- @param x number: Mouse X coordinate
-- @param y number: Mouse Y coordinate
-- @param button number: Mouse button that was pressed
-- @return boolean: True if should return to menu
function InputHandler:handle_mousepressed(x, y, button)
    if self.game_state.paused then
        -- Process pause menu mouse interactions
        local result = self.game_state.pause_menu:handle_input(x, y, button)
        if result == 'Resume' then
            self.game_state.paused = false
        elseif result == 'Main Menu' then
            return true -- Return to menu
        end
    end
    return false
end

--- Processes pause menu input and state changes
-- @param key string: The key that was pressed
-- @return boolean: True if should return to menu
function InputHandler:_handle_pause_menu(key)
    local result = self.game_state.pause_menu:handle_input(key)
    if result == 'Resume' then
        self.game_state.paused = false
    elseif result == 'Main Menu' then
        return true
    end
    return false
end

--- Handles game state transitions based on keyboard input
-- @param key string: The key that was pressed
-- @return boolean: True if should return to menu
function InputHandler:handle_keypressed(key)
    -- Check for easter egg activation first (works even when paused)
    if self.easter_eggs:handle_input(key, self.game_state) then
        return false
    end
    
    -- Handle pause menu input if game is paused
    if self.game_state.paused then
        return self:_handle_pause_menu(key)
    end
    
    -- Toggle pause state with escape key (only when game is active)
    if key == 'escape' and not self.game_state.game_over then
        self.game_state.paused = not self.game_state.paused
        return false
    end
    
    -- Handle game over screen input
    if self.game_state.game_over then
        -- Process game over screen interactions
        if self.game_state.game_over_screen:handle_input(key, self.game_state) then
            return false -- Game restarted
        end
        
        -- Handle space key to restart game
        if key == 'space' then
            self.game_state.reset_game()
            self.easter_eggs:reset() -- Reset easter eggs on game restart
        end
        return false
    end
    
    -- Process snake movement when game is active
    if not self.game_state.paused and not self.game_state.game_over then
        self:handle_snake_movement(key)
    end
    
    return false
end

--- Handles application quit event
function InputHandler:handle_quit()
    love.event.quit()
end

return InputHandler