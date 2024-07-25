-- Custom nvim-cmp source for org-roam nodes.

local source = {}

local registered = false

source.new = function()
  return setmetatable({}, { __index = source })
end

source.get_keyword_pattern = function()
  return [[\K\+]]
end

function source:complete(request, callback)
  -- Ingest the org-roam database.
  local db = vim.fn.json_decode(vim.fn.readfile(self.org_roam_db))
  local input =
    string.sub(request.context.cursor_before_line, request.offset - 1)
  -- Merge the node names and their aliases.
  local raw = vim.tbl_extend('force', db.indexes.alias, db.indexes.title)
  local items = {}
  for title, v in pairs(raw) do
    -- The db structure has:
    -- "<node name>": {
    --   "<node_id>": true
    -- },
    -- FIXIT: There must be better ways to get the node id.
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

source.setup = function()
  if registered then
    return
  end
  registered = true

  local has_cmp, _ = pcall(require, 'cmp')
  if not has_cmp then
    return
  end

  local has_org_roam, org_roam = pcall(require, 'org-roam')
  if not has_org_roam then
    return
  end

  source.org_roam_db = org_roam.database:path()
  if vim.fn.filereadable(source.org_roam_db) == 0 then
    return
  end
end

return source
