# InertiaUI Framework Documentation

InertiaUI is a modular, type-safe ImGui-style UI framework for Roblox Luau. It is designed for performance, extensibility, and clean architecture, utilizing an observer pattern for live theme updates and decoupled state management for all controls.

## Table of Contents
- [Table of Constants & API Reference](#table-of-constants--api-reference)
- [Installation & Setup](#installation--setup)
- [Base Menu & Layout](#base-menu--layout)
- [Controls](#controls)
- [State Management](#state-management)
- [Theming & Personalization](#theming--personalization)
- [Configuration System](#configuration-system)
- [Built-in Global Features](#built-in-global-features)
- [Advanced Developer Documentation](#advanced-developer-documentation)

---

## Table of Constants & API Reference

### Global Functions
| Constant / Function | Type | Description |
| :--- | :--- | :--- |
| `InertiaUI.Create(title, theme)` | `Function` | Initializes a new UI window. Returns a `Window` object. |
| `InertiaUI.SaveConfig(name)` | `Function` | Serializes all control states to a JSON file. |
| `InertiaUI.LoadConfig(name)` | `Function` | Reads a JSON file and applies values to controls. |
| `Notify(title, text, duration)` | `Function` | Spawns a toast notification in the top-right corner. |

### Theme Properties
| Constant | Type | Default (Rounded) | Default (Square) | Description |
| :--- | :--- | :--- | :--- | :--- |
| `Radius` | `number` | `6` | `0` | Corner radius for all UI elements. |
| `Accent` | `Color3` | `139, 92, 246` | `16, 185, 129` | Primary highlight color. |
| `Background` | `Color3` | `24, 24, 27` | `18, 18, 18` | Main window background. |
| `Surface` | `Color3` | `39, 39, 42` | `30, 30, 30` | Title bars, inputs, and elevated elements. |
| `Border` | `Color3` | `63, 63, 70` | `50, 50, 50` | Stroke and border colors. |
| `Text1` | `Color3` | `250, 250, 250` | `240, 240, 240` | Primary text color. |
| `Text2` | `Color3` | `161, 161, 170` | `140, 140, 140` | Secondary/disabled text color. |

### Control Methods
| Method | Returns | Description |
| :--- | :--- | :--- |
| `:Get()` | `any` | Returns the current internal value of the control. |
| `:Set(value)` | `void` | Forces the control to a specific value and updates UI. |
| `:OnChange(callback)`| `void` | Appends a function to the control's callback array. |
| `:Destroy()` | `void` | Removes the control instance from the UI. |

---

## Installation & Setup

Load the script in your executor environment or require it as a ModuleScript.

```lua
-- Executor environment
local InertiaUI = getgenv().InertiaUI

-- ModuleScript environment
local InertiaUI = require(script.Parent.InertiaUI)
```

---

## Base Menu & Layout

### Creating a Window
The `Create` function initializes the root `ScreenGui` and the main draggable frame.

```lua
-- Parameters: Title (string), Theme Name ("Rounded" or "Square")
local Menu = InertiaUI.Create("Main Menu", "Rounded")
```

### Tabs and Sections
The UI is organized hierarchically. Windows contain Tabs; Tabs contain Sections.

```lua
-- Add tabs to the root window
local CombatTab = Menu:Tab("Combat")
local VisualsTab = Menu:Tab("Visuals")
local SettingsTab = Menu:Tab("Settings")

-- Create sections within tabs to group controls
local AimbotSection = CombatTab:Section("Aimbot Configuration")
local ESPSection = VisualsTab:Section("Player ESP")
```

---

## Controls

Controls are added directly to a `Tab` or a `Section`. They return a state object used for reading, writing, and listening to data.

### Checkbox
Boolean toggle.
```lua
local Enabled = AimbotSection:AddCheckbox("Enable Aimbot", false)

Enabled:OnChange(function(value)
    print("Aimbot state:", value)
end)

-- Manual override
Enabled:Set(true)
local state = Enabled:Get()
```

### Slider
Numeric interpolation between a minimum and maximum bound.
```lua
-- Parameters: Label, Min, Max, Default
local FOV = AimbotSection:AddSlider("Field of View", 10, 180, 90)

FOV:OnChange(function(value)
    print("Current FOV:", value)
end)

FOV:Set(120)
local val = FOV:Get()
```

### Dropdown
Selection from a predefined array of strings. Renders as an overlay.
```lua
-- Parameters: Label, Options (array), Default Index (optional)
local Target = AimbotSection:AddDropdown("Target Part", {"Head", "Torso", "Random"}, 1)

Target:OnChange(function(value)
    print("Targeting:", value)
end)

Target:Set("Head")
```

### Multi-Select Dropdown
Allows selecting multiple options from an array. Returns a table of strings.
```lua
-- Parameters: Label, Options, Default (nil), isMulti (boolean)
local ESPElements = ESPSection:AddDropdown("ESP Elements", {"Box", "Name", "Health"}, nil, true)

ESPElements:OnChange(function(values)
    -- values is a table, e.g., {"Box", "Health"}
    print("Active ESP:", table.concat(values, ", "))
end)
```

### Button
Execution trigger. Does not hold state.
```lua
local ResetBtn = SettingsTab:AddButton("Reset to Defaults")

ResetBtn:OnClick(function()
    print("Settings reset")
end)
```

### Keybind
Captures keyboard or mouse input. Supports "Toggle", "Hold", and "Always" modes.
```lua
-- Parameters: Label, Default KeyCode, Mode
local AimKey = AimbotSection:AddKeybind("Aimbind", Enum.KeyCode.MouseRightButton, "Hold")

AimKey:OnBind(function(keyCode, mode)
    print("Bound to:", keyCode.Name, "Mode:", mode)
end)

AimKey:Set(Enum.KeyCode.E)
```

### Text Input
Standard text field for string entry.
```lua
-- Parameters: Label, Placeholder text
local ServerIP = SettingsTab:AddTextInput("Server Hostname", "Enter IP address...")

ServerIP:OnSubmit(function(text)
    print("Submitted:", text)
end)

ServerIP:Set("192.168.1.1")
```

### Color Picker
RGB and Hex input with a live preview.
```lua
-- Parameters: Label, Default Color3
local AccentColor = SettingsTab:AddColorPicker("Menu Accent", Color3.fromRGB(139, 92, 246))

AccentColor:OnChange(function(color)
    print("Selected color:", color)
end)
```

---

## State Management

Every control returns a state table. This separates the UI rendering from your script logic.

### The State Object
```lua
local state = {
    value = defaultValue,
    callbacks = {},
    Get = function() return state.value end,
    Set = function(v) state.value = v; -- update UI end,
    OnChange = function(cb) table.insert(state.callbacks, cb) end
}
```

### Bridging to Script Logic
```lua
local fovSlider = AimbotSection:AddSlider("FOV", 10, 180, 90)

-- Method 1: Using the callback
fovSlider:OnChange(function(val)
    MyScript.Settings.FOV = val
end)

-- Method 2: Polling the value in a loop
task.spawn(function()
    while true do
        MyScript.Settings.FOV = fovSlider:Get()
        task.wait(0.1)
    end
end)
```

---

## Theming & Personalization

The framework uses an observer pattern. Modifying the theme object updates all subscribed UI elements instantly without rebuilding the DOM.

### Switching Base Themes
```lua
Menu:SetTheme("Square") -- Sharp corners, green/dark palette
Menu:SetTheme("Rounded") -- Rounded corners, purple palette
```

### Live Color Modification
```lua
local ActiveTheme = Menu:GetTheme()

-- Modify the table directly
ActiveTheme.Accent = Color3.fromRGB(255, 0, 0)
ActiveTheme.Background = Color3.fromRGB(10, 10, 10)

-- The UI updates automatically via the observer pattern. 
-- If a specific element doesn't update, force a refresh:
Menu:RefreshTheme() 
```

---

## Configuration System

Requires an executor with file system access (`writefile`, `readfile`, `isfile`).

### Saving and Loading
```lua
-- Save current state of all registered controls
InertiaUI.SaveConfig("legit_config")

-- Load a saved config
InertiaUI.LoadConfig("legit_config")

-- Check existence before loading
if InertiaUI.ConfigExists("legit_config") then
    InertiaUI.LoadConfig("legit_config")
end
```

---

## Built-in Global Features

### Watermark
A draggable overlay in the top-left corner. Displays real-time FPS and network ping.
```lua
-- The watermark is initialized automatically when the first Window is created.
-- To move it programmatically:
-- (Access the internal WMFrame if exposed, or rely on user dragging)
```

### Search Bar
Located at the top of the content area. Filters sections by name in real-time.
```lua
-- No configuration required. Type in the box to hide non-matching sections.
```

### Minimize & Resize
- **Minimize:** Click the `_` icon in the top-right title bar to collapse the window to the title bar only.
- **Resize:** Drag the bottom-right corner of the window frame. Minimum size is clamped at 300x200.

### Notifications
```lua
-- Parameters: Title, Text, Duration (seconds)
Notify("System", "Configuration saved successfully.", 3)
```

---

## Advanced Developer Documentation

### Internal Architecture
The UI is decoupled from game logic. The `ThemeManager` holds the global state. When `ThemeManager:Set()` is called, it iterates through `_themeListeners` and pushes the new theme data to every UI element that subscribed to it.

### Building Custom Controls
To add a new control type, follow this blueprint:

1. Create a container `Frame`.
2. Build visual elements using `UI.Create`, `UI.Corner`, and `UI.Stroke`.
3. Define a state table with a `callbacks` array.
4. Hook `UserInputService` or `InputBegan` events to modify the state.
5. Subscribe to `ThemeManager` to update colors dynamically.
6. Register the control so it integrates with the Config system.

```lua
function Controls.CustomControl(parent, label, default)
    local container = UI.Create("Frame", {Size=UDim2.new(1,0,0,24), BackgroundTransparency=1}, parent)
    
    -- Build UI...
    local state = {value = default, callbacks = {}}
    
    -- Hook input...
    container.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            state.value = not state.value
            for _, cb in ipairs(state.callbacks) do cb(state.value) end
        end
    end)
    
    -- Subscribe to theme
    ThemeManager:Subscribe(function(t)
        -- Update colors here
    end)
    
    -- Register for Config
    RegisterControl({
        Name = label, 
        Type = "CustomControl", 
        Get = function() return state.value end, 
        Set = function(v) state.value = v end
    })
    
    return state
end
```

### Overlay Systems (Tooltips & Context Menus)

**Tooltips:**
The `TooltipGui` is hidden by default. Hook it to any element's mouse events:
```lua
myElement.MouseEnter:Connect(function()
    TooltipText.Text = "Tooltip text here."
    TooltipFrame.Visible = true
end)
myElement.MouseLeave:Connect(function()
    TooltipFrame.Visible = false
end)
```

**Context Menus (Right-Click):**
The `ContextGui` acts as a dynamic container.
```lua
myElement.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then
        -- Clear old options
        for _, child in ipairs(ContextFrame:GetChildren()) do 
            if child:IsA("TextButton") then child:Destroy() end 
        end
        
        -- Add new options
        local btn = UI.Create("TextButton", {Text="Option 1", BackgroundTransparency=1}, ContextFrame)
        btn.MouseButton1Click:Connect(function() print("Clicked"); ContextFrame.Visible = false end)
        
        ContextFrame.Size = UDim2.fromOffset(120, 22)
        ContextFrame.Position = UDim2.fromOffset(i.Position.X, i.Position.Y)
        ContextFrame.Visible = true
    end
end)
```

### Extending the Config System
To save custom data (like window position) alongside control states, modify the `InertiaUI.SaveConfig` function:

```lua
function InertiaUI.SaveConfig(name)
    local data = {}
    for _, c in ipairs(ControlRegistry) do data[c.Name] = c.Get() end
    
    -- Inject custom metadata
    data["_Meta"] = {
        WindowPos = Menu.Main.Position,
        Theme = "Rounded"
    }
    
    writefile("Inertia_"..name..".json", HttpService:JSONEncode(data))
end
```
