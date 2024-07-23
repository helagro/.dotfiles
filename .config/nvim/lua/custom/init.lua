-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })

function insert_task_list_item()
    local current_line = vim.api.nvim_get_current_line()
    local indentation = current_line:match("^%s*")
    local new_line = indentation .. "- [ ] " .. current_line:match("^%s*(.*)")
    vim.api.nvim_set_current_line(new_line)
    vim.api.nvim_win_set_cursor(0, {vim.api.nvim_win_get_cursor(0)[1], #new_line})
end

vim.api.nvim_set_keymap('n', 'ª', ':m .-2<CR>==', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '√', ':m .+1<CR>==', { noremap = true, silent = true })

vim.api.nvim_set_keymap('v', '√', ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'ª', ":m '>-2<CR>gv=gv", { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', 'ﬁ', ':lua insert_task_list_item()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', 'ﬁ', '<Esc>:lua insert_task_list_item()<CR>a', { noremap = true, silent = true })
