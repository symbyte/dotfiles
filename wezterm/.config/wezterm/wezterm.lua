local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- Platform detection
local is_windows = wezterm.target_triple:find("windows") ~= nil

-- Set WSL as default on Windows
if is_windows then
  config.default_domain = "WSL:Ubuntu-24.04"
end

-- Theme (matching Ghostty's TokyoNight)
config.color_scheme = "Tokyo Night"

-- Font (NF variant on Windows, regular elsewhere)
if is_windows then
  config.font = wezterm.font("Monaspace Neon NF")
else
  config.font = wezterm.font("Monaspace Neon")
end
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

-- Adjust font size based on screen size (larger font for external displays)
-- Only on macOS; Windows uses the default font size
if not is_windows then
  local function update_font_for_screen(window)
    local overrides = window:get_config_overrides() or {}
    local screens = wezterm.gui.screens()
    local active_screen = screens.active
    if active_screen.width > 2000 then
      overrides.font_size = 14.0
    else
      overrides.font_size = 11.0
    end
    window:set_config_overrides(overrides)
  end

  wezterm.on("window-config-reloaded", function(window, pane)
    update_font_for_screen(window)
  end)

  wezterm.on("window-resized", function(window, pane)
    update_font_for_screen(window)
  end)
end

-- Window appearance
config.window_decorations = "RESIZE" -- removes title bar but keeps resize handles
config.window_padding = {
  left = 2,
  right = 2,
  top = 2,
  bottom = 2,
}

-- Tab bar styling
config.use_fancy_tab_bar = false -- Fancy tab bar breaks hide_tab_bar_if_only_one_tab on Windows
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true

-- macOS specific
config.macos_window_background_blur = 0
config.native_macos_fullscreen_mode = true
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Scrollback (matching kitty's large scrollback)
config.scrollback_lines = 100000

-- No audio bell
config.audible_bell = "Disabled"

-- Window state persistence (matching Ghostty's window-save-state = always)
config.window_close_confirmation = "NeverPrompt"

-- Keybindings matching Ghostty config
-- Use SUPER (Win key) on Windows, CMD on macOS
local mod = is_windows and "SUPER" or "CMD"

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
  { key = "d", mods = mod, action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d", mods = mod .. "|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Close pane
  { key = "w", mods = mod, action = act.CloseCurrentPane({ confirm = false }) },

  -- New tab in current directory
  { key = "t", mods = mod, action = act.SpawnCommandInNewTab({ cwd = wezterm.home_dir }) },

  -- Tab navigation
  { key = "[", mods = mod .. "|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "]", mods = mod .. "|SHIFT", action = act.ActivateTabRelative(1) },

  -- Quick select mode (like copy mode)
  { key = "Space", mods = "CTRL|SHIFT", action = act.QuickSelect },

  -- Ctrl+V paste (for Windows compatibility)
  { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },

  -- Disable Alt+Space system menu so it passes through to terminal
  { key = "Space", mods = "ALT", action = act.DisableDefaultAssignment },
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
