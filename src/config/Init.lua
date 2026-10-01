local cloneref = cloneref or clonereference or function(instance)
	return instance
end

local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))

local ConfigManager = {}
ConfigManager.__index = ConfigManager

local DEFAULT_ROOT = "StealthxUI"
local CONFIG_VERSION = 3

local function hasFunction(name)
	local env = _G
	if type(getgenv) == "function" then
		local ok, value = pcall(getgenv)
		if ok and type(value) == "table" then
			env = value
		end
	end
	return type(env[name]) == "function"
end

local function ensureFolder(path)
	if not path or path == "" or not hasFunction("isfolder") or not hasFunction("makefolder") then
		return false
	end

	if isfolder(path) then
		return true
	end

	local normalized = tostring(path):gsub("\\", "/"):gsub("/+", "/")
	local current = ""

	for segment in normalized:gmatch("[^/]+") do
		current = current == "" and segment or (current .. "/" .. segment)
		if not isfolder(current) then
			local ok = pcall(makefolder, current)
			if not ok and not isfolder(current) then
				return false
			end
		end
	end

	return isfolder(normalized)
end

local function cleanConfigName(value)
	value = tostring(value or "")
	value = value:gsub("[%c/:*?\"<>|]", " ")
	value = value:gsub("%s+", " ")
	value = value:match("^%s*(.-)%s*$") or ""
	return value ~= "" and value:sub(1, 96) or nil
end

local function cleanFolderName(value)
	value = tostring(value or "")
	value = value:gsub("[%c:*?\"<>|]", " ")
	value = value:gsub("/+", "/"):gsub("\\+", "/")
	value = value:gsub("%s+", " ")
	value = value:match("^%s*(.-)%s*$") or ""
	return value ~= "" and value or nil
end

local function parseJSON(path)
	if not hasFunction("isfile") or not hasFunction("readfile") or not isfile(path) then
		return false, "Config file does not exist"
	end

	local ok, value = pcall(function()
		local raw = readfile(path)
		if type(raw) ~= "string" or raw == "" then
			error("Config file is empty")
		end
		return HttpService:JSONDecode(raw)
	end)

	if not ok or typeof(value) ~= "table" then
		return false, "Failed to parse config file"
	end

	return true, value
end

local function writeJSON(path, value)
	if not hasFunction("writefile") then
		return false, "writefile function is not available"
	end

	local okEncode, encoded = pcall(function()
		return HttpService:JSONEncode(value)
	end)
	if not okEncode then
		return false, "Failed to encode config: " .. tostring(encoded)
	end

	local tempPath = path .. ".tmp"
	local okWrite, writeError = pcall(function()
		writefile(tempPath, encoded)
	end)
	if not okWrite then
		return false, "Failed to write config: " .. tostring(writeError)
	end

	if hasFunction("delfile") and hasFunction("renamefile") then
		local swapOk, swapError = pcall(function()
			if isfile(path) then
				delfile(path)
			end
			renamefile(tempPath, path)
		end)
		if swapOk then
			return true
		end
		pcall(delfile, tempPath)
		return false, "Failed to finalize config: " .. tostring(swapError)
	end

	local directOk, directError = pcall(function()
		writefile(path, encoded)
	end)
	pcall(delfile, tempPath)
	if not directOk then
		return false, "Failed to write config: " .. tostring(directError)
	end

	return true
end

local function cloneValue(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, item in next, value do
		copy[key] = cloneValue(item)
	end
	return copy
end

ConfigManager.Parser = {
	Colorpicker = {
		Save = function(element)
			local color = element.Default
			return {
				__type = element.__type,
				value = color and color.ToHex and color:ToHex() or "FFFFFF",
				transparency = element.Transparency,
			}
		end,
		Load = function(element, data)
			if not element or not element.Update or type(data) ~= "table" or type(data.value) ~= "string" then
				return false
			end
			local ok, color = pcall(Color3.fromHex, data.value)
			if not ok then
				return false
			end
			element:Update(color, data.transparency)
			return true
		end,
	},
	Dropdown = {
		Save = function(element)
			return {
				__type = element.__type,
				value = cloneValue(element.Value),
			}
		end,
		Load = function(element, data)
			if element and element.Select and type(data) == "table" then
				element:Select(cloneValue(data.value))
				return true
			end
			return false
		end,
	},
	Input = {
		Save = function(element)
			return {
				__type = element.__type,
				value = element.Value,
			}
		end,
		Load = function(element, data)
			if element and element.Set and type(data) == "table" then
				element:Set(data.value)
				return true
			end
			return false
		end,
	},
	Keybind = {
		Save = function(element)
			return {
				__type = element.__type,
				value = element.Value,
			}
		end,
		Load = function(element, data)
			if element and element.Set and type(data) == "table" then
				element:Set(data.value)
				return true
			end
			return false
		end,
	},
	Slider = {
		Save = function(element)
			return {
				__type = element.__type,
				value = element.Value and element.Value.Default,
			}
		end,
		Load = function(element, data)
			if element and element.Set and type(data) == "table" then
				local number = tonumber(data.value)
				if number then
					element:Set(number)
					return true
				end
			end
			return false
		end,
	},
	Toggle = {
		Save = function(element)
			return {
				__type = element.__type,
				value = element.Value == true,
			}
		end,
		Load = function(element, data)
			if element and element.Set and type(data) == "table" and type(data.value) == "boolean" then
				element:Set(data.value)
				return true
			end
			return false
		end,
	},
}

function ConfigManager:Init(WindowTable)
	if not WindowTable or not WindowTable.Folder then
		warn("[ StealthxUI.ConfigManager ] Window.Folder is not specified.")
		return nil
	end

	if RunService:IsStudio() or not hasFunction("writefile") then
		warn("[ StealthxUI.ConfigManager ] The config system requires executor filesystem functions and is disabled in Studio.")
		return nil
	end

	local folder = cleanFolderName(WindowTable.Folder)
	if not folder then
		warn("[ StealthxUI.ConfigManager ] Invalid Window.Folder.")
		return nil
	end

	local manager = setmetatable({
		Window = WindowTable,
		Folder = folder,
		Path = DEFAULT_ROOT .. "/" .. folder .. "/config/",
		Configs = {},
		Parser = {},
		Destroyed = false,
	}, ConfigManager)

	for name, parser in next, ConfigManager.Parser do
		manager.Parser[name] = parser
	end

	ensureFolder(DEFAULT_ROOT)
	ensureFolder(DEFAULT_ROOT .. "/" .. folder)
	ensureFolder(manager.Path)

	return manager
end

function ConfigManager:SetPath(customPath)
	if self.Destroyed then
		return false, "Config manager has been destroyed"
	end
	if not customPath then
		return false, "Custom path is not specified"
	end

	local path = tostring(customPath):gsub("\\", "/"):gsub("/+", "/")
	if not path:match("/$") then
		path = path .. "/"
	end

	if not ensureFolder(path) then
		return false, "Unable to create config directory"
	end

	self.Path = path
	for name, config in next, self.Configs do
		config.Path = path .. name .. ".json"
	end
	return true
end

function ConfigManager:RegisterParser(elementType, parser)
	if self.Destroyed then
		return false, "Config manager has been destroyed"
	end
	if type(elementType) ~= "string" or elementType == "" then
		return false, "Invalid element type"
	end
	if type(parser) ~= "table" or type(parser.Save) ~= "function" or type(parser.Load) ~= "function" then
		return false, "Parser must provide Save and Load functions"
	end
	self.Parser[elementType] = parser
	return parser
end

function ConfigManager:SyncElements(config)
	local window = self.Window
	config = config or window.CurrentConfig
	if not config then
		return false
	end

	config.Elements = {}
	for flag, element in next, (window.ConfigElements or {}) do
		if element and not element.Destroyed and self.Parser[element.__type] then
			config.Elements[flag] = element
		end
	end

	return true
end

function ConfigManager:UnregisterElement(flag, element)
	local window = self.Window
	if window.ConfigElements and window.ConfigElements[flag] == element then
		window.ConfigElements[flag] = nil
	end
	if window.PendingFlags and window.PendingFlags[flag] == element then
		window.PendingFlags[flag] = nil
	end
	for _, config in next, self.Configs do
		if config.Elements and config.Elements[flag] == element then
			config.Elements[flag] = nil
		end
	end
end

function ConfigManager:CreateConfig(configFilename, autoload)
	if self.Destroyed then
		return false, "Config manager has been destroyed"
	end

	local configName = cleanConfigName(configFilename)
	if not configName then
		return false, "No config file is selected"
	end

	local existing = self.Configs[configName]
	if existing then
		if autoload ~= nil then
			existing.AutoLoad = autoload == true
		end
		existing:SetAsCurrent()
		return existing
	end

	local config = {
		Name = configName,
		Path = self.Path .. configName .. ".json",
		Elements = {},
		PendingData = {},
		CustomData = {},
		AutoLoad = autoload == true,
		Version = CONFIG_VERSION,
		Manager = self,
		Loaded = false,
		Destroyed = false,
		AutoLoadScheduled = false,
	}

	function config:SetAsCurrent()
		if config.Destroyed then
			return config
		end
		config.Manager.Window:SetCurrentConfig(config)
		return config
	end

	function config:Register(name, element)
		if type(name) == "string" and name ~= "" and element then
			config.Elements[name] = element
		end
		return element
	end

	function config:Unregister(name, element)
		if config.Elements[name] == nil or element == nil or config.Elements[name] == element then
			config.Elements[name] = nil
		end
	end

	function config:Set(key, value)
		config.CustomData[key] = value
		return config
	end

	function config:Get(key, default)
		local value = config.CustomData[key]
		if value == nil then
			return default
		end
		return value
	end

	function config:SetAutoLoad(value)
		config.AutoLoad = value == true
		return config
	end

	function config:Save()
		if config.Destroyed then
			return false, "Config has been destroyed"
		end
		if not hasFunction("writefile") then
			return false, "writefile function is not available"
		end
		if not ensureFolder(config.Manager.Path) then
			return false, "Unable to create config directory"
		end

		config.Manager:SyncElements(config)

		local saveData = {
			__library = "StealthxUI",
			__version = CONFIG_VERSION,
			__savedAt = os.time(),
			__autoload = config.AutoLoad == true,
			__elements = {},
			__custom = cloneValue(config.CustomData),
		}

		for flag, data in next, (config.PendingData or {}) do
			saveData.__elements[tostring(flag)] = cloneValue(data)
		end

		for flag, element in next, config.Elements do
			local parser = config.Manager.Parser[element.__type]
			if parser and type(parser.Save) == "function" then
				local ok, value = pcall(parser.Save, element)
				if ok and value ~= nil then
					saveData.__elements[tostring(flag)] = value
				end
			end
		end

		local ok, err = writeJSON(config.Path, saveData)
		if not ok then
			return false, err
		end

		return saveData
	end

	function config:Load()
		if config.Destroyed then
			return false, "Config has been destroyed"
		end

		local ok, loadData = parseJSON(config.Path)
		if not ok then
			return false, loadData
		end

		if type(loadData.__elements) ~= "table" then
			loadData = {
				__version = CONFIG_VERSION,
				__elements = loadData,
				__custom = {},
			}
		end

		config.AutoLoad = loadData.__autoload == true or config.AutoLoad
		config.CustomData = type(loadData.__custom) == "table" and loadData.__custom or {}
		config.PendingData = {}
		config.Manager:SyncElements(config)

		for flag, data in next, loadData.__elements do
			if type(data) ~= "table" then
				continue
			end

			local parser = config.Manager.Parser[data.__type]
			local element = config.Elements[flag]

			if element and parser and element.__type == data.__type then
				local okApply, applied = pcall(parser.Load, element, data)
				if not okApply or applied == false then
					warn("[ StealthxUI.ConfigManager ] Failed to load flag '" .. tostring(flag) .. "'")
				end
			elseif parser and not element then
				config.PendingData[flag] = cloneValue(data)
			elseif element and parser and element.__type ~= data.__type then
				warn("[ StealthxUI.ConfigManager ] Ignored incompatible saved type for '" .. tostring(flag) .. "'")
			end
		end

		config.Loaded = true
		if config.Manager.Window.PendingConfigData == config.PendingData then
			config.Manager.Window.PendingConfigData = config.PendingData
		end
		return config.CustomData
	end

	function config:Delete()
		if config.Destroyed then
			return false, "Config has been destroyed"
		end
		if not hasFunction("delfile") or not hasFunction("isfile") or not isfile(config.Path) then
			self.Destroyed = true
			self.Manager.Configs[config.Name] = nil
			if self.Manager.Window.CurrentConfig == self then
				self.Manager.Window:SetCurrentConfig(nil)
			end
			return true, "Config removed"
		end

		local ok, err = pcall(delfile, config.Path)
		if not ok then
			return false, "Failed to delete config file: " .. tostring(err)
		end

		self.Destroyed = true
		self.Manager.Configs[config.Name] = nil
		if self.Manager.Window.CurrentConfig == config then
			self.Manager.Window:SetCurrentConfig(nil)
		end
		return true, "Config deleted successfully"
	end

	function config:GetData()
		return {
			name = config.Name,
			path = config.Path,
			elements = config.Elements,
			pending = config.PendingData,
			custom = config.CustomData,
			autoload = config.AutoLoad,
			version = config.Version,
		}
	end

	self.Configs[configName] = config
	config:SetAsCurrent()

	local shouldAutoLoad = config.AutoLoad
	if hasFunction("isfile") and hasFunction("readfile") and isfile(config.Path) then
		local storedOk, stored = parseJSON(config.Path)
		if storedOk and stored.__autoload == true then
			shouldAutoLoad = true
			config.AutoLoad = true
		end
	end

	if shouldAutoLoad and not config.AutoLoadScheduled and hasFunction("isfile") and isfile(config.Path) then
		config.AutoLoadScheduled = true
		task.defer(function()
			if self.Destroyed or config.Destroyed then
				return
			end
			if config.Loaded then
				return
			end
			local ok, result = pcall(config.Load)
			if not ok then
				warn("[ StealthxUI.ConfigManager ] Failed to AutoLoad config '" .. configName .. "': " .. tostring(result))
			elseif self.Window and self.Window.Debug then
				print("[ StealthxUI.ConfigManager ] AutoLoaded config: " .. configName)
			end
		end)
	end

	return config
end

function ConfigManager:Config(configFilename, autoload)
	return self:CreateConfig(configFilename, autoload)
end

function ConfigManager:GetAutoLoadConfigs()
	local result = {}
	for name, config in next, self.Configs do
		if config.AutoLoad then
			table.insert(result, name)
		end
	end

	for _, name in next, self:AllConfigs() do
		if not table.find(result, name) then
			local ok, data = parseJSON(self.Path .. name .. ".json")
			if ok and data.__autoload == true then
				table.insert(result, name)
			end
		end
	end

	table.sort(result, function(a, b)
		return a:lower() < b:lower()
	end)
	return result
end

function ConfigManager:DeleteConfig(configName)
	local cleanName = cleanConfigName(configName)
	if not cleanName then
		return false, "No config file is selected"
	end

	local existing = self.Configs[cleanName]
	if existing then
		return existing:Delete()
	end

	if not hasFunction("delfile") then
		return false, "delfile function is not available"
	end
	local path = self.Path .. cleanName .. ".json"
	if not hasFunction("isfile") or not isfile(path) then
		return false, "Config file does not exist"
	end

	local ok, err = pcall(delfile, path)
	if not ok then
		return false, "Failed to delete config file: " .. tostring(err)
	end
	return true, "Config deleted successfully"
end

function ConfigManager:AllConfigs()
	if self.Destroyed or not hasFunction("listfiles") then
		return {}
	end

	ensureFolder(self.Path)
	local files = {}
	for _, file in next, listfiles(self.Path) do
		local name = file:match("([^\\/]+)%.json$")
		if name then
			table.insert(files, name)
		end
	end

	table.sort(files, function(a, b)
		return a:lower() < b:lower()
	end)
	return files
end

function ConfigManager:GetConfig(configName)
	local cleanName = cleanConfigName(configName)
	return cleanName and self.Configs[cleanName] or nil
end

function ConfigManager:Destroy()
	self.Destroyed = true
	self.Configs = {}
	if self.Window then
		self.Window.ConfigManager = nil
	end
	self.Window = nil
	return self
end

return ConfigManager
