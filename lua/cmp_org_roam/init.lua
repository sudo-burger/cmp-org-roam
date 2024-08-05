-- Custom nvim-cmp source for org-roam nodes.

local source = {}

source.new = function()
  return setmetatable({}, { __index = source })
end

source.get_keyword_pattern = function()
  return [[\w\+]]
end

function source:complete(request, callback)
  require('org-roam').database:files({ force = false }):next(function(files)
    local items = {}
    local input =
      string.sub(request.context.cursor_before_line, request.offset - 1)
    local line = request.context.cursor.row - 1
    local start_char = request.context.cursor.col - 1 - #input
    local end_char = request.context.cursor.col - 1
    for _, file in pairs(files.files) do
      local node_id = file:get_property 'id'

      -- Skip files that have no node_id or that are not valid org files.
      if not node_id or file.parser._valid == false then
        goto continue
      end
      -- In theory a node could have no title. Use the node's ID as fallback.
      local node_title = file:get_title() or node_id
      local title_and_aliases = { node_title }

      -- Aliases are stored as space-separated, double-quoted strings.
      -- Split here.
      local node_aliases = file:get_property 'roam_aliases'
      if node_aliases then
        for str in string.gmatch(node_aliases, '"(.-)"') do
          table.insert(title_and_aliases, str)
        end
      end

      for _, node_name in ipairs(title_and_aliases) do
        table.insert(items, {
          filterText = node_name,
          label = node_name,
          textEdit = {
            newText = '[[id:' .. node_id .. '][' .. node_name .. ']]',
            range = {
              start = {
                line = line,
                character = start_char,
              },
              ['end'] = {
                line = line,
                character = end_char,
              },
            },
          },
        })
      end
      ::continue::
    end
    callback {
      items = items,
    }
  end)
end

source.setup = function() end

return source
