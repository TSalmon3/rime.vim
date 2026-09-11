local M = {}

local function cursor_node()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1] - 1
  local line = vim.fn.getline(pos[1])
  local len = vim.fn.strlen(line)
  local col = pos[2]
  if len == 0 then
    return nil, nil
  end
  if col >= len then
    col = len - 1
  end
  if col < 0 then
    col = 0
  end
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok or not parser then
    return nil, nil
  end
  local trees = parser:parse()
  if not trees or not trees[1] then
    return nil, nil
  end
  local root = trees[1]:root()
  if not root then
    return nil, nil
  end
  local bufnr = vim.api.nvim_get_current_buf()
  return root:named_descendant_for_range(row, col, row, col), bufnr
end

local function range_of(node)
  local sr, sc, er, ec = node:range()
  return { sr + 1, sc + 1 }, { er + 1, ec }
end

function M.func_range()
  local ok, res = pcall(function()
    local node, bufnr = cursor_node()
    while node do
      local t = node:type()
      if t == "call_expression" or t == "call" or t == "function_call" then
        break
      end
      node = node:parent()
    end
    if not node then
      return nil
    end
    local fname = node:field("function")[1] or node:named_child(0)
    if not fname then
      return nil
    end
    local name = vim.treesitter.get_node_text(fname, bufnr)
    if not name or name == "" then
      return nil
    end
    local _, last = range_of(node)
    local first = range_of(fname)
    return { first_pos = first, last_pos = last, open_len = #name + 1, close_len = 1 }
  end)
  if ok then
    return res
  end
  return nil
end

function M.tag_range()
  local ok, res = pcall(function()
    local node = cursor_node()
    while node do
      local t = node:type()
      if t == "element" or t == "jsx_element" then
        break
      end
      node = node:parent()
    end
    if not node then
      return nil
    end
    local opener, closer = nil, nil
    for i = 0, node:named_child_count() - 1 do
      local child = node:named_child(i)
      local t = child:type()
      if (t == "start_tag" or t == "jsx_opening_element") and not opener then
        opener = child
      end
      if t == "end_tag" or t == "jsx_closing_element" then
        closer = child
      end
    end
    if not opener or not closer then
      return nil
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local otext = vim.treesitter.get_node_text(opener, bufnr)
    local ctext = vim.treesitter.get_node_text(closer, bufnr)
    if not otext or otext == "" or not ctext or ctext == "" then
      return nil
    end
    local first = range_of(opener)
    local _, last = range_of(closer)
    return { first_pos = first, last_pos = last, open_len = #otext, close_len = #ctext }
  end)
  if ok then
    return res
  end
  return nil
end

return M
