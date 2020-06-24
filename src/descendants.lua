local meta = {
	__call = function(self)
		self.skip = true
	end
}
local function descendants(object, state)
	if not state then
		if not object then
			return
		end
		state = setmetatable({object}, meta)
	end
	local child = state[#state]
	state[#state] = nil
	if state.skip then
		state.skip = false
	else
		local children = child:GetChildren()
		local begin = #state
		for i = 1, #children do
			state[begin + i] = children[i]
		end
	end
	return state[1] and state, state[#state]
end

--[[ example
for skip, object in descendants, workspace do
	print(object)
	if object:IsA('Camera') then
		skip()
	end
end
--]]

return descendants