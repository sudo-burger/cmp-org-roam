-- Custom nvim-cmp source for org-roam nodes.

local source = {}

source.new = function()
  local instance = setmetatable({}, { __index = source })
  local has_cmp, _ = pcall(require, 'cmp')
  if not has_cmp then
    return
  end

  local has_org_roam, _ = pcall(require, 'org-roam')
  if not has_org_roam then
    error 'org-roam not found.'
    return
  end
  return instance
end

source.get_keyword_pattern = function()
  return [[\K\+]]
end

function source:complete(request, callback)
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
  local roam = require 'org-roam'
  local working = true
  roam.database:files():next(function(files)
    for _, file in pairs(files.files) do
      local node_id = file:get_property 'id'
      if node_id and file.parser._valid ~= false then
        local node_title = file:get_title() or node_id
        local title_and_aliases = {}
        table.insert(title_and_aliases, node_title)
        local node_aliases = file:get_property 'roam_aliases' or ''
        for str in string.gmatch(node_aliases, '([^%s]+)') do
          table.insert(title_and_aliases, str)
        end

        for _, v in ipairs(title_and_aliases) do
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
    end
    working = false
  end)
  callback {
    items = items,
    isIncomplete = working,
  }
end

source.setup = function() end

return source
