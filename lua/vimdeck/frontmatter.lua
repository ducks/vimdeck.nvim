local M = {}

-- Parse simple YAML frontmatter (key: value pairs only)
function M.parse_yaml(text)
  local result = {}

  for line in text:gmatch("[^\r\n]+") do
    -- Skip empty lines and comments
    if line:match("^%s*$") or line:match("^%s*#") then
      goto continue
    end

    -- Parse key: value
    local key, value = line:match("^%s*([%w_]+):%s*(.+)$")
    if key and value then
      -- Trim trailing whitespace
      value = value:match("^%s*(.-)%s*$")

      -- Parse value type
      if value == "true" then
        result[key] = true
      elseif value == "false" then
        result[key] = false
      elseif tonumber(value) then
        result[key] = tonumber(value)
      else
        -- Remove quotes if present
        value = value:match('^"(.-)"$') or value:match("^'(.-)'$") or value
        result[key] = value
      end
    end

    ::continue::
  end

  return result
end

-- Extract frontmatter from markdown buffer
-- Returns: config table, start_line (where content begins)
function M.extract_frontmatter(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Check if first line is frontmatter delimiter
  if not lines[1] or lines[1] ~= "---" then
    return {}, 1  -- No frontmatter
  end

  -- Find closing delimiter
  local frontmatter_lines = {}
  local end_line = nil

  for i = 2, #lines do
    if lines[i] == "---" then
      end_line = i
      break
    end
    table.insert(frontmatter_lines, lines[i])
  end

  if not end_line then
    return {}, 1  -- No closing delimiter, not valid frontmatter
  end

  -- Parse the frontmatter
  local frontmatter_text = table.concat(frontmatter_lines, "\n")
  local config = M.parse_yaml(frontmatter_text)

  -- Return config and line number where content starts (after closing ---)
  return config, end_line + 1
end

return M
