-- UI stuff
local signs = { Error = "⚡", Warn = "⚠ ", Hint = "💡", Info = " " }

-- LSP capabilities from blink.cmp (replaces nvim-cmp)
local capabilities = require("blink.cmp").get_lsp_capabilities()
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Python
vim.lsp.config("pyright", {
  capabilities = capabilities,
  settings = {
    exclude = { ".venv" },
    venvPath = ".",
    venv = ".venv"
  }
})
vim.lsp.enable({ "pyright" })

-- Lua
vim.lsp.config("lua_ls", {
  capabilities = capabilities,
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc') then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT'
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME
          -- Depending on the usage, you might want to add additional paths here.
          -- "${3rd}/luv/library"
          -- "${3rd}/busted/library",
        }
        -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
        -- library = vim.api.nvim_get_runtime_file("", true)
      }
    })
  end,
  settings = {
    Lua = {}
  }
})
vim.lsp.enable({ "lua_ls" })

-- Haskell
vim.lsp.config("hls", {
  capabilities = capabilities,
  filetypes = { 'haskell', 'lhaskell', 'cabal' }
})
vim.lsp.enable({ "hls" })

-- C/C++
vim.lsp.config("clangd", { capabilities = capabilities, })
vim.lsp.enable({ "clangd" })

-- Nix
vim.lsp.config("nixd", { capabilities = capabilities, })
vim.lsp.enable({ "nixd" })
