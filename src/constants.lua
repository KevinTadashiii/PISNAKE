local constants = {}

constants.WINDOW_WIDTH = 800
constants.WINDOW_HEIGHT = 600
constants.GRID_SIZE = 32
constants.GRID_WIDTH = 17
constants.GRID_HEIGHT = 17
constants.PLAYABLE_WIDTH = constants.GRID_WIDTH * constants.GRID_SIZE
constants.PLAYABLE_HEIGHT = constants.GRID_HEIGHT * constants.GRID_SIZE
constants.OFFSET_X = math.floor((constants.WINDOW_WIDTH - constants.PLAYABLE_WIDTH) / 2)
constants.OFFSET_Y = math.floor((constants.WINDOW_HEIGHT - constants.PLAYABLE_HEIGHT) / 2)

constants.SNAKE_PADDING = 2
constants.FPS = 60
constants.MOVE_DELAY = 130

constants.FONT_PATH = 'assets/fonts/PressStart2P.ttf'
constants.GAME_OVER_SOUND_PATH = 'assets/sounds/gameover.wav'
constants.EAT_SOUND_PATH = 'assets/sounds/eat.wav'
constants.HOVER_SOUND_PATH = 'assets/sounds/hover.mp3'

constants.BLACK = {0, 0, 0}
constants.WHITE = {1, 1, 1}
constants.RED = {1, 0, 0}
constants.DARK_RED = {0.545, 0, 0}
constants.DARK_GREEN = {0.180, 0.545, 0.341}
constants.LIGHT_GREEN = {0.565, 0.933, 0.565}
constants.SNAKE_GREEN = {0, 1, 0}
constants.SNAKE_HEAD_COLOR = {0, 0.706, 0}
constants.SNAKE_COLOR = {0, 1, 0}
constants.YELLOW = {1, 1, 0}
constants.GRAY = {0.5, 0.5, 0.5}
constants.GREEN = {0, 0.5, 0}
constants.BACKGROUND_COLOR = {0.059, 0.137, 0.059}
constants.FOOD_COLOR = {1, 0, 0}  -- Red color for food

function constants.to_grayscale(color)
    local r, g, b = color[1], color[2], color[3]
    local gray = 0.299 * r + 0.587 * g + 0.114 * b
    return {gray, gray, gray}
end

return constants
