local util = require("trouble.util")
local qf = require("trouble.providers.qf")
local telescope = require("trouble.providers.telescope")
local lsp = require("trouble.providers.lsp")

local M = {}

M.providers = {
  lsp_workspace_diagnostics = lsp.diagnostics,
  lsp_document_diagnostics = lsp.diagnostics,
  lsp_references = lsp.references,
  lsp_definitions = lsp.definitions,
  quickfix = qf.qflist,
  loclist = qf.loclist,
  telescope = telescope.telescope,
}

---@param options Options
function M.get(win, buf, cb, options)
  local name = options.mode
  local provider = M.providers[name]

  if not provider then
    local ok, mod = pcall(require, "trouble.providers." .. name)
    if ok then
      M.providers[name] = mod
      provider = mod
    end
  end

  if not provider then
    util.error(("invalid provider %q"):format(name))
    return {}
  end

  provider(win, buf, function(items)
    -- 1: Error, 2: Warning, 3: Info, 4: Hint
    -- We're trying to keep the hints sorted underneath the errors and warnings 
    -- they arrive with while still surfacing errors above warnings above infos
    local errors = {}
    local warnings = {}
    local infos = {}

    local cur_bucket = infos
    for i, item in pairs(items) do
      if item.severity == 1 then
        cur_bucket = errors
      elseif item.severity == 2 then
        cur_bucket = warnings
      elseif item.severity == 3 then
        cur_bucket = infos
      end
      table.insert(cur_bucket, item)
    end

    local result = {}
    for i, x in pairs(errors) do table.insert(result, x) end
    for i, x in pairs(warnings) do table.insert(result, x) end
    for i, x in pairs(infos) do table.insert(result, x) end
    cb(result)
  end, options)
end

---@param items Item[]
---@return table<string, Item[]>
function M.group(items)
  local ret = {}
  for _, item in ipairs(items) do
    if ret[item.filename] == nil then
      ret[item.filename] = {}
    end
    table.insert(ret[item.filename], item)
  end
  return ret
end

return M
