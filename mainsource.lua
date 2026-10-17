--!strict
-- InertiaUI v4.0
-- A modular, type-safe ImGui framework for Roblox.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==============================================================================
-- MODULE: Types & Constants
-- ==============================================================================

type Color3 = typeof(Color3.new())
type UDim2 = typeof(UDim2.new())

export type ThemeConfig = {
	Radius: number,
	Accent: Color3,
	Background: Color3,
	Surface: Color3,
	Border: Color3,
	TextPrimary: Color3,
	TextSecondary: Color3,
}

export type Control = {
	Set: (self: any, value: any) -> (),
	Get: (self: any) -> any,
	OnChange: (self: any, callback: (value: any) -> ()) -> (),
	Destroy: (self: any) -> (),
}

-- ==============================================================================
-- MODULE: Theme Manager
-- ==============================================================================

local ThemeManager = {}
ThemeManager.__index = ThemeManager

local THEMES = {
	Rounded = {
		Radius = 6,
		Accent = Color3.fromRGB(139, 92, 246),
		Background = Color3.fromRGB(24, 24, 27),
		Surface = Color3.fromRGB(39, 39, 42),
		Border = Color3.fromRGB(63, 63, 70),
		TextPrimary = Color3.fromRGB(250, 250, 250),
		TextSecondary = Color3.fromRGB(161, 161, 170),
	},
	Square = {
		Radius = 0,
		Accent = Color3.fromRGB(16, 185, 129),
		Background = Color3.fromRGB(18, 18, 18),
		Surface = Color3.fromRGB(30, 30, 30),
		Border = Color3.fromRGB(50, 50, 50),
		TextPrimary = Color3.fromRGB(240, 240, 240),
		TextSecondary = Color3.fromRGB(140, 140, 140),
	},
}

function ThemeManager.new(defaultTheme: string)
	local self = setmetatable({
		_current = THEMES[defaultTheme] or THEMES.Rounded,
		_listeners = {},
	}, ThemeManager)
	return self
end

function ThemeManager:Get(): ThemeConfig
	return self._current
end

function ThemeManager:Set(themeName: string)
	local newTheme = THEMES[themeName]
	if not newTheme then return end
	
	self._current = newTheme
	for _, callback in ipairs(self._listeners) do
		task.spawn(callback, newTheme)
	end
end

function ThemeManager:Subscribe(callback: (theme: ThemeConfig) -> ())
	table.insert(self._listeners, callback)
end

-- ==============================================================================
-- MODULE: UI Primitives
-- ==============================================================================

local UI = {}

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
		CornerRadius = UDim.new(0, radius or 0),
	}, parent)
	return corner
end

function UI.Stroke(parent: Instance, color: Color3, thickness: number?): UIStroke
	local stroke = UI.Create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
	return stroke
end

-- ==============================================================================
-- MODULE: Controls
-- ==============================================================================

local Controls = {}

-- Checkbox
function Controls.Checkbox(parent: Frame, label: string, defaultValue: boolean, theme: ThemeManager): Control
	local container = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
	}, parent)

	local box = UI.Create("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 0, 0.5, -8),
		BackgroundColor3 = theme:Get().Surface,
	}, container)
	UI.Corner(box, theme:Get().Radius)
	UI.Stroke(box, theme:Get().Border)

	local indicator = UI.Create("Frame", {
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = theme:Get().Accent,
		Visible = defaultValue,
	}, box)
	UI.Corner(indicator, math.max(0, theme:Get().Radius - 2))

	local textLabel = UI.Create("TextLabel", {
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(24, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = theme:Get().TextPrimary,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, container)

	local state = { value = defaultValue, callbacks = {} }

	local function updateVisuals()
		indicator.Visible = state.value
		TweenService:Create(indicator, TweenInfo.new(0.15), {
			BackgroundTransparency = state.value and 0 or 1,
			Size = state.value and UDim2.new(1, -4, 1, -4) or UDim2.new(0, 0, 0, 0),
		}):Play()
	end

	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			state.value = not state.value
			updateVisuals()
			for _, cb in ipairs(state.callbacks) do cb(state.value) end
		end
	end)

	theme:Subscribe(function(newTheme)
		box.BackgroundColor3 = newTheme.Surface
		indicator.BackgroundColor3 = newTheme.Accent
		textLabel.TextColor3 = newTheme.TextPrimary
		UI.Stroke(box, newTheme.Border)
		box:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, newTheme.Radius)
		indicator:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, math.max(0, newTheme.Radius - 2))
	end)

	return {
		Set = function(_, val) state.value = val; updateVisuals() end,
		Get = function() return state.value end,
		OnChange = function(_, cb) table.insert(state.callbacks, cb) end,
		Destroy = function() container:Destroy() end,
	}
end

-- Slider
function Controls.Slider(parent: Frame, label: string, min: number, max: number, default: number, theme: ThemeManager): Control
	local container = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
	}, parent)

	local textLabel = UI.Create("TextLabel", {
		Size = UDim2.new(0.5, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = theme:Get().TextPrimary,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, container)

	local valueLabel = UI.Create("TextLabel", {
		Size = UDim2.new(0.5, 0, 0, 14),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(default),
		TextColor3 = theme:Get().TextSecondary,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, container)

	local track = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundColor3 = theme:Get().Surface,
	}, container)
	UI.Corner(track, 3)

	local fill = UI.Create("Frame", {
		Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = theme:Get().Accent,
	}, track)
	UI.Corner(fill, 3)

	local state = { value = default, callbacks = {} }
	local dragging = false

	local function updateFromInput(inputX: number)
		local trackPos = track.AbsolutePosition.X
		local trackSize = track.AbsoluteSize.X
		local ratio = math.clamp((inputX - trackPos) / trackSize, 0, 1)
		local newValue = math.floor(min + (max - min) * ratio)
		
		if newValue ~= state.value then
			state.value = newValue
			fill.Size = UDim2.new(ratio, 0, 1, 0)
			valueLabel.Text = tostring(newValue)
			for _, cb in ipairs(state.callbacks) do cb(newValue) end
		end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateFromInput(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromInput(input.Position.X)
		end
	end)

	theme:Subscribe(function(newTheme)
		track.BackgroundColor3 = newTheme.Surface
		fill.BackgroundColor3 = newTheme.Accent
		textLabel.TextColor3 = newTheme.TextPrimary
		valueLabel.TextColor3 = newTheme.TextSecondary
	end)

	return {
		Set = function(_, val) 
			state.value = val
			local ratio = (val - min) / (max - min)
			fill.Size = UDim2.new(ratio, 0, 1, 0)
			valueLabel.Text = tostring(val)
		end,
		Get = function() return state.value end,
		OnChange = function(_, cb) table.insert(state.callbacks, cb) end,
		Destroy = function() container:Destroy() end,
	}
end

-- ==============================================================================
-- MODULE: Window & Layout
-- ==============================================================================

local Window = {}
Window.__index = Window

function Window.new(title: string, theme: ThemeManager)
	local self = setmetatable({}, Window)
	self.Title = title
	self.Theme = theme
	self.Tabs = {}
	
	self.ScreenGui = UI.Create("ScreenGui", {
		Name = "InertiaUI_" .. title,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, PlayerGui)

	self.MainFrame = UI.Create("Frame", {
		Size = UDim2.fromOffset(500, 600),
		Position = UDim2.fromOffset(100, 100),
		BackgroundColor3 = theme:Get().Background,
		BorderSizePixel = 0,
	}, self.ScreenGui)
	UI.Corner(self.MainFrame, theme:Get().Radius)
	UI.Stroke(self.MainFrame, theme:Get().Border)

	-- Title Bar
	self.TitleBar = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = theme:Get().Surface,
	}, self.MainFrame)
	-- Only round top corners
	UI.Create("UICorner", {
		CornerRadius = UDim.new(0, theme:Get().Radius),
	}, self.TitleBar)

	UI.Create("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = theme:Get().TextPrimary,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, self.TitleBar)

	-- Dragging logic
	local dragStart, startPos
	self.TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragStart = input.Position
			startPos = self.MainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragStart = nil
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
			local delta = input.Position - dragStart
			self.MainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	-- Content Area
	self.Content = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 1, -32),
		Position = UDim2.new(0, 0, 0, 32),
		BackgroundTransparency = 1,
	}, self.MainFrame)

	return self
end

function Window:Tab(name: string)
	local tabContainer = UI.Create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = #self.Tabs == 0,
	}, self.Content)

	local scrollFrame = UI.Create("ScrollingFrame", {
		Size = UDim2.new(1, -20, 1, -20),
		Position = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = self.Theme:Get().Border,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	}, tabContainer)

	local listLayout = UI.Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scrollFrame)

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 16)
	end)

	table.insert(self.Tabs, { Name = name, Container = tabContainer, Scroll = scrollFrame })
	
	return {
		AddCheckbox = function(_, label, default) return Controls.Checkbox(scrollFrame, label, default, self.Theme) end,
		AddSlider = function(_, label, min, max, default) return Controls.Slider(scrollFrame, label, min, max, default, self.Theme) end,
	}
end

-- ==============================================================================
-- EXPORT
-- ==============================================================================

local InertiaUI = {}

function InertiaUI.Create(title: string, themeName: string?)
	local theme = ThemeManager.new(themeName or "Rounded")
	return Window.new(title, theme)
end

function InertiaUI.SetGlobalTheme(themeName: string)
	-- In a real app, you'd store the theme instance globally.
	-- For this example, we just demonstrate the API.
	print("Theme set to:", themeName)
end

return InertiaUI
