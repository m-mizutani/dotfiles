local wezterm = require 'wezterm'
local act = wezterm.action
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- 定数定義
local FONT_NAME = 'Source Code Pro'
local FONT_SIZE = 12.0
local ADJUST_WIDTH = 50

-- 見た目の設定
config.font = wezterm.font(FONT_NAME, {
  italic = false,
  weight = "Medium",
})
config.font_size = FONT_SIZE
config.color_scheme = 'Brewer (base16)'
config.window_background_opacity = 0.9

-- ウィンドウの設定
config.window_padding = {
  left = 2,
  right = 2,
  top = 2,
  bottom = 2,
}
config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- タブの見た目
config.colors = {
  tab_bar = {
    background = "#1b1b1b",
    active_tab = {
      bg_color = "#2b2042",
      fg_color = "#c0c0c0",
    },
    inactive_tab = {
      bg_color = "#1b1b1b",
      fg_color = "#808080",
    },
  },
}

-- キーバインド設定
config.leader = { key = 't', mods = 'CTRL' }
config.keys = {
  -- タブ操作
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'LEADER', action = act.CloseCurrentTab{ confirm = true } },
  { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
  { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
  { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },

  -- ペイン分割
  { key = "'", mods = 'LEADER', action = act.SplitPane { direction = 'Right', size = { Percent = 50 } } },
  { key = '"', mods = 'LEADER', action = act.SplitPane { direction = 'Down', size = { Percent = 50 } } },

  -- ペイン操作
  { key = 'o', mods = 'LEADER', action = act.ActivatePaneDirection 'Next' },
  { key = 'n', mods = 'LEADER', action = act.ActivatePaneDirection 'Next' },
  { key = 'p', mods = 'LEADER', action = act.ActivatePaneDirection 'Prev' },
  { key = 'z', mods = 'CTRL', action = act.TogglePaneZoomState },

  -- ペインサイズ調整
  { key = 'LeftArrow', mods = 'LEADER', action = act.AdjustPaneSize { 'Left', ADJUST_WIDTH } },
  { key = 'RightArrow', mods = 'LEADER', action = act.AdjustPaneSize { 'Right', ADJUST_WIDTH } },
  { key = 'UpArrow', mods = 'LEADER', action = act.AdjustPaneSize { 'Up', ADJUST_WIDTH } },
  { key = 'DownArrow', mods = 'LEADER', action = act.AdjustPaneSize { 'Down', ADJUST_WIDTH } },

  -- その他の機能
  { key = 'f', mods = 'LEADER', action = act.QuickSelect },
  { key = 'x', mods = 'LEADER', action = act.ActivateCopyMode },
  { key = 'v', mods = 'LEADER', action = act.PasteFrom 'Clipboard' },
}

-- その他の設定
config.automatically_reload_config = true
config.scrollback_lines = 10000
config.enable_scroll_bar = true

return config