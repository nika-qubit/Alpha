return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "smartpde/telescope-recent-files",
  },
  keys = {
    {
      "<leader><leader>",
      function()
        require("telescope").extensions.recent_files.pick()
      end,
      desc = "Recent files",
    },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts or {})
    pcall(telescope.load_extension, "recent_files")
  end,
}
