# InertiaUI v6.0 - Complete Technical Documentation

InertiaUI v6.0 is a production-grade, modular ImGui-style framework for Roblox Luau. It is engineered for high performance, utilizing an observer-based theme engine and decoupled state management. It includes specialized utilities for game manipulation scripts, ensuring a native, responsive experience in any executor environment.

---

## Table of Contents
1. [Installation & Initialization](#installation--initialization)
2. [Core Architecture](#core-architecture)
3. [Layout & Navigation](#layout--navigation)
4. [Controls Reference](#controls-reference)
5. [Cheat-Specific Utilities](#cheat-specific-utilities)
6. [Global Systems & Overlays](#global-systems--overlays)
7. [Master Example Breakdown](#master-example-breakdown)
8. [Advanced Developer Guide](#advanced-developer-guide)

---

## Installation & Initialization

Load the framework into your environment. It supports both global injection and standard ModuleScript requirements.

```lua
-- Executor Environment
local InertiaUI = getgenv().InertiaUI

-- ModuleScript Environment
local InertiaUI = require(script.Parent.InertiaUI)
```

### Creating the Root Window
The `Create` function initializes the primary `ScreenGui` and the main draggable frame.

```lua
-- Parameters: Title (string), Theme (string: "Rounded" or "Square")
local Menu = InertiaUI.Create("Main Menu", "Rounded")
```

---

## Core Architecture

### Observer-Based Theming
The UI does not rebuild when the theme changes. The `ThemeManager` holds the active color palette and corner radius. When `Menu:SetTheme()` is called, it pushes the new values to every subscribed UI element instantly.

### Decoupled State Management
Controls do not execute game logic. They maintain an internal state table and expose a `callbacks` array. Your script listens to these callbacks to bridge the UI with your actual code.

```lua
local slider = tab:AddSlider("FOV", 0, 180, 90)
slider.callbacks = {function(val) MyScript.FOV = val end}
```

---

## Layout & Navigation

The hierarchy is strictly enforced: **Window > Tabs > Sections > Controls**.

### Tabs
Tabs divide the UI into logical categories.

```lua
local CombatTab = Menu:Tab("Combat")
local VisualsTab = Menu:Tab("Visuals")
```

### Sections
Sections group related controls within a tab. They are collapsible by default.

```lua
local AimbotConfig = CombatTab:Section("Aimbot Configuration")
```

### Search & Filtering
A search bar is automatically generated at the top of the content area. Typing in it dynamically filters sections based on their names.

---

## Controls Reference

All controls return a state object. You can read the value using `:Get()`, force a value using `:Set(value)`, or append functions to the `callbacks` array.

### Checkbox
A boolean toggle. Supports tooltips and right-click context menus.

```lua
-- Parameters: Label, Default (bool), Tooltip (string?), ContextOptions (table?), ContextCallback (function?)
local aimbotEnabled = CombatTab:AddCheckbox(
    "Enable Aimbot", 
    false, 
    "Toggles the main aimbot calculation loop.", 
    {"Reset to Default", "Copy Value"}, 
    function(option)
        if option == "Reset to Default" then aimbotEnabled:Set(false) end
    end
)
```

### Slider
Numeric interpolation. Updates continuously while dragging.

```lua
-- Parameters: Label, Min, Max, Default, Suffix (string?), Tooltip (string?)
local fovSlider = CombatTab:AddSlider("Field of View", 10, 180, 90, "°", "Maximum angle the aimbot will track.")
fovSlider.callbacks = {function(val) print("FOV updated to:", val) end}
```

### Dropdown (Single Select)
Renders a true overlay list. Selecting an option closes the menu.

```lua
-- Parameters: Label, Options (table), DefaultIndex (number?)
local targetPart = CombatTab:AddDropdown("Target Part", {"Head", "Neck", "Torso", "Random"}, 1)
```

### Dropdown (Multi-Select)
Allows multiple selections. Returns a table of strings.

```lua
-- Parameters: Label, Options (table), Default (nil), IsMulti (boolean)
local checks = CombatTab:AddDropdown("Active Checks", {"Team Check", "Alive Check", "Wall Check"}, nil, true)
checks.callbacks = {function(val) print("Active:", table.concat(val, ", ")) end}
```

### Keybind
Captures keyboard/mouse input. Supports "Toggle" and "Hold" modes.

```lua
-- Parameters: Label, Default (Enum.KeyCode), Mode (string)
local aimKey = CombatTab:AddKeybind("Aimbind", Enum.KeyCode.MouseRightButton, "Hold")
```

### Text Input
Standard string entry. Fires callbacks when the Enter key is pressed.

```lua
-- Parameters: Label, Placeholder (string)
local hostnameInput = CombatTab:AddTextInput("Server Whitelist", "Enter IP or Hostname...")
```

### Color Picker
RGB and Hex input with a live preview box.

```lua
-- Parameters: Label, Default (Color3)
local boxColor = VisualsTab:AddColorPicker("Box Color", Color3.fromRGB(255, 0, 0))
```

### Button
Execution trigger. Does not hold state.

```lua
-- Parameters: Label, Callback (function)
VisualsTab:AddButton("Refresh ESP Cache", function()
    print("Cache refreshed")
end)
```

---

## Cheat-Specific Utilities

These functions are designed specifically for game manipulation scripts.

### Player List / Target Selector
Generates a scrollable list of all players in the server. Updates dynamically on `PlayerAdded` and `PlayerRemoving`.

```lua
-- Parameters: Tab/Section, Callback (function(Player))
InertiaUI.AddPlayerList(PlayersTab, function(player)
    print("Targeting:", player.Name)
    -- MyScript.Target = player
end)
```

### Config Loader & Saver
Provides a dropdown to load existing JSON configs and a button to save the current state.

```lua
-- Parameters: Tab/Section
InertiaUI.AddConfigLoader(SettingsTab)
```

---

## Global Systems & Overlays

### Tooltips
Pass a string as the `tooltip` parameter to any control. The framework automatically handles mouse tracking and positioning via the global `OverlayGui`.

### Context Menus (Right-Click)
Pass a table of strings and a callback function to the `contextOpts` and `contextCb` parameters (currently fully implemented on Checkboxes, easily extensible to others). It renders a global overlay menu.

### Notifications
Spawns a toast notification in the top-right corner.

```lua
-- Parameters: Title, Text, Duration (seconds)
Notify("System", "Configuration saved successfully.", 3)
```

### Window Controls
The TitleBar includes three functional buttons:
*   **Minimize (`_`)**: Collapses the content area, leaving only the title bar.
*   **Maximize (`□`)**: Expands the window to fill the screen. Clicking again restores the original size.
*   **Close (`×`)**: Destroys the `ScreenGui` entirely.

---

## Master Example Breakdown

The provided `Master Example` script is the definitive reference for implementing InertiaUI v6.0. It demonstrates the following architectural patterns:

1.  **Hierarchical Setup:** It initializes the Menu, creates four distinct Tabs, and populates them with Sections.
2.  **Advanced Control Wiring:** 
    *   The **Combat Tab** utilizes the Context Menu on the Aimbot Checkbox to demonstrate clipboard integration (`setclipboard`) and state resetting.
    *   The **Visuals Tab** chains Color Pickers to the `callbacks` array to show real-time color logging.
3.  **Utility Integration:** It calls `InertiaUI.AddPlayerList` on the Players tab, passing an anonymous function that triggers a `Notify` toast when a target is selected.
4.  **Theme Switching:** The Settings tab includes a Dropdown that calls `Menu:SetTheme()` dynamically, proving the observer engine works without UI lag.

---

## Advanced Developer Guide

### Extending the Config System
By default, `InertiaUI.SaveConfig` iterates through the `ControlRegistry`. If you have script-specific data (like window coordinates or custom variables) that you want to persist, modify the `SaveConfig` function in the source:

```lua
function InertiaUI.SaveConfig(name)
    local data = {}
    for _, control in ipairs(ControlRegistry) do
        data[control.Name] = control.Get()
    end
    
    -- Inject custom metadata
    data["_Meta"] = {
        WindowPos = Menu.Main.Position,
        CustomVar = MyScript.Variable
    }
    
    writefile("Inertia_" .. name .. ".json", HttpService:JSONEncode(data))
end
```

### Building Custom Controls
To add a new control type, follow the established blueprint in the `Controls` module:
1. Create a container `Frame`.
2. Build visual elements using `UI.Create`, `UI.Corner`, and `UI.Stroke`.
3. Define a state table with a `callbacks` array.
4. Hook `UserInputService` or `InputBegan` events to modify the state.
5. Call `RegisterControl()` to ensure it integrates with the Config system.

```lua
function Controls.ToggleSwitch(parent, label, default)
    local container = UI.Create("Frame", {Size = UDim2.new(1,0,0,24), BackgroundTransparency = 1}, parent)
    -- Build UI...
    local state = {value = default, callbacks = {}}
    -- Hook input...
    RegisterControl({Name = label, Type = "ToggleSwitch", Get = function() return state.value end, Set = function(v) state.value = v end})
    return state
end
```
