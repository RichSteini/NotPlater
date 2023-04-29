if GetLocale() ~= "ptBR" then
	return
end

NotPlaterLocals = setmetatable({
}, {__index = NotPlaterLocals})