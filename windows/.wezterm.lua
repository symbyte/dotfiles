local wezterm = require 'wezterm'
local act = wezterm.action

return {
  default_domain = 'WSL:Ubuntu',
  -- Use hardware Vulkan: avoids NVIDIA's OpenGL sleep crash without CPU rendering.
  front_end = 'WebGpu',
  webgpu_preferred_adapter = {
    name = 'NVIDIA GeForce RTX 5070 Ti',
    device_type = 'DiscreteGpu',
    backend = 'Vulkan',
  },
  window_decorations = 'RESIZE',
  -- This WezTerm build cannot resolve the variable font's regular face.
  font = wezterm.font 'Monaspace Neon',
  font_size = 11,
  -- Keep the tiled window fixed; font shortcuts change cell size instead.
  adjust_window_size_when_changing_font_size = false,

  use_fancy_tab_bar = false,
  tab_bar_at_bottom = true,
  hide_tab_bar_if_only_one_tab = true,

  keys = {
    { key = 'h', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Left') },
    { key = 'j', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Down') },
    { key = 'k', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Up') },
    { key = 'l', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Right') },
    { key = 'Enter', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },
    { key = 'Enter', mods = 'SHIFT', action = act.SendString('\x1b\r') },
    -- Consume Windows' system-menu shortcut and forward Alt+Space to Zellij.
    { key = 'Space', mods = 'ALT', action = act.SendString('\x1b ') },

    -- Physical Win shortcuts; AHK bridges these to neutral keys only in WezTerm.
    -- Ubuntu's Linux home; wezterm.home_dir points at the Windows profile.
    { key = 'd', mods = 'SUPER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = 'SUPER|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 'w', mods = 'SUPER', action = act.CloseCurrentPane { confirm = false } },
    { key = 't', mods = 'SUPER', action = act.SpawnCommandInNewTab { cwd = '/home/symbyte' } },
    { key = '[', mods = 'SUPER|SHIFT', action = act.ActivateTabRelative(-1) },
    { key = ']', mods = 'SUPER|SHIFT', action = act.ActivateTabRelative(1) },

    -- Command-style font sizing, including the unshifted equals key.
    { key = '=', mods = 'SUPER', action = act.IncreaseFontSize },
    { key = '+', mods = 'SUPER|SHIFT', action = act.IncreaseFontSize },
    { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },

    -- Neutral Ctrl+Shift+F13..F20 chords received from komorebi.ahk.
    { key = 'F13', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'F14', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 'F15', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = false } },
    { key = 'F16', mods = 'CTRL|SHIFT', action = act.SpawnCommandInNewTab { cwd = '/home/symbyte' } },
    { key = 'F17', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
    { key = 'F18', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },
    { key = 'F19', mods = 'CTRL|SHIFT', action = act.IncreaseFontSize },
    { key = 'F20', mods = 'CTRL|SHIFT', action = act.DecreaseFontSize },

    { key = 'v', mods = 'CTRL', action = act.PasteFrom('Clipboard') },
    { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },
  },

  mouse_bindings = {
    {
      event = { Down = { streak = 1, button = 'Right' } },
      mods = 'NONE',
      action = act.PasteFrom('Clipboard'),
    },
  },

  -- Exact palette from kitty's VSCode_Dark theme.
  colors = {
    foreground = '#cccccc',
    background = '#1e1e1e',
    selection_fg = '#cccccc',
    selection_bg = '#264f78',
    cursor_bg = '#ffffff',
    cursor_fg = '#1e1e1e',
    cursor_border = '#ffffff',
    split = '#414140',
    ansi = {
      '#000000', '#f14c4c', '#23d18b', '#f5f543',
      '#3b8eea', '#d670d6', '#29b8db', '#e5e5e5',
    },
    brights = {
      '#666666', '#cd3131', '#0dbc79', '#e5e510',
      '#2472c8', '#bc3fbc', '#11a8cd', '#e5e5e5',
    },
    tab_bar = {
      background = '#1e1e1e',
      active_tab = { bg_color = '#3a3d41', fg_color = '#ffffff' },
      inactive_tab = { bg_color = '#1e1e1e', fg_color = '#858485' },
      inactive_tab_hover = { bg_color = '#3a3d41', fg_color = '#cccccc' },
      new_tab = { bg_color = '#1e1e1e', fg_color = '#858485' },
      new_tab_hover = { bg_color = '#3a3d41', fg_color = '#ffffff' },
    },
  },
}
