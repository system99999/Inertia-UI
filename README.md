[EX]
# ImGuiLib

Dear ImGui style UI framework for Roblox Luau. Windows, tabs, and controls only. No gameplay features.

Load `imgui_lib.lua` in an executor. It registers itself on `getgenv().ImGuiLib` (or `_G.ImGuiLib`).

## Create the library

One ScreenGui. Calling `new` again with the same name replaces the old gui.

```lua
local UI = getgenv().ImGuiLib.new({ Name = "MyMenu" })
```

## Window

A draggable framed panel. `Title` is the small header. `Size` and `Position` are UDim2.

```lua
local main = UI:Window({
	Title = "main",
	Size = UDim2.fromOffset(560, 640),
	Position = UDim2.fromOffset(40, 80),
})
```

## Tab

Text tab with an accent underline on the active one. The first tab is selected.

```lua
local legit = main:Tab("Legit")
main:Tab("Players")
main:Tab("Visuals")
main:Tab("Misc")
```

## Column

Half-width scrolling column inside a tab. Call it twice for the two-pane layout.

```lua
local left = legit:Column()
local right = legit:Column()
```

## Section

Labeled stack of controls. On a window with no tabs, call `Window:Section` instead of going through a column.

```lua
local aim = left:Section("Aim Assist")

local style = UI:Window({
	Title = "style",
	Size = UDim2.fromOffset(280, 360),
	Position = UDim2.fromOffset(620, 80),
})
local theme = style:Section("Theme")
```

## Checkbox

Boolean row. The callback runs on click and on creation. `:Side` sets the dim text on the right. `:Get` and `:Set` work on every control. Pass `true` as the second argument to `:Set` to skip the callback.

```lua
local enabled = aim:Checkbox("Enabled", true, function(on)
	print(on)
end)
enabled:Side("none")

print(enabled:Get())
enabled:Set(false)
enabled:Set(true, true) -- silent
```

## Slider

Numeric row. Label on the left, value on the right, accent fill on the track. `fmt` is a `string.format` pattern or a function that returns the readout. Leave `fmt` nil for one decimal place.

```lua
aim:Slider("Field Of View", 0, 180, 90, "%.0f", function(v)
	print(v)
end)

aim:Slider("Delay", 0, 200, 15, function(v)
	return string.format("%dms", math.floor(v + 0.5))
end)
```

## Dropdown

Full-width box with a `+` on the right. Click to open the list. Pass a label, or skip it and give the option list as the first argument.

```lua
aim:Dropdown("Hitboxes", { "Head", "Stomach", "Arms" }, "Head", function(v)
	print(v)
end)

aim:Dropdown({ "Static", "Dynamic" }, "Static", function(v)
	print(v)
end)
```

## Color

Label plus a color chip on the right. This does not open a picker. Push colors with `:Set`.

```lua
local accent = theme:Color("Menu Accent", Color3.fromRGB(154, 112, 214), function(c)
	print(c)
end)

accent:Set(Color3.fromRGB(120, 80, 200))
```

## Keybind

Display row only. Click the value, the next keyboard key is stored, Escape clears it back to `none`. Insert renders as `ins`. Nothing else listens to the key.

```lua
local menuKey = aim:Keybind("MENU KEY", Enum.KeyCode.Insert, function(key)
	print(key)
end)

print(menuKey:Get())
```

## Label

Dim single line. Not clickable.

```lua
aim:Label("read only line")
```

## Separator

One pixel horizontal rule.

```lua
aim:Separator()
```

## Toolbar

Centered strip of icon buttons. `Text` is the glyph. `Callback` is optional.

```lua
UI:Toolbar({
	{ Text = "H", Callback = function()
		main.Frame.Visible = not main.Frame.Visible
	end },
	{ Text = "P" },
})
```

## Table

Scrolling rows inside a window body. `SetRows` replaces the body. Clicking a row sets `Selected` to a zero-based index and updates the footer.

```lua
local players = UI:Window({
	Title = "players",
	Size = UDim2.fromOffset(300, 280),
	Position = UDim2.fromOffset(920, 80),
})

local rows = UI:Table(players.Body, { "name", "pos", "info" })
rows:SetRows({
	{ "name0", "pos0", "info0" },
	{ "name1", "pos1", "info1" },
})

print(rows.Selected) -- -1 until a row is clicked
```

## Destroy

Removes the ScreenGui.

```lua
UI:Destroy()
```
