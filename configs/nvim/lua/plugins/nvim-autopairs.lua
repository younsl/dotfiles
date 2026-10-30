local npairs = require("nvim-autopairs")

npairs.setup({ map_cr = false })

vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    if vim.fn.complete_info({ "selected" }).selected == -1 then
      return vim.keycode("<C-n><C-y>")
    end
    return vim.keycode("<C-y>")
  end
  return npairs.autopairs_cr()
end, { expr = true, replace_keycodes = false, desc = "Confirm completion or autopairs newline" })
