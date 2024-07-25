-- Custom nvim-cmp source for org-roam nodes.

local nodes = {}

local registered = false

nodes.setup = function()
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

  source.new = function()
    return setmetatable({}, { __index = source })
  end

  source.get_trigger_characters = function()
    return { '@' }
  end

  source.get_keyword_pattern = function()
    -- Add dot to existing keyword characters (\k).
    return [[\%(\k\|\.\)\+]]
  end

  source.complete = function(self, request, callback)
    local input =
      string.sub(request.context.cursor_before_line, request.offset - 1)
    local prefix =
      string.sub(request.context.cursor_before_line, 1, request.offset - 1)

    if
      vim.startswith(input, '@')
      and (prefix == '@' or vim.endswith(prefix, ' @'))
    then
      local raw = vim.tbl_extend('force', db.indexes.alias, db.indexes.title)
      local items = {}
      for title, v in pairs(raw) do
        local node_id = 'deadbeef'
        for k, _ in pairs(v) do
          node_id = k
          break
        end
        table.insert(items, {
          filterText = title,
          label = title,
          textEdit = {
            newText = '[[' .. node_id .. '][' .. title .. ']]',
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
    else
      callback { isIncomplete = true }
    end
  end

  cmp.register_source('nodes', source.new())

  cmp.setup.filetype('org', {
    sources = cmp.config.sources {
      -- { name = 'luasnip' },
      -- { name = 'buffer' },
      -- { name = 'calc' },
      -- { name = 'emoji' },
      -- { name = 'path' },

      -- My custom sources.
      { name = 'nodes' },
    },
  })
end

return nodes
