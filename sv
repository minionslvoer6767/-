local cloneref = (cloneref or clonereference or function(instance: any) return instance end)
local httpService = cloneref(game:GetService('HttpService'))
local isfolder, isfile, listfiles = isfolder, isfile, listfiles

if typeof(copyfunction) == "function" then
    local isfolder_copy, isfile_copy, listfiles_copy = copyfunction(isfolder), copyfunction(isfile), copyfunction(listfiles)
    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)
    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end
        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end
        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local SaveManager = {} do
    SaveManager.Folder = 'CallistoSettings'
    SaveManager.SubFolder = ''
    SaveManager.Ignore = {}
    SaveManager.Library = nil
    
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = 'Toggle', idx = idx, value = object:Get() }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Flags[idx]
                if object ~= nil then
                    if object ~= data.value then
                        for _, window in pairs(Callisto.Windows) do
                            for _, page in pairs(window.PageList) do
                            end
                        end
                    end
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = 'Slider', idx = idx, value = object:Get() }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Flags[idx]
                if object ~= nil and object ~= data.value then
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = 'Dropdown', idx = idx, value = object:Get(), multi = object.Multi or false }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Flags[idx]
                if object ~= nil and object ~= data.value then
                end
            end,
        },
        Colorpicker = {
            Save = function(idx, object)
                local color, alpha = object:Get()
                return { type = 'Colorpicker', idx = idx, value = color:ToHex(), alpha = alpha }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Flags[idx]
                if object ~= nil then
                end
            end,
        },
        Keybind = {
            Save = function(idx, object)
                local key = object:Get()
                return { type = 'Keybind', idx = idx, key = key and key.Name or "None" }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Flags[idx]
                if object ~= nil then
                end
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type = 'Input', idx = idx, text = object:Get() }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Flags[idx]
                if object ~= nil and object ~= data.text and type(data.text) == 'string' then
                end
            end,
        },
        Checkbox = {
            Save = function(idx, object)
                return { type = 'Checkbox', idx = idx, value = object:Get() }
            end,
            Load = function(idx, data)
                local object = SaveManager.Library.Flags[idx]
                if object ~= nil and object ~= data.value then
                end
            end,
        },
    }

    function SaveManager:SetLibrary(library)
        self.Library = library
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            "Background", "Foreground", "ForegroundLight", "Border", "Accent", "AccentLight", "AccentDark", "Text",
            "SaveManager_ConfigList", "SaveManager_ConfigName"
        })
    end

    function SaveManager:CheckSubFolder(createFolder)
        if typeof(self.SubFolder) ~= "string" or self.SubFolder == "" then return false end
        if createFolder == true then
            if not isfolder(self.Folder .. "/settings/" .. self.SubFolder) then
                makefolder(self.Folder .. "/settings/" .. self.SubFolder)
            end
        end
        return true
    end

    function SaveManager:GetPaths()
        local paths = {}
        local parts = self.Folder:split('/')
        for idx = 1, #parts do
            local path = table.concat(parts, '/', 1, idx)
            if not table.find(paths, path) then paths[#paths + 1] = path end
        end
        paths[#paths + 1] = self.Folder .. '/themes'
        paths[#paths + 1] = self.Folder .. '/settings'
        if self:CheckSubFolder(false) then
            local subFolder = self.Folder .. "/settings/" .. self.SubFolder
            parts = subFolder:split('/')
            for idx = 1, #parts do
                local path = table.concat(parts, '/', 1, idx)
                if not table.find(paths, path) then paths[#paths + 1] = path end
            end
        end
        return paths
    end

    function SaveManager:BuildFolderTree()
        local paths = self:GetPaths()
        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then continue end
            makefolder(str)
        end
    end

    function SaveManager:CheckFolderTree()
        if isfolder(self.Folder) then return end
        SaveManager:BuildFolderTree()
        task.wait(0.1)
    end

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in next, list do
            self.Ignore[key] = true
        end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function SaveManager:SetSubFolder(folder)
        self.SubFolder = folder
        self:BuildFolderTree()
    end

    function SaveManager:Save(name)
        if (not name) then
            return false, 'no config file is selected'
        end
        SaveManager:CheckFolderTree()

        local fullPath = self.Folder .. '/settings/' .. name .. '.json'
        if SaveManager:CheckSubFolder(true) then
            fullPath = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. '.json'
        end

        local data = { objects = {}, flags = {} }

        -- Safely save flags
        if Callisto.Flags then
            for idx, value in pairs(Callisto.Flags) do
                if self.Ignore[idx] then continue end
                data.flags[idx] = value
            end
        end

        local success, encoded = pcall(httpService.JSONEncode, httpService, data)
        if not success then
            return false, 'failed to encode data'
        end

        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        if (not name) then
            return false, 'no config file is selected'
        end
        SaveManager:CheckFolderTree()

        local file = self.Folder .. '/settings/' .. name .. '.json'
        if SaveManager:CheckSubFolder(true) then
            file = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. '.json'
        end

        if not isfile(file) then return false, 'invalid file' end

        local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
        if not success then return false, 'decode error' end

        if decoded.flags then
            -- Ensure Callisto.Flags exists
            if not Callisto.Flags then
                Callisto.Flags = {}
            end
            for idx, value in pairs(decoded.flags) do
                Callisto.Flags[idx] = value
            end
        end

        return true
    end

    function SaveManager:Delete(name)
        if (not name) then
            return false, 'no config file is selected'
        end

        local file = self.Folder .. '/settings/' .. name .. '.json'
        if SaveManager:CheckSubFolder(true) then
            file = self.Folder .. "/settings/" .. self.SubFolder .. "/" .. name .. '.json'
        end

        if not isfile(file) then return false, 'invalid file' end

        local success = pcall(delfile, file)
        if not success then return false, 'delete file error' end

        return true
    end

    function SaveManager:RefreshConfigList()
        local success, data = pcall(function()
            SaveManager:CheckFolderTree()
            local list = {}
            local out = {}

            if SaveManager:CheckSubFolder(true) then
                list = listfiles(self.Folder .. "/settings/" .. self.SubFolder)
            else
                list = listfiles(self.Folder .. "/settings")
            end
            if typeof(list) ~= "table" then list = {} end

            for i = 1, #list do
                local file = list[i]
                if file:sub(-5) == '.json' then
                    local pos = file:find('.json', 1, true)
                    local start = pos
                    local char = file:sub(pos, pos)
                    while char ~= '/' and char ~= '\\' and char ~= '' do
                        pos = pos - 1
                        char = file:sub(pos, pos)
                    end
                    if char == '/' or char == '\\' then
                        table.insert(out, file:sub(pos + 1, start - 1))
                    end
                end
            end
            return out
        end)

        if (not success) then
            if self.Library then
                notify("Error", 'Failed to load config list: ' .. tostring(data))
            end
            return {}
        end
        return data
    end

    function SaveManager:GetAutoloadConfig()
        SaveManager:CheckFolderTree()
        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if SaveManager:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        if isfile(autoLoadPath) then
            local successRead, name = pcall(readfile, autoLoadPath)
            if not successRead then
                return "none"
            end
            name = tostring(name)
            return if name == "" then "none" else name
        end
        return "none"
    end

    function SaveManager:LoadAutoloadConfig()
        SaveManager:CheckFolderTree()
        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if SaveManager:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        if isfile(autoLoadPath) then
            local successRead, name = pcall(readfile, autoLoadPath)
            if not successRead then
                return notify("Error", 'Failed to load autoload config')
            end
            local success, err = self:Load(name)
            if not success then
                return notify("Error", 'Failed to load autoload config: ' .. err)
            end
            notify("Config", 'Auto loaded config: ' .. name)
        end
    end

    function SaveManager:SaveAutoloadConfig(name)
        SaveManager:CheckFolderTree()
        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if SaveManager:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        local success = pcall(writefile, autoLoadPath, name)
        if not success then return false, 'write file error' end
        return true, ""
    end

    function SaveManager:DeleteAutoLoadConfig()
        SaveManager:CheckFolderTree()
        local autoLoadPath = self.Folder .. "/settings/autoload.txt"
        if SaveManager:CheckSubFolder(true) then
            autoLoadPath = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        local success = pcall(delfile, autoLoadPath)
        if not success then return false, 'delete file error' end
        return true, ""
    end

    function SaveManager:BuildConfigSection(section)
        assert(self.Library, 'Must set SaveManager.Library')

        local configSection = section
        
        configSection:AddLabel({ Title = "Config Name" })
        local configNameInput = configSection:AddInput({
            Title = "",
            Placeholder = "Enter config name...",
            Default = "",
            Flag = "SaveManager_ConfigName",
        })

        configSection:AddButton({
            Title = "Create Config",
            Callback = function()
                -- Safely access Flags table
                if not Callisto.Flags then
                    Callisto.Flags = {}
                end
                
                local name = Callisto.Flags.SaveManager_ConfigName or ""
                if name:gsub(' ', '') == '' then
                    return notify("Error", 'Invalid config name (empty)')
                end
                local success, err = self:Save(name)
                if not success then
                    return notify("Error", 'Failed to create config: ' .. err)
                end
                notify("Config", 'Created config: ' .. name)
                Callisto.Flags.SaveManager_ConfigList = self:RefreshConfigList()
            end
        })

        configSection:AddLabel({ Title = "──────────────────" })

        local configList = configSection:AddDropdown({
            Title = "Config List",
            Values = self:RefreshConfigList(),
            Flag = "SaveManager_ConfigList",
            Multi = false,
        })

        configSection:AddButton({
            Title = "Load Config",
            Callback = function()
                if not Callisto.Flags then
                    Callisto.Flags = {}
                end
                local name = Callisto.Flags.SaveManager_ConfigList
                if not name then return notify("Error", 'No config selected') end
                local success, err = self:Load(name)
                if not success then
                    return notify("Error", 'Failed to load config: ' .. err)
                end
                notify("Config", 'Loaded config: ' .. name)
            end
        })

        configSection:AddButton({
            Title = "Overwrite Config",
            Callback = function()
                if not Callisto.Flags then
                    Callisto.Flags = {}
                end
                local name = Callisto.Flags.SaveManager_ConfigList
                if not name then return notify("Error", 'No config selected') end
                local success, err = self:Save(name)
                if not success then
                    return notify("Error", 'Failed to overwrite config: ' .. err)
                end
                notify("Config", 'Overwrote config: ' .. name)
            end
        })

        configSection:AddButton({
            Title = "Delete Config",
            Callback = function()
                if not Callisto.Flags then
                    Callisto.Flags = {}
                end
                local name = Callisto.Flags.SaveManager_ConfigList
                if not name then return notify("Error", 'No config selected') end
                local success, err = self:Delete(name)
                if not success then
                    return notify("Error", 'Failed to delete config: ' .. err)
                end
                notify("Config", 'Deleted config: ' .. name)
                Callisto.Flags.SaveManager_ConfigList = nil
                configList:Refresh(self:RefreshConfigList())
            end
        })

        configSection:AddButton({
            Title = "Refresh List",
            Callback = function()
                configList:Refresh(self:RefreshConfigList())
                notify("Config", 'List refreshed')
            end
        })

        configSection:AddLabel({ Title = "──────────────────" })

        configSection:AddButton({
            Title = "Set as Autoload",
            Callback = function()
                if not Callisto.Flags then
                    Callisto.Flags = {}
                end
                local name = Callisto.Flags.SaveManager_ConfigList
                if not name then return notify("Error", 'No config selected') end
                local success, err = self:SaveAutoloadConfig(name)
                if not success then
                    return notify("Error", 'Failed to set autoload config: ' .. err)
                end
                notify("Config", 'Set ' .. name .. ' to auto load')
            end
        })

        configSection:AddButton({
            Title = "Reset Autoload",
            Callback = function()
                local success, err = self:DeleteAutoLoadConfig()
                if not success then
                    return notify("Error", 'Failed to reset autoload: ' .. err)
                end
                notify("Config", 'Autoload reset')
            end
        })

        configSection:AddLabel({
            Title = "Current Autoload: " .. self:GetAutoloadConfig()
        })

        self:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
    end

    SaveManager:BuildFolderTree()
end

return SaveManager
