vim.o.autocomplete = true
vim.o.complete = ".^5,w^5,b^5"
vim.o.completeopt = "menuone,noselect,popup,fuzzy,nearest"
vim.o.pumborder = "rounded"

local word_chars = vim.split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_", "")

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("core.completion", {}),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    if not client:supports_method("textDocument/completion") then
      return
    end

    local provider = client.server_capabilities.completionProvider
    local triggers = vim.list_extend(vim.list_extend({}, word_chars), provider.triggerCharacters or {})
    vim.list.unique(triggers)
    provider.triggerCharacters = triggers

    vim.bo[ev.buf].autocomplete = false
    vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
  end,
})

local function tab(direction, key, pum_key)
  return function()
    if vim.fn.pumvisible() == 1 then
      return pum_key
    end
    if vim.snippet.active({ direction = direction }) then
      return ("<Cmd>lua vim.snippet.jump(%d)<CR>"):format(direction)
    end
    return key
  end
end

vim.keymap.set("i", "<Tab>", tab(1, "<Tab>", "<C-n>"), { expr = true, desc = "Next completion item or snippet jump" })
vim.keymap.set("i", "<S-Tab>", tab(-1, "<S-Tab>", "<C-p>"), { expr = true, desc = "Previous completion item or snippet jump" })

vim.keymap.set("i", "<C-Space>", function()
  if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/completion" }) > 0 then
    vim.lsp.completion.get()
  else
    vim.api.nvim_feedkeys(vim.keycode("<C-n>"), "n", false)
  end
end, { desc = "Trigger completion" })
