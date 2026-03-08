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
