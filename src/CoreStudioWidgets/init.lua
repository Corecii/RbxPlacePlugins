
local descendants = require(script.Parent.descendants)

local templatesFolder = script.Templates

local this = {}

local registry = {}
local templates = {}
for skipDescendants, moduleScript in descendants, script.Modules do
	if moduleScript:IsA('ModuleScript') then
		local module = require(moduleScript)
		registry[moduleScript.Name] = module
		templates[moduleScript.Name] = module.template or templatesFolder:FindFirstChild(moduleScript.Name)
		skipDescendants()
	end
end

local members = {
	LoadClass = function(self, itemName)
		if self.isA[itemName] then
			error(('Attempt to inherit %s twice'):format(tostring(itemName)))
		end
		self.isA[itemName] = true
		registry[itemName]:New(self)
	end
}

function this:Make(moduleNames, model)
	local self = {}
	self.isA = {}
	if not model then
		if type(moduleNames) == 'string' then
			if templates[moduleNames] then
				model = templates[moduleNames]:Clone()
			end
		elseif type(moduleNames) == 'table' then
			if moduleNames[1] and templates[moduleNames[1]] then
				model = templates[moduleNames[1]]:Clone()
			end
		else
			error(('Unknown type (%s) passed to MakeItem. Expected string or array.'):format(typeof(moduleNames)))
		end
	end
	self.model = model
	for key, member in next, members do
		self[key] = member
	end
	if type(moduleNames) == 'string' then
		self:LoadClass(moduleNames)
	elseif type(moduleNames) == 'table' then
		for _, moduleName in next, moduleNames do
			self:LoadClass(moduleName)
		end
	else
		error(('Unknown type (%s) passed to MakeItem. Expected string or array.'):format(typeof(moduleNames)))
	end
	return self
end

return this