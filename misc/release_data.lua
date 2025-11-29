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

- New aura engine with configurable tracking buff/debuff slots and cooldown visuals  
- Component display order controls for adjusting frame stacking  
- Profile import/export with shareable strings and links  
- Added group version checking  
- Improved WoW class-matching  
- Fixed highlight textures for 3.3.5  
- Added color options for level text and name text  
- Default CVar applied to hide the Blizzard castbar  
- General polish: better defaults, clearer warnings, and a new “What’s New” dialog
- Support for all localizations
- Various bug fixes 
	]],
}
