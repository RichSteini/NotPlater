local AceGUI = LibStub("AceGUI-3.0")

-- Recycling functions
local new, del
do
	local pool = setmetatable({},{__mode='k'})
	function new()
		local t = next(pool)
		if t then
			pool[t] = nil
			return t
		else
			return {}
		end
	end
	function del(t)
		for k in pairs(t) do
			t[k] = nil
		end	
		pool[t] = true
	end
end

-------------
-- Widgets --
-------------
--[[
	Widgets must provide the following functions
		Acquire() - Called when the object is aquired, should set everything to a default hidden state
		Release() - Called when the object is Released, should remove any anchors and hide the Widget
		
	And the following members
		frame - the frame or derivitive object that will be treated as the widget for size and anchoring purposes
		type - the type of the object, same as the name given to :RegisterWidget()
		
	Widgets contain a table called userdata, this is a safe place to store data associated with the wigdet
	It will be cleared automatically when a widget is released
	Placing values directly into a widget object should be avoided
	
	If the Widget can act as a container for other Widgets the following
		content - frame or derivitive that children will be anchored to
		
	The Widget can supply the following Optional Members


]]

--------------
-- TreeView --
--------------

do
	local Type = "TreeGroup"
	local Version = 6

	local PaneBackdrop  = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	}

	local function Acquire(self)

	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.status = nil
		for k, v in pairs(self.localstatus) do
			if k == "groups" then
				for k2 in pairs(v) do
					v[k2] = nil
				end
			else
				self.localstatus[k] = nil
			end
		end
		self.localstatus.scrollvalue = 0
	end
	
	local function GetButtonParents(line)
		local parent = line.parent
		if parent and parent.value then
			return parent.value, GetButtonParents(parent)
		end
	end
	
	local function GetButtonUniqueValue(line)
		local parent = line.parent
		if parent and parent.value then
			return GetButtonUniqueValue(parent).."\001"..line.value
		else
			return line.value
		end		
	end
	
	local function ButtonOnClick(this)
		local self = this.obj
		self:Fire("OnClick",this.uniquevalue, this.selected)
		if not this.selected then
			self:SetSelected(this.uniquevalue)
			this.selected = true
			this:LockHighlight()
			self:RefreshTree()
		end
	end
	
	local function ExpandOnClick(this)
		local button = this.button
		local self = button.obj
		local status = (self.status or self.localstatus).groups
		status[button.uniquevalue] = not status[button.uniquevalue]
		self:RefreshTree()
	end
	
	local function ButtonOnDoubleClick(button)
		local self = button.obj
		local status = self.status or self.localstatus
		local status = (self.status or self.localstatus).groups
		status[button.uniquevalue] = not status[button.uniquevalue]
		self:RefreshTree()
	end

	local buttoncount = 1
	local function CreateButton(self)
		local button = CreateFrame("Button",("AceGUI30TreeButton%d"):format(buttoncount),self.treeframe, "InterfaceOptionsButtonTemplate")
		buttoncount = buttoncount + 1
		button.obj = self

		button:SetScript("OnClick",ButtonOnClick)
		button:SetScript("OnDoubleClick", ButtonOnDoubleClick)

		button.toggle.button = button
		button.toggle:SetScript("OnClick",ExpandOnClick)
		
		return button
	end

	local function UpdateButton(button, treeline, selected, canExpand, isExpanded)
		local self = button.obj
		local toggle = button.toggle
		local frame = self.frame
		local text = treeline.text or ""
		local level = treeline.level
		local value = treeline.value
		local uniquevalue = treeline.uniquevalue
		local disabled = treeline.disabled
		
		button.treeline = treeline
		button.value = value
		button.uniquevalue = uniquevalue
		if selected then
			button:LockHighlight()
			button.selected = true
		else
			button:UnlockHighlight()
			button.selected = false
		end
		local normalText = button.text
		local normalTexture = button:GetNormalTexture()
		local line = button.line
		button.level = level
		if ( level == 1 ) then
			button:SetTextFontObject("GameFontNormal")
			button:SetHighlightFontObject("GameFontHighlight")
			button.text:SetPoint("LEFT", 8, 2)
		else
			button:SetTextFontObject("GameFontHighlightSmall")
			button:SetHighlightFontObject("GameFontHighlightSmall")
			button.text:SetPoint("LEFT", 8 * level, 2)
		end
		
		if disabled then
			button:EnableMouse(false)
			button.text:SetText("|cff808080"..text..FONT_COLOR_CODE_CLOSE)
		else
			button.text:SetText(text)
			button:EnableMouse(true)
		end
		
		if canExpand then
			if not isExpanded then
				toggle:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
				toggle:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
			else
				toggle:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
				toggle:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
			end
			toggle:Show()
		else
			toggle:Hide()
		end
	end

	
	local function OnScrollValueChanged(this, value)
		if this.obj.noupdate then return end
		local self = this.obj
		local status = self.status or self.localstatus
		status.scrollvalue = value
		self:RefreshTree()
	end
	
	-- called to set an external table to store status in
	local function SetStatusTable(self, status)
		assert(type(status) == "table")
		self.status = status
		if not status.groups then
			status.groups = {}
		end
		if not status.scrollvalue then
			status.scrollvalue = 0
		end
		self:RefreshTree()
	end

	--sets the tree to be displayed
	--[[
		example tree
		
		Alpha
		Bravo
		  -Charlie
		  -Delta
			-Echo
		Foxtrot
		
		tree = { 
			{ 
				value = "A",
				text = "Alpha"
			},
			{
				value = "B",
				text = "Bravo",
				children = {
					{ 
						value = "C", 
						text = "Charlie"
					},
					{
						value = "D",	
						text = "Delta"
						children = { 
							{ 
								value = "E",
								text = "Echo"
							} 
						} 
					}
				}
			},
			{ 
				value = "F", 
				text = "Foxtrot" 
			},
		}
	]]
	local function SetTree(self, tree)
		assert(type(tree) == "table")
		self.tree = tree
		self:RefreshTree()
	end
	
	local function BuildLevel(self, tree, level, parent)
		local lines = self.lines

		local status = (self.status or self.localstatus)
		local groups = status.groups
		local hasChildren = self.hasChildren
		
		for i, v in ipairs(tree) do
			local line = new()
			lines[#lines+1] = line
			line.value = v.value
			line.text = v.text
			line.disabled = v.disabled
			line.tree = tree
			line.level = level
			line.parent = parent
			line.uniquevalue = GetButtonUniqueValue(line)
			
			if v.children then
				line.hasChildren = true
			else
				line.hasChildren = nil
			end
			if v.children then
				if groups[line.uniquevalue] then
					self:BuildLevel(v.children, level+1, line)
				end
			end
		end
	end
	
	--fire an update after one frame to catch the treeframes height
	local function FirstFrameUpdate(this)
		local self = this.obj
		this:SetScript("OnUpdate",nil)
		self:RefreshTree()
	end
	
	local function ResizeUpdate(this)
		this.obj:RefreshTree()
	end
	
	local function RefreshTree(self)
		if not self.tree then return end
		--Build the list of visible entries from the tree and status tables
		local status = self.status or self.localstatus
		local groupstatus = status.groups
		local tree = self.tree
		local lines = self.lines
		local buttons = self.buttons

		local treeframe = self.treeframe

		
		while lines[1] do
			local t = tremove(lines)
			for k in pairs(t) do
				t[k] = nil
			end
			del(t)
		end
		
		self:BuildLevel(tree, 1)
		
		for i, v in ipairs(buttons) do
			v:Hide()
		end
		
		local numlines = #lines
		
		local maxlines = (math.floor(((self.treeframe:GetHeight()or 0) - 20 ) / 20))
		
		local first, last
		
		if numlines <= maxlines then
			--the whole tree fits in the frame
			status.scrollvalue = 0
			self:ShowScroll(false)
			first, last = 1, numlines
		else
			self:ShowScroll(true)
			--scrolling will be needed
			self.noupdate = true
			self.scrollbar:SetMinMaxValues(0, numlines - maxlines)
			--check if we are scrolled down too far
			if numlines - status.scrollvalue < maxlines then
				status.scrollvalue = numlines - maxlines
				self.scrollbar:SetValue(status.scrollvalue)
			end
			self.noupdate = nil
			first, last = status.scrollvalue+1, status.scrollvalue + maxlines
		end
		
		local buttonnum = 1
		for i = first, last do
			local line = lines[i]
			local button = buttons[buttonnum]
			if not button then
				button = self:CreateButton()

				buttons[buttonnum] = button
				button:SetParent(treeframe)
				button:SetFrameLevel(treeframe:GetFrameLevel()+1)
				button:ClearAllPoints()
				if i == 1 then
					if self.showscroll then
						button:SetPoint("TOPRIGHT", self.treeframe,"TOPRIGHT",-22,-10)
						button:SetPoint("TOPLEFT", self.treeframe, "TOPLEFT", 0, -10)
					else
						button:SetPoint("TOPRIGHT", self.treeframe,"TOPRIGHT",0,-10)
						button:SetPoint("TOPLEFT", self.treeframe, "TOPLEFT", 0, -10)
					end
				else
					button:SetPoint("TOPRIGHT", buttons[buttonnum-1], "BOTTOMRIGHT",0,0)
					button:SetPoint("TOPLEFT", buttons[buttonnum-1], "BOTTOMLEFT",0,0)
				end
			end

			UpdateButton(button, line, status.selected == line.uniquevalue, line.hasChildren, groupstatus[line.uniquevalue] )
			button:Show()
			buttonnum = buttonnum + 1
		end

	end
	
	local function SetSelected(self, value)
		local status = self.status or self.localstatus
		if status.selected ~= value then
			status.selected = value
			self:Fire("OnGroupSelected", value)
		end
	end
	
	local function BuildUniqueValue(...)
		local n = select('#', ...)
		if n == 1 then
			return ...
		else
			return (...).."\001"..BuildUniqueValue(select(2,...))
		end
	end
	
	local function Select(self, uniquevalue, ...)
		local status = self.status or self.localstatus
		local groups = status.groups
		for i = 1, select('#', ...) do
			groups[BuildUniqueValue(select(i, ...))] = true
		end
		status.selected = uniquevalue
		self:RefreshTree()
		self:Fire("OnGroupSelected", uniquevalue)
	end
	
	local function SelectByPath(self, ...)
		 self:Select(BuildUniqueValue(...), ...)
	end
	
	--Selects a tree node by UniqueValue
	local function SelectByValue(self, uniquevalue)
		self:Select(uniquevalue,string.split("\001", uniquevalue))
	end
	

	local function ShowScroll(self, show)
		self.showscroll = show
		if show then
			self.scrollbar:Show()
			if self.buttons[1] then
				self.buttons[1]:SetPoint("TOPRIGHT", self.treeframe,"TOPRIGHT",-22,-10)
			end
		else
			self.scrollbar:Hide()
			if self.buttons[1] then
				self.buttons[1]:SetPoint("TOPRIGHT", self.treeframe,"TOPRIGHT",0,-10)
			end
		end
	end
	
	local function OnWidthSet(self, width)
		local content = self.content
		local contentwidth = width - 199
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
	end
	
	
	local function OnHeightSet(self, height)
		local content = self.content
		local contentheight = height - 20
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
	end
	

	local function TreeOnMouseWheel(this, delta)
		local self = this.obj
		if self.showscroll then
			local scrollbar = self.scrollbar
			local min, max = scrollbar:GetMinMaxValues()
			local value = scrollbar:GetValue()
			local newvalue = math.min(max,math.max(min,value - delta))
			if value ~= newvalue then
				scrollbar:SetValue(newvalue)
			end
		end
	end
	
	local createdcount = 0
	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = Type
		self.lines = {}
		self.levels = {}
		self.buttons = {}
		self.hasChildren = {}
		self.localstatus = {}
		self.localstatus.groups = {}
		
		local treeframe = CreateFrame("Frame",nil,frame)
		treeframe.obj = self
		treeframe:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		treeframe:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,0)
		treeframe:SetWidth(183)
		treeframe:SetScript("OnUpdate",FirstFrameUpdate)
		treeframe:SetScript("OnSizeChanged",ResizeUpdate)
		
		treeframe:EnableMouseWheel(true)
		treeframe:SetScript("OnMouseWheel", TreeOnMouseWheel)
		treeframe:SetBackdrop(PaneBackdrop)
		treeframe:SetBackdropColor(0.1,0.1,0.1,0.5)
		treeframe:SetBackdropBorderColor(0.4,0.4,0.4)
		
		self.treeframe = treeframe
		self.Release = Release
		self.Acquire = Acquire
		
		self.SetTree = SetTree
		self.RefreshTree = RefreshTree
		self.SetStatusTable = SetStatusTable
		self.BuildLevel = BuildLevel
		self.CreateButton = CreateButton
		self.SetSelected = SetSelected
		self.ShowScroll = ShowScroll
		self.SetStatusTable = SetStatusTable
		self.Select = Select
		self.SelectByValue = SelectByValue
		self.SelectByPath = SelectByPath
		self.OnWidthSet = OnWidthSet
		self.OnHeightSet = OnHeightSet		
		
		self.frame = frame
		frame.obj = self
		createdcount = createdcount + 1
		local scrollbar = CreateFrame("Slider",("AceConfigDialogTreeGroup%dScrollBar"):format(createdcount),treeframe,"UIPanelScrollBarTemplate")
		self.scrollbar = scrollbar
		local scrollbg = scrollbar:CreateTexture(nil,"BACKGROUND")
		scrollbg:SetAllPoints(scrollbar)
		scrollbg:SetTexture(0,0,0,0.4)
		scrollbar.obj = self
		self.noupdate = true
		scrollbar:SetPoint("TOPRIGHT",treeframe,"TOPRIGHT",-10,-26)
		scrollbar:SetPoint("BOTTOMRIGHT",treeframe,"BOTTOMRIGHT",-10,26)
		scrollbar:SetScript("OnValueChanged", OnScrollValueChanged)
		scrollbar:SetMinMaxValues(0,0)
		self.localstatus.scrollvalue = 0
		scrollbar:SetValueStep(1)
		scrollbar:SetValue(0)
		scrollbar:SetWidth(16)
		self.noupdate = nil

		local border = CreateFrame("Frame",nil,frame)
		self.border = border
		border:SetPoint("TOPLEFT",frame,"TOPLEFT",179,0)
		border:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
		
		border:SetBackdrop(PaneBackdrop)
		border:SetBackdropColor(0.1,0.1,0.1,0.5)
		border:SetBackdropBorderColor(0.4,0.4,0.4)
		
		--Container Support
		local content = CreateFrame("Frame",nil,border)
		self.content = content
		content.obj = self
		content:SetPoint("TOPLEFT",border,"TOPLEFT",10,-10)
		content:SetPoint("BOTTOMRIGHT",border,"BOTTOMRIGHT",-10,10)
		
		AceGUI:RegisterAsContainer(self)
		--AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end
