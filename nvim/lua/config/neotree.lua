require('neo-tree').setup({
  filesystem = {
    group_empty_dirs = true, -- when true, empty folders will be grouped together
  },
  buffers = {
    group_empty_dirs = true, -- when true, empty directories will be grouped together
  }
})

vim.keymap.set('n', '<F6>', '<Cmd>Neotree toggle<CR>')

