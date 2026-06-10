-- QoL bindings
vim.keymap.set("i", "<leader>n", "<Esc>:noh<CR><Esc>")
vim.keymap.set("n", "<Esc>", "<Esc>:noh<CR><Esc>")
vim.keymap.set("n", "U", "<C-r>")
vim.keymap.set("n", "<leader>qc", ":lclose<CR>") -- close quickfix window
vim.keymap.set("n", "<leader>qo", ":lopen<CR>")  -- open quickfix window

-- LSP bindings
vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
-- Lspsaga
vim.keymap.set("n", "<leader>ld", ":Lspsaga goto_definition<CR>")
vim.keymap.set("n", "<leader>lr", ":Lspsaga finder<CR>")
vim.keymap.set("n", "<leader>lci", ":Lspsaga incoming_calls<CR>")
vim.keymap.set("n", "<leader>lco", ":Lspsaga outgoing_calls<CR>")
vim.keymap.set("n", "<leader>lo", ":Lspsaga outline<CR>")

-- Windows
vim.keymap.set("n", "<A-h>", "<C-w>h")
vim.keymap.set("n", "<A-j>", "<C-w>j")
vim.keymap.set("n", "<A-k>", "<C-w>k")
vim.keymap.set("n", "<A-l>", "<C-w>l")
vim.keymap.set("n", "<A-CR>", ":ToggleTerm<CR>")
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
vim.keymap.set("t", "<A-CR>", "<C-\\><C-n>:ToggleTerm<CR>")

-- ToggleTerm
vim.keymap.set("n", "<C-A-/>", ":ToggleTerm direction=float<CR>")
vim.keymap.set("n", "<A-/>", ":ToggleTerm direction=horizontal<CR>")

-- Telescope bindings (lazy-loaded on first use)
vim.keymap.set("n", "<leader>ff", function() require('telescope.builtin').find_files() end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", function() require('telescope.builtin').live_grep() end, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", function() require('telescope.builtin').buffers() end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", function() require('telescope.builtin').help_tags() end, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fp", function()
  local project = require('telescope').extensions.project
  project.project()
end, { desc = "Projects" })
vim.keymap.set("n", "<leader>ft", function() require('telescope.builtin').live_grep({ search_file = 'TODO' }) end, { desc = "Find TODO" })

-- Obsidian bindings
vim.keymap.set("n", "<leader>dn", ":ObsidianToday<CR>", {})
vim.keymap.set("n", "<leader>fn", ":ObsidianQuickSwitch<CR>", {})
vim.keymap.set("n", "<leader>fm", ":ObsidianSearch<CR>", {})
vim.keymap.set("n", "<leader>cn", ":ObsidianNew<CR>", {})

-- Neogen bindings
vim.keymap.set("n", "<Leader>d", function() require('neogen').generate() end, { noremap = true, silent = true })

-- LSP
vim.keymap.set("n", "<leader>?", vim.lsp.buf.hover, {})


-- # Jupyter Notebooks {{{
-- Magma
--vim.keymap.set('n', '<Leader>r', ':MagmaEvaluateOperator<CR>', { silent = true, expr = true, noremap = true } )
--vim.keymap.set('n', '<Leader>rr', ':MagmaEvaluateLine<CR>', { silent = true, noremap = true })
--vim.keymap.set('x', '<Leader>r', ':<C-u>MagmaEvaluateVisual<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<Leader>rc', ':MagmaReevaluateCell<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<Leader>rd', ':MagmaDelete<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<Leader>ro', ':MagmaShowOutput<CR>', { noremap = true, silent = true })
-- Molten
vim.keymap.set("n", "<Leader>e", ":MoltenEvaluateOperator<CR>", { desc = "evaluate operator", silent = true })
vim.keymap.set("n", "<Leader>os", ":noautocmd MoltenEnterOutput<CR>", { desc = "open output window", silent = true })
vim.keymap.set("n", "<Leader>of", ":noautocmd MoltenEnterOutput<CR>:wincmd _<CR>:wincmd |<CR>", { desc = "open output window", silent = true })

vim.keymap.set("n", "<Leader>rr", ":MoltenReevaluateCell<CR>", { desc = "re-eval cell", silent = true })
vim.keymap.set("v", "<Leader>r", ":<C-u>MoltenEvaluateVisual<CR>gv<ESC>", { desc = "execute visual selection", silent = true })
vim.keymap.set("n", "<Leader>oh", ":MoltenHideOutput<CR>", { desc = "close output window", silent = true })
vim.keymap.set("n", "<Leader>md", ":MoltenDelete<CR>", { desc = "delete Molten cell", silent = true })
vim.keymap.set("n", "<Leader>os", ":noautocmd MoltenEnterOutput<CR>",
    { silent = true, desc = "show/enter output" })

-- Quarto (deferred: quarto.runner requires otter.nvim which is set up by home-manager after keybindings.lua loads)
vim.keymap.set("n", "<Leader>rc", function() require("quarto.runner").run_cell() end,  { desc = "run cell", silent = true })
vim.keymap.set("n", "<Leader>ra", function() require("quarto.runner").run_above() end, { desc = "run cell and above", silent = true })
vim.keymap.set("n", "<Leader>rA", function() require("quarto.runner").run_all() end,   { desc = "run all cells", silent = true })
vim.keymap.set("n", "<Leader>rl", function() require("quarto.runner").run_line() end,  { desc = "run line", silent = true })
vim.keymap.set("v", "<Leader>r",  function() require("quarto.runner").run_range() end, { desc = "run visual range", silent = true })
vim.keymap.set("n", "<Leader>RA", function() require("quarto.runner").run_all(true) end, { desc = "run all cells of all languages", silent = true })
-- }}} Jupyter Notebooks
