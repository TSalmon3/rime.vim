local tscap = require("im.tscap")

local M = {}

--- Check whether the treesitter highlight captures at the cursor match.
--- @param pats string[] substring list, matched case-insensitively
---   against capture names (leading '@' ignored), e.g. "comment" hits
---   "@comment" and "markup.raw" hits "@markup.raw.block".
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
  return tscap.match(tscap.captures_at(0, row, col), pats)
end

return M
