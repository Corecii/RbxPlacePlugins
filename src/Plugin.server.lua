-- Roblox freezes now if we create plugins after yielding (2020-02-25)
local plugins_cache = {}
for i = 1, 50 do
	plugins_cache[i] = PluginManager():CreatePlugin()
end

function plugin_from_cache()
	if not plugins_cache[1] then
		error("Exhausted plugin objects cache. Cannot load more than 50 PlacePlugins.")
	end
	return table.remove(plugins_cache)
end

local placePluginsGui = plugin:CreateDockWidgetPluginGui(
	'PlacePlugins',
	DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Left,
		false, -- enabled
		false, -- override saved enable state
		400, 500, -- floating window size
		300, 120  -- minimum size
	)
)

placePluginsGui.Name = 'PlacePlugins'
placePluginsGui.Title = 'PlacePlugins'

local mainGui = script.Parent.PlacePluginsGui.Container:Clone()
mainGui.Size = UDim2.new(1, 0, 1, 0)
mainGui.Parent = placePluginsGui

local guiController = {model = mainGui}
require(script.Parent.PluginGui):New(guiController)

guiController:SetAutoLoadAll(not plugin:GetSetting('DontAutoLoadAll'))
guiController.autoLoadAllChanged:Connect(function(newValue)
	plugin:SetSetting('DontAutoLoadAll', not newValue)
	guiController:SetAutoLoadAll(newValue)
end)

---

local toolbar = plugin:CreateToolbar('Place Plugins')
local loadButton = toolbar:CreateButton('Load New', 'Load any unloaded place plugins', '')
local manageButton = toolbar:CreateButton('Manage', 'Show plugin management panel', '')

loadButton.Enabled = false

manageButton.Click:Connect(function()
	placePluginsGui.Enabled = not placePluginsGui.Enabled
end)

local function updateManageButtonActive()
	manageButton:SetActive(placePluginsGui.Enabled)
end
placePluginsGui:GetPropertyChangedSignal('Enabled'):Connect(updateManageButtonActive)
updateManageButtonActive()

---

local getObjectsCache = {}

local function getObjects(url)
	local objects = getObjectsCache[url]
	if not objects then
		objects = game:GetObjects(url)
		getObjectsCache[url] = objects
	end
	local returnObjects = {}
	for index, object in next, objects do
		returnObjects[index] = object:Clone()
	end
	return returnObjects
end

---

local placePlugins = game:GetService('ServerStorage'):WaitForChild('PlacePlugins', math.huge)

local placePluginsChanged = Instance.new('BindableEvent')

local loaded = {}

---

local function isRemotePlugin(pluginBase)
	return (pluginBase:IsA('NumberValue') or pluginBase:IsA('StringValue')) and #pluginBase:GetChildren() == 0
end

local function getPluginSources(pluginBase)
	if isRemotePlugin(pluginBase) then
		local assetUrl = pluginBase.Value
		if tonumber(assetUrl) then
			assetUrl = 'rbxassetid://'..assetUrl
		end
		local success, errorOrChildren = pcall(getObjects, assetUrl)
		if not success then
			warn(string.format('Failed to load plugin \'%s\' because: %s', pluginBase.Name, errorOrChildren))
		else
			return errorOrChildren
		end
	else
		return {pluginBase}
	end
end

---

local sha1 = require(script.Parent.sha1)

local function getScriptHash(source)
	return sha1.sha1(source)
end

local function getPluginSaveData(pluginBase)
	local pluginInstances = getPluginSources(pluginBase)
	local dictionary = {}
	for _, pluginInstance in next, pluginInstances do
		local descendants = pluginInstance:GetDescendants()
		descendants[#descendants + 1] = pluginInstance
		for _, object in next, descendants do
			local isScript = (object:IsA('Script') or object:IsA('LocalScript')) and not object.Disabled
			local isModule = object:IsA('ModuleScript')
			if isScript or isModule then
				dictionary[getScriptHash(object.Source)] = true
			end
		end
	end
	local array = {}
	for hash, _ in next, dictionary do
		array[#array + 1] = hash
	end
	table.sort(array)
	return 'Lua1:'..table.concat(array,':')
end

local function getPluginSaveId(pluginBase)
	return game.PlaceId..':'..pluginBase.Name
end

local function isPluginKnown(pluginBase)
	local saveId = getPluginSaveId(pluginBase)
	local data = getPluginSaveData(pluginBase)
	return plugin:GetSetting(saveId) == data
end

local function setPluginKnown(pluginBase, isKnown)
	local saveId = getPluginSaveId(pluginBase)
	if not isKnown then
		plugin:SetSetting(saveId, false)
	else
		local data = getPluginSaveData(pluginBase)
		plugin:SetSetting(saveId, data)
	end
end

---

local function loadstring(source, name)
	local scr = Instance.new('ModuleScript')
	scr.Source = 'return function() '..source..' end'
	scr.Name = name or source
	local success, errFunc = pcall(require, scr)
	if success then
		return errFunc
	else
		return nil, errFunc
	end
end

local function loadPluginRaw(name, pluginBase)
	local newPlugin = plugin_from_cache()
	newPlugin.Name = name
	if typeof(pluginBase) == 'Instance' then
		pluginBase.Parent = newPlugin
	else
		for _, v in next, pluginBase do
			v.Parent = newPlugin
		end
	end
	local descendants = newPlugin:GetDescendants()
	local ranAtLeastOne = false
	for _, object in next, descendants do
		if (object:IsA('Script') or object:IsA('LocalScript')) and not object.Disabled then
			local scriptFunction, syntaxError = loadstring(object.Source, object:GetFullName())
			if syntaxError then
				warn(syntaxError)
			else
				local event = Instance.new('BindableEvent')
				event.Event:Connect(function()
					local env = getfenv(scriptFunction)
					setfenv(scriptFunction, setmetatable({
						plugin = newPlugin,
						script = object
					}, {__index = env}))
					scriptFunction()
				end)
				event:Fire()
				ranAtLeastOne = true
			end
		end
	end
	return ranAtLeastOne
end

local function loadPlugin(pluginBase)
	if loaded[pluginBase.Name] then
		return
	end
	local didLoad = false
	if isRemotePlugin(pluginBase) then
		local assetUrl = pluginBase.Value
		if tonumber(assetUrl) then
			assetUrl = 'rbxassetid://'..assetUrl
		end
		local success, errorOrChildren = pcall(getObjects, assetUrl)
		if not success then
			warn(string.format('Failed to load plugin \'%s\' because: %s', pluginBase.Name, errorOrChildren))
		else
			if loadPluginRaw(pluginBase.Name, errorOrChildren) then
				didLoad = true
			end
		end
	else
		if loadPluginRaw(pluginBase.Name, pluginBase:Clone()) then
			didLoad = true
		end
	end
	if didLoad then
		loaded[pluginBase.Name] = true
		setPluginKnown(pluginBase, true)
		local pluginGui = guiController:GetPluginGui(pluginBase)
		if pluginGui then
			pluginGui:SetKnown(true)
			pluginGui:SetLoaded(true)
		end
	end
end

local function loadNew()
	if not placePlugins then
		return
	end
	for _, pluginBase in next, placePlugins:GetChildren() do
		if not plugin:GetSetting(getPluginSaveId(pluginBase)..':NoAutoLoad') then
			loadPlugin(pluginBase)
		end
	end
end

local function loadKnown()
	if not placePlugins then
		return
	end
	for _, pluginBase in next, placePlugins:GetChildren() do
		if isPluginKnown(pluginBase) and not plugin:GetSetting(getPluginSaveId(pluginBase)..':NoAutoLoad') then
			loadPlugin(pluginBase)
		end
	end
end

---

local function listenForScriptChanges(pluginBase)
	local changeEvent = Instance.new('BindableEvent')
	local function forDescendant(object)
		if (object:IsA('Script') or object:IsA('LocalScript')) then
			object:GetPropertyChangedSignal('Source'):Connect(function()
				changeEvent:Fire()
			end)
			changeEvent:Fire()
		end
	end
	pluginBase.DescendantAdded:Connect(forDescendant)
	pluginBase.DescendantRemoving:Connect(function(object)
		if (object:IsA('Script') or object:IsA('LocalScript')) then
			changeEvent:Fire()
		end
		if isRemotePlugin(pluginBase) then
			changeEvent:Fire()
		end
	end)
	local descendants = pluginBase:GetDescendants()
	descendants[#descendants + 1] = pluginBase
	for _, object in next, descendants do
		forDescendant(object)
	end
	if pluginBase:IsA('StringValue') or pluginBase:IsA('NumberValue') then
		pluginBase:GetPropertyChangedSignal('Value'):Connect(function()
			if isRemotePlugin(pluginBase) then
				changeEvent:Fire()
			end
		end)
	end
	return changeEvent.Event
end

---

local function forPluginInstance(pluginInstance)
	local conns = {}
	local pluginGui
	local autoLoad
	local isLoaded
	local title
	local function onNewName()
		title = pluginInstance.Name
		autoLoad = not plugin:GetSetting(getPluginSaveId(pluginInstance)..':NoAutoLoad')
		isLoaded = loaded[pluginInstance.Name]
		if pluginGui then
			pluginGui:SetTitle(title)
			pluginGui:SetAutoLoad(autoLoad)
			pluginGui:SetLoaded(isLoaded)
		end
	end
	onNewName()
	conns[#conns + 1] = pluginInstance:GetPropertyChangedSignal('Name'):Connect(onNewName)
	local isKnown = isPluginKnown(pluginInstance)
	local lastChange = tick()
	conns[#conns + 1] = listenForScriptChanges(pluginInstance):Connect(function()
		lastChange = tick()
		if pluginGui then
			pluginGui:SetKnown(false)
		end
		wait(5)
		if tick() - lastChange >= 5 then
			isKnown = isPluginKnown(pluginInstance)
			pluginGui:SetKnown(isKnown)
		end
	end)
	pluginGui = guiController:MakePluginGui(pluginInstance, {
		title = title,
		autoLoad = autoLoad,
		loaded = isLoaded,
		known = isKnown
	})
	conns[#conns + 1] = guiController.autoLoadChanged:Connect(function(eventId, isAutoLoad)
		if eventId ~= pluginInstance then
			return
		end
		if isAutoLoad then
			plugin:SetSetting(getPluginSaveId(pluginInstance)..':NoAutoLoad', false)
		else
			plugin:SetSetting(getPluginSaveId(pluginInstance)..':NoAutoLoad', true)
		end
		onNewName()
	end)
	conns[#conns + 1] = pluginInstance.AncestryChanged:Connect(function()
		if not placePlugins or not pluginInstance:IsDescendantOf(placePlugins) then
			for _, conn in next, conns do
				conn:disconnect()
			end
			if pluginGui then
				pluginGui:Remove()
			end
		end
	end)
	conns[#conns + 1] = placePluginsChanged.Event:Connect(function()
		if not placePlugins or not pluginInstance:IsDescendantOf(placePlugins) then
			for _, conn in next, conns do
				conn:disconnect()
			end
			if pluginGui then
				pluginGui:Remove()
			end
		end
	end)
end

guiController.loadSingle:Connect(function(pluginInstance)
	loadPlugin(pluginInstance)
end)

guiController.loadAll:Connect(function()
	loadNew()
end)

---

local function forPlacePlugins(pluginsFolder)
	local conns = {}
	local cleanup
	for _, pluginBase in next, pluginsFolder:GetChildren() do
		forPluginInstance(pluginBase)
	end
	conns[#conns + 1] = pluginsFolder.ChildAdded:Connect(function(pluginBase)
		forPluginInstance(pluginBase)
	end)
	placePluginsChanged.Event:Connect(function()
		if placePlugins ~= pluginsFolder then
			cleanup()
		end
	end)
	cleanup = function()
		for _, conn in next, conns do
			conn:disconnect()
		end
	end
end

forPlacePlugins(placePlugins)

spawn(function()
	while true do
		local newPlacePlugins = game:GetService('ServerStorage'):FindFirstChild('PlacePlugins')
		if newPlacePlugins ~= placePlugins then
			placePlugins = newPlacePlugins
			loadButton.Enabled = placePlugins and true or false
			placePluginsChanged:Fire()
			if newPlacePlugins then
				forPlacePlugins(newPlacePlugins)
			end
		end
		wait()
	end
end)

---

loadButton.Click:Connect(function()
	loadNew()
end)
loadButton.Enabled = true

-- if we create plugin objects with scripts in them on the first frame, then they are ran as real plugins
-- this only happens on the first frame though, so i can't make use of it anywhere else
-- instead of having inconsistent behavior, i've decided to make all plugin loads be 'fake' loads
wait()
if not plugin:GetSetting('DontAutoLoadAll') then
	loadKnown()
end
