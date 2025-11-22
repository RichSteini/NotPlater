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
	id = "v3.0.0",
	title = "v3.0.0 Snapshot",
	markdown = [[
# v3.0.0 — Overview

- New buff/debuff aura engine with configurable slots and cooldown visuals  
- Component display-order controls for adjusting frame stacking  
- Profile import/export with shareable strings and links  
- Added color options for level text and name text  
- Improved WoW class-matching  
- Fixed highlight textures for 3.3.5  
- Default CVar applied to hide the Blizzard castbar  
- General polish: better defaults, clearer warnings, and a new “What’s New” dialog

	]],
}
