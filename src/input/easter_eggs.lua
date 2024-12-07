-- EasterEggs Module --

local EasterEggs = {}
EasterEggs.__index = EasterEggs

--- Creates a new EasterEggs instance
-- @return table: New EasterEggs instance with initialized state
function EasterEggs.new()
    local self = setmetatable({}, EasterEggs)
    
    -- Time tracking for key sequence detection
    self.last_key_time = 0  -- Timestamp of last key press in milliseconds
    self.current_word = ""  -- Current sequence of typed characters
    
    -- Track which easter eggs are currently active
    self.active_effects = {
        rainbow = false,  -- Rainbow color mode for snake
        retro = false    -- Retro visual style
    }
    
    return self
end

--- Resets all easter egg states to their defaults
-- Called when transitioning between game states or restarting
function EasterEggs:reset()
    self.current_word = ""  -- Clear current input sequence
    
    -- Disable all active effects
    for effect, _ in pairs(self.active_effects) do
        self.active_effects[effect] = false
    end
end

--- Handles keyboard input for easter egg detection
-- @param key string: The key that was pressed
-- @param game_state table: Reference to current game state
-- @return boolean: True if an easter egg was activated
function EasterEggs:handle_input(key, game_state)
    -- Only process single alphabetic characters
    if type(key) == "string" and #key == 1 and key:match("^[a-zA-Z]$") then
        local current_time = love.timer.getTime() * 1000  -- Current time in milliseconds
        
        -- Reset word buffer if too much time has passed (>1 second)
        if current_time - self.last_key_time > 1000 then
            self.current_word = ""
        end
        
        -- Add new character to current sequence (case-insensitive)
        self.current_word = self.current_word .. key:lower()
        self.last_key_time = current_time
        
        -- Check if current sequence triggers any easter eggs
        local activated = self:_check_patterns(game_state)
        
        if activated then
            self.current_word = ""  -- Reset sequence after activation
            return true
        end
    end
    
    return false
end

--- Checks current input sequence against known easter egg patterns
-- @param game_state table: Reference to current game state
-- @return boolean: True if a pattern was matched and activated
function EasterEggs:_check_patterns(game_state)
    -- Only allow activation while game is paused
    if not game_state.paused then
        return false
    end
    
    -- Check for "rainbow" sequence
    if self.current_word:find("rainbow", 1, true) then
        self:_activate_rainbow_mode(game_state)
        return true
    end
    
    -- Check for "retro" sequence
    if self.current_word:find("retro", 1, true) then
        self:_activate_retro_mode(game_state)
        return true
    end
    
    return false
end

--- Activates rainbow mode easter egg
-- @param game_state table: Reference to current game state
function EasterEggs:_activate_rainbow_mode(game_state)
    self.active_effects.rainbow = true
    if game_state.snake then
        game_state.snake.rainbow_mode = true
    end
    game_state.paused = false  -- Resume game after activation
end

--- Toggles retro mode easter egg
-- @param game_state table: Reference to current game state
function EasterEggs:_activate_retro_mode(game_state)
    self.active_effects.retro = not self.active_effects.retro
    game_state.retro_mode = self.active_effects.retro
    game_state.paused = false  -- Resume game after activation
end

return EasterEggs