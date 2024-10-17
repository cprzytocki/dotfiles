-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 10
config.enable_tab_bar = true
-- config.window_decorations = "RESIZE"
config.window_background_opacity = 0.8
config.macos_window_background_blur = 20
config.enable_wayland = true

-- tab bar
config.hide_tab_bar_if_only_one_tab = true  
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false

local action = wezterm.action
config.keys = {
    -- naturtal text editting
	{ mods = "OPT", key = "LeftArrow", action = action.SendKey({ mods = "ALT", key = "b" }) },
	{ mods = "OPT", key = "RightArrow", action = action.SendKey({ mods = "ALT", key = "f" }) },
	{ mods = "CMD", key = "LeftArrow", action = action.SendKey({ mods = "CTRL", key = "a" }) },
	{ mods = "CMD", key = "RightArrow", action = action.SendKey({ mods = "CTRL", key = "e" }) },
	{ mods = "CMD", key = "Backspace", action = action.SendKey({ mods = "CTRL", key = "u" }) },
	{ mods = 'CMD', key = 'k',  action = action.ClearScrollback('ScrollbackAndViewport') },

}
-- and finally, return the configuration to wezterm
return config
