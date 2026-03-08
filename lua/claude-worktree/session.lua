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

-- Lists all current sessions by reading git worktree list --porcelain and
-- filtering to those matching our prefix.
-- function M.list()
--   local lines = vim.fn.systemlist("git worktree list --porcelain")
--   local sessions = {}
--   local cur = {}
--
--   local function flush()
--     if cur.path then
--       local s = M.from_worktree(cur.path, cur.branch)
--       if s then table.insert(sessions, s) end
--     end
--     cur = {}
--   end
--
--   for _, line in ipairs(lines) do
--     if line == "" then
--       flush()
--     elseif vim.startswith(line, "worktree ") then
--       cur.path = line:sub(10)
--     elseif vim.startswith(line, "branch ") then
--       cur.branch = line:sub(8):match("refs/heads/(.+)") or line:sub(8)
--     end
--   end
--   flush()
--
--   return sessions
-- end

-- Stub: override this after setup() if you want custom session discovery.
function M.find_sessions() end

return M
