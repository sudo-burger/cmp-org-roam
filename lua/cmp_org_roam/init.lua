-- Custom nvim-cmp source for org-roam nodes.

local source = {}

source.new = function()
  local instance = setmetatable({}, { __index = source })
  local has_cmp, _ = pcall(require, 'cmp')
  if not has_cmp then
    return
  end

  local has_org_roam, org_roam = pcall(require, 'org-roam')
  if not has_org_roam then
    return
  end

  instance.org_roam_db = org_roam.database:path()
  if vim.fn.filereadable(instance.org_roam_db) == 0 then
    return
  end
  return instance
end

source.get_keyword_pattern = function()
  return [[\K\+]]
end

function source:complete(request, callback)
  -- Ingest the org-roam database.
  -- FIXIT: sync with db updates (e.g. new nodes).
  local db = vim.fn.json_decode(vim.fn.readfile(self.org_roam_db))
  local input =
    string.sub(request.context.cursor_before_line, request.offset - 1)
  -- Merge the node names and their aliases.
  -- The node structure is:
  -- "<node id>": {
  --   "title": "Something",
  --   "aliases": ["foo", "bar"],
  --   ...
  -- },
  -- In jq, the query would be '.nodes[]|.aliases[],.title|select(. != [])
  local items = {}
  for node_id, node in pairs(db.nodes) do
    local title_and_aliases =
      vim.tbl_extend('force', { node.title }, node.aliases)
    for _, v in pairs(title_and_aliases) do
      table.insert(items, {
        filterText = v,
        label = v,
        textEdit = {
          newText = '[[id:' .. node_id .. '][' .. v .. ']]',
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
  end
  callback {
    items = items,
    isIncomplete = true,
  }
end

source.setup = function() end

return source
