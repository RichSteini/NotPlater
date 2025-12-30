if not NotPlater then
	return
end

--[[
	Update the table below with your latest release notes.
	- Set `id` to a unique value (e.g., version number or date). Changing it forces the dialog to show again.
	- Optionally set `title` to override the heading shown next to "What's New".
	- Paste your Markdown content into `markdown`. Headings (#, ##, ###) and bullet/numbered lists are supported.
]]
NotPlaterReleaseData = {
	id = NotPlater.revision,
	title = NotPlater.revision .. " Snapshot",
	markdown = NotPlater.revision .. [[ 

- Implemented target indicator scaling  
- Fixed automatic aura tracking
- Implemented health text showing min / max / % at the same time  
- Fixed name text length working incorrectly  
- Fixed non-target level offset zooming/scaling not working properly  
- Implemented target indicator border on hover and for selected targets  
- Implemented option to paint names in class colors  
- Fixed simulator frame with auras overlapping the close button  
- Fixed buffs tracking error with manual aura tracking method  
- Implemented distance indicator
- Various other minor fixes  

	]],
}
