local M = {}

-- Render a slide to lines suitable for display
-- Returns array of lines and array of highlight instructions
function M.render_slide(slide, opts)
  opts = opts or {}
  opts.use_figlet = opts.use_figlet ~= false -- default true
  opts.center = opts.center ~= false -- default true

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

  -- Center content vertically if requested
  if opts.center then
    lines = M.center_content(lines, opts.height or 40)
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

  -- Try to use Treesitter for syntax highlighting
  local lang = element.lang or "text"
  local ok, parser = pcall(vim.treesitter.get_string_parser, element.text, lang)

  if ok then
    local tree = parser:parse()[1]
    if tree then
      local root = tree:root()

      -- Get highlights for this language
      local ok_query, query = pcall(vim.treesitter.query.get, lang, 'highlights')

      if ok_query and query then
        for id, node in query:iter_captures(root, element.text, 0, -1) do
          local capture = query.captures[id]
          local hl_group = "@" .. capture .. "." .. lang
          local start_row, start_col, end_row, end_col = node:range()

          -- Add highlight for each line this node spans
          for line_num = start_row, end_row do
            table.insert(highlights, {
              group = hl_group,
              line = line_num,
              col_start = (line_num == start_row) and start_col or 0,
              col_end = (line_num == end_row) and end_col or -1
            })
          end
        end
      end
    end
  end

  -- Fallback: basic string highlight if Treesitter fails
  if #highlights == 0 then
    for i = 1, #lines do
      table.insert(highlights, {
        group = "String",
        line = i - 1,
        col_start = 0,
        col_end = -1
      })
    end
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

-- Center content vertically
function M.center_content(lines, height)
  local content_height = #lines
  local padding = math.floor((height - content_height) / 2)

  if padding <= 0 then
    return lines
  end

  local centered = {}

  -- Add top padding
  for _ = 1, padding do
    table.insert(centered, "")
  end

  -- Add content
  for _, line in ipairs(lines) do
    table.insert(centered, line)
  end

  return centered
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
