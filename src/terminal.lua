-- Terminal module entry point
-- This file serves as the main entry point for the terminal functionality

local Terminal = {}
local constants = require('src.constants')
local BackgroundManager = require('src.graphics.background')

function Terminal.new()
    local self = {
        active = false,
        input = "",
        history = {},
        output_history = {},  -- Store command outputs
        current_history_index = 1,
        show_fps = false,
        username = "player",
        hostname = "pisnake",
        ignore_next_input = false,  -- Flag to ignore next textinput
        scroll_offset = 0,  -- Scroll position
        max_history = 50,   -- Increased history limit
        line_height = 20,    -- Height of each line in pixels
        was_paused = false,  -- Track if game was already paused
        background_manager = BackgroundManager.new(),
    }

    -- Font for the terminal and FPS display
    self.font = love.graphics.newFont(16)
    self.old_font = love.graphics.getFont()

    function self:toggle()
        self.active = not self.active
        if not self.active then
            self.input = ""
            self.scroll_offset = 0  -- Reset scroll position when closing
        else
            self.ignore_next_input = true
        end
        return self.active  -- Return state for main.lua to handle pause
    end

    function self:addToHistory(command)
        if command ~= "" then
            table.insert(self.history, command)
            self.current_history_index = #self.history + 1
        end
    end

    function self:addOutput(command, output)
        table.insert(self.output_history, {
            prompt = self.username .. "@" .. self.hostname .. ":~$ " .. command,
            output = output
        })
        -- Keep only max_history commands in history
        if #self.output_history > self.max_history then
            table.remove(self.output_history, 1)
        end
        -- Auto-scroll to bottom when new command is added
        self:scrollToBottom()
    end

    function self:scrollToBottom()
        local total_height = self:getTotalHeight()
        local visible_height = constants.WINDOW_HEIGHT / 2
        self.scroll_offset = math.max(0, total_height - visible_height + self.line_height)
    end

    function self:getTotalHeight()
        local height = 0
        for _, entry in ipairs(self.output_history) do
            height = height + self.line_height  -- Prompt line
            if entry.output and entry.output ~= "" then
                height = height + self.line_height * self:countLines(entry.output)
            end
        end
        height = height + self.line_height  -- Current input line
        return height
    end

    -- Helper function to count lines in a string
    function self:countLines(str)
        if not str or str == "" then return 0 end
        local lines = 1
        for _ in str:gmatch("\n") do
            lines = lines + 1
        end
        return lines
    end

    function self:executeCommand(command)
        if command == "" then return end
        
        self:addToHistory(command)
        
        -- Convert command to lowercase for case-insensitive comparison
        local cmd = command:lower()
        local output = ""
        
        if cmd == "show_fps" then
            self.show_fps = not self.show_fps
            output = self.show_fps and "FPS display enabled" or "FPS display disabled"
        elseif cmd == "help" then
            output = [[Available commands:
show_fps     Toggle FPS display
show_border  Toggle menu background border
help         Show this help message
clear        Clear terminal
exit         Close terminal
whoami       Display current user]]
        elseif cmd == "clear" then
            self.output_history = {}
            self.scroll_offset = 0
            return
        elseif cmd == "exit" then
            self:toggle()
            output = "Terminal closed"
        elseif cmd == "whoami" then
            output = self.username
        elseif cmd == "show_border" then
            local is_enabled = self.background_manager:toggle_border()
            output = string.format("Menu background border %s", is_enabled and "enabled" or "disabled")
        else
            output = "Command not found: " .. command
        end

        self:addOutput(command, output)
    end

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
            local max_scroll = math.max(0, self:getTotalHeight() - constants.WINDOW_HEIGHT / 2 + self.line_height)
            self.scroll_offset = math.min(max_scroll, self.scroll_offset + constants.WINDOW_HEIGHT / 4)
        elseif key == "home" then
            self.scroll_offset = 0
        elseif key == "end" then
            self:scrollToBottom()
        elseif key == "escape" then
            self:toggle()
        end
    end

    function self:wheelmoved(x, y)
        if not self.active then return end
        
        -- Scroll up/down (multiply by line height for smoother scrolling)
        self.scroll_offset = math.max(0, self.scroll_offset - y * self.line_height)
        
        -- Limit scrolling to content height plus one line to show the input prompt fully
        local max_scroll = math.max(0, self:getTotalHeight() - constants.WINDOW_HEIGHT / 2 + self.line_height)
        self.scroll_offset = math.min(max_scroll, self.scroll_offset)
    end

    function self:textinput(text)
        if not self.active then return end
        if self.ignore_next_input then
            self.ignore_next_input = false
            return
        end
        self.input = self.input .. text
    end

    function self:draw()
        -- Draw FPS counter if enabled
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

        -- Draw terminal if active
        if not self.active then return end

        -- Save current graphics state
        love.graphics.push()
        love.graphics.setFont(self.font)

        -- Draw terminal background
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT / 2)

        -- Create a stencil for scrolling
        love.graphics.stencil(function()
            love.graphics.rectangle("fill", 0, 0, constants.WINDOW_WIDTH, constants.WINDOW_HEIGHT / 2)
        end, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        -- Draw terminal content
        love.graphics.setColor(0.8, 0.8, 0.8, 1)  -- Light gray for text
        
        -- Draw command history and outputs
        local y = 10 - self.scroll_offset
        for _, entry in ipairs(self.output_history) do
            -- Draw prompt in green
            love.graphics.setColor(0, 0.8, 0, 1)
            love.graphics.print(entry.prompt, 10, y)
            y = y + self.line_height
            
            -- Draw output in light gray
            if entry.output and entry.output ~= "" then
                love.graphics.setColor(0.8, 0.8, 0.8, 1)
                love.graphics.print(entry.output, 10, y)
                y = y + self.line_height * self:countLines(entry.output)
            end
        end

        -- Draw current prompt
        love.graphics.setColor(0, 0.8, 0, 1)  -- Green color for prompt
        local prompt = self.username .. "@" .. self.hostname .. ":~$ "
        love.graphics.print(prompt .. self.input .. (love.timer.getTime() % 1 > 0.5 and "_" or ""), 10, y)

        -- Disable stencil test
        love.graphics.setStencilTest()

        -- Draw scroll indicators if needed
        if self.scroll_offset > 0 then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.polygon("fill", constants.WINDOW_WIDTH - 20, 10, constants.WINDOW_WIDTH - 10, 20, constants.WINDOW_WIDTH - 30, 20)
        end
        if self.scroll_offset < self:getTotalHeight() - constants.WINDOW_HEIGHT / 2 + self.line_height then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.polygon("fill", constants.WINDOW_WIDTH - 20, constants.WINDOW_HEIGHT / 2 - 10, constants.WINDOW_WIDTH - 10, constants.WINDOW_HEIGHT / 2 - 20, constants.WINDOW_WIDTH - 30, constants.WINDOW_HEIGHT / 2 - 20)
        end

        -- Restore graphics state
        love.graphics.pop()
    end

    return self
end

return Terminal