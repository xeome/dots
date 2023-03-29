-- doom_config - Doom Nvim user configurations file
--
-- This file contains the user-defined configurations for Doom nvim.
-- Just override stuff in the `doom` global table (it's injected into scope
-- automatically).

-- ADDING A PACKAGE
--
-- doom.use_package("EdenEast/nightfox.nvim", "sainnhe/sonokai")
-- doom.use_package({
--   "ur4ltz/surround.nvim",
--   config = function()
--     require("surround").setup({mappings_style = "sandwich"})
--   end
-- })

-- ADDING A KEYBIND
--
-- doom.use_keybind({
--   -- The `name` field will add the keybind to whichkey
--   {"<leader>s", name = '+search', {
--     -- Bind to a vim command
--     {"g", "Telescope grep_string<CR>", name = "Grep project"},
--     -- Or to a lua function
--     {"p", function()
--       print("Not implemented yet")
--     end, name = ""}
--   }}
-- })

-- ADDING A COMMAND
--
-- doom.use_cmd({
--   {"CustomCommand1", function() print("Trigger my custom command 1") end},
--   {"CustomCommand2", function() print("Trigger my custom command 2") end}
-- })

-- ADDING AN AUTOCOMMAND
--
-- doom.use_autocmd({
--   { "FileType", "javascript", function() print('This is a javascript file') end }
-- })

-- vim: sw=2 sts=2 ts=2 expandtab
vim.api.nvim_command("set guifont=Iosevka\\ Nerd\\ Font,Cooper\\ Hewitt:h12")

vim.g.neovide_refresh_rate = 144
vim.g.neovide_transparency = 1.0

--vim.g.neovide_no_idle = true
--vim.g.neovide_profiler = false
--vim.g.neovide_touch_deadzone = 6.0
--vim.g.neovide_input_use_logo = true
--vim.g.neovide_remember_window_size = true
--vim.g.neovide_touch_drag_timeout = 0.17

vim.g.neovide_cursor_animation_length = 0.10
vim.g.neovide_cursor_trail_length = 0.2
vim.g.neovide_cursor_antialiasing = true
vim.g.neovide_cursor_unfocused_outline_width = 0.125

vim.g.neovide_cursor_vfx_mode = "railgun"
vim.g.neovide_cursor_vfx_opacity = 200.0
vim.g.neovide_cursor_vfx_particle_lifetime = 1.2
vim.g.neovide_cursor_vfx_particle_density = 7.0
vim.g.neovide_cursor_vfx_particle_speed = 10.0
vim.g.neovide_cursor_vfx_particle_phase = 1.5
vim.g.neovide_cursor_vfx_particle_curl = 1.0

vim.g.neovide_padding_top = 10
vim.g.neovide_padding_left = 10
vim.g.neovide_padding_right = 10
vim.g.neovide_padding_bottom = 10
doom.indent = 4
