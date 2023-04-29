if GetLocale() ~= "zhCN" then
	return
end

NotPlaterLocals = setmetatable({
}, {__index = NotPlaterLocals})