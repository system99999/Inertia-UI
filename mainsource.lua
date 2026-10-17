--!strict
-- InertiaUI v6.0 - Production Build
-- Architecture: Modular, Observer-based Theming, Decoupled State.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==============================================================================
-- 1. THEME ENGINE
-- ==============================================================================
type Color3 = typeof(Color3.new())
export type ThemeConfig = {
	Radius: number,
	Accent: Color3,
	Background: Color3,
	Surface: Color3,
	SurfaceHover: Color3,
	Border: Color3,
	Text1: Color3,
	Text2: Color3,
	Danger: Color3,
}

local THEMES: {[string]: ThemeConfig} = {
	Rounded = {
		Radius = 6, Accent = Color3.fromRGB(139, 92, 246),
		Background = Color3.fromRGB(24, 24, 27), Surface = Color3.fromRGB(39, 39, 42),
		SurfaceHover = Color3.fromRGB(50, 50, 55), Border = Color3.fromRGB(63, 63, 70),
		Text1 = Color3.fromRGB(250, 250, 250), Text2 = Color3.fromRGB(161, 161, 170),
		Danger = Color3.fromRGB(239, 68, 68),
	},
	Square = {
		Radius = 0, Accent = Color3.fromRGB(16, 185, 129),
		Background = Color3.fromRGB(18, 18, 18), Surface = Color3.fromRGB(30, 30, 30),
		SurfaceHover = Color3.fromRGB(40, 40, 40), Border = Color3.fromRGB(50, 50, 50),
		Text1 = Color3.fromRGB(240, 240, 240), Text2 = Color3.fromRGB(140, 140, 140),
		Danger = Color3.fromRGB(220, 38, 38),
	},
}

local ThemeManager = {}
local _currentTheme = THEMES.Rounded
local _themeListeners: {(ThemeConfig) -> ()} = {}

function ThemeManager:Get(): ThemeConfig return _currentTheme end

function ThemeManager:Set(name: string)
	local newTheme = THEMES[name]
	if not newTheme then return end
	_currentTheme = newTheme
	for _, callback in ipairs(_themeListeners) do
		task.spawn(callback, newTheme)
	end
end

function ThemeManager:Subscribe(callback: (ThemeConfig) -> ())
	table.insert(_themeListeners, callback)
end

-- ==============================================================================
-- 2. UI PRIMITIVES
-- ==============================================================================
local UI = {}

local function Tween(instance: Instance, properties: {[string]: any}, duration: number?)
	TweenService:Create(instance, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad), properties):Play()
end

function UI.Create(class: string, properties: {[string]: any}, parent: Instance?): Instance
	local instance = Instance.new(class)
	for key, value in properties do
		instance[key] = value
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function UI.Corner(parent: Instance, radius: number?): UICorner
	local corner = UI.Create("UICorner", {
		CornerRadius = UDim.new(0, radius or _currentTheme.Radius),
	}, parent)
	ThemeManager:Subscribe(function(theme)
		corner.CornerRadius = UDim.new(0, theme.Radius)
	end)
	return corner
end

function UI.Stroke(parent: Instance, color: Color3?): UIStroke
	local stroke = UI.Create("UIStroke", {
		Color = color or _currentTheme.Border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
	ThemeManager:Subscribe(function(theme)
		stroke.Color = theme.Border
	end)
	return stroke
end

-- ==============================================================================
-- 3. GLOBAL OVERLAYS
-- ==============================================================================
local OverlayGui = UI.Create("ScreenGui", {
	Name = "Inertia_Overlay",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = 100,
	IgnoreGuiInset = true,
}, PlayerGui)

-- Tooltips
local TooltipFrame = UI.Create("Frame", {
	Size = UDim2.fromOffset(150, 30),
	BackgroundColor3 = _currentTheme.Surface,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 200,
}, OverlayGui)
UI.Corner(TooltipFrame)
UI.Stroke(TooltipFrame)

local TooltipText = UI.Create("TextLabel", {
	Size = UDim2.new(1, -10, 1, 0),
	Position = UDim2.fromOffset(5, 0),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = _currentTheme.Text1,
	TextSize = 12,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 201,
}, TooltipFrame)

-- Context Menus
local ContextFrame = UI.Create("Frame", {
	Size = UDim2.fromOffset(120, 0),
	BackgroundColor3 = _currentTheme.Surface,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 200,
}, OverlayGui)
UI.Corner(ContextFrame)
UI.Stroke(ContextFrame)
UI.Create("UIListLayout", {Padding = UDim.new(0, 2)}, ContextFrame)

-- Dropdown Overlay
local DropdownOverlay = UI.Create("Frame", {
	Size = UDim2.fromOffset(200, 0),
	BackgroundColor3 = _currentTheme.Surface,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 150,
}, OverlayGui)
UI.Corner(DropdownOverlay)
UI.Stroke(DropdownOverlay)
UI.Create("UIListLayout", {Padding = UDim.new(0, 2)}, DropdownOverlay)

-- Notifications
local NotifGui = UI.Create("ScreenGui", {
	Name = "Inertia_Notifs",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = 101,
	Parent = PlayerGui,
})

local function Notify(title: string, text: string, duration: number?)
	duration = duration or 3
	local notif = UI.Create("Frame", {
		Size = UDim2.fromOffset(250, 60),
		BackgroundColor3 = _currentTheme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(260, 10),
	}, NotifGui)
	UI.Corner(notif)
	
	UI.Create("TextLabel", {
		Size = UDim2.new(1, -10, 0, 20),
		Position = UDim2.fromOffset(5, 5),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = _currentTheme.Accent,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, notif)
	
	UI.Create("TextLabel", {
		Size = UDim2.new(1, -10, 0, 30),
		Position = UDim2.fromOffset(5, 25),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = _currentTheme.Text1,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, notif)

	Tween(notif, {Position = UDim2.fromOffset(10, 10)})
	task.delay(duration, function()
		Tween(notif, {Position = UDim2.fromOffset(260, 10)})
		task.wait(0.2)
		notif:Destroy()
	end)
end

-- Global Input Handling for Overlays
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if ContextFrame.Visible then ContextFrame.Visible = false end
		if DropdownOverlay.Visible then DropdownOverlay.Visible = false end
	end
end)

-- ==============================================================================
-- 4. CONTROLS
-- ==============================================================================
local Controls = {}
local ControlRegistry: {any} = {}

local function RegisterControl(control: any)
	table.insert(ControlRegistry, control)
end

local function AttachInteractions(frame: Frame, tooltipText: string?, contextOptions: {string}?, contextCallback: ((string) -> ())?)
	if tooltipText then
		frame.MouseEnter:Connect(function()
			TooltipText.Text = tooltipText
			TooltipFrame.Size = UDim2.fromOffset(TooltipText.TextBounds.X + 10, 30)
			TooltipFrame.Visible = true
		end)
		frame.MouseLeave:Connect(function()
			TooltipFrame.Visible = false
		end)
	end

	if contextOptions then
		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				for _, child in ipairs(ContextFrame:GetChildren()) do
					if child:IsA("TextButton") then child:Destroy() end
				end
				for _, option in ipairs(contextOptions) do
					local btn = UI.Create("TextButton", {
						Size = UDim2.new(1, 0, 0, 22),
						BackgroundTransparency = 1,
						Text = option,
						TextColor3 = _currentTheme.Text1,
						TextSize = 12,
						Font = Enum.Font.Gotham,
						ZIndex = 201,
					}, ContextFrame)
					btn.MouseButton1Click:Connect(function()
						if contextCallback then contextCallback(option) end
						ContextFrame.Visible = false
					end)
				end
				ContextFrame.Size = UDim2.fromOffset(120, #contextOptions * 24)
				ContextFrame.Position = UDim2.fromOffset(input.Position.X, input.Position.Y)
				ContextFrame.Visible = true
			end
		end)
	end
end

-- Checkbox
function Controls.Checkbox(parent: Instance, label: string, default: boolean, tooltip: string?, contextOpts: {string}?, contextCb: ((string) -> ())?)
	local container = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
	}, parent)
	
	local box = UI.Create("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 0, 0.5, -8),
		BackgroundColor3 = _currentTheme.Surface,
	}, container)
	UI.Corner(box)
	UI.Stroke(box)
	
	local indicator = UI.Create("Frame", {
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = _currentTheme.Accent,
		Visible = default,
	}, box)
	UI.Corner(indicator)
	
	UI.Create("TextLabel", {
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(24, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = _currentTheme.Text1,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, container)

	local state = {value = default, callbacks = {}}
	
	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			state.value = not state.value
			indicator.Visible = state.value
			Tween(indicator, {BackgroundTransparency = state.value and 0 or 1})
			for _, callback in ipairs(state.callbacks) do callback(state.value) end
		end
	end)

	ThemeManager:Subscribe(function(theme)
		box.BackgroundColor3 = theme.Surface
		indicator.BackgroundColor3 = theme.Accent
	end)
	
	AttachInteractions(container, tooltip, contextOpts, contextCb)
	RegisterControl({Name = label, Type = "Checkbox", Get = function() return state.value end, Set = function(v) state.value = v; indicator.Visible = v end})
	return state
end

-- Slider
function Controls.Slider(parent: Instance, label: string, min: number, max: number, default: number, suffix: string?, tooltip: string?)
	local container = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
	}, parent)
	
	UI.Create("TextLabel", {
		Size = UDim2.new(0.5, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = _currentTheme.Text1,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, container)
	
	local valueLabel = UI.Create("TextLabel", {
		Size = UDim2.new(0.5, 0, 0, 14),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(default) .. (suffix or ""),
		TextColor3 = _currentTheme.Text2,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, container)
	
	local track = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundColor3 = _currentTheme.Surface,
	}, container)
	UI.Corner(track)
	
	local fill = UI.Create("Frame", {
		Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = _currentTheme.Accent,
	}, track)
	UI.Corner(fill)

	local state = {value = default, callbacks = {}}
	local dragging = false
	
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			local newValue = math.floor(min + (max - min) * ratio)
			if newValue ~= state.value then
				state.value = newValue
				fill.Size = UDim2.new(ratio, 0, 1, 0)
				valueLabel.Text = tostring(newValue) .. (suffix or "")
				for _, callback in ipairs(state.callbacks) do callback(newValue) end
			end
		end
	end)

	ThemeManager:Subscribe(function(theme)
		track.BackgroundColor3 = theme.Surface
		fill.BackgroundColor3 = theme.Accent
	end)
	
	AttachInteractions(container, tooltip)
	RegisterControl({Name = label, Type = "Slider", Get = function() return state.value end, Set = function(v) state.value = v; fill.Size = UDim2.new((v-min)/(max-min),0,1,0); valueLabel.Text = tostring(v)..(suffix or "") end})
	return state
end

-- Dropdown (True Overlay)
function Controls.Dropdown(parent: Instance, label: string, options: {string}, defaultIndex: number?, isMulti: boolean?)
	local container = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 25),
		BackgroundTransparency = 1,
	}, parent)
	
	UI.Create("TextLabel", {
		Size = UDim2.new(1, -30, 1, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = _currentTheme.Text1,
		TextSize = 12,
		Font = Enum.Font.Gotham,
	}, container)
	
	local valueLabel = UI.Create("TextLabel", {
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 5, 0, 0),
		BackgroundTransparency = 1,
		Text = isMulti and "Select..." or (options[defaultIndex or 1] or ""),
		TextColor3 = _currentTheme.Text2,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, container)
	
	local arrow = UI.Create("TextLabel", {
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -20, 0, 0),
		BackgroundTransparency = 1,
		Text = "+",
		TextColor3 = _currentTheme.Accent,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
	}, container)

	local state = {value = isMulti and {} or (options[defaultIndex or 1] or ""), callbacks = {}}
	local isOpen = false

	local function renderOptions()
		for _, child in ipairs(DropdownOverlay:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for index, option in ipairs(options) do
			local btn = UI.Create("TextButton", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Text = option,
				TextColor3 = _currentTheme.Text1,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				ZIndex = 151,
			}, DropdownOverlay)
			btn.MouseButton1Click:Connect(function()
				if isMulti then
					if table.find(state.value, option) then
						table.remove(state.value, table.find(state.value, option))
					else
						table.insert(state.value, option)
					end
					valueLabel.Text = #state.value > 0 and table.concat(state.value, ", ") or "Select..."
				else
					state.value = option
					valueLabel.Text = option
					isOpen = false
					DropdownOverlay.Visible = false
					arrow.Text = "+"
				end
				for _, callback in ipairs(state.callbacks) do callback(state.value) end
			end)
		end
		DropdownOverlay.Size = UDim2.fromOffset(200, #options * 24)
	end

	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isOpen = not isOpen
			if isOpen then
				renderOptions()
				local absPos = container.AbsolutePosition
				DropdownOverlay.Position = UDim2.fromOffset(absPos.X, absPos.Y + 25)
				DropdownOverlay.Visible = true
				arrow.Text = "-"
			else
				DropdownOverlay.Visible = false
				arrow.Text = "+"
			end
		end
	end)

	RegisterControl({Name = label, Type = "Dropdown", Get = function() return state.value end, Set = function(v) state.value = v; valueLabel.Text = type(v) == "table" and table.concat(v, ", ") or v end})
	return state
end

-- Button
function Controls.Button(parent: Instance, label: string, callback: () -> ())
	local btn = UI.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 25),
		BackgroundColor3 = _currentTheme.Accent,
		Text = label,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
	}, parent)
	UI.Corner(btn)
	btn.MouseButton1Click:Connect(callback)
	ThemeManager:Subscribe(function(theme) btn.BackgroundColor3 = theme.Accent end)
	return btn
end

-- Keybind
function Controls.Keybind(parent: Instance, label: string, default: Enum.KeyCode, mode: string)
	local container = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
	}, parent)
	
	UI.Create("TextLabel", {
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = _currentTheme.Text1,
		TextSize = 12,
		Font = Enum.Font.Gotham,
	}, container)
	
	local bindLabel = UI.Create("TextLabel", {
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.new(1, -75, 0, 0),
		BackgroundColor3 = _currentTheme.Surface,
		Text = "[" .. default.Name .. "]",
		TextColor3 = _currentTheme.Text2,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, container)
	UI.Corner(bindLabel)

	local state = {value = default, mode = mode, active = false, callbacks = {}}
	local listening = false
	
	bindLabel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			listening = true
			bindLabel.Text = "[...]"
		end
	end)
	
	UserInputService.InputBegan:Connect(function(input)
		if listening and input.KeyCode ~= Enum.KeyCode.Unknown then
			state.value = input.KeyCode
			bindLabel.Text = "[" .. input.KeyCode.Name .. "]"
			listening = false
			for _, callback in ipairs(state.callbacks) do callback(input.KeyCode, state.mode) end
		elseif input.KeyCode == state.value then
			if state.mode == "Toggle" then state.active = not state.active
			elseif state.mode == "Hold" then state.active = true end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == state.value and state.mode == "Hold" then state.active = false end
	end)

	RegisterControl({Name = label, Type = "Keybind", Get = function() return state.value end, Set = function(v) state.value = v; bindLabel.Text = "[" .. v.Name .. "]" end})
	return state
end

-- Text Input
function Controls.TextInput(parent: Instance, label: string, placeholder: string)
	local container = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 25),
		BackgroundTransparency = 1,
	}, parent)
	
	UI.Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = _currentTheme.Text2,
		TextSize = 11,
		Font = Enum.Font.Gotham,
	}, container)
	
	local box = UI.Create("TextBox", {
		Size = UDim2.new(1, 0, 0, 15),
		Position = UDim2.new(0, 0, 0, 10),
		PlaceholderText = placeholder,
		BackgroundColor3 = _currentTheme.Surface,
		TextColor3 = _currentTheme.Text1,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		ClearTextOnFocus = false,
	}, container)
	UI.Corner(box)

	local state = {value = "", callbacks = {}}
	box.FocusLost:Connect(function(enterPressed)
		state.value = box.Text
		if enterPressed then
			for _, callback in ipairs(state.callbacks) do callback(box.Text) end
		end
	end)

	RegisterControl({Name = label, Type = "Input", Get = function() return state.value end, Set = function(v) state.value = v; box.Text = v end})
	return state
end

-- Color Picker
function Controls.ColorPicker(parent: Instance, label: string, default: Color3)
	local container = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 25),
		BackgroundTransparency = 1,
	}, parent)
	
	UI.Create("TextLabel", {
		Size = UDim2.new(1, -30, 1, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = _currentTheme.Text1,
		TextSize = 12,
		Font = Enum.Font.Gotham,
	}, container)
	
	local preview = UI.Create("Frame", {
		Size = UDim2.fromOffset(20, 14),
		Position = UDim2.new(1, -25, 0, 5),
		BackgroundColor3 = default,
	}, container)
	UI.Corner(preview)
	UI.Stroke(preview)

	local state = {value = default, callbacks = {}}
	
	-- Simplified popup for brevity, but fully functional
	local popup = UI.Create("Frame", {
		Size = UDim2.fromOffset(200, 120),
		BackgroundColor3 = _currentTheme.Surface,
		ZIndex = 10,
		Visible = false,
	}, container)
	UI.Corner(popup)
	UI.Stroke(popup)

	local rSlider = Controls.Slider(popup, "R", 0, 255, default.R * 255)
	local gSlider = Controls.Slider(popup, "G", 0, 255, default.G * 255)
	local bSlider = Controls.Slider(popup, "B", 0, 255, default.B * 255)

	local function updateColor()
		local newColor = Color3.fromRGB(rSlider.value, gSlider.value, bSlider.value)
		state.value = newColor
		preview.BackgroundColor3 = newColor
		for _, callback in ipairs(state.callbacks) do callback(newColor) end
	end

	rSlider.callbacks = {updateColor}
	gSlider.callbacks = {updateColor}
	bSlider.callbacks = {updateColor}

	preview.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			popup.Visible = not popup.Visible
		end
	end)

	RegisterControl({Name = label, Type = "Color", Get = function() return state.value end, Set = function(v) state.value = v; preview.BackgroundColor3 = v; rSlider:Set(v.R*255); gSlider:Set(v.G*255); bSlider:Set(v.B*255) end})
	return state
end

-- ==============================================================================
-- 5. WINDOW & LAYOUT
-- ==============================================================================
local Window = {}
Window.__index = Window

function Window.new(title: string, themeName: string)
	ThemeManager:Set(themeName or "Rounded")
	local self = setmetatable({}, Window)
	self.Title = title
	self.Tabs = {}

	self.Gui = UI.Create("ScreenGui", {
		Name = "Inertia_" .. title,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, PlayerGui)

	self.Main = UI.Create("Frame", {
		Size = UDim2.fromOffset(500, 600),
		Position = UDim2.fromOffset(100, 100),
		BackgroundColor3 = _currentTheme.Background,
		BorderSizePixel = 0,
	}, self.Gui)
	UI.Corner(self.Main)
	UI.Stroke(self.Main)

	-- Resize Handle
	local resizeHandle = UI.Create("Frame", {
		Size = UDim2.fromOffset(15, 15),
		Position = UDim2.new(1, -15, 1, -15),
		BackgroundTransparency = 1,
	}, self.Main)
	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local startPos = input.Position
			local startSize = self.Main.Size
			local moveConnection = UserInputService.InputChanged:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseMovement then
					self.Main.Size = UDim2.fromOffset(
						math.max(300, startSize.X.Offset + (inp.Position.X - startPos.X)),
						math.max(200, startSize.Y.Offset + (inp.Position.Y - startPos.Y))
					)
				end
			end)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then moveConnection:Disconnect() end
			end)
		end
	end)

	-- Title Bar
	self.TitleBar = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = _currentTheme.Surface,
	}, self.Main)
	UI.Create("UICorner", {CornerRadius = UDim.new(0, _currentTheme.Radius)}, self.TitleBar)
	
	UI.Create("TextLabel", {
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = _currentTheme.Text1,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, self.TitleBar)

	-- Window Controls
	local minBtn = UI.Create("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -90, 0, 6), BackgroundTransparency = 1, Text = "_", TextColor3 = _currentTheme.Text2, TextSize = 16, Font = Enum.Font.GothamBold}, self.TitleBar)
	local maxBtn = UI.Create("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -60, 0, 6), BackgroundTransparency = 1, Text = "□", TextColor3 = _currentTheme.Text2, TextSize = 14, Font = Enum.Font.GothamBold}, self.TitleBar)
	local closeBtn = UI.Create("TextButton", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -30, 0, 6), BackgroundTransparency = 1, Text = "×", TextColor3 = _currentTheme.Text2, TextSize = 18, Font = Enum.Font.GothamBold}, self.TitleBar)

	local minimized = false
	local maximized = false
	local originalSize = self.Main.Size
	local originalPos = self.Main.Position

	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		self.Content.Visible = not minimized
		self.TabBar.Visible = not minimized
		self.Main.Size = minimized and UDim2.fromOffset(self.Main.Size.X.Offset, 32) or (maximized and UDim2.new(1, -20, 1, -20) or originalSize)
	end)

	maxBtn.MouseButton1Click:Connect(function()
		maximized = not maximized
		if maximized then
			self.Main.Size = UDim2.new(1, -20, 1, -20)
			self.Main.Position = UDim2.fromOffset(10, 10)
		else
			self.Main.Size = originalSize
			self.Main.Position = originalPos
		end
		if minimized then
			minimized = false
			self.Content.Visible = true
			self.TabBar.Visible = true
		end
	end)

	closeBtn.MouseButton1Click:Connect(function()
		self.Gui:Destroy()
	end)

	-- Dragging
	local dragStart, startPos
	self.TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragStart = input.Position
			startPos = self.Main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
			self.Main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + (input.Position.X - dragStart.X),
				startPos.Y.Scale, startPos.Y.Offset + (input.Position.Y - dragStart.Y)
			)
		end
	end)

	self.TabBar = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 32),
		BackgroundColor3 = _currentTheme.Surface,
	}, self.Main)

	self.Content = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 1, -62),
		Position = UDim2.new(0, 0, 0, 62),
		BackgroundTransparency = 1,
	}, self.Main)

	-- Search Bar
	local search = UI.Create("TextBox", {
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.fromOffset(10, 5),
		PlaceholderText = "Search...",
		BackgroundColor3 = _currentTheme.Background,
		TextColor3 = _currentTheme.Text1,
		TextSize = 12,
		Font = Enum.Font.Gotham,
	}, self.Content)
	UI.Corner(search)
	search:GetPropertyChangedSignal("Text"):Connect(function()
		local query = search.Text:lower()
		for _, tab in ipairs(self.Tabs) do
			for _, section in ipairs(tab.Sections) do
				section.Container.Visible = section.Name:lower():find(query) ~= nil or query == ""
			end
		end
	end)

	ThemeManager:Subscribe(function(theme)
		self.Main.BackgroundColor3 = theme.Background
		self.TitleBar.BackgroundColor3 = theme.Surface
		self.TabBar.BackgroundColor3 = theme.Surface
	end)

	return self
end

function Window:Tab(name: string, iconId: string?)
	local tab = {Name = name, Sections = {}, Container = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = (#self.Tabs == 0),
	}, self.Content)}
	table.insert(self.Tabs, tab)

	local btn = UI.Create("TextButton", {
		Size = UDim2.new(1 / #self.Tabs, 0, 1, 0),
		Position = UDim2.new((#self.Tabs - 1) / #self.Tabs, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = _currentTheme.Text2,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
	}, self.TabBar)
	
	if iconId then
		UI.Create("ImageLabel", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(0, 5, 0.5, -8),
			Image = iconId,
			ImageColor3 = _currentTheme.Text2,
			BackgroundTransparency = 1,
		}, btn)
	end

	local line = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = _currentTheme.Accent,
		Visible = (#self.Tabs == 1),
	}, btn)

	btn.MouseButton1Click:Connect(function()
		for _, t in ipairs(self.Tabs) do
			t.Container.Visible = (t == tab)
			line.Visible = (t == tab)
		end
	end)

	ThemeManager:Subscribe(function(theme) line.BackgroundColor3 = theme.Accent end)
	return tab
end

function Tab:Section(name: string)
	local self = {Name = name, Container = UI.Create("Frame", {
		Size = UDim2.new(1, -20, 0, 200),
		Position = UDim2.new(0, 10, 0, 30 + #self.Parent.Sections * 210),
		BackgroundTransparency = 1,
	}, self.Parent.Container)}
	table.insert(self.Parent.Sections, self)

	local header = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
	}, self.Container)
	
	UI.Create("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = _currentTheme.Text1,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)
	
	local toggle = UI.Create("TextLabel", {
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -20, 0, 0),
		BackgroundTransparency = 1,
		Text = "-",
		TextColor3 = _currentTheme.Accent,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
	}, header)
	
	UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = _currentTheme.Accent,
	}, header)

	self.Scroll = UI.Create("ScrollingFrame", {
		Size = UDim2.new(1, -10, 1, -25),
		Position = UDim2.new(0, 5, 0, 25),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = _currentTheme.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	}, self.Container)
	
	local layout = UI.Create("UIListLayout", {Padding = UDim.new(0, 5)}, self.Scroll)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.Scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	end)

	local collapsed = false
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			collapsed = not collapsed
			self.Scroll.Visible = not collapsed
			toggle.Text = collapsed and "+" or "-"
		end
	end)
	return self
end

-- Control Adders
function Tab:AddCheckbox(l, d, t, c, cb) return Controls.Checkbox(self.Scroll or self.Container, l, d, t, c, cb) end
function Tab:AddSlider(l, min, max, d, s, t) return Controls.Slider(self.Scroll or self.Container, l, min, max, d, s, t) end
function Tab:AddDropdown(l, o, d, m) return Controls.Dropdown(self.Scroll or self.Container, l, o, d, m) end
function Tab:AddColorPicker(l, d) return Controls.ColorPicker(self.Scroll or self.Container, l, d) end
function Tab:AddTextInput(l, p) return Controls.TextInput(self.Scroll or self.Container, l, p) end
function Tab:AddKeybind(l, d, m) return Controls.Keybind(self.Scroll or self.Container, l, d, m) end
function Tab:AddButton(l, cb) return Controls.Button(self.Scroll or self.Container, l, cb) end

-- ==============================================================================
-- 6. CHEAT UTILITIES
-- ==============================================================================
local Utilities = {}

-- Player List
function Utilities.AddPlayerList(tab: any, callback: (Player) -> ())
	local container = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 300),
		BackgroundTransparency = 1,
	}, tab.Scroll or tab.Container)
	UI.Corner(container)

	local scroll = UI.Create("ScrollingFrame", {
		Size = UDim2.new(1, -10, 1, -10),
		Position = UDim2.fromOffset(5, 5),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = _currentTheme.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	}, container)

	local layout = UI.Create("UIListLayout", {Padding = UDim.new(0, 4)}, scroll)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)

	local function refreshList()
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local row = UI.Create("Frame", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundColor3 = _currentTheme.Surface,
					BorderSizePixel = 0,
				}, scroll)
				UI.Corner(row, 4)

				UI.Create("TextLabel", {
					Size = UDim2.new(1, -60, 1, 0),
					Position = UDim2.fromOffset(8, 0),
					BackgroundTransparency = 1,
					Text = player.DisplayName,
					TextColor3 = _currentTheme.Text1,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, row)

				local targetBtn = UI.Create("TextButton", {
					Size = UDim2.fromOffset(50, 18),
					Position = UDim2.new(1, -55, 0, 3),
					BackgroundColor3 = _currentTheme.Accent,
					Text = "Target",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 11,
					Font = Enum.Font.GothamMedium,
				}, row)
				UI.Corner(targetBtn, 3)

				targetBtn.MouseButton1Click:Connect(function()
					if callback then callback(player) end
					Notify("Target", "Now targeting " .. player.DisplayName, 2)
				end)
			end
		end
	end

	Players.PlayerAdded:Connect(refreshList)
	Players.PlayerRemoving:Connect(refreshList)
	refreshList()
end

-- Config Loader
function Utilities.AddConfigLoader(tab: any)
	local configs = {}
	if listfiles then
		for _, file in ipairs(listfiles("Inertia_")) do
			if file:find(".json") then
				table.insert(configs, file:gsub("Inertia_", ""):gsub(".json", ""))
			end
		end
	end
	if #configs == 0 then configs = {"No configs found"} end

	local dropdown = tab:AddDropdown("Load Config", configs, 1)
	dropdown.callbacks = {function(selected)
		if selected ~= "No configs found" then
			InertiaUI.LoadConfig(selected)
		end
	end}

	tab:AddButton("Save Current Config", function()
		local name = "config_" .. os.time()
		InertiaUI.SaveConfig(name)
		Notify("Config", "Saved as " .. name, 2)
	end)
end

-- ==============================================================================
-- 7. EXPORT & CONFIG SYSTEM
-- ==============================================================================
local InertiaUI = {}

function InertiaUI.Create(title: string, theme: string?)
	return Window.new(title, theme)
end

function InertiaUI.SaveConfig(name: string)
	local data = {}
	for _, control in ipairs(ControlRegistry) do
		data[control.Name] = control.Get()
	end
	writefile("Inertia_" .. name .. ".json", HttpService:JSONEncode(data))
	Notify("Config", "Saved " .. name, 2)
end

function InertiaUI.LoadConfig(name: string)
	if isfile("Inertia_" .. name .. ".json") then
		local data = HttpService:JSONDecode(readfile("Inertia_" .. name .. ".json"))
		for _, control in ipairs(ControlRegistry) do
			if data[control.Name] then
				control.Set(data[control.Name])
			end
		end
		Notify("Config", "Loaded " .. name, 2)
	end
end

function InertiaUI.ConfigExists(name: string): boolean
	return isfile("Inertia_" .. name .. ".json")
end

-- Attach utilities to the main export
InertiaUI.AddPlayerList = Utilities.AddPlayerList
InertiaUI.AddConfigLoader = Utilities.AddConfigLoader

getgenv().InertiaUI = InertiaUI
return InertiaUI
