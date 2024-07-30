# cmp-org-roam

nvim-cmp source for [org-roam.nvim](https://github.com/chipsenkbeil/org-roam.nvim) nodes.

# Setup

None needed.

## Configuration

After installing the package, just add 'org_roam' to the the list of nvim-cmp sources.

Suggested lazy.nvim configuration:

```lua
return { 
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    { 'sudo-burger/cmp-org-roam', dependencies = { 'chipsenkbeil/org-roam.nvim' } },
  },
  config = function()
    cmp =  require('cmp')
    cmp.setup.filetype('org', {
      sources = cmp.config.sources {
        { name = 'org_roam' },
      },
    })
  end,
}
```
