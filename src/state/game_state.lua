-- GameState Module --

local constants = require("src.constants")
local Snake = require("src.game_objects.snake")
local Food = require("src.game_objects.food")

local PauseMenu = require("src.ui.pause_menu")
local GameOverScreen = require("src.ui.game_over")
local HUD = require("src.ui.hud")
local Grid = require("src.ui.grid")

local InputHandler = require("src.input.input_handler")
local SettingsManager = require("src.settings.settings_manager")
local BackgroundEffect = require("src.background_effect")

local GameState = {}
GameState.__index = GameState

-- Constructor for the GameState class.
-- Initializes all game components and sets the initial game state.
function GameState.new()
    local self = setmetatable({}, GameState)
    
    -- Initialize components
    self:initialize_ui_components()
    self:initialize_settings_manager()
    self:initialize_sounds()
    self:initialize_shaders()
    self:initialize_game_objects()
    self:initialize_screen_shake()
    self:initialize_input_handler()
    
    return self
end

-- Initializes UI components, including the pause menu, game over screen, HUD, and grid.
function GameState:initialize_ui_components()
    -- Initialize UI components
    self.pause_menu = PauseMenu.new()
    self.game_over_screen = GameOverScreen.new()
    self.hud = HUD.new()
    self.grid = Grid.new()
end

-- Initializes the settings manager, which handles game settings and preferences.
function GameState:initialize_settings_manager()
    -- Initialize settings manager
    self.settings_manager = SettingsManager.new()
end

-- Initializes sound effects, including the game over sound and eat sounds.
function GameState:initialize_sounds()
    -- Load sound effects
    self.game_over_sound = love.audio.newSource(constants.GAME_OVER_SOUND_PATH, "static")
    
    -- Create eat sound pool
    self.eat_sounds = {}
    self.current_eat_sound = 1
    for i = 1, 3 do  -- Create 3 sound sources for eating
        self.eat_sounds[i] = love.audio.newSource(constants.EAT_SOUND_PATH, "static")
    end
    
    -- Update volumes
    self:update_sound_volumes()
end

-- Initializes shaders, including the grayscale shader used for retro mode.
function GameState:initialize_shaders()
    -- Load grayscale shader
    self.grayscale_shader = love.graphics.newShader("src/shaders/grayscale.glsl")
end

-- Initializes game objects, including the snake, food, and background effect.
function GameState:initialize_game_objects()
    -- Initialize game objects and state
    self.snake = Snake.new()
    self.food = Food.new()
    self.score = 0
    self.game_over = false
    self.paused = false
    self.waiting_to_start = true  -- New state for initial "press any key"
    self.retro_mode = false
    self.last_move_time = love.timer.getTime()
    self.retro_canvas = nil
    self.background_effect = BackgroundEffect.new()  -- Add background effect
end

-- Initializes screen shake, which is used to create a visual effect when the snake collides with something.
function GameState:initialize_screen_shake()
    -- Initialize screen shake
    self.shake = {
        duration = 0,
        magnitude = 0,
        time = 0,
        offset_x = 0,
        offset_y = 0
    }
end

-- Initializes the input handler, which processes keyboard and mouse input.
function GameState:initialize_input_handler()
    -- Initialize input handler
    self.input_handler = InputHandler.new(self)
end

-- Resets the game to its initial state.
-- This includes resetting the score, game objects, and any active easter eggs.
function GameState:reset_game()
    -- Reset game state
    self.score = 0
    self.game_over = false
    self.paused = false
    self.waiting_to_start = true  -- Reset to waiting state
    self.retro_mode = false
    self.last_move_time = love.timer.getTime()
    
    -- Reset game objects
    self.snake:reset()
    self.food:randomize_position()
    
    -- Reset easter eggs
    if self.input_handler and self.input_handler.easter_eggs then
        self.input_handler.easter_eggs:reset()
    end
end

-- Updates the volume of the game's sound effects based on the current settings.
-- This ensures that all sounds are played at the correct volume.
function GameState:update_sound_volumes()
    local volume = self.settings_manager:get_setting('sound_volume') / 100.0
    self.game_over_sound:setVolume(0.7 * volume)
    for _, sound in ipairs(self.eat_sounds) do
        sound:setVolume(0.5 * volume)
    end
end

-- Plays a sound effect when the snake eats food.
-- Utilizes a pool of sound sources to ensure sounds do not overlap.
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

-- Main update loop for the game state.
-- Handles screen shake, updates game objects, and processes game logic based on the current state.
function GameState:update(dt)
    -- Update screen shake
    if self.shake.duration > 0 then
        self.shake.time = self.shake.time + dt
        if self.shake.time >= self.shake.duration then
            -- Reset shake
            self.shake.duration = 0
            self.shake.magnitude = 0
            self.shake.time = 0
            self.shake.offset_x = 0
            self.shake.offset_y = 0
        else
            -- Calculate shake offset
            local progress = self.shake.time / self.shake.duration
            local damping = 1 - progress  -- Gradually reduce shake intensity
            local angle = love.math.random() * math.pi * 2
            self.shake.offset_x = math.cos(angle) * self.shake.magnitude * damping
            self.shake.offset_y = math.sin(angle) * self.shake.magnitude * damping
        end
    end

    -- Update HUD animations
    self.hud:update(dt)

    if self.paused then
        -- Only update pause menu if terminal is not active
        if not (terminal and terminal.active) then
            self.pause_menu:update(dt)
        end
        return true
    end

    -- Don't update snake if waiting to start
    if self.waiting_to_start then
        -- Don't update anything while waiting to start
        return true
    end

    if not self.game_over and not self.paused then
        -- Update background effect based on snake movement direction.
        local snake_dx, snake_dy = 0, 0
        if self.snake.direction == "right" then
            snake_dx = 1
        elseif self.snake.direction == "left" then
            snake_dx = -1
        elseif self.snake.direction == "up" then
            snake_dy = -1
        elseif self.snake.direction == "down" then
            snake_dy = 1
        end
        self.background_effect:update(dt, snake_dx, snake_dy)
        
        -- Update snake with dt
        if not self.snake:update(dt) then
            -- Trigger screen shake on collision
            self:start_shake(0.3, 10)  -- 0.3 seconds, magnitude 10
            
            self.game_over = true
            self:update_sound_volumes()  -- Ensure volume is current
            self.game_over_sound:play()
        end
        
        -- Check for food collision
        local head = self.snake:getHeadPosition()
        if head[1] == self.food.position[1] and head[2] == self.food.position[2] then
            -- Play eat sound
            self:play_eat_sound()
            
            -- Update score and trigger animation
            self.score = self.score + 1
            self.hud:trigger_score_animation()
            
            -- Grow snake
            self.snake.length = self.snake.length + 1
            
            -- Spawn new food
            self.food:randomize_position()
            while self.snake:contains_position(self.food.position) do
                self.food:randomize_position()
            end
        end
    end
    return true
end

-- Starts a screen shake effect with the specified duration and magnitude.
function GameState:start_shake(duration, magnitude)
    self.shake.duration = duration
    self.shake.magnitude = magnitude
    self.shake.time = 0
end

-- Handles keyboard input events.
-- Processes interactions with the pause menu when the game is paused.
function GameState:handle_input()
    return self.input_handler:handle_input()
end

-- Renders the game state to the screen.
-- Applies visual effects like screen shake and draws all game components.
function GameState:draw()
    -- Apply screen shake offset
    if self.shake.duration > 0 then
        love.graphics.push()
        love.graphics.translate(self.shake.offset_x, self.shake.offset_y)
    end

    -- Create a canvas for retro mode if needed
    if self.retro_mode and not self.retro_canvas then
        self.retro_canvas = love.graphics.newCanvas(constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
    end
    
    if self.retro_mode then
        -- Draw everything to the canvas first
        love.graphics.setCanvas({self.retro_canvas, stencil=true})
        love.graphics.clear()
    end
    
    -- Fill background with base color
    love.graphics.setBackgroundColor(unpack(constants.BACKGROUND_COLOR))
    love.graphics.clear()

    -- Draw background effect before anything else
    self.background_effect:draw()
    
    -- Draw game grid
    self.grid:draw()
    
    -- Draw game elements
    self.snake:draw()
    self.food:draw()
    self.hud:draw({score = self.score})
    
    -- Draw "Press any key to start" message if waiting
    if self.waiting_to_start then
        -- Draw semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.3)  -- Lighter overlay than game over
        love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT)
        
        -- Draw message box
        love.graphics.setFont(love.graphics.newFont(constants.FONT_PATH, 20))
        local text = "Press any key to start"
        local text_width = love.graphics.getFont():getWidth(text)
        local text_height = love.graphics.getFont():getHeight()
        
        -- Box dimensions
        local padding = 20
        local box_x = constants.WINDOW_WIDTH/2 - text_width/2 - padding
        local box_y = constants.WINDOW_HEIGHT/2 - text_height/2 - padding/2 + 50  -- Moved down
        local box_width = text_width + padding * 2
        local box_height = text_height + padding
        
        -- Draw box fill
        love.graphics.setColor(constants.DARK_GREEN)
        love.graphics.rectangle("fill", box_x, box_y, box_width, box_height, 10)
        
        -- Draw box border
        love.graphics.setColor(constants.SNAKE_GREEN)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", box_x, box_y, box_width, box_height, 10)
        
        -- Draw text with fade effect
        local alpha = math.abs(math.sin(love.timer.getTime() * 3))
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(text,
            constants.WINDOW_WIDTH/2 - text_width/2,
            constants.WINDOW_HEIGHT/2 - text_height/2 + 50)  -- Moved down
        
        -- Reset color and line width
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(1)
    end
    
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
        -- Switch back to the main canvas and apply grayscale effect
        love.graphics.setCanvas()
        love.graphics.setShader(self.grayscale_shader)
        love.graphics.draw(self.retro_canvas, 0, 0)
        love.graphics.setShader()
    else
        love.graphics.setCanvas()
    end

    -- Reset screen shake transform
    if self.shake.duration > 0 then
        love.graphics.pop()
    end
end

-- Note: In LÖVE, we don't need this method as the main loop is handled by love.update and love.draw
-- This is left here for compatibility but should not be used
function GameState:run()
    return false
end

-- Handles keyboard input events.
-- Processes interactions with the pause menu when the game is paused.
function GameState:keypressed(key)
    -- First, check if we're waiting to start
    if self.waiting_to_start then
        self.waiting_to_start = false
        return false
    end

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

-- Handles mouse input events.
-- Processes interactions with the pause menu when the game is paused.
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

-- Handles mouse movement events.
-- Processes interactions with the pause menu when the game is paused.
function GameState:mousemoved(x, y)
    if self.paused then
        self.pause_menu:handle_mouse(x, y)
    end
end

-- Handles mouse release events.
-- Processes interactions with the game over screen when the game is over.
function GameState:mousereleased(x, y, button)
    if self.game_over then
        -- Check if click was in the retry/menu area
        -- For now, just return to menu
        return "menu"
    end
    return nil
end

return GameState