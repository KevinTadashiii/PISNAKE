--[[
    Constants Module
    
    This module defines all the global constants used throughout the PISNAKE game.
    Includes window dimensions, grid settings, colors, and asset paths.
]]

local constants = {}

-- Window and Display Settings
constants.WINDOW_WIDTH = 800        -- Game window width in pixels
constants.WINDOW_HEIGHT = 608       -- Game window height in pixels

-- Grid Configuration
constants.GRID_SIZE = 32           -- Size of each grid cell in pixels
constants.GRID_WIDTH = 17          -- Number of grid cells horizontally
constants.GRID_HEIGHT = 17         -- Number of grid cells vertically
constants.PLAYABLE_WIDTH = constants.GRID_WIDTH * constants.GRID_SIZE   -- Total playable area width
constants.PLAYABLE_HEIGHT = constants.GRID_HEIGHT * constants.GRID_SIZE -- Total playable area height

-- Centering Offsets
-- Calculate padding to center the game grid in the window
constants.OFFSET_X = math.floor((constants.WINDOW_WIDTH - constants.PLAYABLE_WIDTH) / 2)
constants.OFFSET_Y = math.floor((constants.WINDOW_HEIGHT - constants.PLAYABLE_HEIGHT) / 2)

-- Game Mechanics
constants.SNAKE_PADDING = 2        -- Visual padding inside grid cells for snake segments
constants.FPS = 60                 -- Target frames per second
constants.MOVE_DELAY = 130         -- Milliseconds between snake movements (controls game speed)

-- Asset File Paths
constants.FONT_PATH = 'assets/fonts/PressStart2P.ttf'         -- Retro-style pixel font
constants.GAME_OVER_SOUND_PATH = 'assets/sounds/gameover.wav' -- Sound played on game over
constants.EAT_SOUND_PATH = 'assets/sounds/eat.wav'           -- Sound played when snake eats food
constants.HOVER_SOUND_PATH = 'assets/sounds/hover.mp3'       -- Sound played on menu hover
constants.APPLE_SPRITE_PATH = 'assets/sprites/Apple.png'     -- Apple sprite for food

-- Color Definitions (RGB format, values from 0 to 1)
-- Basic Colors
constants.BLACK = {0, 0, 0}                    -- Pure black for text and outlines
constants.WHITE = {1, 1, 1}                    -- Pure white for text and highlights
constants.RED = {1, 0, 0}                      -- Bright red for warnings and food
constants.YELLOW = {1, 1, 0}                   -- Yellow for highlights and special effects
constants.GRAY = {0.5, 0.5, 0.5}              -- Medium gray for inactive elements

-- Green Variations
constants.DARK_GREEN = {0.180, 0.545, 0.341}   -- Dark green for background elements
constants.LIGHT_GREEN = {0.565, 0.933, 0.565}  -- Light green for highlights
constants.GREEN = {0, 0.5, 0}                  -- Medium green for general use
constants.SNAKE_GREEN = {0, 1, 0}              -- Bright green for snake body

-- Special Purpose Colors
constants.DARK_RED = {0.545, 0, 0}             -- Dark red for danger indicators
constants.SNAKE_HEAD_COLOR = {0, 0.706, 0}     -- Distinct green for snake head
constants.SNAKE_COLOR = {0, 1, 0}              -- Main snake body color
constants.BACKGROUND_COLOR = {0.059, 0.137, 0.059}  -- Dark green background
constants.FOOD_COLOR = {1, 0, 0}               -- Bright red for food items

--[[
    Converts an RGB color to grayscale using standard luminance weights.
    Used for creating disabled or inactive color states.
    
    @param color (table) RGB color table {r, g, b} with values from 0 to 1
    @return (table) Grayscale color table {gray, gray, gray}
]]
function constants.to_grayscale(color)
    local r, g, b = color[1], color[2], color[3]
    -- Convert to grayscale using standard luminance weights
    local gray = 0.299 * r + 0.587 * g + 0.114 * b
    return {gray, gray, gray}
end

return constants
