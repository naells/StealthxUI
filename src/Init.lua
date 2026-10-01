local StealthxUI = {
	Window = nil,
	Theme = nil,
	Creator = require("./modules/Creator"),
	LocalizationModule = require("./modules/Localization"),
	NotificationModule = require("./components/Notification"),
	Themes = nil,
	Transparent = false,

	TransparencyValue = 0.15,

	UIScale = 1,

	ConfigManager = nil,
	Version = "0.0.0",

	Services = require("./utils/services/Init"),

	OnThemeChangeFunction = nil,

	cloneref = nil,
	UIScaleObj = nil,

	CreateWindow = nil,

	CurrentInput = nil,
}

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

StealthxUI.cloneref = cloneref

local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

function StealthxUI.GenerateGUID()
	return HttpService:GenerateGUID(false)
end

local CurInput = StealthxUI.GenerateGUID()

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
	--[[if GameProcessed then
		return
	end]]

	task.defer(function()
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			if StealthxUI.CurrentInput and StealthxUI.CurrentInput ~= CurInput then
				return
			end

			StealthxUI.CurrentInput = CurInput
			--print(CurInput)
			--StealthxUI.InputStartedOnUI = false
		end
	end)
end)
UserInputService.InputEnded:Connect(function(Input, GameProcessed)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		if StealthxUI.CurrentInput and StealthxUI.CurrentInput ~= CurInput then
			return
		end

		StealthxUI.CurrentInput = nil
	end
end)

local LocalPlayer = Players.LocalPlayer or nil

local Package = HttpService:JSONDecode(require("../build/package"))
if Package then
	StealthxUI.Version = Package.version
end

local KeySystem = require("./components/KeySystem")

local Creator = StealthxUI.Creator

local New = Creator.New

--local Tween = Creator.Tween
--local ServicesModule = StealthxUI.Services

local Acrylic = require("./utils/Acrylic/Init")

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local GUIParent = gethui and gethui() or (CoreGui or LocalPlayer:WaitForChild("PlayerGui"))

local UIScaleObj = New("UIScale", {
	Scale = StealthxUI.UIScale,
})

StealthxUI.UIScaleObj = UIScaleObj

StealthxUI.ScreenGui = New("ScreenGui", {
	Name = "StealthxUI",
	Parent = GUIParent,
	IgnoreGuiInset = true,
	ScreenInsets = "None",
	DisplayOrder = -99999,
}, {

	New("Folder", {
		Name = "Window",
	}),
	-- New("Folder", {
	--     Name = "Notifications"
	-- }),
	-- New("Folder", {
	--     Name = "Dropdowns"
	-- }),
	New("Folder", {
		Name = "KeySystem",
	}),
	New("Folder", {
		Name = "Popups",
	}),
	New("Folder", {
		Name = "ToolTips",
	}),
})

StealthxUI.NotificationGui = New("ScreenGui", {
	Name = "StealthxUI/Notifications",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
StealthxUI.DropdownGui = New("ScreenGui", {
	Name = "StealthxUI/Dropdowns",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
StealthxUI.TooltipGui = New("ScreenGui", {
	Name = "StealthxUI/Tooltips",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
ProtectGui(StealthxUI.ScreenGui)
ProtectGui(StealthxUI.NotificationGui)
ProtectGui(StealthxUI.DropdownGui)
ProtectGui(StealthxUI.TooltipGui)

Creator.Init(StealthxUI)

function StealthxUI:SetParent(parent)
	if StealthxUI.ScreenGui then
		StealthxUI.ScreenGui.Parent = parent
	end
	if StealthxUI.NotificationGui then
		StealthxUI.NotificationGui.Parent = parent
	end
	if StealthxUI.DropdownGui then
		StealthxUI.DropdownGui.Parent = parent
	end
	if StealthxUI.TooltipGui then
		StealthxUI.TooltipGui.Parent = parent
	end
end
math.clamp(StealthxUI.TransparencyValue, 0, 1)

local Holder = StealthxUI.NotificationModule.Init(StealthxUI.NotificationGui)

function StealthxUI:Notify(Config)
	Config.Holder = Holder.Frame
	Config.Window = StealthxUI.Window
	--Config.StealthxUI = StealthxUI
	return StealthxUI.NotificationModule.New(Config)
end

function StealthxUI:SetNotificationLower(Val)
	Holder.SetLower(Val)
end

function StealthxUI:SetFont(FontId)
	Creator.UpdateFont(FontId)
end

function StealthxUI:OnThemeChange(func)
	StealthxUI.OnThemeChangeFunction = func
end

function StealthxUI:AddTheme(LTheme)
	StealthxUI.Themes[LTheme.Name] = LTheme
	return LTheme
end

function StealthxUI:SetTheme(Value)
	if StealthxUI.Themes[Value] then
		StealthxUI.Theme = StealthxUI.Themes[Value]
		Creator.SetTheme(StealthxUI.Themes[Value])

		if StealthxUI.OnThemeChangeFunction then
			StealthxUI.OnThemeChangeFunction(Value)
		end

		return StealthxUI.Themes[Value]
	end
	return nil
end

function StealthxUI:GetThemes()
	return StealthxUI.Themes
end
function StealthxUI:GetCurrentTheme()
	return StealthxUI.Theme.Name
end
function StealthxUI:GetTransparency()
	return StealthxUI.Transparent or false
end
function StealthxUI:GetWindowSize()
	return StealthxUI.Window.UIElements.Main.Size
end
function StealthxUI:Localization(LocalizationConfig)
	return StealthxUI.LocalizationModule:New(LocalizationConfig, Creator)
end

function StealthxUI:SetLanguage(Value)
	if Creator.Localization then
		return Creator.SetLanguage(Value)
	end
	return false
end

function StealthxUI:ToggleAcrylic(Value)
	if StealthxUI.Window and StealthxUI.Window.AcrylicPaint and StealthxUI.Window.AcrylicPaint.Model then
		StealthxUI.Window.Acrylic = Value
		StealthxUI.Window.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
		if Value then
			Acrylic.Enable()
		else
			Acrylic.Disable()
		end
	end
end

function StealthxUI:Gradient(stops, props)
	local colorSequence = {}
	local transparencySequence = {}

	for posStr, stop in next, stops do
		local position = tonumber(posStr)
		if position then
			position = math.clamp(position / 100, 0, 1)

			local color = stop.Color
			if typeof(color) == "string" and string.sub(color, 1, 1) == "#" then
				color = Color3.fromHex(color)
			end

			local transparency = stop.Transparency or 0

			table.insert(colorSequence, ColorSequenceKeypoint.new(position, color))
			table.insert(transparencySequence, NumberSequenceKeypoint.new(position, transparency))
		end
	end

	table.sort(colorSequence, function(a, b)
		return a.Time < b.Time
	end)
	table.sort(transparencySequence, function(a, b)
		return a.Time < b.Time
	end)

	if #colorSequence < 2 then
		table.insert(colorSequence, ColorSequenceKeypoint.new(1, colorSequence[1].Value))
		table.insert(transparencySequence, NumberSequenceKeypoint.new(1, transparencySequence[1].Value))
	end

	local gradientData = {
		Color = ColorSequence.new(colorSequence),
		Transparency = NumberSequence.new(transparencySequence),
	}

	if props then
		for k, v in pairs(props) do
			gradientData[k] = v
		end
	end

	return gradientData
end

function StealthxUI:Popup(PopupConfig)
	PopupConfig.StealthxUI = StealthxUI
	return require("./components/popup/Init").new(PopupConfig, StealthxUI.ScreenGui.Popups)
end

StealthxUI.Themes = require("./themes/Init")(StealthxUI, Creator)

Creator.Themes = StealthxUI.Themes

StealthxUI:SetTheme("Dark")
StealthxUI:SetLanguage(Creator.Language)

function StealthxUI:CreateWindow(Config)
	local CreateWindow = require("./components/window/Init")

	if not RunService:IsStudio() and writefile then
		if not isfolder("StealthxUI") then
			makefolder("StealthxUI")
		end
		if Config.Folder then
			makefolder(Config.Folder)
		else
			makefolder(Config.Title)
		end
	end

	Config.StealthxUI = StealthxUI
	Config.Window = StealthxUI.Window
	Config.Parent = StealthxUI.ScreenGui.Window

	if StealthxUI.Window then
		warn("You cannot create more than one window")
		return
	end

	local CanLoadWindow = true

	local Theme = StealthxUI.Themes[Config.Theme or "Dark"]

	--StealthxUI.Theme = Theme
	Creator.SetTheme(Theme)

	local hwid = gethwid or function()
		return Players.LocalPlayer.UserId
	end

	local Filename = hwid()

	if Config.KeySystem then
		CanLoadWindow = false

		local function loadKeysystem()
			KeySystem.new(Config, Filename, function(c)
				CanLoadWindow = c
			end)
		end

		local keyPath = (Config.Folder or "Temp") .. "/" .. Filename .. ".key"

		if Config.KeySystem.KeyValidator then
			if Config.KeySystem.SaveKey and isfile(keyPath) then
				local savedKey = readfile(keyPath)
				local isValid = Config.KeySystem.KeyValidator(savedKey)

				if isValid then
					CanLoadWindow = true
				else
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		elseif not Config.KeySystem.API then
			if Config.KeySystem.SaveKey and isfile(keyPath) then
				local savedKey = readfile(keyPath)
				local isKey = (type(Config.KeySystem.Key) == "table") and table.find(Config.KeySystem.Key, savedKey)
					or tostring(Config.KeySystem.Key) == tostring(savedKey)

				if isKey then
					CanLoadWindow = true
				else
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		else
			if isfile(keyPath) then
				local fileKey = readfile(keyPath)
				local isSuccess = false

				for _, i in next, Config.KeySystem.API do
					local serviceData = StealthxUI.Services[i.Type]
					if serviceData then
						local args = {}
						for _, argName in next, serviceData.Args do
							table.insert(args, i[argName])
						end

						local service = serviceData.New(table.unpack(args))
						local success = service.Verify(fileKey)
						if success then
							isSuccess = true
							break
						end
					end
				end

				CanLoadWindow = isSuccess
				if not isSuccess then
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		end

		repeat
			task.wait()
		until CanLoadWindow
	end

	local Window = CreateWindow(Config)

	StealthxUI.Transparent = Config.Transparent
	StealthxUI.Window = Window

	if Config.Acrylic then
		Acrylic.init()
	end

	-- function Window:ToggleTransparency(Value)
	--     StealthxUI.Transparent = Value
	--     StealthxUI.Window.Transparent = Value

	--     Window.UIElements.Main.Background.BackgroundTransparency = Value and StealthxUI.TransparencyValue or 0
	--     Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and StealthxUI.TransparencyValue or 0
	--     Window.UIElements.Main.Gradient.UIGradient.Transparency = NumberSequence.new{
	--         NumberSequenceKeypoint.new(0, 1),
	--         NumberSequenceKeypoint.new(1, Value and 0.85 or 0.7),
	--     }
	-- end

	return Window
end

return StealthxUI
