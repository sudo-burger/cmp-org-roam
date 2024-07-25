-- Custom nvim-cmp source for org-roam nodes.

local M = {}

local registered = false

M.setup = function()
  -- if registered then
  --   return
  -- end
  registered = true

  local has_cmp, cmp = pcall(require, 'cmp')
  if not has_cmp then
    return
  end

  local has_org_roam, org_roam = pcall(require, 'org-roam')
  if not has_org_roam then
    return
  end
  -- Ingest the org-roam database.
  local config = org_roam.database:path()
  if vim.fn.filereadable(config) == 0 then
    return
  end
  local db = vim.fn.json_decode(vim.fn.readfile(config))

  local source = {}

  function source.new()
    return setmetatable({}, { __index = source })
  end

  function source:get_keyword_pattern()
    return [[\K\+]]
  end

  function source:complete(request, callback)
    local input =
      string.sub(request.context.cursor_before_line, request.offset - 1)
    local prefix =
      string.sub(request.context.cursor_before_line, 1, request.offset - 1)

    -- Merge the node names and their aliases.
    local raw = vim.tbl_extend('force', db.indexes.alias, db.indexes.title)
    local items = {}
    for title, v in pairs(raw) do
      -- The db structure has:
      -- "<node name>": {
      --   "<node_id>": true
      -- },
      -- FIXIT: This is a stupid hack to get the node_id.
      local node_id = 'deadbeef'
      for k, _ in pairs(v) do
        node_id = k
        break
      end
      table.insert(items, {
        filterText = title,
        label = title,
        textEdit = {
          newText = '[[id:' .. node_id .. '][' .. title .. ']]',
          range = {
            start = {
              line = request.context.cursor.row - 1,
              character = request.context.cursor.col - 1 - #input,
            },
            ['end'] = {
              line = request.context.cursor.row - 1,
              character = request.context.cursor.col - 1,
            },
          },
        },
      })
    end
    callback {
      items = items,
      isIncomplete = true,
    }
  end

  cmp.register_source('cmp-org-roam', source.new())
end

return M
