local M = {}

local config = require("claude-worktree.config")
local session = require("claude-worktree.session")
local docker = require("claude-worktree.docker")
local ui = require("claude-worktree.ui")

-- ─── Internal: spin up Docker and open terminal after worktree exists ─────────
local function start_session(sname, branch, worktree_path)
  local image = config.options.docker_image

  local this_file = debug.getinfo(1, "S").source:sub(2)
  local plugin_root = this_file:match("^(.*)/lua/claude%-worktree/init%.lua$")
  local dockerfile = config.options.dockerfile_path or (plugin_root and (plugin_root .. "/docker/Dockerfile"))

  if not dockerfile then
    vim.notify("[claude-worktree] Could not locate Dockerfile. Set config.dockerfile_path.", vim.log.levels.ERROR)
    return
  end

  local git_common_dir = require("git-worktree.git").gitroot_dir()
  if not git_common_dir then
    vim.notify("[claude-worktree] Could not resolve git common dir.", vim.log.levels.ERROR)
    return
  end

  vim.notify("[claude-worktree] Starting container '" .. sname .. "'...", vim.log.levels.INFO)

  docker.build_image(dockerfile, image, function(img_ok, img_err)
    if not img_ok then
      vim.schedule(function()
        vim.notify("[claude-worktree] " .. img_err, vim.log.levels.ERROR)
      end)
      return
    end

    docker.create_container({
      name = sname,
      worktree_path = worktree_path,
      git_common_dir = git_common_dir,
      image = image,
      branch = branch,
    }, function(ctr_ok, ctr_err)
      if not ctr_ok then
        vim.schedule(function()
          vim.notify("[claude-worktree] " .. ctr_err, vim.log.levels.ERROR)
        end)
        return
      end

      vim.schedule(function()
        ui.open_terminal(session.from_worktree(worktree_path, branch))
      end)
    end)
  end)
end

-- ─── Setup ───────────────────────────────────────────────────────────────────

function M.setup(user_config)
  config.setup(user_config)

  local Hooks = require("git-worktree.hooks")

  -- When git-worktree switches to a worktree, open the claude terminal if it
  -- matches our naming convention.
  Hooks.register(Hooks.type.SWITCH, function(path, prev_path)
    vim.schedule(function()
      local prev = session.from_worktree(prev_path)
      if prev then
        ui.close_terminal(prev)
      end

      local s = session.from_worktree(path)
      if not s then
        return
      end

      docker.is_running(s.container, function(running)
        if running then
          vim.schedule(function()
            ui.open_terminal(s)
          end)
        end
      end)
    end)
  end)

  -- When git-worktree deletes a worktree (e.g. via <C-d> in the telescope
  -- picker), clean up the associated container.
  Hooks.register(Hooks.type.DELETE, function(path)
    local s = session.from_worktree(path)
    if not s then
      return
    end
    docker.stop_container(s.container, function() end)
    docker.remove_container(s.container, function(_, err)
      if err then
        vim.schedule(function()
          vim.notify("[claude-worktree] docker rm: " .. err, vim.log.levels.WARN)
        end)
      end
    end)
  end)
end

-- ─── New session ─────────────────────────────────────────────────────────────
-- opts (all optional):
--   branch    string  -- branch name (default: "claude-<timestamp>")
--   upstream  string  -- upstream to track
--   name      string  -- override container/session name

function M.new_session(opts)
  opts = opts or {}

  local ok, gw = pcall(require, "git-worktree")
  if not ok then
    vim.notify("[claude-worktree] git-worktree.nvim is required but not found.", vim.log.levels.ERROR)
    return
  end

  local Hooks = require("git-worktree.hooks")
  local git = require("git-worktree.git")

  local ts = tostring(os.time())
  local branch = opts.branch or ("claude-" .. ts)
  local sname = opts.name or (config.options.container_prefix .. branch:gsub("[^%w%-]", "-"))
  local wt_path = git.gitroot_dir() .. "/" .. sname

  vim.notify("[claude-worktree] Creating worktree for session '" .. sname .. "'...", vim.log.levels.INFO)

  local fired = false
  Hooks.register(Hooks.type.CREATE, function(path, created_branch, _upstream)
    if fired then
      return
    end
    if created_branch ~= branch and path ~= wt_path then
      return
    end
    fired = true
    start_session(sname, created_branch, path)
  end)

  gw.create_worktree(wt_path, branch, opts.upstream)
end

-- ─── Switch session ───────────────────────────────────────────────────────────

function M.switch_session()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("[claude-worktree] telescope.nvim is required for session switching.", vim.log.levels.ERROR)
    return
  end
  local telescope_worktree = require("telescope").load_extension("git_worktree")
  telescope_worktree.git_worktree({
    -- worktree search for specifically claude worktrees
    default_text = 'claude'
  })
end

M.list_sessions = M.switch_session
return M
