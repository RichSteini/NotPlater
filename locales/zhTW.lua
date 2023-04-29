if GetLocale() ~= "zhTW" then
	return
end

NotPlaterLocals = setmetatable({
}, {__index = NotPlaterLocals})