local M = {}
local docker = require("claude-worktree.docker")
local config = require("claude-worktree.config")

local _bufs = {} -- [session.name] = bufnr

-- Opens (or reattaches to) the terminal buffer for a session.
function M.open_terminal(session)
  local bufnr = _bufs[session.name]

  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    local win = vim.fn.bufwinid(bufnr)
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
    else
      M._focus_or_split(bufnr)
    end
    return
  end

  bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "hide" -- closing the window keeps the process alive
  _bufs[session.name] = bufnr

  M._focus_or_split(bufnr)

  vim.fn.termopen(docker.get_exec_cmd(session.container), {
    on_exit = function(fin, code, bar)
      print("fin", fin)
      print("bar", bar)
      vim.schedule(function()
        vim.notify(
          string.format("[claude-worktree] Session '%s' exited (code %d).", session.name, code),
          vim.log.levels.WARN
        )
        _bufs[session.name] = nil
      end)
    end,
  })
end

-- Closes the window showing a session's terminal (buffer stays alive due to
-- bufhidden=hide, so the docker exec process keeps running).
function M.close_terminal(session)
  local bufnr = _bufs[session.name]
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end
  local win = vim.fn.bufwinid(bufnr)
  if win ~= -1 then
    vim.api.nvim_win_close(win, false)
  end
end

function M._focus_or_split(bufnr)
  local opts            = config.options.terminal
  local split           = opts.split or "vertical"
  local size            = opts.size or 80

  local prev_splitright = vim.o.splitright
  local prev_splitbelow = vim.o.splitbelow
  vim.o.splitright      = opts.splitright ~= false
  vim.o.splitbelow      = opts.splitbelow == true

  if split == "tab" then
    vim.cmd("tabnew")
  elseif split == "horizontal" then
    vim.cmd(size .. "split")
  else
    vim.cmd(size .. "vsplit")
  end
  vim.api.nvim_set_current_buf(bufnr)

  vim.o.splitright = prev_splitright
  vim.o.splitbelow = prev_splitbelow
end

return M
