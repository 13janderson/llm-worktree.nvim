if vim.g.opencode_worktree_loaded then return end
vim.g.opencode_worktree_loaded = true

local cw = require("opencode-worktree")

vim.api.nvim_create_user_command("OpenCodeWorktreeNew", function(args)
  local opts = {}
  if args.args and args.args ~= "" then
    opts.branch = args.args
  end
  cw.new_session(opts)
end, {
  nargs = "?",
  desc  = "Create a new OpenCode worktree session (optional: branch name)",
})

vim.api.nvim_create_user_command("OpenCodeWorktreeSwitch", function()
  cw.switch_session()
end, { desc = "Switch OpenCode worktree sessions" })

vim.api.nvim_create_user_command("OpenCodeWorktreeDelete", function(args)
  cw.delete_session(args.args ~= "" and args.args or nil)
end, {
  nargs = "?",
  desc  = "Delete an OpenCode worktree session",
})

-- New session
vim.keymap.set("n", "<leader>cn", cw.new_session, { desc = "OpenCode: new session" })

-- Switch / list sessions (opens git-worktree telescope picker)
vim.keymap.set("n", "<leader>cs", cw.switch_session, { desc = "OpenCode: switch session" })
