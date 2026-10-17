-- InertiaUI v6.0 - Master Example Script
-- This script initializes the UI and populates it with every available control and utility.

local UI = getgenv().InertiaUI

-- 1. Initialize the main window
local Menu = UI.Create("Inertia UI - Master Example", "Rounded")

-- 2. Create Tabs
local CombatTab = Menu:Tab("Combat")
local VisualsTab = Menu:Tab("Visuals")
local PlayersTab = Menu:Tab("Players")
local SettingsTab = Menu:Tab("Settings")

-- ==============================================================================
-- COMBAT TAB
-- ==============================================================================

-- Section for Aimbot
CombatTab:Section("Aimbot Configuration")

-- Checkbox with Tooltip and Context Menu
local aimbotEnabled = CombatTab:AddCheckbox(
    "Enable Aimbot", 
    false, 
    "Toggles the main aimbot calculation loop.", 
    {"Reset to Default", "Copy Value"}, 
    function(option)
        if option == "Reset to Default" then aimbotEnabled:Set(false) Notify("Context", "Reset to default", 2) end
        if option == "Copy Value" then setclipboard(tostring(aimbotEnabled:Get())) Notify("Context", "Copied to clipboard", 2) end
    end
)

-- Sliders with Suffixes and Tooltips
local fovSlider = CombatTab:AddSlider("Field of View", 10, 180, 90, "°", "Maximum angle the aimbot will track.")
fovSlider.callbacks = {function(val) print("FOV updated to:", val) end}

local smoothSlider = CombatTab:AddSlider("Smoothing", 0, 100, 15, "%", "Higher values make the aim slower.")
smoothSlider.callbacks = {function(val) print("Smoothing updated to:", val) end}

-- Single Select Dropdown
local targetPart = CombatTab:AddDropdown("Target Part", {"Head", "Neck", "Torso", "Random"}, 1)
targetPart.callbacks = {function(val) print("Targeting:", val) end}

-- Multi-Select Dropdown
local checks = CombatTab:AddDropdown("Active Checks", {"Team Check", "Alive Check", "Wall Check", "Friend Check"}, nil, true)
checks.callbacks = {function(val) print("Active checks:", table.concat(val, ", ")) end}

-- Keybinds (Hold and Toggle modes)
local aimKey = CombatTab:AddKeybind("Aimbind", Enum.KeyCode.MouseRightButton, "Hold")
aimKey.callbacks = {function(key, mode) print("Aimbind activated:", key.Name, mode) end}

local silentKey = CombatTab:AddKeybind("Silent Aim Toggle", Enum.KeyCode.Z, "Toggle")
silentKey.callbacks = {function(key, mode) 
    Notify("Silent Aim", mode == "Toggle" and "Toggled" or "Active", 2) 
end}

-- Text Input
local hostnameInput = CombatTab:AddTextInput("Server Whitelist", "Enter IP or Hostname...")
hostnameInput.callbacks = {function(text) print("Whitelist updated:", text) end}

-- ==============================================================================
-- VISUALS TAB
-- ==============================================================================

VisualsTab:Section("ESP Settings")

local espEnabled = VisualsTab:AddCheckbox("Enable ESP", true, "Renders player outlines and names.")

-- Color Pickers
local boxColor = VisualsTab:AddColorPicker("Box Color", Color3.fromRGB(255, 0, 0))
boxColor.callbacks = {function(color) print("Box color changed to:", color) end}

local nameColor = VisualsTab:AddColorPicker("Name Color", Color3.fromRGB(255, 255, 255))
nameColor.callbacks = {function(color) print("Name color changed to:", color) end}

local distSlider = VisualsTab:AddSlider("Max Render Distance", 100, 2000, 500, " studs")
distSlider.callbacks = {function(val) print("Render distance:", val) end}

-- Button
VisualsTab:AddButton("Refresh ESP Cache", function()
    Notify("Visuals", "ESP cache cleared and rebuilt.", 2)
end)

-- ==============================================================================
-- PLAYERS TAB
-- ==============================================================================

PlayersTab:Section("Server Players")

-- Cheat Utility: Player List
UI.AddPlayerList(PlayersTab, function(player)
    Notify("Targeting", "Locking onto " .. player.DisplayName, 2)
    -- Example logic:
    -- MyScript.Target = player
end)

PlayersTab:Section("Target Notes")

-- Text Input for notes
local notesInput = PlayersTab:AddTextInput("Target Notes", "Write notes about this player...")
notesInput.callbacks = {function(text) print("Notes saved:", text) end}

-- ==============================================================================
-- SETTINGS TAB
-- ==============================================================================

SettingsTab:Section("Menu Configuration")

-- Theme Switcher Dropdown
local themeDropdown = SettingsTab:AddDropdown("UI Theme", {"Rounded", "Square"}, 1)
themeDropdown.callbacks = {function(themeName)
    Menu:SetTheme(themeName)
    Notify("Theme", "Switched to " .. themeName, 2)
end}

-- Cheat Utility: Config Loader
UI.AddConfigLoader(SettingsTab)

SettingsTab:Section("Actions")

-- Action Buttons
SettingsTab:AddButton("Reset All Settings", function()
    fovSlider:Set(90)
    smoothSlider:Set(15)
    aimbotEnabled:Set(false)
    Notify("Settings", "All values reset to defaults.", 2)
end)

SettingsTab:AddButton("Close Menu", function()
    Menu.Gui:Destroy()
    Notify("System", "Menu closed.", 2)
end)

-- ==============================================================================
-- GLOBAL NOTIFICATION TEST
-- ==============================================================================
task.wait(1)
Notify("InertiaUI", "Master Example loaded successfully.", 3)
