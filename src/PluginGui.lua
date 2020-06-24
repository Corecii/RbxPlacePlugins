
local CoreStudioWidgets = require(script.Parent.CoreStudioWidgets)

local this = {}

local function animateBasic238(button, background)
	button.MouseButton1Down:Connect(function()
		background.BackgroundColor3 = Color3.fromRGB(238, 238, 238)
	end)
	button.MouseButton1Up:Connect(function()
		background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end)
	button.MouseEnter:Connect(function()
		background.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
	end)
	button.MouseLeave:Connect(function()
		background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end)
	background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
end

local function makeEvent()
	local eventI = Instance.new('BindableEvent')
	local event = {
		connect = function(self, ...)
			return eventI.Event:Connect(...)
		end,
		fire = function(self, ...)
			return eventI:Fire(...)
		end,
		Event = eventI
	}
	event.Connect, event.Fire = event.connect, event.fire
	return event
end

local members = {
	MakePluginGui = function(self, id, infoBase)
		local gui = self.templatePluginItem:Clone()
		local titleGui = gui:FindFirstChild('TitleText', true)
		local statusGui = gui:FindFirstChild('StatusText', true)
		local loadToggleButton = gui:FindFirstChild('LoadToggleButton', true)
		local loadCheckMark = gui:FindFirstChild('LoadCheckMark', true)
		local loadButton = gui:FindFirstChild('LoadButton', true)
		local loadedStatus = gui:FindFirstChild('LoadedText', true)
		local info = {
			gui = gui,
			SetLoaded = function(info, value)
				info.loaded = value
				loadButton.Visible = not value
				loadedStatus.Visible = value
				info:UpdateStatus()
			end,
			SetKnown = function(info, value)
				info.known = value
				info:UpdateStatus()
			end,
			SetTitle = function(info, value)
				info.title = value
				titleGui.Text = tostring(value)
				self:UpdateSorting()
			end,
			SetAutoLoad = function(info, value)
				info.autoLoad = value
				loadCheckMark.Visible = value
			end,
			UpdateStatus = function(info)
				local status
				if info.loaded then
					status = 'Loaded'
				elseif info.known then
					status = 'Known'
				else
					status = 'New'
				end
				statusGui.Text = status
			end,
			Remove = function(info)
				gui:Destroy()
				if self.plugins[id] == info then
					self.plugins[id] = nil
				end
			end,
		}
		self.plugins[id] = info
		loadToggleButton.MouseButton1Click:Connect(function()
			self.autoLoadChanged:fire(id, not info.autoLoad)
		end)
		animateBasic238(loadButton.Button, loadButton.Background)
		loadButton.Button.MouseButton1Click:Connect(function()
			self.loadSingle:fire(id)
		end)
		info:SetLoaded(infoBase.loaded)
		info:SetKnown(infoBase.known)
		info:SetAutoLoad(infoBase.autoLoad)
		info:SetTitle(infoBase.title)
		gui.Parent = self.itemsParent
		self:UpdateSorting()
		return info
	end,
	UpdateSorting = function(self)
		local plugins = {}
		for _, plugin in next, self.plugins do
			plugins[#plugins + 1] = plugin
		end
		table.sort(plugins, function(a, b)
			return a.title < b.title
		end)
		for index, plugin in next, plugins do
			plugin.gui.LayoutOrder = index
		end
	end,
	GetPluginGui = function(self, id)
		return self.plugins[id]
	end,
	GetPlugins = function(self)
		return self.plugins
	end,
	SetAutoLoadAll = function(self, value)
		self.autoLoadAll = value
		self.loadAutoCheckMark.Visible = value
	end,
	GetAutoLoadAll = function(self)
		return self.autoLoadAll or false 
	end
}

function this:New(self)
	for key, member in next, members do
		self[key] = member
	end

	---

	self.loadSingle = makeEvent() --> id
	self.autoLoadChanged = makeEvent() --> id, value
	self.loadAll = makeEvent() --> void
	self.autoLoadAllChanged = makeEvent() --> value

	---

	self.itemsParent = self.model:FindFirstChild('ScrollContent', true)

	self.templatePluginItem = self.model:FindFirstChild('TemplatePluginItem', true)
	self.templatePluginItem.Parent = nil

	self.plugins = {}

	---
	
	local scrollingContentGui = self.model:FindFirstChild('ScrollingContent', true)
	local mainListLayout = self.model:FindFirstChild('MainListLayout', true)
	local scrollingContent = CoreStudioWidgets:Make('ScrollingContent', scrollingContentGui)
	local function updateCanvasSize()
		local size = mainListLayout.AbsoluteContentSize
		scrollingContent:SetCanvasSize(UDim2.new(0, math.min(size.x, self.model.AbsoluteSize.x - 30), 0, size.y))
	end
	updateCanvasSize()
	mainListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		updateCanvasSize()
	end)

	---
	
	local loadAllButton = self.model:FindFirstChild('LoadAllButton', true)
	animateBasic238(loadAllButton.Button, loadAllButton.Background)
	loadAllButton.Button.MouseButton1Click:Connect(function()
		self.loadAll:fire()
	end)

	---

	local loadAutoToggleButton = self.model:FindFirstChild('LoadAutoToggleButton', true)
	self.loadAutoCheckMark = self.model:FindFirstChild('LoadAutoToggleMark', true)
	loadAutoToggleButton.MouseButton1Click:Connect(function()
		self.autoLoadAllChanged:fire(not self:GetAutoLoadAll())
	end)
end

return this