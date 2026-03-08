local M = {}

M.defaults = {
  docker_image = "worktree-session:latest",
  dockerfile_path = nil,  -- nil = use bundled Dockerfile
  container_prefix = "cw-",
  -- Command to run inside the container. Interpolated with the container name
  -- available as {name}. Defaults to claude with --continue fallback.
  command = "claude --continue --dangerously-skip-permissions || claude --dangerously-skip-permissions",
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
