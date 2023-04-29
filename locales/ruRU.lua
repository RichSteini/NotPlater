if GetLocale() ~= "ruRU" then
	return
end

NotPlaterLocals = setmetatable({
}, {__index = NotPlaterLocals})