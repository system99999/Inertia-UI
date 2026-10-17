
-- dear imgui style ui framework for roblox luau
-- no features. windows, tabs, sections, controls.
-- getgenv().ImGuiLib or _G.ImGuiLib

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Theme = {
	Window = Color3.fromRGB(28, 26, 36),
	Border = Color3.fromRGB(48, 44, 62),
	Header = Color3.fromRGB(24, 22, 32),
	Control = Color3.fromRGB(38, 36, 48),
	ControlBorder = Color3.fromRGB(58, 54, 74),
	Accent = Color3.fromRGB(154, 112, 214),
	Text = Color3.fromRGB(196, 196, 208),
	Dim = Color3.fromRGB(140, 140, 156),
	Track = Color3.fromRGB(46, 44, 58),
	Font = Enum.Font.Code,
}

local Library = {}
Library.__index = Library
Library.Theme = Theme

local function host()
	if typeof(getgenv) == "function" then
		return getgenv()
	end
	return _G
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function list(parent, gap)
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Vertical
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, gap or 4)
	l.Parent = parent
	return l
end

local function label(parent, text, color, size, x)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Theme.Font
	t.TextSize = size or 13
	t.TextColor3 = color or Theme.Text
	t.TextXAlignment = x or Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Center
	t.Text = text or ""
	t.Parent = parent
	return t
end

function Library.new(opts)
	opts = opts or {}
	local self = setmetatable({
		Windows = {},
		Order = 0,
		ActiveSlider = nil,
		Listening = nil,
	}, Library)

	local old = CoreGui:FindFirstChild(opts.Name or "ImGuiFramework")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = opts.Name or "ImGuiFramework"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = CoreGui
	self.Gui = gui
	self:_input()
	return self
end

function Library:Window(opts)
	opts = opts or {}
	local win = Instance.new("Frame")
	win.Name = opts.Title or "window"
	win.BackgroundColor3 = Theme.Window
	win.BorderSizePixel = 0
	win.Size = opts.Size or UDim2.fromOffset(420, 520)
	win.Position = opts.Position or UDim2.fromOffset(40, 80)
	win.Parent = self.Gui
	stroke(win, Theme.Border, 1)

	local bar = Instance.new("TextButton")
	bar.Size = UDim2.new(1, 0, 0, 22)
	bar.BackgroundColor3 = Theme.Header
	bar.BorderSizePixel = 0
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Parent = win
	local title = label(bar, opts.Title or "window", Theme.Dim, 13)
	title.Size = UDim2.new(1, -12, 1, 0)
	title.Position = UDim2.fromOffset(8, 0)

	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(6, 26)
	body.Size = UDim2.new(1, -12, 1, -32)
	body.Parent = win

	local api = {
		Lib = self,
		Frame = win,
		Body = body,
		Tabs = {},
		TabButtons = {},
	}

	local dragging, origin, startPos
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			origin = input.Position
			startPos = win.Position
		end
	end)
	table.insert(self.Windows, function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - origin
			win.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
		end
	end)
	table.insert(self.Windows, function(input, ended)
		if ended and input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	function api:TabBar()
		if self._tabBar then
			return self._tabBar
		end
		local barFrame = Instance.new("Frame")
		barFrame.BackgroundTransparency = 1
		barFrame.Size = UDim2.new(1, 0, 0, 24)
		barFrame.Parent = self.Body
		local pages = Instance.new("Frame")
		pages.BackgroundTransparency = 1
		pages.Position = UDim2.fromOffset(0, 26)
		pages.Size = UDim2.new(1, 0, 1, -26)
		pages.Parent = self.Body
		self._tabBar = barFrame
		self._pages = pages
		return barFrame
	end

	function api:Tab(name)
		self:TabBar()
		local i = 0
		for _ in pairs(self.TabButtons) do
			i += 1
		end
		local btn = Instance.new("TextButton")
		btn.BackgroundTransparency = 1
		btn.Size = UDim2.fromOffset(72, 22)
		btn.Position = UDim2.fromOffset(i * 76, 0)
		btn.Font = Theme.Font
		btn.TextSize = 13
		btn.Text = name
		btn.Parent = self._tabBar
		local underline = Instance.new("Frame")
		underline.Size = UDim2.new(1, -8, 0, 1)
		underline.Position = UDim2.new(0, 4, 1, -1)
		underline.BorderSizePixel = 0
		underline.BackgroundColor3 = Theme.Accent
		underline.Visible = false
		underline.Parent = btn

		local page = Instance.new("Frame")
		page.BackgroundTransparency = 1
		page.Size = UDim2.fromScale(1, 1)
		page.Visible = false
		page.Parent = self._pages
		local columns = Instance.new("Frame")
		columns.BackgroundTransparency = 1
		columns.Size = UDim2.fromScale(1, 1)
		columns.Parent = page
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = columns

		local function show()
			for n, b in pairs(self.TabButtons) do
				local on = n == name
				b.Button.TextColor3 = on and Theme.Text or Theme.Dim
				b.Line.Visible = on
				b.Page.Visible = on
			end
		end
		btn.MouseButton1Click:Connect(show)
		self.TabButtons[name] = { Button = btn, Line = underline, Page = page }
		if i == 0 then
			show()
		end

		local tab = { Columns = columns, Count = 0 }
		function tab:Column()
			self.Count += 1
			local col = Instance.new("ScrollingFrame")
			col.BackgroundTransparency = 1
			col.BorderSizePixel = 0
			col.Size = UDim2.new(1 / 2, -4, 1, 0)
			col.ScrollBarThickness = 3
			col.AutomaticCanvasSize = Enum.AutomaticSize.Y
			col.CanvasSize = UDim2.fromOffset(0, 0)
			col.LayoutOrder = self.Count
			col.Parent = self.Columns
			list(col, 8)
			local lib = api.Lib
			local column = {}
			function column:Section(title)
				return lib:_section(col, title)
			end
			return column
		end
		return tab
	end

	function api:Section(title)
		return self.Lib:_section(self.Body, title)
	end

	return api
end

function Library:_section(parent, title)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Parent = parent
	list(holder, 3)
	if title and title ~= "" then
		local h = label(holder, title, Theme.Text, 13)
		h.Size = UDim2.new(1, 0, 0, 16)
	end
	local section = { Lib = self, Frame = holder }
	function section:Checkbox(text, default, cb)
		return self.Lib:_checkbox(holder, text, default, cb)
	end
	function section:Slider(text, min, max, default, fmt, cb)
		return self.Lib:_slider(holder, text, min, max, default, fmt, cb)
	end
	function section:Dropdown(text, options, default, cb)
		return self.Lib:_dropdown(holder, text, options, default, cb)
	end
	function section:Keybind(text, default, cb)
		return self.Lib:_keybind(holder, text, default, cb)
	end
	function section:Color(text, default, cb)
		return self.Lib:_color(holder, text, default, cb)
	end
	function section:Label(text)
		local l = label(holder, text, Theme.Dim, 12)
		l.Size = UDim2.new(1, 0, 0, 14)
		return l
	end
	function section:Separator()
		local s = Instance.new("Frame")
		s.Size = UDim2.new(1, 0, 0, 1)
		s.BackgroundColor3 = Theme.Border
		s.BorderSizePixel = 0
		s.Parent = holder
	end
	return section
end

function Library:_row(parent, h)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, h)
	f.Parent = parent
	return f
end

function Library:_checkbox(parent, text, default, cb)
	local state = default and true or false
	local f = self:_row(parent, 18)
	local box = Instance.new("TextButton")
	box.Size = UDim2.fromOffset(12, 12)
	box.Position = UDim2.fromOffset(0, 3)
	box.BackgroundColor3 = Theme.Control
	box.BorderSizePixel = 0
	box.Text = ""
	box.AutoButtonColor = false
	box.Parent = f
	stroke(box, Theme.ControlBorder, 1)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromOffset(8, 8)
	fill.Position = UDim2.fromOffset(2, 2)
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.Parent = box
	local name = label(f, text, Theme.Text, 13)
	name.Position = UDim2.fromOffset(18, 0)
	name.Size = UDim2.new(1, -70, 1, 0)
	local side = label(f, "", Theme.Dim, 12, Enum.TextXAlignment.Right)
	side.Position = UDim2.new(1, -52, 0, 0)
	side.Size = UDim2.fromOffset(52, 18)
	local api = {}
	function api:Set(v, silent)
		state = v and true or false
		fill.Visible = state
		if not silent and cb then cb(state) end
	end
	function api:Get() return state end
	function api:Side(textValue) side.Text = textValue or "" end
	box.MouseButton1Click:Connect(function() api:Set(not state) end)
	api:Set(state, true)
	return api
end

function Library:_slider(parent, text, min, max, default, fmt, cb)
	local value = math.clamp(default or min, min, max)
	local f = self:_row(parent, 32)
	local name = label(f, text, Theme.Text, 13)
	name.Size = UDim2.new(1, -64, 0, 14)
	local readout = label(f, "", Theme.Dim, 12, Enum.TextXAlignment.Right)
	readout.Position = UDim2.new(1, -60, 0, 0)
	readout.Size = UDim2.fromOffset(60, 14)
	local bar = Instance.new("TextButton")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.fromOffset(0, 18)
	bar.BackgroundColor3 = Theme.Track
	bar.BorderSizePixel = 0
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Parent = f
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = bar
	local api = {}
	local function show()
		local rel = (value - min) / math.max(max - min, 0.0001)
		fill.Size = UDim2.fromScale(math.clamp(rel, 0, 1), 1)
		if typeof(fmt) == "function" then
			readout.Text = fmt(value)
		elseif fmt then
			readout.Text = string.format(fmt, value)
		else
			readout.Text = string.format("%.1f", value)
		end
	end
	function api:Set(v, silent)
		value = math.clamp(v, min, max)
		show()
		if not silent and cb then cb(value) end
	end
	function api:Get() return value end
	local function fromX(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		api:Set(min + (max - min) * rel)
	end
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.ActiveSlider = fromX
			fromX(input.Position.X)
		end
	end)
	show()
	return api
end

function Library:_dropdown(parent, text, options, default, cb)
	if typeof(text) == "table" and options == nil then
		options = text
		text = nil
	end
	local value = default or options[1]
	local f = self:_row(parent, text and 36 or 20)
	local y = 0
	if text then
		local name = label(f, text, Theme.Text, 13)
		name.Size = UDim2.new(1, 0, 0, 14)
		y = 16
	end
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 18)
	btn.Position = UDim2.fromOffset(0, y)
	btn.BackgroundColor3 = Theme.Control
	btn.BorderSizePixel = 0
	btn.Font = Theme.Font
	btn.TextSize = 12
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextColor3 = Theme.Text
	btn.AutoButtonColor = false
	btn.Parent = f
	stroke(btn, Theme.ControlBorder, 1)
	local plus = label(btn, "+", Theme.Dim, 14, Enum.TextXAlignment.Right)
	plus.Size = UDim2.new(1, -6, 1, 0)
	local menu = Instance.new("Frame")
	menu.Visible = false
	menu.ZIndex = 40
	menu.BackgroundColor3 = Theme.Header
	menu.BorderSizePixel = 0
	menu.Position = UDim2.fromOffset(0, y + 20)
	menu.Size = UDim2.new(1, 0, 0, #options * 18)
	menu.Parent = f
	stroke(menu, Theme.Border, 1)
	local api = {}
	function api:Set(v, silent)
		value = v
		btn.Text = "  " .. tostring(v)
		if not silent and cb then cb(v) end
	end
	function api:Get() return value end
	for i, opt in ipairs(options) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 18)
		b.Position = UDim2.fromOffset(0, (i - 1) * 18)
		b.BackgroundTransparency = 1
		b.ZIndex = 41
		b.Font = Theme.Font
		b.TextSize = 12
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.TextColor3 = Theme.Text
		b.Text = "  " .. opt
		b.Parent = menu
		b.MouseButton1Click:Connect(function()
			api:Set(opt)
			menu.Visible = false
		end)
	end
	btn.MouseButton1Click:Connect(function()
		menu.Visible = not menu.Visible
	end)
	api:Set(value, true)
	return api
end

function Library:_color(parent, text, default, cb)
	local value = default or Theme.Accent
	local f = self:_row(parent, 18)
	local name = label(f, text, Theme.Text, 13)
	name.Size = UDim2.new(1, -28, 1, 0)
	local chip = Instance.new("TextButton")
	chip.Size = UDim2.fromOffset(18, 12)
	chip.Position = UDim2.new(1, -18, 0, 3)
	chip.BackgroundColor3 = value
	chip.BorderSizePixel = 0
	chip.Text = ""
	chip.AutoButtonColor = false
	chip.Parent = f
	stroke(chip, Theme.ControlBorder, 1)
	local api = {}
	function api:Set(c, silent)
		value = c
		chip.BackgroundColor3 = c
		if not silent and cb then cb(c) end
	end
	function api:Get() return value end
	return api
end

function Library:_keybind(parent, text, default, cb)
	local key = default
	local f = self:_row(parent, 18)
	local name = label(f, text, Theme.Text, 13)
	name.Size = UDim2.new(1, -48, 1, 0)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(42, 16)
	btn.Position = UDim2.new(1, -42, 0, 1)
	btn.BackgroundTransparency = 1
	btn.Font = Theme.Font
	btn.TextSize = 12
	btn.TextColor3 = Theme.Dim
	btn.TextXAlignment = Enum.TextXAlignment.Right
	btn.Parent = f
	local api = {}
	local function nameOf(k)
		if k == nil then return "none" end
		if typeof(k) == "EnumItem" then
			if k == Enum.KeyCode.Insert then return "ins" end
			return string.lower(k.Name)
		end
		return tostring(k)
	end
	function api:Set(k, silent)
		key = k
		btn.Text = nameOf(k)
		if not silent and cb then cb(k) end
	end
	function api:Get() return key end
	btn.MouseButton1Click:Connect(function()
		self.Listening = api
		btn.Text = "..."
	end)
	api:Set(key, true)
	return api
end

function Library:Toolbar(icons)
	local n = #icons
	local w = 8 + n * 28
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromOffset(w, 28)
	bar.Position = UDim2.new(0.5, -w / 2, 0, 18)
	bar.BackgroundColor3 = Theme.Header
	bar.BorderSizePixel = 0
	bar.Parent = self.Gui
	stroke(bar, Theme.Border, 1)
	for i, item in ipairs(icons) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(22, 20)
		b.Position = UDim2.fromOffset(6 + (i - 1) * 28, 4)
		b.BackgroundColor3 = Color3.fromRGB(42, 38, 56)
		b.BorderSizePixel = 0
		b.Font = Theme.Font
		b.TextSize = 12
		b.TextColor3 = Theme.Accent
		b.Text = item.Text or tostring(i)
		b.Parent = bar
		b.MouseButton1Click:Connect(function()
			if item.Callback then item.Callback() end
		end)
	end
	return bar
end

function Library:Table(parent, headers)
	local holder = Instance.new("ScrollingFrame")
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Size = UDim2.new(1, 0, 1, -22)
	holder.ScrollBarThickness = 3
	holder.AutomaticCanvasSize = Enum.AutomaticSize.Y
	holder.CanvasSize = UDim2.fromOffset(0, 0)
	holder.Parent = parent
	list(holder, 0)
	local head = Instance.new("Frame")
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1, 0, 0, 16)
	head.Parent = holder
	for i, h in ipairs(headers) do
		local t = label(head, h, Theme.Dim, 12)
		t.Position = UDim2.new((i - 1) / #headers, 4, 0, 0)
		t.Size = UDim2.new(1 / #headers, -4, 1, 0)
	end
	local footer = label(parent, "selected row - -1", Theme.Dim, 12)
	footer.Size = UDim2.new(1, 0, 0, 16)
	footer.Position = UDim2.new(0, 0, 1, -16)
	local api = { Selected = -1 }
	function api:SetRows(rows)
		for _, c in ipairs(holder:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for index, row in ipairs(rows) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 16)
			b.BackgroundTransparency = 1
			b.Text = ""
			b.AutoButtonColor = false
			b.Parent = holder
			for i = 1, #headers do
				local t = label(b, tostring(row[i] or ""), Theme.Text, 12)
				t.Position = UDim2.new((i - 1) / #headers, 4, 0, 0)
				t.Size = UDim2.new(1 / #headers, -4, 1, 0)
			end
			b.MouseButton1Click:Connect(function()
				api.Selected = index - 1
				footer.Text = "selected row - " .. tostring(api.Selected)
			end)
		end
	end
	return api
end

function Library:_input()
	UserInputService.InputChanged:Connect(function(input)
		for _, fn in ipairs(self.Windows) do fn(input, false) end
		if self.ActiveSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
			self.ActiveSlider(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		for _, fn in ipairs(self.Windows) do fn(input, true) end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.ActiveSlider = nil
		end
	end)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if not self.Listening or gpe then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				self.Listening:Set(nil)
			else
				self.Listening:Set(input.KeyCode)
			end
			self.Listening = nil
		end
	end)
end

function Library:Destroy()
	self.Gui:Destroy()
end

host().ImGuiLib = Library
return Library
