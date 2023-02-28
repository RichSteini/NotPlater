if( GetLocale() ~= "deDE" ) then
	return
end

NotPlaterLocals = setmetatable({
}, {__index = NotPlaterLocals})