local M = {}

--- Check whether the treesitter node at the cursor matches any pattern.
--- @param pats string[] substring list, matched case-insensitively
---   against the node type chain (node + ancestors).
--- @return boolean true when any pattern hits.
function M.hit(pats)
  if type(pats) ~= "table" or #pats == 0 then
    return false
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local line = vim.fn.getline(row + 1)
  local len = vim.fn.strlen(line)
  if len == 0 then
    return false
  end
  if col >= len then
    col = len - 1
  end
  if col < 0 then
    col = 0
  end
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok or not parser then
    return false
  end
  local trees = parser:parse()
  if not trees or not trees[1] then
    return false
  end
  local root = trees[1]:root()
  if not root then
    return false
  end
  local node = root:named_descendant_for_range(row, col, row, col)
  while node do
    local t = node:type()
    if t and t ~= "" then
      local lt = t:lower()
      for _, p in ipairs(pats) do
        if type(p) == "string" and p ~= "" then
          if lt:find(p:lower(), 1, true) then
            return true
          end
        end
      end
    end
    node = node:parent()
  end
  return false
end

return M
