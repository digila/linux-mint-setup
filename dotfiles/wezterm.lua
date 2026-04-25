-- ============================================================
-- WezTerm 設定 (日本語開発環境向け)
-- このファイルは ~/.config/wezterm/wezterm.lua からシンボリックリンクされます
-- 編集すると WezTerm が自動で再読み込みします (再起動不要)
-- ============================================================
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ---------- 外観 ----------
config.color_scheme = 'Tokyo Night'
config.window_background_opacity = 0.96
config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
config.window_decorations = 'TITLE | RESIZE'

-- ---------- フォント ----------
config.font = wezterm.font_with_fallback({
  { family = 'PlemolJP Console NF', weight = 'Regular' },
  'HackGen Console NF',
  'UDEV Gothic NF',
  'Noto Sans Mono CJK JP',
  'DejaVu Sans Mono',
})
config.font_size = 12.0
config.line_height = 1.1
config.cell_width = 1.0
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
config.treat_east_asian_ambiguous_width_as_wide = false

-- ---------- タブバー ----------
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false

-- ---------- カーソル ----------
config.default_cursor_style = 'SteadyBlock'
config.cursor_blink_rate = 500

-- ---------- スクロールバック ----------
config.scrollback_lines = 10000
config.enable_scroll_bar = false

-- ---------- IME ----------
config.use_ime = true

-- ---------- キーバインド ----------
config.keys = {
  -- Windows風 コピー&ペースト (Ctrl+C: 選択中のみコピー / それ以外はSIGINT)
  { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
  { key = 'c', mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      local sel = window:get_selection_text_for_pane(pane)
      if sel ~= "" then
        window:perform_action(act.CopyTo 'Clipboard', pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act.SendKey { key = 'c', mods = 'CTRL' }, pane)
      end
    end),
  },

  -- ペイン分割 (d: 横分割, D: 縦分割)
  { key = 'd', mods = 'CTRL|SHIFT',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'D', mods = 'CTRL|SHIFT',
    action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },

  -- ペイン間移動
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left'  },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up'    },
  { key = 'DownArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down'  },

  -- ペインリサイズ (Alt+Shift+矢印)
  { key = 'LeftArrow',  mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left',  5 } },
  { key = 'RightArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'UpArrow',    mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up',    5 } },
  { key = 'DownArrow',  mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down',  5 } },

  -- ペインを閉じる
  { key = 'w', mods = 'CTRL|SHIFT',
    action = act.CloseCurrentPane { confirm = true } },

  -- タブ操作
  { key = 't',   mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'Tab', mods = 'CTRL',         action = act.ActivateTabRelative( 1) },
  { key = 'Tab', mods = 'CTRL|SHIFT',   action = act.ActivateTabRelative(-1) },

  -- フォントサイズ
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize    },

  -- コマンドパレット / 設定再読込
  { key = 'F1', action = act.ActivateCommandPalette },
  { key = 'r',  mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },
}

-- ---------- マウス ----------
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods  = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
}

-- ---------- その他 ----------
config.audible_bell = 'Disabled'
config.warn_about_missing_glyphs = false
config.check_for_updates = false

-- ============================================================
-- カレントディレクトリをタブとウィンドウタイトルに表示 (OSC 7連携)
-- ============================================================
local function format_cwd(uri_str)
  if not uri_str then return "~" end
  local path = uri_str:gsub('^file://[^/]*', '')
  path = path:gsub('%%(%x%x)', function(hex)
    return string.char(tonumber(hex, 16))
  end)
  local home = os.getenv('HOME')
  if home and path:sub(1, #home) == home then
    path = '~' .. path:sub(#home + 1)
  end
  if path == '' then path = '/' end
  return path
end

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local cwd_uri = pane.current_working_dir
  local cwd = "?"
  if cwd_uri then
    if type(cwd_uri) == 'userdata' then
      cwd = format_cwd(tostring(cwd_uri))
    else
      cwd = format_cwd(cwd_uri)
    end
  end
  if #cwd > max_width - 6 then
    cwd = '…' .. cwd:sub(-(max_width - 8))
  end
  local index = tab.tab_index + 1
  return {
    { Text = ' ' .. index .. ': ' .. cwd .. ' ' },
  }
end)

wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
  local cwd_uri = tab.active_pane.current_working_dir
  local cwd = "~"
  if cwd_uri then
    if type(cwd_uri) == 'userdata' then
      cwd = format_cwd(tostring(cwd_uri))
    else
      cwd = format_cwd(cwd_uri)
    end
  end
  return cwd .. ' — WezTerm'
end)

return config
