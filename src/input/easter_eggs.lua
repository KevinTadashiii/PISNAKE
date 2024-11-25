--[[
Easter eggs handler for the snake game.
Manages secret features that can be activated through keyboard input.
]]

local EasterEggs = {}
EasterEggs.__index = EasterEggs

function EasterEggs.new()
    local self = setmetatable({}, EasterEggs)
    self.last_key_time = 0
    self.current_word = ""
    self.active_effects = {
        rainbow = false,
        retro = false
    }
    return self
end

function EasterEggs:reset()
    -- Reset all easter egg states
    self.current_word = ""
    for effect, _ in pairs(self.active_effects) do
        self.active_effects[effect] = false
    end
end

function EasterEggs:handle_input(key, game_state)
    -- Handle easter egg input detection
    -- Args:
    --     key: Key that was pressed
    --     game_state: Reference to the game state to modify based on easter eggs
    -- Returns:
    --     bool: True if an easter egg was activated, False otherwise
    
    -- Convert key to character if it's a single letter
    if type(key) == "string" and #key == 1 and key:match("^[a-zA-Z]$") then
        local current_time = love.timer.getTime() * 1000 -- Convert to milliseconds
        
        -- Reset word if more than 1 second between keypresses
        if current_time - self.last_key_time > 1000 then
            self.current_word = ""
        end
        
        self.current_word = self.current_word .. key:lower()
        self.last_key_time = current_time
        
        -- Check for known easter egg patterns
        local activated = self:_check_patterns(game_state)
        
        if activated then
            self.current_word = "" -- Reset after activation
            return true
        end
    end
    
    return false
end

function EasterEggs:_check_patterns(game_state)
    -- Check for known easter egg patterns in the current word
    -- Args:
    --     game_state: Reference to the game state to modify based on easter eggs
    -- Returns:
    --     bool: True if any pattern was matched and activated, False otherwise
    
    -- Rainbow mode - can only be activated while paused
    if self.current_word:find("rainbow", 1, true) then
        if game_state.paused then
            self.active_effects.rainbow = true
            if game_state.snake then
                game_state.snake.rainbow_mode = true
            end
            game_state.paused = false -- Unpause after activating rainbow mode
            return true
        end
    end
    
    -- Retro mode - can only be activated while paused
    if self.current_word:find("retro", 1, true) then
        if game_state.paused then
            self.active_effects.retro = not self.active_effects.retro -- Toggle retro mode
            game_state.retro_mode = self.active_effects.retro -- Update game state
            game_state.paused = false -- Unpause the game
            return true
        end
    end
    
    return false
end

return EasterEggs