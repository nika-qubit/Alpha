-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Window navigation
vim.keymap.set("n", "<C-J>", "<C-W><C-J>", { desc = "Move to lower window" })
vim.keymap.set("n", "<C-K>", "<C-W><C-K>", { desc = "Move to upper window" })
vim.keymap.set("n", "<C-L>", "<C-W><C-L>", { desc = "Move to right window" })
vim.keymap.set("n", "<C-H>", "<C-W><C-H>", { desc = "Move to left window" })

-- Neo-tree Explorer (replaces Snacks Explorer)
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Explorer Neo-tree (Root Dir)" })
vim.keymap.set("n", "<leader>E", "<cmd>Neotree toggle cwd<cr>", { desc = "Explorer Neo-tree (cwd)" })
vim.keymap.set("n", "<leader>fe", "<cmd>Neotree toggle<cr>", { desc = "Explorer Neo-tree (Root Dir)" })
vim.keymap.set("n", "<leader>fE", "<cmd>Neotree toggle cwd<cr>", { desc = "Explorer Neo-tree (cwd)" })
vim.keymap.set("n", "<F6>", "<cmd>Neotree toggle<cr>", { desc = "Toggle Neo-tree" })

-- Telescope Recent Files
vim.keymap.set("n", "<leader><leader>", function()
  require("telescope").extensions.recent_files.pick()
end, { desc = "Recent files (Telescope)" })
