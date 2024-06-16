-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })

vim.api.nvim_set_keymap('n', 'ª', ':m .-2<CR>==', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '√', ':m .+1<CR>==', { noremap = true, silent = true })

vim.api.nvim_set_keymap('v', '√', ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'ª', ":m '>-2<CR>gv=gv", { noremap = true, silent = true })
