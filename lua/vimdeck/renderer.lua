local M = {}

-- Render a slide to lines suitable for display
-- Returns array of lines and array of highlight instructions
function M.render_slide(slide, opts)
  opts = opts or {}
  opts.use_figlet = opts.use_figlet ~= false -- default true
  opts.center_vertical = opts.center_vertical ~= false -- default true
  opts.center_horizontal = opts.center_horizontal ~= false -- default true

  local lines = {}
  local highlights = {}

  for _, element in ipairs(slide.elements) do
    local rendered_lines, rendered_highlights = M.render_element(element, opts)

    -- Track line offset for highlights
    local line_offset = #lines

    -- Add rendered lines
    for _, line in ipairs(rendered_lines) do
      table.insert(lines, line)
    end

    -- Add highlights with adjusted line numbers
    for _, hl in ipairs(rendered_highlights) do
      table.insert(highlights, {
        group = hl.group,
        line = hl.line + line_offset,
        col_start = hl.col_start,
        col_end = hl.col_end
      })
    end

    -- Add blank line between elements
    table.insert(lines, "")
  end

  -- Center content if requested
  if opts.center_vertical or opts.center_horizontal then
    lines = M.center_content(lines, opts.height or 40, opts.width, opts.center_vertical, opts.center_horizontal)
  end

  return lines, highlights
end

-- Render a single element
function M.render_element(element, opts)
  if element.type == 'heading' then
    return M.render_heading(element, opts)
  elseif element.type == 'code' then
    return M.render_code(element, opts)
  elseif element.type == 'list_item' then
    return M.render_list_item(element, opts)
  elseif element.type == 'quote' then
    return M.render_quote(element, opts)
  elseif element.type == 'paragraph' then
    return M.render_paragraph(element, opts)
  else
    return { element.text }, {}
  end
end

-- Render heading (with optional figlet for h1/h2)
function M.render_heading(element, opts)
  local text = element.text:gsub("^#+%s+", "") -- Strip markdown markers
  local lines = {}
  local highlights = {}

  -- Use figlet for h1 and h2 if available
  if opts.use_figlet and (element.level == 1 or element.level == 2) then
    local figlet_output = M.figlet(text, element.level)
    if figlet_output then
      lines = figlet_output
      -- Highlight all figlet lines
      for i = 1, #lines do
        table.insert(highlights, {
          group = element.level == 1 and "Title" or "Statement",
          line = i - 1,
          col_start = 0,
          col_end = -1
        })
      end
      return lines, highlights
    end
  end

  -- Fallback: plain text with highlight
  local prefix = string.rep("#", element.level) .. " "
  table.insert(lines, prefix .. text)
  table.insert(highlights, {
    group = "Title",
    line = 0,
    col_start = 0,
    col_end = -1
  })

  return lines, highlights
end

-- Render code block with syntax highlighting
function M.render_code(element, opts)
  local lines = vim.split(element.text, "\n")
  local highlights = {}

  -- Simple highlighting: use Identifier for visual distinction
  -- More complex Treesitter highlighting is tricky with dynamic buffers
  for i = 1, #lines do
    table.insert(highlights, {
      group = "Identifier",
      line = i - 1,
      col_start = 0,
      col_end = -1
    })
  end

  return lines, highlights
end

-- Render list item
function M.render_list_item(element, opts)
  local text = element.text
  local lines = { "  • " .. text }
  local highlights = {
    { group = "Special", line = 0, col_start = 0, col_end = 4 }
  }
  return lines, highlights
end

-- Render blockquote
function M.render_quote(element, opts)
  local lines = {}
  local highlights = {}

  -- Split into lines and add ┃ prefix to each
  for line in element.text:gmatch("[^\r\n]+") do
    table.insert(lines, "┃ " .. line)
    table.insert(highlights, {
      group = "Comment",
      line = #lines - 1,
      col_start = 0,
      col_end = -1
    })
  end

  return lines, highlights
end

-- Render paragraph
function M.render_paragraph(element, opts)
  return { element.text }, {}
end

-- Generate ASCII art using figlet
function M.figlet(text, level)
  local font = level == 1 and "standard" or "small"
  local handle = io.popen("figlet -f " .. font .. " -w 120 " .. vim.fn.shellescape(text))
  if not handle then
    return nil
  end

  local result = handle:read("*a")
  handle:close()

  if not result or result == "" then
    return nil
  end

  return vim.split(result, "\n")
end

-- Center content vertically and/or horizontally
function M.center_content(lines, height, width, center_vertical, center_horizontal)
  width = width or vim.o.columns
  local result = lines

  -- Horizontal centering: find max line width and pad each line
  if center_horizontal then
    local max_width = 0
    for _, line in ipairs(result) do
      local line_width = vim.fn.strdisplaywidth(line)
      if line_width > max_width then
        max_width = line_width
      end
    end

    local horizontally_centered = {}
    local left_padding = math.floor((width - max_width) / 2)

    if left_padding > 0 then
      local padding_str = string.rep(" ", left_padding)
      for _, line in ipairs(result) do
        table.insert(horizontally_centered, padding_str .. line)
      end
      result = horizontally_centered
    end
  end

  -- Vertical centering
  if center_vertical then
    local content_height = #result
    local top_padding = math.floor((height - content_height) / 2)

    if top_padding > 0 then
      local vertically_centered = {}

      -- Add top padding
      for _ = 1, top_padding do
        table.insert(vertically_centered, "")
      end

      -- Add content
      for _, line in ipairs(result) do
        table.insert(vertically_centered, line)
      end

      result = vertically_centered
    end
  end

  return result
end

-- Apply highlights to buffer
function M.apply_highlights(bufnr, highlights, ns_id)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      bufnr,
      ns_id,
      hl.group,
      hl.line,
      hl.col_start,
      hl.col_end
    )
  end
end

return M
