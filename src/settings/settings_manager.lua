-- SettingsManager Module --

local SettingsManager = {}
SettingsManager.__index = SettingsManager

local instance = nil

--[[
Creates a new SettingsManager instance or returns existing one
@param force_reload (boolean) If true, forces reload of settings from disk
@return SettingsManager instance
]]
function SettingsManager.new(force_reload)
    if instance and not force_reload then
        return instance
    end

    local self = setmetatable({}, SettingsManager)
    
    -- Determine appropriate save directory based on distribution method
    local save_dir = love.filesystem.getSourceBaseDirectory()
    if love.filesystem.isFused() then
        -- Use dedicated save directory when running as compiled executable
        save_dir = love.filesystem.getSaveDirectory()
    end
    
    -- Ensure data directory exists for settings storage
    love.filesystem.createDirectory("data")
    
    -- Configure settings storage location
    self.settings_file = 'data/settings.json'
    
    -- Define default settings
    self.default_settings = {
        sound_volume = 100  -- Default volume level (0-100)
    }
    
    -- Handle forced reload case
    if force_reload and instance then
        instance.settings = instance:load_settings()
        return instance
    end
    
    -- Initialize settings and store instance
    self.settings = self:load_settings()
    instance = self
    return self
end

--[[
Loads settings from file or creates new with defaults
@return table containing current settings
]]
function SettingsManager:load_settings()
    local contents
    if love.filesystem.getInfo(self.settings_file) then
        contents = love.filesystem.read(self.settings_file)
    end
    
    if contents and contents ~= "" then
        -- Parse JSON format settings
        local settings = {}
        for k, v in string.gmatch(contents, '"([^"]+)"%s*:%s*([%d%.]+)') do
            settings[k] = tonumber(v)
        end
        -- Merge with defaults to ensure all required settings exist
        local final_settings = {}
        for k, v in pairs(self.default_settings) do
            final_settings[k] = settings[k] or v
        end
        return final_settings
    end
    
    -- Handle case where file doesn't exist or is invalid
    local default_copy = self:copy_table(self.default_settings)
    self.settings = default_copy
    self:save_settings()
    return default_copy
end

--[[
Saves current settings to file in JSON format
@return boolean indicating success
]]
function SettingsManager:save_settings()
    local json = "{\n"
    local items = {}
    for k, v in pairs(self.settings) do
        table.insert(items, string.format('    "%s": %s', k, tostring(v)))
    end
    json = json .. table.concat(items, ",\n") .. "\n}"
    
    local success, message = love.filesystem.write(self.settings_file, json)
    if not success then
        return false
    end
    return true
end

--[[
Retrieves a setting value
@param key (string) The setting key to retrieve
@return The setting value or default if not found
]]
function SettingsManager:get_setting(key)
    return self.settings[key] or self.default_settings[key]
end

--[[
Updates a setting value and persists to storage
@param key (string) The setting key to update
@param value (any) The new value to store
]]
function SettingsManager:set_setting(key, value)
    self.settings[key] = value
    self:save_settings()
end

--[[
Creates a shallow copy of a table
@param t (table) The table to copy
@return A new table with copied values
]]
function SettingsManager:copy_table(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

return SettingsManager