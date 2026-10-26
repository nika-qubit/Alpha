return {
  "nvim-mini/mini.diff",
  event = "LazyFile",
  opts = {
    view = {
      style = "sign",
      signs = { add = "+", change = "~", delete = "-" },
    },
  },
  keys = {
    {
      "<leader>vo",
      function()
        require("mini.diff").toggle_overlay()
      end,
      desc = "Toggle inline diff overlay",
    },
  },
}
