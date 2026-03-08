local M            = {}

local PLUGIN_LABEL = "claude-worktree.plugin=1"
local CLAUDE_DIR   = vim.fn.expand("~/.claude")
local CLAUDE_JSON  = vim.fn.expand("~/.claude.json")
local HOST_UID     = vim.fn.system("id -u"):gsub("%s+", "")
local HOST_GID     = vim.fn.system("id -g"):gsub("%s+", "")

-- Builds the docker image from a Dockerfile.
-- cb(ok, err)
function M.build_image(dockerfile_path, tag, cb)
  local dir = vim.fn.fnamemodify(dockerfile_path, ":h")
  vim.notify("[claude-worktree] Building docker image " .. tag .. "...", vim.log.levels.INFO)
  vim.system(
    { "docker", "build", "-t", tag, "-f", dockerfile_path,
      "--build-arg", "UID=" .. HOST_UID,
      "--build-arg", "GID=" .. HOST_GID,
      dir },
    { text = true },
    function(out)
      if out.code ~= 0 then
        cb(false, "docker build failed:\n" .. (out.stderr or out.stdout or ""))
      else
        cb(true, nil)
      end
    end
  )
end

-- Creates and starts a container (runs `sleep infinity` as PID 1 so it stays alive).
-- Claude is attached later via `docker exec`.
--
-- opts: {
--   name            = string,  -- container name
--   worktree_path   = string,  -- host path, mounted rw at /workspace
--   git_common_dir  = string,  -- host path to <repo>/.git, mounted ro at /repo-git-ro
--   image           = string,
--   branch          = string,  -- stored as label for find_sessions
-- }
-- cb(ok, err)
function M.create_container(opts, cb)
  local args = {
    "docker", "run", "-d",
    "--name", opts.name,
    -- plugin discovery labels
    "--label", PLUGIN_LABEL,
    "--label", "claude-worktree.name=" .. opts.name,
    "--label", "claude-worktree.worktree=" .. opts.worktree_path,
    "--label", "claude-worktree.branch=" .. opts.branch,
    -- worktree files: read-write so Claude can edit code.
    -- Mount to a session-unique path so claude --continue tracks conversations
    -- per worktree rather than treating all sessions as the same project.
    "--mount", "type=bind,src=" .. opts.worktree_path .. ",dst=/workspace/" .. opts.name,
    -- git object store: read-only so commits are impossible
    "--mount", "type=bind,src=" .. opts.git_common_dir .. ",dst=/repo-git-ro,readonly",
    -- tell git to use the read-only common dir for objects/refs
    "--env", "GIT_COMMON_DIR=/repo-git-ro",
    -- persistent Claude credentials and config from the host
    "--mount", "type=bind,src=" .. CLAUDE_DIR .. ",dst=/home/claude/.claude",
    "--mount", "type=bind,src=" .. CLAUDE_JSON .. ",dst=/home/claude/.claude.json",
    "-w", "/workspace/" .. opts.name,
    opts.image,
    "sleep", "infinity",
  }

  vim.system(args, { text = true }, function(out)
    if out.code ~= 0 then
      cb(false, "docker run failed:\n" .. (out.stderr or out.stdout or ""))
    else
      cb(true, nil)
    end
  end)
end

-- Returns the shell command string to open Claude inside the container.
-- The working directory is set to the session-unique path so --continue
-- resumes the correct per-worktree conversation.
function M.get_exec_cmd(container_name)
  return "docker exec -it -w /workspace/" .. container_name ..
      " " .. container_name ..
      " sh -c 'claude --continue --dangerously-skip-permissions || claude --dangerously-skip-permissions'"
end

-- Stops a container. cb(ok, err)
function M.stop_container(name, cb)
  vim.system({ "docker", "stop", name }, { text = true }, function(out)
    cb(out.code == 0, out.code ~= 0 and (out.stderr or "") or nil)
  end)
end

-- Removes a container. cb(ok, err)
function M.remove_container(name, cb)
  vim.system({ "docker", "rm", "-f", name }, { text = true }, function(out)
    cb(out.code == 0, out.code ~= 0 and (out.stderr or "") or nil)
  end)
end

-- Returns true/false for whether the named container is running. cb(running, err)
function M.is_running(name, cb)
  vim.system(
    { "docker", "inspect", "--format", "{{.State.Running}}", name },
    { text = true },
    function(out)
      if out.code ~= 0 then
        cb(false, out.stderr)
      else
        cb(vim.trim(out.stdout) == "true", nil)
      end
    end
  )
end

return M
