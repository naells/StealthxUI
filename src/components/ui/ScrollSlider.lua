local ScrollSlider = {}

local cloneref = cloneref or clonereference or function(i)
	return i
end
local UserInputService = cloneref(game:GetService("UserInputService"))

local Creator = require("../../modules/Creator")
local New = Creator.New

function ScrollSlider.New(ScrollingFrame, Parent, Window, Thickness, StealthxUI)
	local Slider = New("Frame", {
		Size = UDim2.new(0, Thickness, 1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Parent = Parent,
		ZIndex = 999,
		Active = true,
	})

	local Thumb = Creator.NewRoundFrame(Thickness / 2, "Squircle", {
		Size = UDim2.new(1, 0, 0, 0),
		ImageTransparency = 0.85,
		ThemeTag = { ImageColor3 = "Text" },
		Parent = Slider,
	})

	local Hitbox = New("Frame", {
		Size = UDim2.new(1, 12, 1, 12),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Active = true,
		ZIndex = 999,
		Parent = Thumb,
	})

	local ScrollSliderActionId = Creator:GenerateUniqueID()
	local isDragging = false
	local connectionMove, connectionEnd
	local Connections = {}

	local function TrackConnection(Connection)
		if Connection then
			table.insert(Connections, Connection)
		end
		return Connection
	end

	local function DisconnectDragConnections()
		if connectionMove then
			connectionMove:Disconnect()
			connectionMove = nil
		end
		if connectionEnd then
			connectionEnd:Disconnect()
			connectionEnd = nil
		end
		isDragging = false
	end

	local function DisconnectTrackedConnections()
		DisconnectDragConnections()
		for Index = #Connections, 1, -1 do
			local Connection = table.remove(Connections, Index)
			if Connection then
				pcall(function() Connection:Disconnect() end)
			end
		end
		if StealthxUI.CurrentInput == ScrollSliderActionId then
			StealthxUI.CurrentInput = nil
		end
	end

	local function UpdateVisuals()
		local canvasY = ScrollingFrame.AbsoluteCanvasSize.Y
		local windowY = ScrollingFrame.AbsoluteWindowSize.Y

		if canvasY <= windowY then
			Thumb.Visible = false
			return
		end

		Thumb.Visible = true

		local sizeRatio = math.clamp(windowY / canvasY, 0.05, 1)
		Thumb.Size = UDim2.new(1, 0, sizeRatio, 0)

		local maxScroll = canvasY - windowY
		local maxThumbScale = 1 - sizeRatio

		if maxScroll > 0 then
			local scrollRatio = ScrollingFrame.CanvasPosition.Y / maxScroll
			Thumb.Position = UDim2.new(0, 0, math.clamp(scrollRatio * maxThumbScale, 0, maxThumbScale), 0)
		else
			Thumb.Position = UDim2.new(0, 0, 0, 0)
		end
	end

	local function StopDrag()
		ScrollingFrame.ScrollingEnabled = true
		DisconnectDragConnections()
		if StealthxUI.CurrentInput == ScrollSliderActionId then
			StealthxUI.CurrentInput = nil
		end
	end

	TrackConnection(Hitbox.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if isDragging then
			return
		end
		if StealthxUI.CurrentInput and StealthxUI.CurrentInput ~= ScrollSliderActionId then
			return
		end

		StealthxUI.CurrentInput = ScrollSliderActionId

		isDragging = true
		ScrollingFrame.ScrollingEnabled = false

		local startY = input.Position.Y
		local startCanvasY = ScrollingFrame.CanvasPosition.Y

		connectionMove = UserInputService.InputChanged:Connect(function(moveInput)
			if
				moveInput.UserInputType == Enum.UserInputType.MouseMovement
				or moveInput.UserInputType == Enum.UserInputType.Touch
			then
				local deltaY = moveInput.Position.Y - startY

				local canvasY = ScrollingFrame.AbsoluteCanvasSize.Y
				local windowY = ScrollingFrame.AbsoluteWindowSize.Y
				local maxScroll = math.max(canvasY - windowY, 0)

				local sliderPx = Slider.AbsoluteSize.Y
				local thumbPx = Thumb.AbsoluteSize.Y
				local maxThumbPx = math.max(sliderPx - thumbPx, 1)

				local scrollDelta = deltaY * (maxScroll / maxThumbPx)

				ScrollingFrame.CanvasPosition =
					Vector2.new(ScrollingFrame.CanvasPosition.X, math.clamp(startCanvasY + scrollDelta, 0, maxScroll))
			end
		end)

		connectionEnd = UserInputService.InputEnded:Connect(function(endInput)
			if endInput.UserInputType == input.UserInputType then
				if StealthxUI.CurrentInput and StealthxUI.CurrentInput ~= ScrollSliderActionId then
					return
				end

				StealthxUI.CurrentInput = nil

				StopDrag()
			end
		end)
	end))

	TrackConnection(ScrollingFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(UpdateVisuals))
	TrackConnection(ScrollingFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(UpdateVisuals))
	TrackConnection(ScrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateVisuals))

	Slider.Destroying:Connect(function()
		ScrollingFrame.ScrollingEnabled = true
		DisconnectTrackedConnections()
	end)

	UpdateVisuals()

	return Slider
end

return ScrollSlider
