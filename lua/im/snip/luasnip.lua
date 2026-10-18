local M = {}

local function collect(ls, ft, out, seen)
  local ok, list = pcall(function()
    return ls.get_snippets(ft)
  end)
  if not ok or type(list) ~= "table" then
    return
  end
  for _, sn in ipairs(list) do
    local trigger = sn.trigger or sn.trig or ""
    if type(trigger) == "table" then
      trigger = trigger[1] or ""
    end
    if type(trigger) == "string" and trigger ~= "" and not seen[trigger] then
      seen[trigger] = true
      local raw = sn.dscr or sn.description or sn.desc
      local desc = ""
      if type(raw) == "table" then
        desc = table.concat(raw, " ")
      elseif type(raw) == "string" then
        desc = raw
      end
      if desc == "" then
        local nm = sn.name or ""
        desc = type(nm) == "string" and nm or ""
      end
      table.insert(out, {
        word = trigger,
        menu = desc,
      })
    end
  end
end

function M.items(ft)
  local ok, ls = pcall(require, "luasnip")
  if not ok or ls == nil then
    return {}
  end
  if type(ls.get_snippets) ~= "function" then
    return {}
  end
  if type(ft) ~= "string" or ft == "" then
    ft = vim.bo.filetype
  end
  local out, seen = {}, {}
  collect(ls, ft, out, seen)
  if ft ~= "all" then
    collect(ls, "all", out, seen)
  end
  return out
end

return M
