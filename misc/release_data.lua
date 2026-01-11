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

- Implemented filters to filter out nameplates based on criterias
- Implemented nameplate template category
- Implemented elite / rare icon
- Implemented class icon
- Implemented NPC icons
- Implemented icon zoom for aura / spell icons
- Implemented name text mouseover highlight
- Added aura borders
- Fixed aura container grow direction / rows
- Fixed aura matching
- Various bug fixes  

	]],
}
