local M = {}

M.defaults = {
  docker_image = "worktree-session:latest",
  dockerfile_path = nil, -- nil = use bundled Dockerfile
  container_prefix = "oc-",
  -- Command to run inside the container. Interpolated with the container name
  -- available as {name}.
  command = "opencode --continue",
  terminal = {
    split = "vertical", -- "vertical" | "horizontal" | "tab"
    size = 80,
    splitright = true,  -- open vertical splits to the right
    splitbelow = false, -- open horizontal splits below
  },
}

M.options = {}

function M.setup(user_config)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

return M
