if GetLocale() ~= "koKR" then
	return
end

NotPlaterLocals = setmetatable({
}, {__index = NotPlaterLocals})