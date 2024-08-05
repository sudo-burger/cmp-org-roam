-- See: https://neovim.io/doc/user/pi_health.html#health-functions
local M = {}
M.check = function()
  local deps = {
    'cmp',
    'org-roam',
  }
  vim.health.start 'cmp-org-roam report'
  for _, item in ipairs(deps) do
    local has_item, _ = pcall(require, item)
    if has_item then
      vim.health.ok(item .. ' found.')
    else
      vim.health.error(item .. ' not found.')
    end
  end
  -- make sure setup function parameters are ok
  -- if check_setup() then
  --   vim.health.ok("Setup is correct")
  -- else
  --   vim.health.error("Setup is incorrect")
  -- end
  -- -- do some more checking
  -- -- ...
  -- vim.health.ok 'Setup is correct'
end
return M
