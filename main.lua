-- PISNAKE - Main Game Module --

-- Import required modules
local Menu = require('src.screens.menu')
local constants = require('src.constants')
local Instructions = require('src.screens.instructions')
local Settings = require('src.screens.settings')
local GameState = require('src.state.game_state')
local Terminal = require('src.terminal')
local Transition = require('src.transition')

-- Game state enumeration
-- Defines the different screens/states the game can be in
local States = {
    MENU = "menu",          -- Main menu screen
    PLAYING = "playing",    -- Active gameplay
    INSTRUCTIONS = "instructions",  -- Help/tutorial screen
    SETTINGS = "settings"   -- Game settings screen
}

-- Core game management variables
local state_handlers = {}   -- Handlers for each game state
local current_state = States.MENU  -- Tracks current game state
local transition = nil      -- Handles screen transitions
local terminal = nil       -- Debug terminal instance

-- Object instances for different game states
-- Each state maintains its own instance to preserve state data
local state_objects = {
    menu = nil,          -- Main menu screen instance
    instructions = nil,  -- Instructions screen instance
    settings = nil,      -- Settings screen instance
    game = nil          -- Active game instance
}

--[[
    Handles smooth transitions between game states
    @param new_state (string) The state to transition to
    @param callback (function) Optional function to call after transition
]]
local function transition_to(new_state, callback)
    if transition and not transition:isActive() then
        transition:start_transition(function()
            current_state = new_state
            if callback then callback() end
        end)
    end
end

-- Menu state handler
state_handlers[States.MENU] = {
    --[[
        Updates menu state and processes state transitions
        @param dt (number) Delta time since last frame
    ]]
    update = function(dt)
        local menu_next = state_objects.menu:update(dt)
        if menu_next and not transition.active then
            if menu_next == "play" then
                -- Start new game
                transition_to(States.PLAYING, function()
                    state_objects.game:reset_game()
                end)
            elseif menu_next == "instructions" then
                -- Show game instructions
                transition_to(States.INSTRUCTIONS)
            elseif menu_next == "settings" then
                -- Open settings menu
                transition_to(States.SETTINGS)
            elseif menu_next == "quit" then
                -- Exit game with transition
                transition_to(nil, function()
                    love.event.quit()
                end)
            end
        end
    end,
    -- Renders the menu interface
    draw = function()
        state_objects.menu:draw()
    end,
    --[[
        Processes keyboard input in menu state
        @param key (string) The key that was pressed
    ]]
    keypressed = function(key)
        local result = state_objects.menu:keypressed(key)
        if result then
            if result == "Play" then
                -- Initialize and start new game
                transition_to(States.PLAYING, function()
                    state_objects.game = GameState.new()
                end)
            elseif result == "Instructions" then
                transition_to(States.INSTRUCTIONS)
            elseif result == "Settings" then
                transition_to(States.SETTINGS)
            elseif result == "Quit" then
                transition_to(nil, function()
                    love.event.quit()
                end)
            end
        end
    end
}

-- Game state handler
state_handlers[States.PLAYING] = {
    --[[
        Updates game state and checks for game-to-menu transitions
        @param dt (number) Delta time since last frame
    ]]
    update = function(dt)
        local game_next = state_objects.game:update(dt)
        if game_next == "menu" and not transition.active then
            transition_to(States.MENU)
        end
    end,
    -- Renders the active game screen
    draw = function()
        state_objects.game:draw()
    end,
    --[[
        Handles gameplay keyboard controls
        @param key (string) The key that was pressed
    ]]
    keypressed = function(key)
        if state_objects.game:keypressed(key) == "menu" then
            transition_to(States.MENU)
        end
    end
}

-- Instructions state handler
state_handlers[States.INSTRUCTIONS] = {
    --[[
        Updates instructions screen and handles return to menu
        @param dt (number) Delta time since last frame
    ]]
    update = function(dt)
        if state_objects.instructions:update(dt) and not transition.active then
            transition_to(States.MENU)
        end
    end,
    -- Renders the instructions interface
    draw = function()
        state_objects.instructions:draw()
    end,
    --[[
        Processes keyboard input in instructions screen
        @param key (string) The key that was pressed
    ]]
    keypressed = function(key)
        if state_objects.instructions:keypressed(key) then
            transition_to(States.MENU)
        end
    end
}

-- Settings state handler
state_handlers[States.SETTINGS] = {
    --[[
        Updates settings screen and handles return to menu
        @param dt (number) Delta time since last frame
    ]]
    update = function(dt)
        if state_objects.settings:update(dt) and not transition.active then
            transition_to(States.MENU, function()
                state_objects.menu:update_hover_sounds()
            end)
        end
    end,
    -- Renders the settings interface
    draw = function()
        state_objects.settings:draw()
    end,
    --[[
        Processes keyboard input in settings screen
        @param key (string) The key that was pressed
    ]]
    keypressed = function(key)
        if state_objects.settings:keypressed(key) then
            transition_to(States.MENU, function()
                state_objects.menu:update_hover_sounds()
            end)
        end
    end
}

--[[
    LÖVE2D callback: Initializes game components and window settings
    Called once at the start of the game
]]
function love.load()
    -- Set up game window
    love.window.setMode(constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
    love.window.setTitle("PISNAKE")
    
    -- Initialize all game state objects
    state_objects.menu = Menu.new()
    state_objects.instructions = Instructions.new()
    state_objects.settings = Settings.new()
    state_objects.game = GameState.new()
    terminal = Terminal.new()
    transition = Transition.new()
end

--[[
    LÖVE2D callback: Main game update loop
    @param dt (number) Delta time since last frame
]]
function love.update(dt)
    -- Update transition effects if active
    if transition then
        transition:update(dt)
    end
    
    -- Pause game updates when terminal is active or during transitions
    if (terminal and terminal.active) or (transition and transition:isActive()) then
        return
    end

    -- Update current game state
    local current_handler = state_handlers[current_state]
    if current_handler and current_handler.update then
        current_handler.update(dt)
    end
end

--[[
    LÖVE2D callback: Main rendering function
    Handles all game rendering in proper order
]]
function love.draw()
    -- Draw current game state
    local current_handler = state_handlers[current_state]
    if current_handler and current_handler.draw then
        current_handler.draw()
    end
    
    -- Draw terminal overlay if active
    if terminal then
        terminal:draw()
    end

    -- Draw transition effects
    if transition then
        transition:draw()
    end

    -- Show pause message when terminal is active during gameplay
    if terminal and terminal.active and current_state == States.PLAYING then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("GAME PAUSED", 0, constants.WINDOW_HEIGHT / 2 + 50, constants.WINDOW_WIDTH, "center")
    end
end

--[[
    LÖVE2D callback: Global keyboard input handler
    @param key (string) The key that was pressed
]]
function love.keypressed(key)
    -- Ignore input during transitions
    if transition and transition:isActive() then
        return
    end
    
    -- Toggle terminal with backtick key
    if key == "`" then
        if terminal then
            terminal:toggle()
        end
        return
    end
    
    -- Handle terminal input when active
    if terminal and terminal.active then
        terminal:keypressed(key)
        return
    end
    
    -- Handle input for current game state
    local current_handler = state_handlers[current_state]
    if current_handler and current_handler.keypressed then
        current_handler.keypressed(key)
    end
end

--[[
    LÖVE2D callback: Text input handler
    Used for terminal text input
    @param text (string) The text that was input
]]
function love.textinput(text)
    if terminal and terminal.active then
        terminal:textinput(text)
    end
end

--[[
    LÖVE2D callback: Mouse wheel handler
    Used for terminal scrolling
    @param x (number) Horizontal scroll amount
    @param y (number) Vertical scroll amount
]]
function love.wheelmoved(x, y)
    if terminal and terminal.active then
        terminal:wheelmoved(x, y)
    end
end

--[[
    LÖVE2D callback: Mouse click handler
    Processes mouse input for all game states
    @param x (number) Mouse X coordinate
    @param y (number) Mouse Y coordinate
    @param button (number) Mouse button that was pressed
]]
function love.mousepressed(x, y, button)
    -- Ignore mouse input during transitions
    if transition and transition:isActive() then
        return
    end
    
    -- Ignore mouse input when terminal is active
    if terminal and terminal.active then
        return
    end

    -- Handle mouse input based on current state
    if current_state == States.MENU then
        local result = state_objects.menu:handle_mousepressed(x, y, button)
        if result == "Play" then
            transition_to(States.PLAYING, function()
                state_objects.game = GameState.new()
            end)
        elseif result == "Instructions" then
            transition_to(States.INSTRUCTIONS)
        elseif result == "Settings" then
            transition_to(States.SETTINGS)
        elseif result == "Quit" then
            transition_to(nil, function()
                love.event.quit()
            end)
        end
    elseif current_state == States.PLAYING then
        if state_objects.game:mousepressed(x, y, button) == "menu" then
            transition_to(States.MENU)
        end
    elseif current_state == States.INSTRUCTIONS then
        if state_objects.instructions:mousepressed(x, y, button) then
            transition_to(States.MENU)
        end
    elseif current_state == States.SETTINGS then
        if state_objects.settings:mousepressed(x, y, button) then
            transition_to(States.MENU, function()
                state_objects.menu:update_hover_sounds()
            end)
        end
    end
end

--[[
    LÖVE2D callback: Mouse movement handler
    Updates hover states and cursor interactions
    @param x (number) Mouse X coordinate
    @param y (number) Mouse Y coordinate
]]
function love.mousemoved(x, y)
    -- Ignore mouse movement when terminal is active
    if terminal and terminal.active then
        return
    end

    -- Update mouse movement based on current state
    if current_state == States.MENU then
        state_objects.menu:mousemoved(x, y)
    elseif current_state == States.PLAYING then
        state_objects.game:mousemoved(x, y)
    elseif current_state == States.INSTRUCTIONS then
        state_objects.instructions:handle_mouse_move(x, y)
    elseif current_state == States.SETTINGS then
        state_objects.settings:mousemoved(x, y)
    end
end

--[[
    LÖVE2D callback: Mouse release handler
    Completes mouse interactions for all game states
    @param x (number) Mouse X coordinate
    @param y (number) Mouse Y coordinate
    @param button (number) Mouse button that was released
]]
function love.mousereleased(x, y, button)
    -- Ignore mouse release when terminal is active
    if terminal and terminal.active then
        return
    end

    -- Handle mouse release based on current state
    if current_state == States.MENU then
        state_objects.menu:mousereleased(x, y, button)
    elseif current_state == States.PLAYING then
        state_objects.game:mousereleased(x, y, button)
    elseif current_state == States.SETTINGS then
        state_objects.settings:mousereleased(x, y, button)
    end
end
