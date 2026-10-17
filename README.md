# InertiaUI Documentation

This is a breakdown of how the framework is structured, how to initialize it, and how to use every control and feature it provides. The goal here is to give you a complete understanding of the architecture so you can integrate it into your scripts without guessing how the state management works.

## Initialization and Base Window

The framework exposes a single global table when loaded. Depending on your environment, you will either pull it from the global environment or require it as a module.

```lua
-- Executor environment
local InertiaUI = getgenv().InertiaUI

-- ModuleScript environment
local InertiaUI = require(script.InertiaUI)
```

To start building the interface, you need to create a Window. This acts as the root container for everything else. The second argument determines the base aesthetic, specifically the corner radius and default color palette.

```lua
-- Creates a 500x600 window with rounded corners and the default purple theme
local Menu = InertiaUI.Create("Main Menu", "Rounded")

-- Creates the same window but with sharp, squared corners and a green/dark theme
local Menu = InertiaUI.Create("Main Menu", "Square")
```

## Layout: Tabs and Sections

The UI is organized hierarchically. A Window contains Tabs, and Tabs contain Sections. Sections are just visual groupings to keep controls organized; they don't hold complex logic themselves.

```lua
-- Add tabs to the root window
local CombatTab = Menu:Tab("Combat")
local VisualsTab = Menu:Tab("Visuals")
local SettingsTab = Menu:Tab("Settings")

-- Create sections within those tabs to group related features
local AimbotSection = CombatTab:Section("Aimbot Configuration")
local TriggerbotSection = CombatTab:Section("Triggerbot")
local ESPSection = VisualsTab:Section("Player ESP")
```

## Controls

Every control returns a state object. This object has methods to read the current value, force a value, and listen for changes. This separation keeps the UI rendering decoupled from your actual script logic.

### Checkbox

Used for boolean toggles. It takes a label and a default boolean state.

```lua
local AimbotEnabled = AimbotSection:AddCheckbox("Enable Aimbot", false)

-- The OnChange callback fires every time the user clicks the box.
-- 'value' is a boolean.
AimbotEnabled:OnChange(function(value)
    print("Aimbot state changed to:", value)
    -- Hook this into your actual script logic
    -- AimbotModule.Enabled = value 
end)

-- You can also read or force the state programmatically
local currentState = AimbotEnabled:Get() -- Returns true or false
AimbotEnabled:Set(true) -- Forces the UI and internal state to true
```

### Slider

Handles numeric interpolation between a minimum and maximum bound. The framework handles the mouse drag math, clamping, and visual updates internally.

```lua
-- Parameters: Label, Min, Max, Default Value
local FOVSlider = AimbotSection:AddSlider("Field of View", 10, 180, 90)

-- Fires continuously while the user is dragging the slider.
-- 'value' is a number.
FOVSlider:OnChange(function(value)
    -- Update your internal variables in real-time
    -- AimbotModule.Settings.FOV = value
    -- FOVCircle.Size = UDim2.fromOffset(value * 2, value * 2)
end)

local currentFOV = FOVSlider:Get() -- Returns 90
FOVSlider:Set(120) -- Snaps the slider to 120
```

### Dropdown

Provides a selection from a predefined array of strings. It handles the overlay rendering so it doesn't push other UI elements down when opened.

```lua
-- Parameters: Label, Array of options, Default index (optional)
local TargetPart = AimbotSection:AddDropdown("Target Part", {"Head", "Torso", "Random"}, 1)

-- Fires when the user selects a new option. 'value' is the string they picked.
TargetPart:OnChange(function(value)
    print("Now targeting:", value)
end)

local currentTarget = TargetPart:Get() -- Returns "Head"
TargetPart:Set("Torso") -- Forces the dropdown to display and select "Torso"
```

### Button

A simple execution trigger. It doesn't hold state; it just fires a callback when clicked.

```lua
local ResetButton = SettingsTab:AddButton("Reset to Defaults")

-- Fires once per click.
ResetButton:OnClick(function()
    print("Resetting configuration...")
    -- Clear your internal tables or reload defaults here
end)
```

### Keybind

Captures keyboard or mouse input. It supports different activation modes (Toggle, Hold, Always) which you can define in your own logic based on what the user sets.

```lua
-- Parameters: Label, Default KeyCode, Activation Mode
local AimKey = AimbotSection:AddKeybind("Aimbind", Enum.KeyCode.MouseRightButton, "Hold")

-- Fires when the user successfully binds a new key.
AimKey:OnBind(function(keyCode, mode)
    print("Keybind updated to:", keyCode.Name, "Mode:", mode)
end)

local boundKey = AimKey:Get() -- Returns Enum.KeyCode.MouseRightButton
AimKey:Set(Enum.KeyCode.E) -- Changes the bound key to 'E'
```

### Text Input

A standard text field for string entry. It handles focus states and clears the placeholder text when the user clicks inside.

```lua
-- Parameters: Label, Placeholder text
local ServerIP = SettingsTab:AddTextInput("Server Hostname", "Enter IP address...")

-- Fires when the user presses Enter or clicks outside the box (loses focus).
ServerIP:OnSubmit(function(text)
    print("User submitted:", text)
end)

local currentText = ServerIP:Get() -- Returns the string inside the box
ServerIP:Set("192.168.1.1") -- Programmatically sets the text
```

## Theming and Personalization

The framework uses an observer pattern for its theme engine. When you change a theme property, the UI doesn't just rebuild; it listens for the change and updates the specific instances in real-time. This is what allows for live personalization without lag.

### Switching Base Themes

You can swap between the predefined themes instantly.

```lua
Menu:SetTheme("Square") -- Switches to sharp corners and the green/dark palette
Menu:SetTheme("Rounded") -- Switches back to rounded corners and purple palette
```

### Modifying Colors Live

If you want to let the user pick their own colors, you can modify the active theme object directly and force a refresh.

```lua
-- Get the current theme table
local ActiveTheme = Menu:GetTheme()

-- Change the accent color to red
ActiveTheme.Accent = Color3.fromRGB(255, 0, 0)

-- Change the background color
ActiveTheme.Background = Color3.fromRGB(10, 10, 10)

-- Tell the UI to redraw all elements with the new values
Menu:RefreshTheme()
```

## Configuration System

The framework includes a built-in serialization system to save and load the state of all controls. This requires an executor that supports the `writefile` and `readfile` functions. It converts the state of every registered control into a JSON string and writes it to the file system.

### Saving and Loading

```lua
-- Saves the current state of every control in the menu to a file named "legit_config.json"
Menu:SaveConfig("legit_config")

-- Reads "legit_config.json" and applies the saved values to all matching controls
Menu:LoadConfig("legit_config")
```

### Checking Existence

It is good practice to check if a config exists before trying to load it, usually on script startup.

```lua
if Menu:ConfigExists("legit_config") then
    Menu:LoadConfig("legit_config")
else
    print("No saved config found, using default values.")
end
```

## Architecture Notes

The code is structured to keep the UI layer completely separate from your game logic. The controls don't know what an "Aimbot" is; they only know they hold a boolean or a number. 

When you use `:OnChange()`, you are bridging the gap between the UI state and your script's internal state. This design prevents the UI from breaking if you change how your actual hack or script works under the hood. You just update the callback logic, and the UI remains stable.
