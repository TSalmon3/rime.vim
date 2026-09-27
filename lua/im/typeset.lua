local tscap = require("im.tscap")

local M = {}

--- Collect protected byte intervals per line for [start1, end1].
--- @param bufnr integer buffer handle
--- @param start1 integer first line, 1-based
--- @param end1 integer last line, 1-based end-inclusive
--- @param pats string[] substring list, matched case-insensitively
---   against capture names (leading '@' ignored).
--- @return table row("5") -> list of {s, e} byte cols, 0-based end-exclusive.
function M.protected_map(bufnr, start1, end1, pats)
  local res = {}
  if type(pats) ~= "table" or #pats == 0 then
    return res
  end
  local lpats = {}
  for _, p in ipairs(pats) do
    local n = tscap.normalize(p)
    if n ~= "" then
      table.insert(lpats, n)
    end
  end
  if #lpats == 0 then
    return res
  end
  if type(bufnr) ~= "number" or not vim.api.nvim_buf_is_valid(bufnr) then
    return res
  end
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or parser == nil then
    return res
  end
  tscap.ensure_parsed(parser)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start1 - 1, end1, false)
  local lens = {}
  for i, l in ipairs(lines) do
    lens[start1 + i - 1] = vim.fn.strlen(l)
  end
  local function add(row, s, e) -- {{{
    if s >= e then
      return
    end
    local k = tostring(row)
    res[k] = res[k] or {}
    table.insert(res[k], { s, e })
  end -- }}}
  local qget = vim.treesitter.query.get
  local function cap_hit(cname) -- {{{
    local lc = tscap.normalize(cname)
    if lc == "" then
      return false
    end
    for _, p in ipairs(lpats) do
      if lc:find(p, 1, true) then
        return true
      end
    end
    return false
  end -- }}}
  local function process_tree(tree, lang) -- {{{
    if tree == nil or type(lang) ~= "string" or lang == "" then
      return
    end
    local okq, query = pcall(qget, lang, "highlights")
    if not okq or query == nil then
      return
    end
    local okroot, root = pcall(function()
      return tree:root()
    end)
    if not okroot or root == nil then
      return
    end
    local okiter, iter = pcall(function()
      return query:iter_captures(root, bufnr, start1 - 1, end1)
    end)
    if not okiter or iter == nil then
      return
    end
    for id, node in iter do
      if node ~= nil and cap_hit(query.captures[id]) then
        local sr, sc, er, ec = node:range()
        local r1 = math.max(sr + 1, start1)
        local r2 = math.min(er + 1, end1)
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
      end
    end
  end -- }}}
  pcall(function()
    parser:for_each_tree(function(tree, langtree)
      local lang = nil
      if langtree ~= nil and langtree.lang ~= nil then
        lang = langtree:lang()
      end
      if type(lang) ~= "string" or lang == "" then
        lang = parser:lang()
      end
      process_tree(tree, lang)
    end)
  end)
  return res
end

return M
