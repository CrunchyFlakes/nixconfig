-- UI stuff
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- to enable nvim-cmp (use in setup of lsps)
local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- to enable lsp-format (use in setup of lsps)
local on_attach = function(client)
  require("lsp-format").on_attach(client)
end

-- Python
vim.g.python3_host_prog = "$HOME/.pyenv/versions/neovim3/bin/python"
require('lspconfig').pyright.setup { capabilities = capabilities, on_attach = on_attach,
  settings = { exclude = { ".venv" }, venvPath = ".", venv = ".venv" } }

-- Lua
require('lspconfig').lua_ls.setup { capabilities = capabilities, on_attach = on_attach }

-- Haskell
require('lspconfig').hls.setup { capabilities = capabilities, on_attach = on_attach,
  filetypes = { 'haskell', 'lhaskell', 'cabal' } }
