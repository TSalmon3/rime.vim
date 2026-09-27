local M = {}

--- Strip a leading '@' and lowercase the name.
--- @param s string|nil
--- @return string
function M.normalize(s) -- {{{
  if type(s) ~= "string" then
    return ""
  end
  if s:sub(1, 1) == "@" then
    s = s:sub(2)
  end
  return s:lower()
end -- }}}

--- Substring match (case-insensitive, '@'-insensitive).
--- @param captures string[] capture names, e.g. {"markup.raw.block"}
--- @param pats string[] config patterns, e.g. {"markup.raw"}
--- @return boolean
function M.match(captures, pats) -- {{{
  local lpats = {}
  if type(pats) == "table" then
    for _, p in ipairs(pats) do
      local n = M.normalize(p)
      if n ~= "" then
        table.insert(lpats, n)
      end
    end
  end
  if #lpats == 0 then
    return false
  end
  if type(captures) ~= "table" then
    return false
  end
  for _, c in ipairs(captures) do
    local lc = M.normalize(c)
    if lc ~= "" then
      for _, p in ipairs(lpats) do
        if lc:find(p, 1, true) then
          return true
        end
      end
    end
  end
  return false
end -- }}}

--- Parse (including injections) so captures resolve headless too. Never errors.
--- @param parser vim.treesitter.LanguageTree|nil
function M.ensure_parsed(parser) -- {{{
  if parser == nil then
    return
  end
  pcall(parser.parse, parser, true)
end -- }}}

--- Capture names covering (row0, col0). 0-based row, 0-based byte col.
--- Never errors; returns {} when treesitter is unavailable.
--- @param bufnr integer buffer handle (0 = current)
--- @param row0 integer 0-based row
--- @param col0 integer 0-based byte col
--- @return string[] capture names without '@'
function M.captures_at(bufnr, row0, col0) -- {{{
  if type(row0) ~= "number" or type(col0) ~= "number" then
    return {}
  end
  if type(bufnr) ~= "number" then
    bufnr = 0
  end
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or parser == nil then
    return {}
  end
  M.ensure_parsed(parser)
  local ok2, caps = pcall(vim.treesitter.get_captures_at_pos, bufnr, row0, col0)
  if not (ok2 and type(caps) == "table") then
    return {}
  end
  local out = {}
  for _, c in ipairs(caps) do
    if type(c) == "table" and type(c.capture) == "string" then
      table.insert(out, c.capture)
    end
  end
  return out
end -- }}}

return M
