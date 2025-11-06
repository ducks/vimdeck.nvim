local M = {}

-- Parse markdown buffer into slides using Treesitter
-- Slides are separated by horizontal rules (---, ***, ___)
-- Returns array of slide tables with structured content
function M.parse_slides(bufnr)
  -- Get the markdown parser
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'markdown')
  if not ok then
    vim.notify("vimdeck: markdown treesitter parser not found", vim.log.levels.ERROR)
    return {}
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  -- Query for all elements we care about
  local query = vim.treesitter.query.parse('markdown', [[
    (thematic_break) @separator
    (atx_heading) @heading
    (fenced_code_block) @code
    (list_item) @list_item
    (block_quote) @quote
    (paragraph) @paragraph
  ]])

  local slides = {}
  local current_slide = { start_row = 0, elements = {} }

  -- Iterate through all matches
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local capture = query.captures[id]
    local start_row, start_col, end_row, end_col = node:range()
    local text = vim.treesitter.get_node_text(node, bufnr)

    if capture == 'separator' then
      -- New slide starts here
      current_slide.end_row = start_row - 1
      if #current_slide.elements > 0 then
        table.insert(slides, current_slide)
      end
      current_slide = { start_row = start_row + 1, elements = {} }
    else
      -- Skip paragraphs that are inside list items or block quotes
      if capture == 'paragraph' then
        -- Check if any ancestor is a list_item or block_quote
        local current = node:parent()
        while current do
          if current:type() == 'list_item' or current:type() == 'block_quote' then
            goto continue
          end
          current = current:parent()
        end

        -- Also skip paragraphs that start with > (likely part of blockquote)
        if text:match("^>") then
          goto continue
        end
      end

      -- Add element to current slide
      local element = {
        type = capture,
        node = node,
        start_row = start_row,
        end_row = end_row,
        text = text
      }

      -- Extract additional metadata and clean text for specific types
      if capture == 'heading' then
        element.level = M.get_heading_level(node)
      elseif capture == 'code' then
        element.lang = M.get_code_language(node, bufnr)
        element.text = M.get_code_content(node, bufnr)
      elseif capture == 'list_item' then
        element.text = M.get_list_item_text(node, bufnr)
      elseif capture == 'quote' then
        element.text = M.get_quote_text(node, bufnr)
      end

      table.insert(current_slide.elements, element)
      ::continue::
    end
  end

  -- Add final slide
  current_slide.end_row = vim.api.nvim_buf_line_count(bufnr) - 1
  if #current_slide.elements > 0 then
    table.insert(slides, current_slide)
  end

  return slides
end

-- Get heading level (1-6) from atx_heading node
function M.get_heading_level(heading_node)
  for child in heading_node:iter_children() do
    if child:type() == 'atx_h1_marker' then return 1 end
    if child:type() == 'atx_h2_marker' then return 2 end
    if child:type() == 'atx_h3_marker' then return 3 end
    if child:type() == 'atx_h4_marker' then return 4 end
    if child:type() == 'atx_h5_marker' then return 5 end
    if child:type() == 'atx_h6_marker' then return 6 end
  end
  return 1 -- default
end

-- Get code block language from fenced_code_block node
function M.get_code_language(code_node, bufnr)
  for child in code_node:iter_children() do
    if child:type() == 'info_string' then
      local lang = vim.treesitter.get_node_text(child, bufnr)
      return lang ~= "" and lang or "text"
    end
  end
  return "text"
end

-- Get clean code content from fenced_code_block (without fence markers)
function M.get_code_content(code_node, bufnr)
  for child in code_node:iter_children() do
    if child:type() == 'code_fence_content' then
      return vim.treesitter.get_node_text(child, bufnr)
    end
  end
  -- Fallback: strip fence markers manually
  local text = vim.treesitter.get_node_text(code_node, bufnr)
  -- Remove opening fence (```lang)
  text = text:gsub("^```[^\n]*\n", "")
  -- Remove closing fence (```)
  text = text:gsub("\n```$", "")
  return text
end

-- Get clean text from list item (without markdown markers)
function M.get_list_item_text(list_node, bufnr)
  -- List items have structure: list_marker + inline content
  for child in list_node:iter_children() do
    -- Skip list_marker_minus, list_marker_star, etc
    if child:type():match("^inline") or child:type() == "paragraph" then
      return vim.treesitter.get_node_text(child, bufnr)
    end
  end
  -- Fallback: strip markdown markers manually
  local text = vim.treesitter.get_node_text(list_node, bufnr)
  return text:gsub("^%s*[%-%*%+]%s+", "")
end

-- Get clean text from blockquote (without > markers)
function M.get_quote_text(quote_node, bufnr)
  -- Get raw text and strip all > markers from each line
  local text = vim.treesitter.get_node_text(quote_node, bufnr)
  local cleaned_lines = {}

  for line in text:gmatch("[^\r\n]+") do
    -- Remove leading > and optional space
    local cleaned = line:gsub("^>%s?", "")
    table.insert(cleaned_lines, cleaned)
  end

  return table.concat(cleaned_lines, "\n")
end

return M
