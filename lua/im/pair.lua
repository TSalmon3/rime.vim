local tscap = require("im.tscap")

local M = {}

--- Check whether the treesitter highlight captures at the cursor match.
--- Same capture semantics as im.context: case-insensitive substring
--- against capture names with the leading '@' ignored.
--- @param pats string[] config patterns, e.g. {"comment", "string"}
--- @return boolean true when blocked.
function M.ts_blocked(pats)
  if type(pats) ~= "table" or #pats == 0 then
    return false
  end
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local len = vim.fn.strlen(vim.fn.getline(row + 1))
  if col >= len then
    col = len - 1
  end
  if col < 0 then
    col = 0
  end
  return tscap.match(tscap.captures_at(0, row, col), pats)
end

return M
