--[[
Settings manager to handle persistent game settings.
]]

local SettingsManager = {}
SettingsManager.__index = SettingsManager

local instance = nil

function SettingsManager.new(force_reload)
    if instance and not force_reload then
        return instance
    end

    local self = setmetatable({}, SettingsManager)
    
    -- Store settings in assets/data directory
    self.settings_file = 'assets/data/settings.json'
    
    self.default_settings = {
        sound_volume = 100
    }
    
    -- If we're forcing a reload and instance exists, just reload settings
    if force_reload and instance then
        instance.settings = instance:load_settings()
        return instance
    end
    
    self.settings = self:load_settings()
    instance = self
    return self
end

function SettingsManager:load_settings()
    -- Load settings from file or create with defaults if not exists
    local file = io.open(self.settings_file, "r")
    if file then
        local contents = file:read("*all")
        file:close()
        
        if contents then
            -- Parse JSON
            local settings = {}
            for k, v in string.gmatch(contents, '"([^"]+)"%s*:%s*([%d%.]+)') do
                settings[k] = tonumber(v)
            end
            -- Ensure all default settings exist
            local final_settings = {}
            for k, v in pairs(self.default_settings) do
                final_settings[k] = settings[k] or v
            end
            return final_settings
        end
    end
    
    -- Create initial settings file with defaults
    self:save_settings()
    return self:copy_table(self.default_settings)
end

function SettingsManager:save_settings()
    -- Save current settings to file
    local json = "{\n"
    local items = {}
    for k, v in pairs(self.settings) do
        table.insert(items, string.format('    "%s": %s', k, tostring(v)))
    end
    json = json .. table.concat(items, ",\n") .. "\n}"
    
    local file = io.open(self.settings_file, "w")
    if file then
        file:write(json)
        file:close()
    else
        print("Error: Could not open settings file for writing")
    end
end

function SettingsManager:get_setting(key)
    -- Get a setting value
    return self.settings[key] or self.default_settings[key]
end

function SettingsManager:set_setting(key, value)
    -- Set a setting value and save
    self.settings[key] = value
    self:save_settings()
end

function SettingsManager:copy_table(t)
    -- Helper function to deep copy a table
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

return SettingsManager