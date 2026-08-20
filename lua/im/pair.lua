local M = {}

function M.ts_blocked(pats)
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local len = vim.fn.strlen(vim.fn.getline(row + 1))
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
  local root = parser:parse()[1]:root()
  local node = root:named_descendant_for_range(row, col, row, col)
  while node do
    local t = node:type()
    for _, p in ipairs(pats) do
      if p ~= "" and t:lower():find(p:lower(), 1, true) then
        return true
      end
    end
    node = node:parent()
  end
  return false
end

return M
