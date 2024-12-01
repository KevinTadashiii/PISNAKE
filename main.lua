local Menu = require('src.screens.menu')
local constants = require('src.constants')
local Instructions = require('src.screens.instructions')
local Settings = require('src.screens.settings')
local GameState = require('src.state.game_state')
local Terminal = require('src.terminal')
local Transition = require('src.transition')

local States = {
    MENU = "menu",
    PLAYING = "playing",
    INSTRUCTIONS = "instructions",
    SETTINGS = "settings"
}

local state_handlers = {}
local current_state = States.MENU
local transition = nil
local terminal = nil

local state_objects = {
    menu = nil,
    instructions = nil,
    settings = nil,
    game = nil
}

local function transition_to(new_state, callback)
    if transition and not transition:isActive() then
        transition:start_transition(function()
            current_state = new_state
            if callback then callback() end
        end)
    end
end

state_handlers[States.MENU] = {
    update = function(dt)
        local menu_next = state_objects.menu:update(dt)
        if menu_next and not transition.active then
            if menu_next == "play" then
                transition_to(States.PLAYING, function()
                    state_objects.game:reset_game()
                end)
            elseif menu_next == "instructions" then
                transition_to(States.INSTRUCTIONS)
            elseif menu_next == "settings" then
                transition_to(States.SETTINGS)
            elseif menu_next == "quit" then
                transition_to(nil, function()
                    love.event.quit()
                end)
            end
        end
    end,
    draw = function()
        state_objects.menu:draw()
    end,
    keypressed = function(key)
        local result = state_objects.menu:keypressed(key)
        if result then
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
        end
    end
}

state_handlers[States.PLAYING] = {
    update = function(dt)
        local game_next = state_objects.game:update(dt)
        if game_next == "menu" and not transition.active then
            transition_to(States.MENU)
        end
    end,
    draw = function()
        state_objects.game:draw()
    end,
    keypressed = function(key)
        if state_objects.game:keypressed(key) == "menu" then
            transition_to(States.MENU)
        end
    end
}

state_handlers[States.INSTRUCTIONS] = {
    update = function(dt)
        if state_objects.instructions:update(dt) and not transition.active then
            transition_to(States.MENU)
        end
    end,
    draw = function()
        state_objects.instructions:draw()
    end,
    keypressed = function(key)
        if state_objects.instructions:keypressed(key) then
            transition_to(States.MENU)
        end
    end
}

state_handlers[States.SETTINGS] = {
    update = function(dt)
        if state_objects.settings:update(dt) and not transition.active then
            transition_to(States.MENU, function()
                state_objects.menu:update_hover_sounds()
            end)
        end
    end,
    draw = function()
        state_objects.settings:draw()
    end,
    keypressed = function(key)
        if state_objects.settings:keypressed(key) then
            transition_to(States.MENU, function()
                state_objects.menu:update_hover_sounds()
            end)
        end
    end
}

function love.load()
    love.window.setMode(constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
    love.window.setTitle("PISNAKE")
    
    state_objects.menu = Menu.new()
    state_objects.instructions = Instructions.new()
    state_objects.settings = Settings.new()
    state_objects.game = GameState.new()
    terminal = Terminal.new()
    transition = Transition.new()
end

function love.update(dt)
    if transition then
        transition:update(dt)
    end
    
    if (terminal and terminal.active) or (transition and transition:isActive()) then
        return
    end

    local current_handler = state_handlers[current_state]
    if current_handler and current_handler.update then
        current_handler.update(dt)
    end
end

function love.draw()
    local current_handler = state_handlers[current_state]
    if current_handler and current_handler.draw then
        current_handler.draw()
    end
    
    if terminal then
        terminal:draw()
    end

    if transition then
        transition:draw()
    end

    if terminal and terminal.active and current_state == States.PLAYING then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("GAME PAUSED", 0, constants.WINDOW_HEIGHT / 2 + 50, constants.WINDOW_WIDTH, "center")
    end
end

function love.keypressed(key)
    if transition and transition:isActive() then
        return
    end
    
    if key == "`" then
        if terminal then
            terminal:toggle()
        end
        return
    end
    
    if terminal and terminal.active then
        terminal:keypressed(key)
        return
    end
    
    local current_handler = state_handlers[current_state]
    if current_handler and current_handler.keypressed then
        current_handler.keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    if transition and transition:isActive() then
        return
    end
    
    if terminal and terminal.active then
        return
    end

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

function love.mousemoved(x, y)
    if terminal and terminal.active then
        return
    end

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

function love.mousereleased(x, y, button)
    if terminal and terminal.active then
        return
    end

    if current_state == States.MENU then
        state_objects.menu:mousereleased(x, y, button)
    elseif current_state == States.PLAYING then
        state_objects.game:mousereleased(x, y, button)
    elseif current_state == States.SETTINGS then
        state_objects.settings:mousereleased(x, y, button)
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
