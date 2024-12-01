-- Terminal Module --

local Terminal = {}
local constants = require('src.constants')
local BackgroundManager = require('src.graphics.background')

-- Table of available terminal commands and their implementations
local commands = {
    -- Toggles FPS counter display
    show_fps = function(self)
        self.show_fps = not self.show_fps
        return self.show_fps and "FPS display enabled" or "FPS display disabled"
    end,
    
    -- Displays available commands and their descriptions
    help = function()
        return [[Available commands:
show_fps     Toggle FPS display
show_border  Toggle menu background border
help         Show this help message
clear        Clear terminal
exit         Close terminal
whoami       Display current user]]
    end,
    
    -- Clears terminal history and resets scroll position
    clear = function(self)
        self.output_history = {}
        self.scroll_offset = 0
        return nil
    end,
    
    -- Closes the terminal interface
    exit = function(self)
        self:toggle()
        return "Terminal closed"
    end,
    
    -- Displays current username
    whoami = function(self)
        return self.username
    end,
    
    -- Toggles the visibility of terminal border
    show_border = function(self)
        local is_enabled = self.background_manager:toggle_border()
        return string.format("Menu background border %s", is_enabled and "enabled" or "disabled")
    end
}

-- Terminal configuration parameters
local config = {
    max_history = 50,    -- Maximum number of commands to keep in history
    line_height = 20,    -- Height of each line in pixels
    font_size = 16       -- Terminal font size
}

-- Creates and initializes terminal state
local function createTerminalState()
    return {
        active = false,              -- Terminal visibility state
        input = "",                  -- Current input text
        history = {},               -- Command history
        output_history = {},        -- Command outputs history
        current_history_index = 1,   -- Current position in command history
        show_fps = false,           -- FPS counter visibility
        username = "player",        -- Terminal username
        hostname = "pisnake",       -- Terminal hostname
        ignore_next_input = false,  -- Flag to skip next input (prevents duplicate input)
        scroll_offset = 0,          -- Current scroll position
        was_paused = false,         -- Game pause state tracker
        background_manager = BackgroundManager.new()
    }
end

function Terminal.new()
    local self = createTerminalState()
    
    -- Initialize terminal fonts
    self.font = love.graphics.newFont(config.font_size)
    self.old_font = love.graphics.getFont()

    -- Toggles terminal visibility and handles input state
    function self:toggle()
        self.active = not self.active
        if not self.active then
            self.input = ""
            self.scroll_offset = 0
        else
            self.ignore_next_input = true
        end
        return self.active
    end

    -- Adds command to history and manages history size
    function self:addToHistory(command)
        if command ~= "" then
            table.insert(self.history, command)
            if #self.history > config.max_history then
                table.remove(self.history, 1)
            end
            self.current_history_index = #self.history + 1
        end
    end

    -- Adds command output to history with formatting
    function self:addOutput(command, output)
        if output then
            table.insert(self.output_history, {
                prompt = string.format("%s@%s:~$ %s", self.username, self.hostname, command),
                output = output
            })
            if #self.output_history > config.max_history then
                table.remove(self.output_history, 1)
            end
            self:scrollToBottom()
        end
    end

    -- Scrolls terminal view to the bottom
    function self:scrollToBottom()
        local total_height = self:getTotalHeight()
        local visible_height = constants.WINDOW_HEIGHT / 2
        self.scroll_offset = math.max(0, total_height - visible_height + config.line_height)
    end

    -- Calculates total height of terminal content
    function self:getTotalHeight()
        local height = 0
        for _, entry in ipairs(self.output_history) do
            height = height + config.line_height
            if entry.output and entry.output ~= "" then
                height = height + config.line_height * self:countLines(entry.output)
            end
        end
        height = height + config.line_height
        return height
    end

    -- Counts number of lines in a string
    function self:countLines(str)
        if not str or str == "" then return 0 end
        local lines = 1
        for _ in str:gmatch("\n") do
            lines = lines + 1
        end
        return lines
    end

    -- Processes and executes terminal commands
    function self:executeCommand(command)
        if command == "" then return end
        
        self:addToHistory(command)
        
        local cmd = command:lower()
        local handler = commands[cmd]
        local output
        
        if handler then
            output = handler(self)
        else
            output = "Command not found: " .. command
        end
        
        if output then
            self:addOutput(command, output)
        end
    end

    -- Handles keyboard input for terminal navigation and commands
    function self:keypressed(key)
        if not self.active then return end

        if key == "return" or key == "kpenter" then
            self:executeCommand(self.input)
            self.input = ""
        elseif key == "backspace" then
            self.input = self.input:sub(1, -2)
        elseif key == "up" and #self.history > 0 then
            self.current_history_index = math.max(1, self.current_history_index - 1)
            self.input = self.history[self.current_history_index] or ""
        elseif key == "down" and #self.history > 0 then
            self.current_history_index = math.min(#self.history + 1, self.current_history_index + 1)
            self.input = self.history[self.current_history_index] or ""
        elseif key == "pageup" then
            self.scroll_offset = math.max(0, self.scroll_offset - constants.WINDOW_HEIGHT / 4)
        elseif key == "pagedown" then
            local max_scroll = math.max(0, self:getTotalHeight() - constants.WINDOW_HEIGHT / 2 + config.line_height)
            self.scroll_offset = math.min(max_scroll, self.scroll_offset + constants.WINDOW_HEIGHT / 4)
        elseif key == "home" then
            self.scroll_offset = 0
        elseif key == "end" then
            self:scrollToBottom()
        elseif key == "escape" then
            self:toggle()
        end
    end

    -- Handles mouse wheel scrolling
    function self:wheelmoved(x, y)
        if not self.active then return end
        
        -- Adjust scroll position based on wheel movement
        self.scroll_offset = math.max(0, self.scroll_offset - y * config.line_height)
        
        -- Limit scrolling to content bounds
        local max_scroll = math.max(0, self:getTotalHeight() - constants.WINDOW_HEIGHT / 2 + config.line_height)
        self.scroll_offset = math.min(max_scroll, self.scroll_offset)
    end

    -- Handles text input for the terminal
    function self:textinput(text)
        if not self.active then return end
        if self.ignore_next_input then
            self.ignore_next_input = false
            return
        end
        self.input = self.input .. text
    end

    -- Renders the terminal interface
    function self:draw()
        -- Draw FPS counter when enabled
        if self.show_fps then
            love.graphics.push()
            love.graphics.setFont(self.font)
            love.graphics.setColor(0, 1, 0, 1)  -- Green color for FPS
            local fps = love.timer.getFPS()
            local fps_text = string.format("FPS: %d", fps)
            local text_width = self.font:getWidth(fps_text)
            love.graphics.print(fps_text, constants.WINDOW_WIDTH - text_width - 10, 10)
            love.graphics.pop()
        end

        if not self.active then return end

        -- Set up terminal graphics state
        love.graphics.push()
        love.graphics.setFont(self.font)

        -- Draw terminal background
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT / 2)

        -- Create scrollable area using stencil
        love.graphics.stencil(function()
            love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT / 2)
        end, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        -- Draw terminal content
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        
        local y = 10 - self.scroll_offset
        for _, entry in ipairs(self.output_history) do
            -- Draw command prompt
            love.graphics.setColor(0, 0.8, 0, 1)  -- Green color for prompt
            love.graphics.print(entry.prompt, 10, y)
            y = y + config.line_height
            
            -- Draw command output
            if entry.output and entry.output ~= "" then
                love.graphics.setColor(0.8, 0.8, 0.8, 1)  -- Light gray for output
                love.graphics.print(entry.output, 10, y)
                y = y + config.line_height * self:countLines(entry.output)
            end
        end

        -- Draw current input prompt
        love.graphics.setColor(0, 0.8, 0, 1)
        local prompt = string.format("%s@%s:~$ ", self.username, self.hostname)
        love.graphics.print(prompt .. self.input .. (love.timer.getTime() % 1 > 0.5 and "_" or ""), 10, y)

        love.graphics.setStencilTest()

        -- Draw scroll indicators when content overflows
        if self.scroll_offset > 0 then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.polygon("fill", constants.WINDOW_WIDTH - 20, 10, constants.WINDOW_WIDTH - 10, 20, constants.WINDOW_WIDTH - 30, 20)
        end
        if self.scroll_offset < self:getTotalHeight() - constants.WINDOW_HEIGHT / 2 + config.line_height then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.polygon("fill", constants.WINDOW_WIDTH - 20, constants.WINDOW_HEIGHT / 2 - 10, constants.WINDOW_WIDTH - 10, constants.WINDOW_HEIGHT / 2 - 20, constants.WINDOW_WIDTH - 30, constants.WINDOW_HEIGHT / 2 - 20)
        end

        love.graphics.pop()
    end

    return self
end

return Terminal