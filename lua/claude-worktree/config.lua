local M = {}

M.defaults = {
  docker_image = "claude-worktree:latest",
  dockerfile_path = nil, -- nil = use bundled Dockerfile
  worktree_root = nil,   -- nil = <repo_root>/.worktrees
  container_prefix = "cw-",
  terminal = {
    split = "vertical",   -- "vertical" | "horizontal" | "tab"
    size = 80,
    splitright = true,    -- open vertical splits to the right
    splitbelow = false,   -- open horizontal splits below
  },
}

M.options = {}

function M.setup(user_config)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

return M
