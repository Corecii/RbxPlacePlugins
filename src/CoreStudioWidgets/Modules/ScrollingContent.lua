
local this = {}

local function getAbsoluteSizeFromUDim2(absoluteSize, udim2)
	return Vector2.new(absoluteSize.x*udim2.X.Scale + udim2.X.Offset, absoluteSize.y*udim2.Y.Scale + udim2.Y.Offset)
end

local function animateBasic238(frame)
	frame.Button.MouseButton1Down:Connect(function()
		frame.BackgroundColor3 = Color3.fromRGB(238, 238, 238)
	end)
	frame.Button.MouseButton1Up:Connect(function()
		frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end)
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
end

local members = {
	UpdateScrollbars = function(self)
		local windowSize = self.model.AbsoluteSize - Vector2.new(2, 2)
		local canvasSize = getAbsoluteSizeFromUDim2(windowSize, self.scrollContent.CanvasSize)
		local windowSizeYScroller = windowSize - Vector2.new(20, 0)
		local windowSizeXScroller = windowSize - Vector2.new(0, 20)
		local windowSizeXYScroller = windowSize - Vector2.new(20, 20)

		local sizePct = windowSize/canvasSize
		if sizePct.x < 1 and sizePct.y < 1 then
			sizePct = windowSizeXYScroller/canvasSize
			self.windowSize = windowSizeXYScroller
		else
			if sizePct.y < 1 then
				sizePct = windowSizeYScroller/canvasSize
				self.windowSize = windowSizeYScroller
			elseif sizePct.x < 1 then
				sizePct = windowSizeXScroller/canvasSize
				self.windowSize = windowSizeXScroller
			end
			if sizePct.x < 1 and sizePct.y < 1 then
				sizePct = windowSizeXYScroller/canvasSize
				self.windowSize = windowSizeXYScroller
			end
		end
		if math.abs(sizePct.x) == math.huge then
			sizePct = Vector2.new(1, sizePct.y)
		end
		if math.abs(sizePct.y) == math.huge then
			sizePct = Vector2.new(sizePct.x, 1)
		end
		self.sizePct = sizePct
		self.canvasSize = canvasSize

		self.scrollContent.Size = UDim2.new(1, (sizePct.y < 1 and -20 or 0), 1, (sizePct.x < 1 and -20 or 0))

		local scrollerBaseSize = self.windowSize - Vector2.new(41, 41)
		local scrollerBarSize = scrollerBaseSize*sizePct
		scrollerBarSize = Vector2.new(math.max(19, scrollerBarSize.x), math.max(19, scrollerBarSize.y))

		self.yScrollerContainer.Visible = sizePct.y < 1
		self.yScrollerContainer.Size = UDim2.new(0, 21, 1, sizePct.x < 1 and -21 or 0)
		self.yScrollerBar.Size = UDim2.new(0, 19, 0, scrollerBarSize.y)
		self.yScroller.Size = UDim2.new(0, 19, 1, -40 - scrollerBarSize.y - scrollerBarSize.y%2 + 2)

		self.xScrollerContainer.Visible = sizePct.x < 1
		self.xScrollerContainer.Size = UDim2.new(1, sizePct.y < 1 and -21 or 0, 0, 21)
		self.xScrollerBar.Size = UDim2.new(0, scrollerBarSize.x, 0, 19)
		self.xScroller.Size = UDim2.new(1, -40 - scrollerBarSize.x - scrollerBarSize.x%2 + 2, 0, 19)

		self:UpdateScrollbarPositions()
	end,
	UpdateScrollbarPositions = function(self)
		local positionPcts = self:GetPercentFromInnerPixels(self.scrollContent.CanvasPosition)
		self.yScrollerBar.Position = UDim2.new(0.5, 0, math.clamp(positionPcts.y, 0, 1), 0)
		self.xScrollerBar.Position = UDim2.new(math.clamp(positionPcts.x, 0, 1), 0, 0.5, 0)
	end,
	GetPercentFromInnerPixels = function(self, pxVector2)
		return pxVector2/(self.canvasSize - self.windowSize)
	end,
	GetPercentFromOuterPixels = function(self, pxVector2)
		local scrollerBaseSize = self.windowSize - Vector2.new(41, 41)
		local scrollerBarSize = scrollerBaseSize*self.sizePct
		scrollerBarSize = Vector2.new(math.max(19, math.floor(scrollerBarSize.x + 0.5)), math.max(19, math.floor(scrollerBarSize.y + 0.5)))
		return pxVector2/(scrollerBaseSize - scrollerBarSize)
	end,
	GetInnerPixelsFromOuterPixels = function(self, pxVector2)
		local pctVector2 = self:GetPercentFromOuterPixels(pxVector2)
		local innerPxVector2 = pctVector2*(self.canvasSize - self.windowSize)
		return innerPxVector2
	end,
	GetScrollAmount = function(self)
		return self.scrollAmount or Vector2.new(27, 27)
	end,
	SetScrollAmount = function(self, value)
		self.scrollAmount = value
	end,
	Scroll = function(self, direction)
		self.scrollContent.CanvasPosition = self.scrollContent.CanvasPosition + direction*self:GetScrollAmount()
	end,
	BeginScrollingY = function(self, startMousePosition)
		self:StopScrolling()
		self.yScrollerBar.SecondBorder.BackgroundColor3 = Color3.fromRGB(238, 238, 238)
		self.mousePositionDetector.Visible = true
		local startCanvasPosition = self.scrollContent.CanvasPosition
		self.scrollConn = self.mousePositionDetector.MouseMoved:Connect(function(_, y)
			local offset = y - startMousePosition
			local newCanvasPosition = startCanvasPosition + self:GetInnerPixelsFromOuterPixels(Vector2.new(0, offset))
			self.scrollContent.CanvasPosition = newCanvasPosition
		end)
	end,
	BeginScrollingX = function(self, startMousePosition)
		self:StopScrolling()
		self.xScrollerBar.SecondBorder.BackgroundColor3 = Color3.fromRGB(238, 238, 238)
		self.mousePositionDetector.Visible = true
		local startCanvasPosition = self.scrollContent.CanvasPosition
		self.scrollConn = self.mousePositionDetector.MouseMoved:Connect(function(x, _)
			local offset = x - startMousePosition
			local newCanvasPosition = startCanvasPosition + self:GetInnerPixelsFromOuterPixels(Vector2.new(offset, 0))
			self.scrollContent.CanvasPosition = newCanvasPosition
		end)
	end,
	StopScrolling = function(self)
		if self.scrollConn then
			self.scrollConn:disconnect()
			self.mousePositionDetector.Visible = false
			self.yScrollerBar.SecondBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			self.xScrollerBar.SecondBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end,
	SetCanvasPosition = function(self, value)
		self.scrollContent.CanvasPosition = value
		self:StopScrolling()
	end,
	SetCanvasSize = function(self, value)
		self.scrollContent.CanvasSize = value
	end,
}

function this:New(self)
	for key, member in next, members do
		self[key] = member
	end

	self.yScrollerVisible = true
	self.xScrollerVisible = true
	
	self.scrollContent = self.model:FindFirstChild('ScrollContent', true)

	self.yScrollerContainer = self.model:FindFirstChild('VerticalScroller', true)
	self.yScrollerN = self.yScrollerContainer:FindFirstChild('Up', true)
	self.yScrollerP = self.yScrollerContainer:FindFirstChild('Down', true)
	self.yScroller = self.yScrollerContainer:FindFirstChild('Scroller', true)
	self.yScrollerBar = self.yScroller:FindFirstChild('Bar', true)

	self.xScrollerContainer = self.model:FindFirstChild('HorizontalScroller', true)
	self.xScrollerN = self.xScrollerContainer:FindFirstChild('Left', true)
	self.xScrollerP = self.xScrollerContainer:FindFirstChild('Right', true)
	self.xScroller = self.xScrollerContainer:FindFirstChild('Scroller', true)
	self.xScrollerBar = self.xScroller:FindFirstChild('Bar', true)

	self.mousePositionDetector = self.model:FindFirstChild('MousePositionDetector', true)

	---

	self.model:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
		self:UpdateScrollbars()
	end)
	self.scrollContent:GetPropertyChangedSignal('CanvasSize'):Connect(function()
		self:UpdateScrollbars()
	end)
	self.scrollContent:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		self:UpdateScrollbarPositions()
	end)

	self.yScrollerBar.Button.MouseButton1Up:Connect(function()
		self:StopScrolling()
	end)
	self.xScrollerBar.Button.MouseButton1Up:Connect(function()
		self:StopScrolling()
	end)
	self.mousePositionDetector.MouseButton1Up:Connect(function()
		self:StopScrolling()
	end)
	self.mousePositionDetector.MouseLeave:Connect(function()
		self:StopScrolling()
	end)

	self.yScrollerBar.Button.MouseButton1Down:Connect(function(_, y)
		self:BeginScrollingY(y)
	end)
	self.xScrollerBar.Button.MouseButton1Down:Connect(function(x, _)
		self:BeginScrollingX(x)
	end)

	local function handleMovementButton(button, direction, scrollerBar)
		animateBasic238(button)
		local index = 0
		local down = false
		button.Button.MouseButton1Down:Connect(function()
			scrollerBar.SecondBorder.BackgroundColor3 = Color3.fromRGB(238, 238, 238)
			self:Scroll(direction)
			index = index + 1
			down = true
			local myIndex = index
			wait(0.4)
			while index == myIndex do
				self:Scroll(direction)
				wait(0.08)
			end
			if not down then
				scrollerBar.SecondBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			end
		end)
		button.Button.MouseButton1Up:Connect(function()
			index = index + 1
			down = false
		end)
		button.Button.MouseLeave:Connect(function()
			index = index + 1
			down = false
		end)
	end

	handleMovementButton(self.yScrollerP, Vector2.new(0, 1), self.yScrollerBar)
	handleMovementButton(self.yScrollerN, Vector2.new(0,-1), self.yScrollerBar)
	handleMovementButton(self.xScrollerP, Vector2.new(1, 0), self.xScrollerBar)
	handleMovementButton(self.xScrollerN, Vector2.new(-1,0), self.xScrollerBar)

	---
	self.mousePositionDetector.Visible = false
	self.yScrollerBar.SecondBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.xScrollerBar.SecondBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

	self:UpdateScrollbars()
end

return this