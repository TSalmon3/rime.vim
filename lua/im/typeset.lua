local M = {}

local function type_match(t, lpats)
  if not t or t == "" then
    return false
  end
  local lt = t:lower()
  for _, p in ipairs(lpats) do
    if lt:find(p, 1, true) then
      return true
    end
  end
  return false
end

--- Collect protected byte intervals per line for [start1, end1] (1-based,
--- end-inclusive) whose treesitter node type (or any ancestor) matches pats.
--- Substring match, case-insensitive — same semantics as im#pair#cond.
--- @return table row(1-based) -> list of {s, e} byte cols, 0-based end-exclusive.
function M.protected_map(bufnr, start1, end1, pats)
  local res = {}
  if type(pats) ~= "table" or #pats == 0 then
    return res
  end
  local lpats = {}
  for _, p in ipairs(pats) do
    if type(p) == "string" and p ~= "" then
      table.insert(lpats, p:lower())
    end
  end
  if #lpats == 0 then
    return res
  end
  if type(bufnr) ~= "number" or not vim.api.nvim_buf_is_valid(bufnr) then
    return res
  end
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return res
  end
  local ok2, trees = pcall(function()
    return parser:parse()
  end)
  if not ok2 or not trees or not trees[1] then
    return res
  end
  local root = trees[1]:root()
  if not root then
    return res
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, start1 - 1, end1, false)
  local lens = {}
  for i, l in ipairs(lines) do
    lens[start1 + i - 1] = vim.fn.strlen(l)
  end
  local function add(row, s, e)
    if s >= e then
      return
    end
    res[row] = res[row] or {}
    table.insert(res[row], { s, e })
  end
  -- Record at the highest matching node; children are covered, stop descent.
  local function walk(node)
    local matched = type_match(node:type(), lpats)
    local sr, sc, er, ec = node:range()
    local r1 = math.max(sr + 1, start1)
    local r2 = math.min(er + 1, end1)
    if r1 > r2 then
      return
    end
    if matched then
      for row = r1, r2 do
        local len = lens[row] or 0
        local s = (row == sr + 1) and sc or 0
        local e = (row == er + 1) and ec or len
        if s < 0 then
          s = 0
        end
        if e > len then
          e = len
        end
        add(row, s, e)
      end
      return
    end
    for child in node:iter_children() do
      if child:named() then
        local cr, _, cr2 = child:range()
        if not (cr2 + 1 < start1 or cr + 1 > end1) then
          walk(child)
        end
      end
    end
  end
  local ok3 = pcall(walk, root)
  if not ok3 then
    return {}
  end
  return res
end

return M
