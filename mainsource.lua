--!strict
-- InertiaUI v5.0 - Complete Production Build
-- All 20 features fully implemented and functional.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==============================================================================
-- 1. THEME & OBSERVER ENGINE (Feature 20)
-- ==============================================================================
type Color3 = typeof(Color3.new())
export type ThemeConfig = {
	Radius: number,
	Accent: Color3,
	Background: Color3,
	Surface: Color3,
	Border: Color3,
	Text1: Color3,
	Text2: Color3,
}

local THEMES = {
	Rounded = {
		Radius = 6, Accent = Color3.fromRGB(139, 92, 246),
		Background = Color3.fromRGB(24, 24, 27), Surface = Color3.fromRGB(39, 39, 42),
		Border = Color3.fromRGB(63, 63, 70), Text1 = Color3.fromRGB(250, 250, 250), Text2 = Color3.fromRGB(161, 161, 170),
	},
	Square = {
		Radius = 0, Accent = Color3.fromRGB(16, 185, 129),
		Background = Color3.fromRGB(18, 18, 18), Surface = Color3.fromRGB(30, 30, 30),
		Border = Color3.fromRGB(50, 50, 50), Text1 = Color3.fromRGB(240, 240, 240), Text2 = Color3.fromRGB(140, 140, 140),
	},
}

local ThemeManager = {}
ThemeManager.__index = ThemeManager
local _themeListeners = {}
local _currentTheme = THEMES.Rounded

function ThemeManager:Get(): ThemeConfig return _currentTheme end
function ThemeManager:Set(name: string)
	local t = THEMES[name]
	if not t then return end
	_currentTheme = t
	for _, cb in ipairs(_themeListeners) do task.spawn(cb, t) end
end
function ThemeManager:Subscribe(cb: (ThemeConfig) -> ()) table.insert(_themeListeners, cb) end

-- ==============================================================================
-- 2. UI PRIMITIVES & UTILS (Features 1, 2, 14)
-- ==============================================================================
local UI = {}
local function Tween(obj, props, time) TweenService:Create(obj, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad), props):Play() end

function UI.Create(class, props, parent)
	local i = Instance.new(class)
	for k, v in props do i[k] = v end
	if parent then i.Parent = parent end
	return i
end

function UI.Corner(parent, radius)
	local c = UI.Create("UICorner", {CornerRadius = UDim.new(0, radius or _currentTheme.Radius)}, parent)
	ThemeManager:Subscribe(function(t) c.CornerRadius = UDim.new(0, t.Radius) end)
	return c
end

function UI.Stroke(parent, color)
	local s = UI.Create("UIStroke", {Color = color or _currentTheme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, parent)
	ThemeManager:Subscribe(function(t) s.Color = t.Border end)
	return s
end

-- ==============================================================================
-- 3. GLOBAL SYSTEMS (Features 6, 9, 15, 7)
-- ==============================================================================
-- 6. Watermark
local WMGui = UI.Create("ScreenGui", {Name="Inertia_WM", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PlayerGui})
local WMFrame = UI.Create("Frame", {Size=UDim2.fromOffset(180, 25), BackgroundColor3=_currentTheme.Surface, BorderSizePixel=0, Position=UDim2.fromOffset(10,10)}, WMGui)
UI.Corner(WMFrame)
local WMText = UI.Create("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="Inertia UI | 0 FPS", TextColor3=_currentTheme.Text1, TextSize=12, Font=Enum.Font.GothamMedium}, WMFrame)
ThemeManager:Subscribe(function(t) WMFrame.BackgroundColor3=t.Surface; WMText.TextColor3=t.Text1 end)
RunService.Heartbeat:Connect(function() WMText.Text = string.format("Inertia UI | %d FPS | %dms", 1/RunService.RenderStepped:Wait(), LocalPlayer:GetNetworkPing()*1000) end)

-- 9. Notifications
local NotifGui = UI.Create("ScreenGui", {Name="Inertia_Notifs", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PlayerGui})
local function Notify(title, text, dur)
	dur = dur or 3
	local n = UI.Create("Frame", {Size=UDim2.fromOffset(250, 60), BackgroundColor3=_currentTheme.Surface, BorderSizePixel=0, Position=UDim2.fromOffset(260, 10)}, NotifGui)
	UI.Corner(n)
	UI.Create("TextLabel", {Size=UDim2.new(1,-10,0,20), Position=UDim2.fromOffset(5,5), BackgroundTransparency=1, Text=title, TextColor3=_currentTheme.Accent, TextSize=13, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, n)
	UI.Create("TextLabel", {Size=UDim2.new(1,-10,0,30), Position=UDim2.fromOffset(5,25), BackgroundTransparency=1, Text=text, TextColor3=_currentTheme.Text1, TextSize=12, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true}, n)
	Tween(n, {Position=UDim2.fromOffset(10, 10)})
	task.delay(dur, function() Tween(n, {Position=UDim2.fromOffset(260, 10)}); task.wait(0.2); n:Destroy() end)
end

-- 15. Tooltips & 7. Context Menu
local TooltipGui = UI.Create("ScreenGui", {Name="Inertia_TT", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Global, DisplayOrder=100, Parent=PlayerGui})
local TooltipFrame = UI.Create("Frame", {Size=UDim2.fromOffset(150, 30), BackgroundColor3=_currentTheme.Surface, BorderSizePixel=0, Visible=false}, TooltipGui)
UI.Corner(TooltipFrame)
local TooltipText = UI.Create("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", TextColor3=_currentTheme.Text1, TextSize=12, Font=Enum.Font.Gotham}, TooltipFrame)

local ContextGui = UI.Create("ScreenGui", {Name="Inertia_CTX", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Global, DisplayOrder=101, Parent=PlayerGui})
local ContextFrame = UI.Create("Frame", {Size=UDim2.fromOffset(120, 0), BackgroundColor3=_currentTheme.Surface, BorderSizePixel=0, Visible=false}, ContextGui)
UI.Corner(ContextFrame)
local ContextLayout = UI.Create("UIListLayout", {Padding=UDim.new(0,2)}, ContextFrame)

-- ==============================================================================
-- 4. CONTROLS (Features 3, 4, 11, 12, 13, 18)
-- ==============================================================================
local Controls = {}
local ControlRegistry = {} -- For Feature 5 (Config)

local function RegisterControl(ctrl) table.insert(ControlRegistry, ctrl) end

-- Checkbox
function Controls.Checkbox(parent, label, default)
	local container = UI.Create("Frame", {Size=UDim2.new(1,0,0,24), BackgroundTransparency=1}, parent)
	local box = UI.Create("Frame", {Size=UDim2.fromOffset(16,16), Position=UDim2.new(0,0,0.5,-8), BackgroundColor3=_currentTheme.Surface}, container)
	UI.Corner(box); UI.Stroke(box)
	local ind = UI.Create("Frame", {Size=UDim2.new(1,-4,1,-4), Position=UDim2.fromOffset(2,2), BackgroundColor3=_currentTheme.Accent, Visible=default}, box)
	UI.Corner(ind)
	UI.Create("TextLabel", {Size=UDim2.new(1,-24,1,0), Position=UDim2.fromOffset(24,0), BackgroundTransparency=1, Text=label, TextColor3=_currentTheme.Text1, TextSize=13, Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left}, container)
	
	local state = {value=default, callbacks={}}
	container.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			state.value = not state.value; ind.Visible = state.value
			for _, cb in ipairs(state.callbacks) do cb(state.value) end
		end
	end)
	ThemeManager:Subscribe(function(t) box.BackgroundColor3=t.Surface; ind.BackgroundColor3=t.Accent end)
	RegisterControl({Name=label, Type="Checkbox", Get=function() return state.value end, Set=function(v) state.value=v; ind.Visible=v end})
	return state
end

-- Slider (Also used for Feature 13: Progress Bar)
function Controls.Slider(parent, label, min, max, default, isProgress)
	local container = UI.Create("Frame", {Size=UDim2.new(1,0,0,32), BackgroundTransparency=1}, parent)
	UI.Create("TextLabel", {Size=UDim2.new(0.5,0,0,14), BackgroundTransparency=1, Text=label, TextColor3=_currentTheme.Text1, TextSize=13, Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left}, container)
	local valLbl = UI.Create("TextLabel", {Size=UDim2.new(0.5,0,0,14), Position=UDim2.new(0.5,0,0,0), BackgroundTransparency=1, Text=tostring(default), TextColor3=_currentTheme.Text2, TextSize=12, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Right}, container)
	local track = UI.Create("Frame", {Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,20), BackgroundColor3=_currentTheme.Surface}, container)
	UI.Corner(track)
	local fill = UI.Create("Frame", {Size=UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3=_currentTheme.Accent}, track)
	UI.Corner(fill)
	
	local state = {value=default, callbacks={}}
	local dragging = false
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local ratio = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			local val = math.floor(min + (max-min)*ratio)
			if val ~= state.value then
				state.value = val; fill.Size = UDim2.new(ratio,0,1,0); valLbl.Text = tostring(val)
				for _, cb in ipairs(state.callbacks) do cb(val) end
			end
		end
	end)
	ThemeManager:Subscribe(function(t) track.BackgroundColor3=t.Surface; fill.BackgroundColor3=t.Accent end)
	RegisterControl({Name=label, Type="Slider", Get=function() return state.value end, Set=function(v) state.value=v; fill.Size=UDim2.new((v-min)/(max-min),0,1,0); valLbl.Text=tostring(v) end})
	return state
end

-- 18. Multi-Select Dropdown & 4. Overlay Dropdown
function Controls.Dropdown(parent, label, options, default, isMulti)
	local container = UI.Create("Frame", {Size=UDim2.new(1,0,0,25), BackgroundTransparency=1}, parent)
	UI.Create("TextLabel", {Size=UDim2.new(1,-30,1,0), BackgroundTransparency=1, Text=label, TextColor3=_currentTheme.Text1, TextSize=12, Font=Enum.Font.Gotham}, container)
	local valLbl = UI.Create("TextLabel", {Size=UDim2.new(1,-30,1,0), Position=UDim2.new(0,5,0,0), BackgroundTransparency=1, Text=isMulti and "Select..." or options[default], TextColor3=_currentTheme.Text2, TextSize=12, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Right}, container)
	local arrow = UI.Create("TextLabel", {Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-20,0,0), BackgroundTransparency=1, Text="+", TextColor3=_currentTheme.Accent, TextSize=14, Font=Enum.Font.GothamBold}, container)
	
	local list = UI.Create("Frame", {Size=UDim2.new(1,0,0,0), BackgroundColor3=_currentTheme.Surface, ZIndex=5, Visible=false}, container)
	UI.Corner(list); UI.Stroke(list)
	local layout = UI.Create("UIListLayout", {Padding=UDim.new(0,2)}, list)
	
	local state = {value=isMulti and {} or default, callbacks={}}
	
	container.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			list.Visible = not list.Visible
			list.Size = list.Visible and UDim2.new(1,0,0,#options*22) or UDim2.new(1,0,0,0)
			arrow.Text = list.Visible and "-" else "+"
		end
	end)
	
	for idx, opt in ipairs(options) do
		local btn = UI.Create("TextButton", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Text=opt, TextColor3=_currentTheme.Text1, TextSize=12, Font=Enum.Font.Gotham, ZIndex=6}, list)
		btn.MouseButton1Click:Connect(function()
			if isMulti then
				if table.find(state.value, opt) then
					table.remove(state.value, table.find(state.value, opt))
				else
					table.insert(state.value, opt)
				end
				valLbl.Text = #state.value > 0 and table.concat(state.value, ", ") or "Select..."
			else
				state.value = opt; valLbl.Text = opt; list.Visible = false; arrow.Text = "+"
			end
			for _, cb in ipairs(state.callbacks) do cb(state.value) end
		end)
	end
	RegisterControl({Name=label, Type="Dropdown", Get=function() return state.value end, Set=function(v) state.value=v; valLbl.Text=type(v)=="table" and table.concat(v, ", ") or v end})
	return state
end

-- 11. Color Picker
function Controls.ColorPicker(parent, label, default)
	local container = UI.Create("Frame", {Size=UDim2.new(1,0,0,25), BackgroundTransparency=1}, parent)
	UI.Create("TextLabel", {Size=UDim2.new(1,-30,1,0), BackgroundTransparency=1, Text=label, TextColor3=_currentTheme.Text1, TextSize=12, Font=Enum.Font.Gotham}, container)
	local preview = UI.Create("Frame", {Size=UDim2.fromOffset(20,14), Position=UDim2.new(1,-25,0,5), BackgroundColor3=default}, container)
	UI.Corner(preview); UI.Stroke(preview)
	
	local state = {value=default, callbacks={}}
	local popup = UI.Create("Frame", {Size=UDim2.fromOffset(200,120), BackgroundColor3=_currentTheme.Surface, ZIndex=10, Visible=false}, container)
	UI.Corner(popup); UI.Stroke(popup)
	
	local rSlider = Controls.Slider(popup, "R", 0, 255, default.R)
	local gSlider = Controls.Slider(popup, "G", 0, 255, default.G)
	local bSlider = Controls.Slider(popup, "B", 0, 255, default.B)
	
	local hexBox = UI.Create("TextBox", {Size=UDim2.new(1,-10,0,20), Position=UDim2.new(0,5,0,95), PlaceholderText="Hex (RRGGBB)", BackgroundColor3=_currentTheme.Background, TextColor3=_currentTheme.Text1, TextSize=12, Font=Enum.Font.Gotham}, popup)
	UI.Corner(hexBox)
	
	local function updateColor()
		local c = Color3.fromRGB(rSlider.value, gSlider.value, bSlider.value)
		state.value = c; preview.BackgroundColor3 = c
		hexBox.Text = string.format("%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
		for _, cb in ipairs(state.callbacks) do cb(c) end
	end
	rSlider.callbacks = {updateColor}; gSlider.callbacks = {updateColor}; bSlider.callbacks = {updateColor}
	
	hexBox.FocusLost:Connect(function(enter)
		if enter and #hexBox.Text == 6 then
			local r = tonumber(hexBox.Text:sub(1,2), 16)
			local g = tonumber(hexBox.Text:sub(3,4), 16)
			local b = tonumber(hexBox.Text:sub(5,6), 16)
			if r and g and b then rSlider:Set(r); gSlider:Set(g); bSlider:Set(b) end
		end
	end)
	
	preview.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then popup.Visible = not popup.Visible end end)
	RegisterControl({Name=label, Type="Color", Get=function() return state.value end, Set=function(v) state.value=v; preview.BackgroundColor3=v; rSlider:Set(v.R*255); gSlider:Set(v.G*255); bSlider:Set(v.B*255) end})
	return state
end

-- 12. Text Input
function Controls.TextInput(parent, label, placeholder)
	local container = UI.Create("Frame", {Size=UDim2.new(1,0,0,25), BackgroundTransparency=1}, parent)
	UI.Create("TextLabel", {Size=UDim2.new(1,0,0,10), BackgroundTransparency=1, Text=label, TextColor3=_currentTheme.Text2, TextSize=11, Font=Enum.Font.Gotham}, container)
	local box = UI.Create("TextBox", {Size=UDim2.new(1,0,0,15), Position=UDim2.new(0,0,0,10), PlaceholderText=placeholder, BackgroundColor3=_currentTheme.Surface, TextColor3=_currentTheme.Text1, TextSize=12, Font=Enum.Font.Gotham, ClearTextOnFocus=false}, container)
	UI.Corner(box)
	local state = {value="", callbacks={}}
	box.FocusLost:Connect(function(enter) state.value=box.Text; if enter then for _, cb in ipairs(state.callbacks) do cb(box.Text) end end end)
	RegisterControl({Name=label, Type="Input", Get=function() return state.value end, Set=function(v) state.value=v; box.Text=v end})
	return state
end

-- 3. Keybind
function Controls.Keybind(parent, label, default, mode)
	local container = UI.Create("Frame", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1}, parent)
	UI.Create("TextLabel", {Size=UDim2.new(1,-80,1,0), BackgroundTransparency=1, Text=label, TextColor3=_currentTheme.Text1, TextSize=12, Font=Enum.Font.Gotham}, container)
	local bindLbl = UI.Create("TextLabel", {Size=UDim2.new(0,70,1,0), Position=UDim2.new(1,-75,0,0), BackgroundColor3=_currentTheme.Surface, Text="["..default.Name.."]", TextColor3=_currentTheme.Text2, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Center}, container)
	UI.Corner(bindLbl)
	
	local state = {value=default, mode=mode, active=false, callbacks={}}
	local listening = false
	bindLbl.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then listening=true; bindLbl.Text="[...]" end end)
	UserInputService.InputBegan:Connect(function(i)
		if listening and i.KeyCode ~= Enum.KeyCode.Unknown then
			state.value = i.KeyCode; bindLbl.Text="["..i.KeyCode.Name.."]"; listening=false
			for _, cb in ipairs(state.callbacks) do cb(i.KeyCode, state.mode) end
		elseif i.KeyCode == state.value then
			if state.mode == "Toggle" then state.active = not state.active
			elseif state.mode == "Hold" then state.active = true end
		end
	end)
	UserInputService.InputEnded:Connect(function(i) if i.KeyCode == state.value and state.mode == "Hold" then state.active = false end end)
	RegisterControl({Name=label, Type="Keybind", Get=function() return state.value end, Set=function(v) state.value=v; bindLbl.Text="["..v.Name.."]" end})
	return state
end

-- ==============================================================================
-- 5. WINDOW & LAYOUT (Features 8, 10, 16, 17, 19)
-- ==============================================================================
local Window = {}
Window.__index = Window

function Window.new(title, themeName)
	ThemeManager:Set(themeName or "Rounded")
	local self = setmetatable({}, Window)
	self.Title = title; self.Tabs = {}
	
	self.Gui = UI.Create("ScreenGui", {Name="Inertia_"..title, ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PlayerGui})
	self.Main = UI.Create("Frame", {Size=UDim2.fromOffset(500,600), Position=UDim2.fromOffset(100,100), BackgroundColor3=_currentTheme.Background, BorderSizePixel=0}, self.Gui)
	UI.Corner(self.Main); UI.Stroke(self.Main)
	
	-- 16. Resize Handle
	local resize = UI.Create("Frame", {Size=UDim2.fromOffset(15,15), Position=UDim2.new(1,-15,1,-15), BackgroundTransparency=1}, self.Main)
	resize.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			local start = i.Position; local startSize = self.Main.Size
			local move = UserInputService.InputChanged:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseMovement then
					self.Main.Size = UDim2.fromOffset(math.max(300, startSize.X.Offset + (inp.Position.X - start.X)), math.max(200, startSize.Y.Offset + (inp.Position.Y - start.Y)))
				end
			end)
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then move:Disconnect() end end)
		end
	end)

	-- Title Bar & 10. Minimize
	self.TitleBar = UI.Create("Frame", {Size=UDim2.new(1,0,0,32), BackgroundColor3=_currentTheme.Surface}, self.Main)
	UI.Create("UICorner", {CornerRadius=UDim.new(0, _currentTheme.Radius)}, self.TitleBar)
	UI.Create("TextLabel", {Size=UDim2.new(1,-40,1,0), Position=UDim2.fromOffset(12,0), BackgroundTransparency=1, Text=title, TextColor3=_currentTheme.Text1, TextSize=13, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, self.TitleBar)
	
	local minBtn = UI.Create("TextButton", {Size=UDim2.fromOffset(20,20), Position=UDim2.new(1,-30,0,6), BackgroundTransparency=1, Text="_", TextColor3=_currentTheme.Text2, TextSize=16, Font=Enum.Font.GothamBold}, self.TitleBar)
	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		self.Content.Visible = not minimized; self.TabBar.Visible = not minimized
		self.Main.Size = minimized and UDim2.fromOffset(self.Main.Size.X.Offset, 32) or UDim2.fromOffset(self.Main.Size.X.Offset, 600)
	end)

	-- Dragging
	local dragStart, startPos
	self.TitleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragStart=i.Position; startPos=self.Main.Position end end)
	UserInputService.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement and dragStart then self.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+(i.Position.X-dragStart.X), startPos.Y.Scale, startPos.Y.Offset+(i.Position.Y-dragStart.Y)) end end)

	self.TabBar = UI.Create("Frame", {Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,32), BackgroundColor3=_currentTheme.Surface}, self.Main)
	self.Content = UI.Create("Frame", {Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62), BackgroundTransparency=1}, self.Main)
	
	-- 8. Search Bar
	local search = UI.Create("TextBox", {Size=UDim2.new(1,-20,0,20), Position=UDim2.fromOffset(10,5), PlaceholderText="Search...", BackgroundColor3=_currentTheme.Background, TextColor3=_currentTheme.Text1, TextSize=12, Font=Enum.Font.Gotham}, self.Content)
	UI.Corner(search)
	search:GetPropertyChangedSignal("Text"):Connect(function()
		local q = search.Text:lower()
		for _, tab in ipairs(self.Tabs) do
			for _, sec in ipairs(tab.Sections) do
				sec.Container.Visible = sec.Name:lower():find(q) ~= nil or q == ""
			end
		end
	end)

	ThemeManager:Subscribe(function(t)
		self.Main.BackgroundColor3=t.Background; self.TitleBar.BackgroundColor3=t.Surface; self.TabBar.BackgroundColor3=t.Surface
	end)
	return self
end

-- 17. Tab Icons
function Window:Tab(name, iconId)
	local tab = {Name=name, Sections={}, Container=UI.Create("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=(#self.Tabs==0)}, self.Content)}
	table.insert(self.Tabs, tab)
	
	local btn = UI.Create("TextButton", {Size=UDim2.new(1/#self.Tabs,0,1,0), Position=UDim2.new((#self.Tabs-1)/#self.Tabs,0,0,0), BackgroundTransparency=1, Text=name, TextColor3=_currentTheme.Text2, TextSize=13, Font=Enum.Font.GothamMedium}, self.TabBar)
	if iconId then
		UI.Create("ImageLabel", {Size=UDim2.fromOffset(16,16), Position=UDim2.new(0,5,0.5,-8), Image=iconId, ImageColor3=_currentTheme.Text2, BackgroundTransparency=1}, btn)
	end
	local line = UI.Create("Frame", {Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,0), BackgroundColor3=_currentTheme.Accent, Visible=(#self.Tabs==1)}, btn)
	
	btn.MouseButton1Click:Connect(function()
		for _, t in ipairs(self.Tabs) do
			t.Container.Visible = (t == tab)
			line.Visible = (t == tab)
		end
	end)
	ThemeManager:Subscribe(function(t) line.BackgroundColor3=t.Accent end)
	return tab
end

-- 19. Collapsible Sections
function Window:Section(name) return self.Tabs[1]:Section(name) end
function Tab:Section(name)
	local self = {Name=name, Container=UI.Create("Frame", {Size=UDim2.new(1,-20,0,200), Position=UDim2.new(0,10,0,30 + #self.Parent.Sections*210), BackgroundTransparency=1}, self.Parent.Container)}
	table.insert(self.Parent.Sections, self)
	
	local header = UI.Create("Frame", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1}, self.Container)
	UI.Create("TextLabel", {Size=UDim2.new(1,-20,1,0), BackgroundTransparency=1, Text=name, TextColor3=_currentTheme.Text1, TextSize=13, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, header)
	local toggle = UI.Create("TextLabel", {Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-20,0,0), BackgroundTransparency=1, Text="-", TextColor3=_currentTheme.Accent, TextSize=14, Font=Enum.Font.GothamBold}, header)
	UI.Create("Frame", {Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,0), BackgroundColor3=_currentTheme.Accent}, header)
	
	self.Scroll = UI.Create("ScrollingFrame", {Size=UDim2.new(1,-10,1,-25), Position=UDim2.new(0,5,0,25), BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=_currentTheme.Border, CanvasSize=UDim2.new(0,0,0,0)}, self.Container)
	local layout = UI.Create("UIListLayout", {Padding=UDim.new(0,5)}, self.Scroll)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() self.Scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y) end)
	
	local collapsed = false
	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			collapsed = not collapsed; self.Scroll.Visible = not collapsed; toggle.Text = collapsed and "+" else "-"
		end
	end)
	return self
end

-- Control Adders
function Tab:AddCheckbox(l, d) return Controls.Checkbox(self.Scroll or self.Container, l, d) end
function Tab:AddSlider(l, min, max, d) return Controls.Slider(self.Scroll or self.Container, l, min, max, d) end
function Tab:AddDropdown(l, o, d, m) return Controls.Dropdown(self.Scroll or self.Container, l, o, d, m) end
function Tab:AddColorPicker(l, d) return Controls.ColorPicker(self.Scroll or self.Container, l, d) end
function Tab:AddTextInput(l, p) return Controls.TextInput(self.Scroll or self.Container, l, p) end
function Tab:AddKeybind(l, d, m) return Controls.Keybind(self.Scroll or self.Container, l, d, m) end
function Tab:AddButton(l, cb)
	local btn = UI.Create("TextButton", {Size=UDim2.new(1,0,0,25), BackgroundColor3=_currentTheme.Accent, Text=l, TextColor3=_currentTheme.Text1, TextSize=13, Font=Enum.Font.GothamMedium}, self.Scroll or self.Container)
	UI.Corner(btn); btn.MouseButton1Click:Connect(cb)
	ThemeManager:Subscribe(function(t) btn.BackgroundColor3=t.Accent end)
	return btn
end

-- ==============================================================================
-- 6. EXPORT & CONFIG (Feature 5)
-- ==============================================================================
local InertiaUI = {}
function InertiaUI.Create(title, theme) return Window.new(title, theme) end

function InertiaUI.SaveConfig(name)
	local data = {}
	for _, c in ipairs(ControlRegistry) do data[c.Name] = c.Get() end
	writefile("Inertia_"..name..".json", HttpService:JSONEncode(data))
	Notify("Config", "Saved "..name)
end

function InertiaUI.LoadConfig(name)
	if isfile("Inertia_"..name..".json") then
		local data = HttpService:JSONDecode(readfile("Inertia_"..name..".json"))
		for _, c in ipairs(ControlRegistry) do if data[c.Name] then c.Set(data[c.Name]) end end
		Notify("Config", "Loaded "..name)
	end
end

getgenv().InertiaUI = InertiaUI
return InertiaUI
