-- Game state management for the snake game
-- Handles game state, score, and timing

local constants = require("src.constants")
local Snake = require("src.game_objects.snake")
local Food = require("src.game_objects.food")
local PauseMenu = require("src.ui.pause_menu")
local GameOverScreen = require("src.ui.game_over")
local HUD = require("src.ui.hud")
local Grid = require("src.ui.grid")
local InputHandler = require("src.input.input_handler")
local SettingsManager = require("src.settings.settings_manager")

local GameState = {}
GameState.__index = GameState

function GameState.new()
    local self = setmetatable({}, GameState)
    
    -- Initialize UI components
    self.pause_menu = PauseMenu.new()
    self.game_over_screen = GameOverScreen.new()
    self.hud = HUD.new()
    self.grid = Grid.new()
    
    -- Initialize settings manager
    self.settings_manager = SettingsManager.new()
    
    -- Load sound effects
    self.game_over_sound = love.audio.newSource(constants.GAME_OVER_SOUND_PATH, "static")
    
    -- Create eat sound pool
    self.eat_sounds = {}
    self.current_eat_sound = 1
    for i = 1, 3 do  -- Create 3 sound sources for eating
        self.eat_sounds[i] = love.audio.newSource(constants.EAT_SOUND_PATH, "static")
    end
    
    -- Load grayscale shader
    self.grayscale_shader = love.graphics.newShader("src/shaders/grayscale.glsl")
    
    -- Update volumes
    self:update_sound_volumes()
    
    -- Initialize game objects and state
    self.snake = Snake.new()
    self.food = Food.new()
    self.score = 0
    self.game_over = false
    self.paused = false
    self.retro_mode = false
    self.last_move_time = love.timer.getTime()
    self.retro_canvas = nil
    
    -- Initialize input handler
    self.input_handler = InputHandler.new(self)
    
    return self
end

function GameState:reset_game()
    self.snake = Snake.new()
    self.food = Food.new()
    self.score = 0
    self.game_over = false
    self.paused = false
    self.last_move_time = love.timer.getTime()
end

function GameState:update_sound_volumes()
    local volume = self.settings_manager:get_setting('sound_volume') / 100.0
    self.game_over_sound:setVolume(0.2 * volume)
    for _, sound in ipairs(self.eat_sounds) do
        sound:setVolume(0.5 * volume)
    end
end

function GameState:play_eat_sound()
    -- Find a non-playing sound source
    local found = false
    local start = self.current_eat_sound
    repeat
        if not self.eat_sounds[self.current_eat_sound]:isPlaying() then
            found = true
        else
            self.current_eat_sound = (self.current_eat_sound % #self.eat_sounds) + 1
        end
    until found or self.current_eat_sound == start

    -- If we found a free sound source, play it
    if found then
        self.eat_sounds[self.current_eat_sound]:play()
        self.current_eat_sound = (self.current_eat_sound % #self.eat_sounds) + 1
    end
end

function GameState:update(dt)
    if self.paused then
        -- Only update pause menu if terminal is not active
        if not (terminal and terminal.active) then
            self.pause_menu:update(dt)
        end
        return true
    end

    if not self.game_over and not self.paused then
        -- Update snake with dt
        if not self.snake:update(dt) then
            self.game_over = true
            self:update_sound_volumes()  -- Ensure volume is current
            self.game_over_sound:play()
        end
        
        -- Check for food collision
        local head = self.snake:getHeadPosition()
        if head[1] == self.food.position[1] and head[2] == self.food.position[2] then
            self.snake.length = self.snake.length + 1
            self.score = self.score + 1
            self:update_sound_volumes()  -- Ensure volume is current
            self:play_eat_sound()
             self.food:randomize_position()
            while self.snake:contains_position(self.food.position) do
                self.food:randomize_position()
            end
        end
    end
    return true
end

function GameState:handle_input()
    return self.input_handler:handle_input()
end

function GameState:draw()
    -- Create a canvas for retro mode if needed
    if self.retro_mode and not self.retro_canvas then
        self.retro_canvas = love.graphics.newCanvas(constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
    end
    
    -- Fill background
    love.graphics.setBackgroundColor(constants.BACKGROUND_COLOR)
    love.graphics.clear()
    
    if self.retro_mode then
        -- Draw everything to the canvas first
        love.graphics.setCanvas(self.retro_canvas)
        love.graphics.clear()
    end
    
    -- Draw game elements
    self.grid:draw()
    self.snake:draw()
    self.food:draw()
    self.hud:draw({score = self.score})
    
    if self.paused then
        -- Process mouse hover for pause menu
        local mx, my = love.mouse.getPosition()
        self.pause_menu:handle_mouse(mx, my)
        self.pause_menu:draw(self.score)
    end
    
    if self.game_over then
        self.game_over_screen:draw(self.score)
        self.retro_mode = false  -- Reset retro mode on game over
    end
    
    if self.retro_mode then
        -- Switch back to the main canvas before applying effects
        love.graphics.setCanvas()
        -- Draw the canvas with the grayscale shader
        love.graphics.setShader(self.grayscale_shader)
        love.graphics.draw(self.retro_canvas, 0, 0)
        love.graphics.setShader()
    else
        -- Make sure we're drawing to the screen
        love.graphics.setCanvas()
    end
end

function GameState:run()
    -- Note: In LÖVE, we don't need this method as the main loop is handled by love.update and love.draw
    -- This is left here for compatibility but should not be used
    return false
end

function GameState:keypressed(key)
    if self.game_over then
        if key == 'return' or key == 'space' then
            -- Reset game
            self:reset_game()
            return false
        end
        return false
    end

    if key == 'escape' then
        self.paused = not self.paused
        return false
    end

    if self.paused then
        -- Check for easter eggs first when paused
        if self.input_handler.easter_eggs:handle_input(key, self) then
            return false
        end
        
        -- Pass keyboard input to pause menu
        local result = self.pause_menu:handle_input(key)
        if result == 'Resume' then
            self.paused = false
        elseif result == 'Main Menu' then
            return "menu"  -- Return to main menu
        end
        return false
    end

    -- Handle snake movement
    self.input_handler:handle_snake_movement(key)
    return false
end

function GameState:mousepressed(x, y, button)
    if self.paused then
        local result = self.pause_menu:mousepressed(x, y, button)
        if result == 'Resume' then
            self.paused = false
        elseif result == 'Main Menu' then
            return "menu"  -- Return to main menu
        end
    end
    return false
end

function GameState:mousemoved(x, y)
    if self.paused then
        self.pause_menu:handle_mouse(x, y)
    end
end

function GameState:mousereleased(x, y, button)
    if self.game_over then
        -- Check if click was in the retry/menu area
        -- For now, just return to menu
        return "menu"
    end
    return nil
end

return GameState