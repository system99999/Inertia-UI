

# InertiaUI

A modular, type-safe ImGui framework for Roblox Luau. Designed for performance, extensibility, and clean architecture.

---

## Table of Contents
- [Installation & Setup](#installation--setup)
- [Base Menu Initialization](#base-menu-initialization)
- [Tabs & Sections](#tabs--sections)
- [Controls](#controls)
  - [Checkbox](#checkbox)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [Button](#button)
  - [Keybind](#keybind)
  - [Text Input](#text-input)
- [Theming & Personalization](#theming--personalization)
- [Configuration System](#configuration-system)
- [API Reference](#api-reference)

---

## Installation & Setup

1. Place `source.lua` in your executor's script environment or require it via a module script.
2. Ensure your executor supports `getgenv()` or standard Luau module loading.

```lua
-- If using an executor with getgenv:
local InertiaUI = getgenv().InertiaUI

-- If using a ModuleScript:
local InertiaUI = require(script.Parent.InertiaUI)
```

---

## Base Menu Initialization

To create the main menu window, call `InertiaUI.Create()`. This returns a Window object that serves as the root of your UI.

```lua
-- Create a new window with the default "Rounded" theme
local Menu = InertiaUI.Create("Main Menu", "Rounded")

-- Or, create with the "Square" theme
local Menu = InertiaUI.Create("Main Menu", "Square")
```

---

## Tabs & Sections

Organize your UI using Tabs. Each tab acts as a container for your controls.

```lua
-- Add a new tab to the menu
local CombatTab = Menu:Tab("Combat")
local VisualsTab = Menu:Tab("Visuals")
local SettingsTab = Menu:Tab("Settings")

-- Add a section to group related controls (Optional but recommended)
local AimbotSection = CombatTab:Section("Aimbot Settings")
local ESPSection = VisualsTab:Section("Player ESP")
```

---

## Controls

All controls are added directly to a Tab or a Section. They return a Control object that allows you to read, write, and listen to state changes.

### Checkbox

A boolean toggle.

```lua
local aimbotEnabled = CombatTab:AddCheckbox("Enable Aimbot", false)

-- Listen for changes
aimbotEnabled:OnChange(function(value)
    print("Aimbot is now:", value)
end)

-- Get or set the value programmatically
local currentState = aimbotEnabled:Get() -- Returns boolean
aimbotEnabled:Set(true) -- Forces the checkbox to true
```

### Slider

A numeric value selector with a defined minimum and maximum.

```lua
local fovSlider = CombatTab:AddSlider("Field of View", 10, 180, 90)

-- Listen for changes
fovSlider:OnChange(function(value)
    print("Current FOV:", value)
end)

-- Get or set the value
local currentFOV = fovSlider:Get() -- Returns number
fovSlider:Set(120) -- Forces slider to 120
```

### Dropdown

A selection menu from a list of options.

```lua
local targetPart = CombatTab:AddDropdown("Target Part", {"Head", "Torso", "Random"})

-- Listen for changes
targetPart:OnChange(function(value)
    print("Targeting:", value)
end)

-- Get or set the value
local currentTarget = targetPart:Get() -- Returns string
targetPart:Set("Head") -- Forces selection to "Head"
```

### Button

A simple clickable action trigger.

```lua
local resetButton = SettingsTab:AddButton("Reset Settings")

-- Listen for clicks
resetButton:OnClick(function()
    print("Settings reset!")
    -- Add your reset logic here
end)
```

### Keybind

A keyboard input catcher. Supports Toggle, Hold, and Always modes.

```lua
local aimKey = CombatTab:AddKeybind("Aimbind", Enum.KeyCode.MouseRightButton, "Hold")

-- Listen for key changes
aimKey:OnBind(function(keyCode, mode)
    print("Bound to:", keyCode.Name, "Mode:", mode)
end)

-- Get or set the keybind
local currentKey = aimKey:Get() -- Returns Enum.KeyCode
aimKey:Set(Enum.KeyCode.E) -- Changes keybind to 'E'
```

### Text Input

A text field for user input.

```lua
local hostnameInput = SettingsTab:AddTextInput("Server Hostname", "Enter IP...")

-- Listen for text submission (Enter key)
hostnameInput:OnSubmit(function(text)
    print("Connecting to:", text)
end)

-- Get or set the text
local currentText = hostnameInput:Get() -- Returns string
hostnameInput:Set("192.168.1.1") -- Sets the text field
```

---

## Theming & Personalization

InertiaUI is built with a reactive Theme Engine. Users can personalize the menu by switching themes or modifying the theme properties directly.

### Switching Themes

The library ships with two base themes: `Rounded` and `Square`.

```lua
-- Switch the entire UI to Square mode
Menu:SetTheme("Square")

-- Switch back to Rounded
Menu:SetTheme("Rounded")
```

### Customizing Theme Colors

You can modify the active theme's colors on the fly. The UI will update instantly.

```lua
local currentTheme = Menu:GetTheme()

-- Change the accent color to red
currentTheme.Accent = Color3.fromRGB(255, 0, 0)

-- Change the background color
currentTheme.Background = Color3.fromRGB(10, 10, 10)

-- Force the UI to redraw with new colors
Menu:RefreshTheme()
```

### Allowing User Personalization

If you want to expose theme settings to the end-user, add controls that modify the theme object:

```lua
local themeTab = Menu:Tab("Personalize")

themeTab:AddButton("Switch to Square", function()
    Menu:SetTheme("Square")
end)

themeTab:AddButton("Switch to Rounded", function()
    Menu:SetTheme("Rounded")
end)

themeTab:AddColorPicker("Accent Color", Menu:GetTheme().Accent, function(newColor)
    Menu:GetTheme().Accent = newColor
    Menu:RefreshTheme()
end)
```

---

## Configuration System

Save and load user preferences using the built-in JSON config system. This requires an executor that supports `writefile` and `readfile`.

### Saving a Config

```lua
-- Save the current state of all controls to a file
Menu:SaveConfig("my_legit_config")
```

### Loading a Config

```lua
-- Load a previously saved config
Menu:LoadConfig("my_legit_config")
```

### Checking if a Config Exists

```lua
if Menu:ConfigExists("my_legit_config") then
    Menu:LoadConfig("my_legit_config")
else
    print("Config not found, using defaults.")
end
```

---

## API Reference

### `InertiaUI`
| Method | Description |
| :--- | :--- |
| `Create(title: string, theme: string?) -> Window` | Initializes a new UI window. |

### `Window`
| Method | Description |
| :--- | :--- |
| `Tab(name: string) -> Tab` | Creates a new tab. |
| `SetTheme(name: string)` | Switches the global theme. |
| `GetTheme() -> ThemeConfig` | Returns the current theme object. |
| `RefreshTheme()` | Forces a UI redraw with current theme colors. |
| `SaveConfig(name: string)` | Saves control states to a JSON file. |
| `LoadConfig(name: string)` | Loads control states from a JSON file. |
| `ConfigExists(name: string) -> boolean` | Checks if a config file exists. |

### `Tab` / `Section`
| Method | Description | Returns |
| :--- | :--- | :--- |
| `AddCheckbox(label, default) -> Control` | Adds a boolean toggle. | `Control` |
| `AddSlider(label, min, max, default) -> Control` | Adds a numeric slider. | `Control` |
| `AddDropdown(label, options) -> Control` | Adds a selection list. | `Control` |
| `AddButton(label, callback) -> Control` | Adds a clickable button. | `Control` |
| `AddKeybind(label, default, mode) -> Control`| Adds a keybind catcher. | `Control` |
| `AddTextInput(label, placeholder) -> Control`| Adds a text input field. | `Control` |

### `Control`
| Method | Description |
| :--- | :--- |
| `Get() -> any` | Returns the current value of the control. |
| `Set(value: any)` | Forces the control to a specific value. |
| `OnChange(callback)` | Fires when the user changes the value. |
| `Destroy()` | Removes the control from the UI. |
