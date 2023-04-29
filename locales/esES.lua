if GetLocale() ~= "esES" then
	return
end

NotPlaterLocals = setmetatable({
}, {__index = NotPlaterLocals})