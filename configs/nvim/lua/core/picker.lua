local M = {}

vim.o.wildmode = "noselect:lastused,full"
vim.o.wildoptions = "pum,fuzzy"

local group = vim.api.nvim_create_augroup("core.picker", {})

vim.api.nvim_create_autocmd("CmdlineChanged", {
  group = group,
  pattern = { ":", "/", "?" },
  callback = function()
    vim.fn.wildtrigger()
  end,
})

vim.keymap.set("c", "<Up>", function()
  return vim.fn.wildmenumode() == 1 and "<C-e><Up>" or "<Up>"
end, { expr = true })
vim.keymap.set("c", "<Down>", function()
  return vim.fn.wildmenumode() == 1 and "<C-e><Down>" or "<Down>"
end, { expr = true })

local files_cache = {}

local function list_files()
  if vim.fn.executable("fd") == 1 then
    return vim.fn.systemlist({ "fd", "--type", "f", "--hidden", "--follow", "--exclude", ".git", "--exclude", "node_modules" })
  end
  local files = vim.fn.globpath(".", "**", true, true)
  files = vim.tbl_filter(function(f)
    return vim.fn.isdirectory(f) == 0 and not f:find("/node_modules/", 1, true)
  end, files)
  return vim.tbl_map(function(f)
    return vim.fn.fnamemodify(f, ":.")
  end, files)
end

function M.find(arg, _)
  if #files_cache == 0 then
    files_cache = list_files()
  end
  return arg == "" and files_cache or vim.fn.matchfuzzy(files_cache, arg)
end

vim.o.findfunc = "v:lua.require'core.picker'.find"

local function grep(pattern)
  local cmd
  if vim.fn.systemlist({ "git", "rev-parse", "--is-inside-work-tree" })[1] == "true" then
    cmd = { "git", "grep", "-n", "--column", "-I", "--untracked", "-e", pattern }
  else
    cmd = { "grep", "-rnIH", "--exclude-dir=.git", "--exclude-dir=node_modules", "-e", pattern, "." }
  end
  local lines = vim.fn.systemlist(cmd)
  return vim.list_slice(lines, 1, 200)
end

local grep_selected

vim.api.nvim_create_user_command("Grep", function()
  if not grep_selected then
    return
  end
  local file, lnum, col = grep_selected:match("^(.-):(%d+):(%d*):?")
  grep_selected = nil
  if not file then
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(file))
  vim.api.nvim_win_set_cursor(0, { tonumber(lnum), math.max((tonumber(col) or 1) - 1, 0) })
end, {
  nargs = "+",
  complete = function(_, cmdline)
    local pattern = cmdline:match("^%s*Grep%s+(.*)$") or ""
    return #pattern > 1 and grep(pattern) or {}
  end,
})

vim.api.nvim_create_autocmd("CmdlineLeavePre", {
  group = group,
  pattern = ":",
  callback = function()
    local info = vim.fn.cmdcomplete_info()
    if vim.tbl_isempty(info.matches or {}) then
      return
    end
    local cmdline = vim.fn.getcmdline()
    if cmdline:match("^%s*fin?d?%s") and info.selected == -1 then
      vim.fn.setcmdline("find " .. info.matches[1])
    elseif cmdline:match("^%s*Grep%s") then
      grep_selected = info.matches[info.selected ~= -1 and info.selected + 1 or 1]
      vim.fn.setcmdline(info.cmdline_orig)
    end
  end,
})

vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = group,
  pattern = ":",
  callback = function()
    files_cache = {}
  end,
})

return M
