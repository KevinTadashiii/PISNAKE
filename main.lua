local Menu = require('src.screens.menu')
local constants = require('src.constants')
local Instructions = require('src.screens.instructions')
local Settings = require('src.screens.settings')
local GameState = require('src.state.game_state')
local Terminal = require('src.terminal')
local Transition = require('src.transition')

-- Game states
local States = {
    MENU = "menu",
    PLAYING = "playing",
    INSTRUCTIONS = "instructions",
    SETTINGS = "settings"
}

-- Global game state
local current_state = States.MENU
local menu = nil
local instructions = nil
local settings = nil
local game = nil
local terminal = nil
local transition = nil
local is_paused = false
local next_state = nil  -- Used to store the next state during transition

function love.load()
    -- Set up window
    love.window.setMode(constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
    love.window.setTitle("PIsnake")
    
    -- Initialize menu, instructions, and settings
    menu = Menu.new()
    instructions = Instructions.new()
    settings = Settings.new()
    game = GameState.new()
    terminal = Terminal.new()
    transition = Transition.new()
end

function love.update(dt)
    -- Update transition first
    if transition then
        transition:update(dt)
    end
    
    -- Skip all updates when terminal is active
    if (terminal and terminal.active) or (transition and transition:isActive()) then
        return
    end

    -- Handle state updates
    if current_state == States.MENU then
        local menu_next = menu:update(dt)
        if menu_next and not transition.active then
            if menu_next == "play" then
                transition:start_transition(function()
                    current_state = States.PLAYING
                    game:reset_game()
                end)
            elseif menu_next == "instructions" then
                transition:start_transition(function()
                    current_state = States.INSTRUCTIONS
                end)
            elseif menu_next == "settings" then
                transition:start_transition(function()
                    current_state = States.SETTINGS
                end)
            elseif menu_next == "quit" then
                transition:start_transition(function()
                    love.event.quit()
                end)
            end
        end
    elseif current_state == States.PLAYING then
        local game_next = game:update(dt)
        if game_next == "menu" and not transition.active then
            transition:start_transition(function()
                current_state = States.MENU
            end)
        end
    elseif current_state == States.INSTRUCTIONS then
        if instructions:update(dt) and not transition.active then
            transition:start_transition(function()
                current_state = States.MENU
            end)
        end
    elseif current_state == States.SETTINGS then
        if settings:update(dt) and not transition.active then
            transition:start_transition(function()
                current_state = States.MENU
                menu:update_hover_sounds()
            end)
        end
    end
end

function love.draw()
    if current_state == States.MENU then
        menu:draw()
    elseif current_state == States.PLAYING then
        game:draw()
    elseif current_state == States.INSTRUCTIONS then
        instructions:draw()
    elseif current_state == States.SETTINGS then
        settings:draw()
    end
    
    -- Draw terminal on top if active
    if terminal then
        terminal:draw()
    end

    -- Draw transition effect on top of everything
    if transition then
        transition:draw()
    end

    -- Draw pause indicator when terminal is open and game is playing
    if terminal and terminal.active and current_state == States.PLAYING then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("GAME PAUSED", 0, constants.WINDOW_HEIGHT / 2 + 50, constants.WINDOW_WIDTH, "center")
    end
end

function love.keypressed(key)
    -- Block all keyboard interactions during transition
    if transition and transition:isActive() then
        return
    end
    
    -- Check for terminal toggle first
    if key == "`" then
        if terminal then
            terminal:toggle()
        end
        return
    end
    
    -- If terminal is active, handle its input only
    if terminal and terminal.active then
        terminal:keypressed(key)
        return
    end
    
    if current_state == States.MENU then
        local result = menu:keypressed(key)
        if result == "Play" then
            transition:start_transition(function()
                current_state = States.PLAYING
                game = GameState.new()
            end)
        elseif result == "Instructions" then
            transition:start_transition(function()
                current_state = States.INSTRUCTIONS
            end)
        elseif result == "Settings" then
            transition:start_transition(function()
                current_state = States.SETTINGS
            end)
        elseif result == "Quit" then
            transition:start_transition(function()
                love.event.quit()
            end)
        end
    elseif current_state == States.PLAYING then
        if game:keypressed(key) == "menu" then
            transition:start_transition(function()
                current_state = States.MENU
            end)
        end
    elseif current_state == States.INSTRUCTIONS then
        if instructions:keypressed(key) then
            transition:start_transition(function()
                current_state = States.MENU
            end)
        end
    elseif current_state == States.SETTINGS then
        if settings:keypressed(key) then
            transition:start_transition(function()
                current_state = States.MENU
                menu:update_hover_sounds()
            end)
        end
    end
end

function love.mousepressed(x, y, button)
    -- Block all mouse interactions during transition
    if transition and transition:isActive() then
        return
    end
    
    -- Skip mouse input if terminal is active
    if terminal and terminal.active then
        return
    end

    if current_state == States.MENU then
        local result = menu:handle_mousepressed(x, y, button)
        if result == "Play" then
            transition:start_transition(function()
                current_state = States.PLAYING
                game = GameState.new()
            end)
        elseif result == "Instructions" then
            transition:start_transition(function()
                current_state = States.INSTRUCTIONS
            end)
        elseif result == "Settings" then
            transition:start_transition(function()
                current_state = States.SETTINGS
            end)
        elseif result == "Quit" then
            transition:start_transition(function()
                love.event.quit()
            end)
        end
    elseif current_state == States.PLAYING then
        -- Forward mouse input to game state
        if game:mousepressed(x, y, button) == "menu" then
            transition:start_transition(function()
                current_state = States.MENU
            end)
        end
    elseif current_state == States.INSTRUCTIONS then
        if instructions:mousepressed(x, y, button) then
            transition:start_transition(function()
                current_state = States.MENU
            end)
        end
    elseif current_state == States.SETTINGS then
        if settings:mousepressed(x, y, button) then
            transition:start_transition(function()
                current_state = States.MENU
                menu:update_hover_sounds()
            end)
        end
    end
end

function love.mousemoved(x, y)
    -- Skip mouse movement if terminal is active
    if terminal and terminal.active then
        return
    end

    if current_state == States.MENU then
        menu:mousemoved(x, y)
    elseif current_state == States.PLAYING then
        -- Forward mouse movement to game state
        game:mousemoved(x, y)
    elseif current_state == States.INSTRUCTIONS then
        instructions:handle_mouse_move(x, y)
    elseif current_state == States.SETTINGS then
        settings:mousemoved(x, y)
    end
end

function love.mousereleased(x, y, button)
    -- Skip mouse release if terminal is active
    if terminal and terminal.active then
        return
    end

    if current_state == States.MENU then
        menu:mousereleased(x, y, button)
    elseif current_state == States.PLAYING then
        game:mousereleased(x, y, button)
    elseif current_state == States.SETTINGS then
        settings:mousereleased(x, y, button)
    end
end

function love.wheelmoved(x, y)
    if terminal and terminal.active then
        terminal:wheelmoved(x, y)
    end
end

function love.textinput(text)
    if terminal and terminal.active then
        terminal:textinput(text)
    end
end
