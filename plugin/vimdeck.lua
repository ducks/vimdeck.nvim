-- Prevent loading file twice
if vim.g.loaded_vimdeck then
  return
end
vim.g.loaded_vimdeck = true

-- Create user commands
vim.api.nvim_create_user_command('Vimdeck', function()
  require('vimdeck').present()
end, {
  desc = 'Start presentation from current markdown buffer'
})

vim.api.nvim_create_user_command('VimdeckFile', function(opts)
  if not opts.args or opts.args == '' then
    vim.notify('VimdeckFile requires a file path argument', vim.log.levels.ERROR)
    return
  end
  require('vimdeck').present_file(opts.args)
end, {
  nargs = 1,
  complete = 'file',
  desc = 'Start presentation from markdown file'
})
