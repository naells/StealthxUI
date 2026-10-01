return {
	Elements = {
		Paragraph = require("./Paragraph"),
		Button = require("./Button"),
		Toggle = require("./Toggle"),
		Slider = require("./Slider"),
		ProgressBar = require("./ProgressBar"),
		Keybind = require("./Keybind"),
		Input = require("./Input"),
		Dropdown = require("./Dropdown"),
		Code = require("./Code"),
		Colorpicker = require("./Colorpicker"),
		Section = require("./Section"),
		Divider = require("./Divider"),
		Space = require("./Space"),
		Image = require("./Image"),
		Group = require("./Group"),
		HStack = require("./HStack"),
		VStack = require("./VStack"),
		Viewport = require("./Viewport"),
	},
	Load = function(tbl, Container, Elements, Window, StealthxUI, OnElementCreateFunction, ElementsModule, UIScale, Tab)
		for name, module in next, Elements do
			tbl[name] = function(self, config)
				config = config or {}
				config.Tab = Tab or tbl
				config.ParentType = tbl.__type
				config.ParentTable = tbl
				config.Index = #tbl.Elements + 1
				Window._NextElementId = (Window._NextElementId or 0) + 1
				config.GlobalIndex = Window._NextElementId
				config.Parent = Container
				config.Window = Window
				config.StealthxUI = StealthxUI
				config.UIScale = UIScale
				config.ElementsModule = ElementsModule

				local _elementInstance, content = module:New(config)

				if config.Flag and typeof(config.Flag) == "string" then
					Window.ConfigElements = Window.ConfigElements or {}
					Window.PendingFlags = Window.ConfigElements
					Window.ConfigElements[config.Flag] = content

					if Window.CurrentConfig then
						Window.CurrentConfig:Register(config.Flag, content)
					end

					local pendingData = Window.PendingConfigData and Window.PendingConfigData[config.Flag]
					local ConfigManager = Window.ConfigManager
					local parser = pendingData and ConfigManager and ConfigManager.Parser[pendingData.__type]
					if parser and content.__type == pendingData.__type then
						local success, applied = pcall(parser.Load, content, pendingData)
						if success and applied ~= false then
							Window.PendingConfigData[config.Flag] = nil
						else
							warn("[ StealthxUI.ConfigManager ] Failed to apply pending config for '" .. config.Flag .. "'")
						end
					elseif pendingData and content.__type ~= pendingData.__type then
						Window.PendingConfigData[config.Flag] = nil
						warn("[ StealthxUI.ConfigManager ] Ignored incompatible saved type for '" .. config.Flag .. "'")
					end
				end

				local frame
				for key, value in next, content do
					if typeof(value) == "table" and key ~= "ElementFrame" and key:match("Frame$") then
						frame = value
						break
					end
				end

				if frame then
					content.ElementFrame = frame.UIElements.Main
					function content:SetTitle(title)
						return frame.SetTitle and frame:SetTitle(title)
					end
					function content:SetDesc(desc)
						return frame.SetDesc and frame:SetDesc(desc)
					end
					function content:SetImage(image, size)
						return frame.SetImage and frame:SetImage(image, size)
					end
					function content:SetThumbnail(image, size)
						return frame.SetThumbnail and frame:SetThumbnail(image, size)
					end
					function content:Highlight()
						frame:Highlight()
					end
					function content:Destroy()
						frame:Destroy()

						Window.AllElements[config.GlobalIndex] = nil
						if Window.ConfigManager and Window.ConfigManager.UnregisterElement then
							Window.ConfigManager:UnregisterElement(config.Flag, content)
						end
						if config.Flag and Window.ConfigElements and Window.ConfigElements[config.Flag] == content then
							Window.ConfigElements[config.Flag] = nil
						end
						table.remove(tbl.Elements, config.Index)
						if Tab and Tab == tbl and Tab.Elements[config.Index] == content then
							table.remove(Tab.Elements, config.Index)
						end
						tbl:UpdateAllElementShapes(tbl)
					end
				end

				Window.AllElements[config.GlobalIndex] = content
				content._GlobalIndex = config.GlobalIndex
				tbl.Elements[config.Index] = content
				if Tab and Tab == tbl then
					Tab.Elements[config.Index] = content
				end

				if Window.NewElements then
					tbl:UpdateAllElementShapes(tbl)
				end

				if OnElementCreateFunction then
					OnElementCreateFunction(content, tbl.Elements)
				end
				return content
			end
		end
		function tbl:UpdateAllElementShapes(bbb)
			for i, element in next, bbb.Elements do
				local frame
				for key, value in pairs(element) do
					if typeof(value) == "table" and key:match("Frame$") then
						frame = value
						break
					end
				end

				if not frame and element.UpdateShape then
					frame = element
				end

				if frame then
					--print("idx changed : " .. i .. " " .. (element.Title or "not found"))
					frame.Index = i
					if frame.UpdateShape then
						--print(" .changed: " .. i)
						frame.UpdateShape(bbb)
					end
				end
			end
		end
	end,
}
