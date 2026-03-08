local M = {}

-- A session is any git worktree whose directory name starts with the
-- configured container_prefix. Container name == worktree basename.

local function get_prefix()
  return require("claude-worktree.config").options.container_prefix
end

-- Builds a lightweight session object from a worktree path (and optional branch).
-- Returns nil if the path doesn't match our naming convention.
function M.from_worktree(path, branch)
  local name = vim.fn.fnamemodify(path:gsub("/$", ""), ":t")
  if not vim.startswith(name, get_prefix()) then return nil end
  return {
    name      = name,
    branch    = branch,
    worktree  = path,
    container = name,
  }
end

return M
