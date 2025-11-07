local M = {}

-- State
M.current_slide = 1
M.slides = {}
M.bufnr = nil
M.ns_id = nil

-- Setup navigation for a presentation
function M.setup(slides, bufnr, ns_id)
  M.slides = slides
  M.bufnr = bufnr
  M.ns_id = ns_id
  M.current_slide = 1

  -- Setup keymaps
  M.setup_keymaps(bufnr)

  -- Display first slide
  M.show_slide(1)
end

-- Setup keybindings for presentation navigation
function M.setup_keymaps(bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- Navigation
  vim.keymap.set('n', '<PageDown>', function() M.next_slide() end, opts)
  vim.keymap.set('n', '<PageUp>', function() M.prev_slide() end, opts)
  vim.keymap.set('n', '<Space>', function() M.next_slide() end, opts)
  vim.keymap.set('n', '<BS>', function() M.prev_slide() end, opts)

  -- Direct navigation
  vim.keymap.set('n', 'gg', function() M.goto_slide(1) end, opts)
  vim.keymap.set('n', 'G', function() M.goto_slide(#M.slides) end, opts)

  -- Quit
  vim.keymap.set('n', 'q', function() M.quit() end, opts)
  vim.keymap.set('n', 'Q', function() M.quit() end, opts)
end

-- Show specific slide
function M.show_slide(slide_num)
  if slide_num < 1 or slide_num > #M.slides then
    return
  end

  M.current_slide = slide_num

  local renderer = require('vimdeck.renderer')
  local config = require('vimdeck').config
  local slide = M.slides[slide_num]

  -- Get window dimensions for centering
  local win_height = vim.api.nvim_win_get_height(0)
  local win_width = vim.api.nvim_win_get_width(0)

  -- Render slide with user config
  local lines, highlights = renderer.render_slide(slide, {
    height = win_height,
    width = win_width,
    use_figlet = config.use_figlet,
    center_vertical = config.center_vertical,
    center_horizontal = config.center_horizontal,
    margin = config.margin,
  })

  -- Flatten any lines that contain embedded newlines and track line mapping
  local flattened_lines = {}
  local line_mapping = {} -- old line -> new line (0-indexed)

  for old_line_idx, line in ipairs(lines) do
    line_mapping[old_line_idx - 1] = #flattened_lines -- 0-indexed

    if line:find("\n") then
      -- Split lines with embedded newlines
      for subline in line:gmatch("[^\n]+") do
        table.insert(flattened_lines, subline)
      end
    else
      table.insert(flattened_lines, line)
    end
  end

  -- Adjust highlight line numbers based on mapping
  local adjusted_highlights = {}
  for _, hl in ipairs(highlights) do
    local new_line = line_mapping[hl.line]
    if new_line then
      table.insert(adjusted_highlights, {
        group = hl.group,
        line = new_line,
        col_start = hl.col_start,
        col_end = hl.col_end
      })
    end
  end

  -- Update buffer
  vim.api.nvim_buf_set_option(M.bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, flattened_lines)
  vim.api.nvim_buf_set_option(M.bufnr, 'modifiable', false)

  -- Clear old highlights
  vim.api.nvim_buf_clear_namespace(M.bufnr, M.ns_id, 0, -1)

  -- Apply new highlights with adjusted line numbers
  renderer.apply_highlights(M.bufnr, adjusted_highlights, M.ns_id)

  -- Update status line with slide number
  M.update_statusline()
end

-- Go to next slide
function M.next_slide()
  if M.current_slide < #M.slides then
    M.show_slide(M.current_slide + 1)
  end
end

-- Go to previous slide
function M.prev_slide()
  if M.current_slide > 1 then
    M.show_slide(M.current_slide - 1)
  end
end

-- Go to specific slide
function M.goto_slide(slide_num)
  M.show_slide(slide_num)
end

-- Update statusline to show slide progress
function M.update_statusline()
  local status = string.format("Slide %d/%d", M.current_slide, #M.slides)
  vim.api.nvim_buf_set_var(M.bufnr, 'vimdeck_status', status)
  vim.cmd('redrawstatus')
end

-- Quit presentation
function M.quit()
  -- Close the window/buffer
  vim.cmd('quit')
end

return M
