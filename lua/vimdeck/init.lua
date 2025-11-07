local M = {}

M.config = {
  use_figlet = true,
  center_vertical = true,
  center_horizontal = true,
  margin = 2, -- horizontal margin (columns) on each side
}

-- Setup the plugin with user config
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

-- Start a presentation from the current buffer
function M.present()
  local source_bufnr = vim.api.nvim_get_current_buf()

  -- Check if current buffer is markdown
  local filetype = vim.api.nvim_buf_get_option(source_bufnr, 'filetype')
  if filetype ~= 'markdown' then
    vim.notify("vimdeck: Current buffer is not markdown", vim.log.levels.ERROR)
    return
  end

  -- Parse slides
  local parser = require('vimdeck.parser')
  local slides = parser.parse_slides(source_bufnr)

  if #slides == 0 then
    vim.notify("vimdeck: No slides found. Separate slides with horizontal rules (---)", vim.log.levels.WARN)
    return
  end

  vim.notify(string.format("vimdeck: Found %d slides", #slides), vim.log.levels.INFO)

  -- Create presentation buffer
  local pres_bufnr = vim.api.nvim_create_buf(false, true)

  -- Setup buffer options
  vim.api.nvim_buf_set_option(pres_bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(pres_bufnr, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(pres_bufnr, 'swapfile', false)
  vim.api.nvim_buf_set_option(pres_bufnr, 'modifiable', false)
  vim.api.nvim_buf_set_option(pres_bufnr, 'filetype', 'vimdeck')

  -- Create namespace for highlights
  local ns_id = vim.api.nvim_create_namespace('vimdeck')

  -- Open in new tab
  vim.cmd('tabnew')
  vim.api.nvim_win_set_buf(0, pres_bufnr)

  -- Hide UI elements for presentation mode
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.cursorline = false
  vim.opt_local.signcolumn = 'no'
  vim.opt_local.foldcolumn = '0'
  vim.opt_local.colorcolumn = ''

  -- Setup custom statusline
  vim.opt_local.statusline = '%{get(b:, "vimdeck_status", "Vimdeck")}'

  -- Setup navigation
  local navigation = require('vimdeck.navigation')
  navigation.setup(slides, pres_bufnr, ns_id)
end

-- Convenience function to present a file
function M.present_file(filepath)
  -- Open the file
  vim.cmd('edit ' .. vim.fn.fnameescape(filepath))

  -- Present it
  M.present()
end

return M
