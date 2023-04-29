if GetLocale() ~= "itIT" then
	return
end

NotPlaterLocals = setmetatable({
}, {__index = NotPlaterLocals})