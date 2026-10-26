-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Tabs
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Ensure Mason bin (including tree-sitter CLI) is on PATH for nvim-treesitter parser builds
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if not string.find(vim.env.PATH or "", mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. ":" .. (vim.env.PATH or "")
end

-- Highlight fenced code blocks in markdown (including sql, bigquery, spark, yaml, json, python, bash)
vim.g.markdown_fenced_languages = {
  "sql",
  "bigquery=sql",
  "spark=sql",
  "sparksql=sql",
  "yaml",
  "json",
  "python",
  "bash",
  "sh",
}

pcall(vim.treesitter.language.register, "sql", { "sql", "bigquery", "spark", "sparksql" })

