return {
  "nvim-neo-tree/neo-tree.nvim",
  cmd = "Neotree",
  opts = {
    filesystem = {
      bind_to_cwd = false,
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      group_empty_dirs = true,
      hijack_netrw_behavior = "open_default",
    },
    buffers = {
      group_empty_dirs = true,
      follow_current_file = { enabled = true },
    },
  },
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer Neo-tree (Root Dir)" },
    { "<leader>E", "<cmd>Neotree toggle cwd<cr>", desc = "Explorer Neo-tree (cwd)" },
    { "<leader>fe", "<cmd>Neotree toggle<cr>", desc = "Explorer Neo-tree (Root Dir)" },
    { "<leader>fE", "<cmd>Neotree toggle cwd<cr>", desc = "Explorer Neo-tree (cwd)" },
  },
}
