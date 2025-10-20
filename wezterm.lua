local wezterm = require 'wezterm'
local act = wezterm.action
local config = {}
if wezterm.config_builder then
config = wezterm.config_builder()
end
config.use_ime = true
-- 定数定義
local FONT_NAME = 'Source Han Code JP'
-- local FONT_NAME = 'Bizin Gothic'
-- local FONT_SIZE = 13.0
local FONT_SIZE = 10.0
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
skip_close_confirmation_for_processes_named = { "bash", "zsh", "fish", "tmux", "sh" }

-- === 背景画像設定（追加部分） ===

-- 背景画像のパスを設定
local background_image_path = wezterm.home_dir .. "/Pictures/wezterm.png"

-- ファイルの存在確認関数
local function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  else
    return false
  end
end

-- 背景画像が存在する場合のみ設定を適用
if file_exists(background_image_path) then
config.background = {
    {
    -- 画像レイヤー（上層）
    source = { File = background_image_path },
    opacity = 0.5, -- 透明度（お好みで調整：0.0-1.0）
    vertical_align = "Middle",
    horizontal_align = "Center",
    repeat_x = "NoRepeat",
    repeat_y = "NoRepeat",
    -- width = "100%",
    -- height = "100%",
  },
  {
    -- 黒の透過レイヤー（下層）
    source = {
      Color = "#000000"
    },
    opacity = 0.8, -- 黒レイヤーの透明度（お好みで調整）
    width = "100%",
    height = "100%",
  }
}
end

return config
