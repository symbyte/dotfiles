local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- Theme (matching Ghostty's TokyoNight)
config.color_scheme = "Tokyo Night"

-- Font
config.font = wezterm.font("Monaspace Neon")
config.font_size = 11.0

-- Tab title shows current directory name of first pane
wezterm.on("format-tab-title", function(tab)
  local pane = tab.active_pane
  local cwd = pane.current_working_dir
  if cwd then
    local path = cwd.file_path or cwd:gsub("^file://[^/]*", "")
    local dir = path:match("([^/]+)/?$") or path
    return " " .. dir .. " "
  end
  return tab.active_pane.title
end)

-- Adjust font size based on monitor (larger font for external displays)
wezterm.on("window-resized", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  local dims = window:get_dimensions()

  -- Built-in MacBook display is typically around 1800px wide at effective resolution
  -- External monitors are usually wider
  if dims.pixel_width > 2000 then
    overrides.font_size = 14.0
  else
    overrides.font_size = 11.0
  end

  window:set_config_overrides(overrides)
end)

-- Window appearance
config.window_decorations = "RESIZE" -- removes title bar but keeps resize handles
config.window_padding = {
  left = 2,
  right = 2,
  top = 2,
  bottom = 2,
}

-- Tab bar styling (powerline-inspired like kitty)
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true

-- macOS specific
config.macos_window_background_blur = 0
config.native_macos_fullscreen_mode = true
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

-- Scrollback (matching kitty's large scrollback)
config.scrollback_lines = 100000

-- No audio bell
config.audible_bell = "Disabled"

-- Window state persistence (matching Ghostty's window-save-state = always)
config.window_close_confirmation = "NeverPrompt"

-- Keybindings matching Ghostty config
config.keys = {
  -- Split navigation (ctrl+shift+h/j/k/l)
  { key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },

  -- Toggle split zoom (ctrl+shift+enter)
  { key = "Enter", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState },

  -- Shift+enter sends escape sequence (matching Ghostty's keybind = shift+enter=text:\x1b\r)
  { key = "Enter", mods = "SHIFT", action = act.SendString("\x1b\r") },

  -- Split panes
  { key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Close pane
  { key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = false }) },

  -- New tab in current directory
  { key = "t", mods = "CMD", action = act.SpawnCommandInNewTab({ cwd = wezterm.home_dir }) },

  -- Tab navigation
  { key = "[", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "]", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },

  -- Quick select mode (like copy mode)
  { key = "Space", mods = "CTRL|SHIFT", action = act.QuickSelect },
}

-- Mouse bindings
config.mouse_bindings = {
  -- Right click paste
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = act.PasteFrom("Clipboard"),
  },
}

return config
