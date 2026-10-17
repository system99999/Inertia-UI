-- example menu. load imgui_lib.lua first, then paste this.
-- every control is on screen. nothing here is a feature.

local Lib = (typeof(getgenv) == "function" and getgenv().ImGuiLib) or _G.ImGuiLib
assert(Lib, "load imgui_lib.lua first")

local UI = Lib.new({ Name = "DearImGuiClone" })

local main = UI:Window({
	Title = "main",
	Size = UDim2.fromOffset(560, 640),
	Position = UDim2.fromOffset(36, 70),
})

local legit = main:Tab("Legit")
local left = legit:Column()
local right = legit:Column()

local aim = left:Section("Aim Assist")
local enabled = aim:Checkbox("Enabled", true)
enabled:Side("none")
aim:Slider("Field Of View", 0, 180, 90, "%.0f")
aim:Dropdown({ "Static", "Dynamic" }, "Static")
aim:Slider("Horizontal Smoothing", 0, 100, 30, "%.1f")
aim:Slider("Vertical Smoothing", 0, 100, 12, "%.1f")
aim:Dropdown("Checks", {
	"Team Check, Alive Check, Enemy Check",
	"Team Check",
	"None",
}, "Team Check, Alive Check, Enemy Check")
aim:Dropdown("Hitboxes", { "Head, Stomach, Arms", "Head", "Stomach" }, "Head, Stomach, Arms")
aim:Checkbox("Randomize Position", false)
aim:Dropdown("Hitscan Type", { "Static", "Dynamic" }, "Static")
local readjust = aim:Checkbox("Readjustment", false)
readjust:Side("none")
aim:Slider("Dead Zone", 0, 100, 44, "%.1f")
aim:Slider("Stutter", 0, 100, 25, function(v)
	return string.format("%.1ft", v)
end)
aim:Label("one of each control is in this menu")

local trigger = right:Section("Trigger Assist")
local triggerOn = trigger:Checkbox("Enabled", true)
triggerOn:Side("none")
trigger:Slider("Delay", 0, 200, 15, function(v)
	return string.format("%dms", math.floor(v + 0.5))
end)
trigger:Slider("Interval", 0, 200, 75, function(v)
	return string.format("%dms", math.floor(v + 0.5))
end)
trigger:Dropdown("Checks", {
	"Team Check, Alive Check, Enemy Check",
	"None",
}, "Team Check, Alive Check, Enemy Check")
trigger:Dropdown("Hitboxes", { "Head, Stomach, Arms", "Head" }, "Head, Stomach, Arms")
local triggerReadjust = trigger:Checkbox("Readjustment", false)
triggerReadjust:Side("none")

trigger:Separator()

local miscCol = right:Section("Misc")
miscCol:Slider("Cursor Offset", 0, 100, 50, function(v)
	return string.format("%dpx", math.floor(v + 0.5))
end)
miscCol:Slider("", 0, 100, 50, function(v)
	return string.format("%dpx", math.floor(v + 0.5))
end)
miscCol:Keybind("MENU KEY", Enum.KeyCode.Insert)

main:Tab("Players")
local visualsTab = main:Tab("Visuals")
local miscTab = main:Tab("Misc")

local vis = visualsTab:Column():Section("Visuals")
vis:Checkbox("Box", true)
vis:Checkbox("Skeleton", false)
vis:Dropdown("Box Type", { "Full", "Corner" }, "Corner")
vis:Color("Color", Color3.fromRGB(154, 112, 214))
vis:Label("tab content, same widgets")

local menuSec = miscTab:Column():Section("Menu")
menuSec:Checkbox("Hover Highlight", true)
menuSec:Checkbox("Window Glow", false)
menuSec:Keybind("Toggle", Enum.KeyCode.RightShift)

local style = UI:Window({
	Title = "style",
	Size = UDim2.fromOffset(280, 360),
	Position = UDim2.fromOffset(620, 150),
})
local theme = style:Section("Theme")
theme:Color("Menu Accent", Color3.fromRGB(154, 112, 214))
theme:Color("Contrast One", Color3.fromRGB(18, 18, 22))
theme:Color("Contrast Two", Color3.fromRGB(28, 28, 34))
theme:Color("Inline", Color3.fromRGB(42, 40, 58))
theme:Color("Outline", Color3.fromRGB(12, 12, 16))
theme:Color("Text Active", Color3.fromRGB(230, 230, 236))
theme:Color("Text Inactive", Color3.fromRGB(150, 150, 160))
style:Section(""):Separator()
local styleSec = style:Section("Style")
styleSec:Checkbox("Hover Highlight", true)
styleSec:Checkbox("Window Glow", false)

local players = UI:Window({
	Title = "players",
	Size = UDim2.fromOffset(300, 280),
	Position = UDim2.fromOffset(920, 80),
})
local tableApi = UI:Table(players.Body, { "name", "pos", "info" })
local rows = {}
for i = 0, 9 do
	rows[#rows + 1] = { "name" .. i, "pos" .. i, "info" .. i }
end
tableApi:SetRows(rows)

UI:Toolbar({
	{ Text = "H", Callback = function()
		main.Frame.Visible = not main.Frame.Visible
	end },
	{ Text = "T" },
	{ Text = "P", Callback = function()
		players.Frame.Visible = not players.Frame.Visible
	end },
	{ Text = "=" },
	{ Text = "</>" },
	{ Text = "O", Callback = function()
		style.Frame.Visible = not style.Frame.Visible
	end },
	{ Text = "^" },
})
