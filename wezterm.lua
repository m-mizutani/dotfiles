-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}
local adjustWidth = 50

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = 'Batman'

local fontName = 'Source Code Pro'
-- local fontName = 'NOTONOTO35 Console'
-- local fontName = 'NOTONOTO Console'
-- local fontName = 'Bizin Gothic'
-- local fontName = 'Juisee'

config.font = wezterm.font(fontName, {
  italic = false,
  weight = "Medium",
})
config.font_size = 12.0
config.color_scheme = 'Brewer (base16)'
config.window_background_opacity = 0.9

config.leader = { key = 't', mods = 'CTRL' }
config.keys = {
  {
    key = 'c',
    mods = 'LEADER',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = "'",
    mods = 'LEADER',
    action = wezterm.action.SplitPane {
      direction = 'Right',
      size = { Percent = 50 },
    },
  },
  {
    key = '"',
    mods = 'LEADER',
    action = wezterm.action.SplitPane {
      direction = 'Down',
      size = { Percent = 50 },
    },
  },
  {
    key = 'o',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Next',
  },
  {
    key = 'n',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Next',
  },
  {
    key = 'p',
    mods = 'LEADER',
    action = wezterm.action.ActivatePaneDirection 'Prev',
  },
  {
    key = 'f',
    mods = 'LEADER',
    action = wezterm.action.QuickSelect,
  },
  {
    key = 'x',
    mods = 'LEADER',
    action = wezterm.action.ActivateCopyMode,
  },
  {
    key = 'z',
    mods = 'CTRL',
    action = wezterm.action.TogglePaneZoomState,
  },
  {
    key = 'LeftArrow',
    mods = 'LEADER',
    action = wezterm.action.AdjustPaneSize { 'Left', adjustWidth },
  },
  {
    key = 'RightArrow',
    mods = 'LEADER',
    action = wezterm.action.AdjustPaneSize { 'Right', adjustWidth },
  },
}

-- and finally, return the configuration to wezterm
return config

