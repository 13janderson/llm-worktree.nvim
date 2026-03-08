if vim.g.claude_worktree_loaded then return end
vim.g.claude_worktree_loaded = true

local cw = require("claude-worktree")

vim.api.nvim_create_user_command("ClaudeWorktreeNew", function(args)
  local opts = {}
  if args.args and args.args ~= "" then
    opts.branch = args.args
  end
  cw.new_session(opts)
end, {
  nargs = "?",
  desc  = "Create a new Claude worktree session (optional: branch name)",
})

vim.api.nvim_create_user_command("ClaudeWorktreeSwitch", function()
  cw.switch_session()
end, { desc = "Switch Claude worktree sessions" })

vim.api.nvim_create_user_command("ClaudeWorktreeDelete", function(args)
  cw.delete_session(args.args ~= "" and args.args or nil)
end, {
  nargs = "?",
  desc  = "Delete a Claude worktree session",
})

-- New session
vim.keymap.set("n", "<leader>cn", cw.new_session, { desc = "Claude: new session" })

-- Switch / list sessions (opens git-worktree telescope picker)
vim.keymap.set("n", "<leader>cs", cw.switch_session, { desc = "Claude: switch session" })
