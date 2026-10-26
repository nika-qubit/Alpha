-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local ns_sql = vim.api.nvim_create_namespace("markdown_sql_hl")

local sql_keywords = {
  SELECT = true, FROM = true, WHERE = true, INSERT = true, INTO = true,
  VALUES = true, UPDATE = true, SET = true, DELETE = true, CREATE = true,
  OR = true, REPLACE = true, TABLE = true, IF = true, NOT = true,
  EXISTS = true, ALTER = true, ADD = true, DROP = true, RENAME = true,
  TO = true, COLUMN = true, COLUMNS = true, DESCRIBE = true, DESC = true,
  EXTENDED = true, FORMATTED = true, SHOW = true, TBLPROPERTIES = true,
  NAMESPACE = true, NAMESPACES = true, TABLES = true, VIEWS = true,
  USING = true, OPTIONS = true, LOCATION = true, WITH = true,
  CONNECTION = true, DEFAULT = true, COLLATE = true, ORDER = true,
  BY = true, GROUP = true, HAVING = true, LIMIT = true, OFFSET = true,
  ASC = true, IN = true, IS = true, AS = true, ON = true, JOIN = true,
  LEFT = true, RIGHT = true, INNER = true, OUTER = true, FULL = true,
  CROSS = true, UNION = true, ALL = true, DISTINCT = true, CASE = true,
  WHEN = true, THEN = true, ELSE = true, END = true, AND = true,
  NULL = true, TRUE = true, FALSE = true, CAST = true, SAFE_CAST = true,
  INTERVAL = true, PRIMARY = true, KEY = true, PARTITIONED = true,
  CLUSTER = true, FOR = true, SYSTEM_TIME = true, VERSION = true,
  ICEBERG = true,
}

local sql_types = {
  INT64 = true, INT = true, INTEGER = true, BIGINT = true, SMALLINT = true,
  TINYINT = true, BYTEINT = true, FLOAT64 = true, FLOAT = true, DOUBLE = true,
  NUMERIC = true, BIGNUMERIC = true, DECIMAL = true, STRING = true,
  VARCHAR = true, CHAR = true, BYTES = true, BINARY = true, BOOLEAN = true,
  BOOL = true, DATE = true, DATETIME = true, TIME = true, TIMESTAMP = true,
  TIMESTAMPTZ = true, GEOGRAPHY = true, GEOMETRY = true, JSON = true,
  STRUCT = true, ARRAY = true, MAP = true, RECORD = true,
}

local sql_funcs = {
  SAFE = true, HEX = true, UNHEX = true, LOWER = true, UPPER = true,
  COUNT = true, SUM = true, AVG = true, MIN = true, MAX = true,
  COALESCE = true, IFNULL = true, NULLIF = true, CONCAT = true,
  SUBSTR = true, SUBSTRING = true, TRIM = true, LENGTH = true,
  ROUND = true, ABS = true, NOW = true, CURRENT_TIMESTAMP = true,
  CURRENT_DATE = true, TO_JSON_STRING = true, PARSE_JSON = true,
}

local function is_ident_start(b)
  return (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b == 95
end

local function is_ident_cont(b)
  return is_ident_start(b) or (b >= 48 and b <= 57)
end

local function is_digit(b)
  return b >= 48 and b <= 57
end

local function highlight_sql_line(buf, row, line)
  local n = #line
  local i = 1
  while i <= n do
    local b = line:byte(i)
    -- 1. SQL comment (-- ...)
    if b == 45 and i + 1 <= n and line:byte(i + 1) == 45 then
      vim.api.nvim_buf_set_extmark(buf, ns_sql, row, i - 1, {
        end_col = n,
        hl_group = "@comment.sql",
        priority = 210,
      })
      break
    end
    -- 2. Backtick-quoted identifier (`google.com:...`)
    if b == 96 then
      local j = i + 1
      while j <= n and line:byte(j) ~= 96 do
        j = j + 1
      end
      if j <= n then
        j = j + 1
      end
      vim.api.nvim_buf_set_extmark(buf, ns_sql, row, i - 1, {
        end_col = j - 1,
        hl_group = "@constant.sql",
        priority = 210,
      })
      i = j
    -- 3. Hex / WKB literal (X'...' or x'...')
    elseif (b == 88 or b == 120) and i + 1 <= n and line:byte(i + 1) == 39 then
      local j = i + 2
      while j <= n do
        if line:byte(j) == 39 then
          j = j + 1
          if j <= n and line:byte(j) == 39 then
            j = j + 1
          else
            break
          end
        else
          j = j + 1
        end
      end
      vim.api.nvim_buf_set_extmark(buf, ns_sql, row, i - 1, {
        end_col = j - 1,
        hl_group = "@string.special.sql",
        priority = 210,
      })
      i = j
    -- 4. Single-quoted or double-quoted string literal ('...' or "...")
    elseif b == 39 or b == 34 then
      local quote = b
      local j = i + 1
      while j <= n do
        local cj = line:byte(j)
        if cj == 92 and j + 1 <= n then
          j = j + 2
        elseif cj == quote then
          j = j + 1
          if j <= n and line:byte(j) == quote then
            j = j + 1
          else
            break
          end
        else
          j = j + 1
        end
      end
      vim.api.nvim_buf_set_extmark(buf, ns_sql, row, i - 1, {
        end_col = j - 1,
        hl_group = "@string.sql",
        priority = 210,
      })
      i = j
    -- 5. Identifier, Keyword, Data Type, or Function
    elseif is_ident_start(b) then
      local j = i + 1
      while j <= n and is_ident_cont(line:byte(j)) do
        j = j + 1
      end
      local word = line:sub(i, j - 1)
      local upper = word:upper()
      local k = j
      while k <= n and line:byte(k) == 32 do
        k = k + 1
      end
      local followed_by_paren = k <= n and line:byte(k) == 40
      local hl = "@variable.sql"
      if upper == "TRUE" or upper == "FALSE" then
        hl = "@boolean.sql"
      elseif upper == "NULL" then
        hl = "@constant.builtin.sql"
      elseif sql_keywords[upper] then
        hl = "@keyword.sql"
      elseif sql_types[upper] then
        hl = "@type.builtin.sql"
      elseif upper:sub(1, 3) == "ST_" or sql_funcs[upper] or followed_by_paren then
        hl = "@function.call.sql"
      end
      vim.api.nvim_buf_set_extmark(buf, ns_sql, row, i - 1, {
        end_col = j - 1,
        hl_group = hl,
        priority = 210,
      })
      i = j
    -- 6. Numeric literal
    elseif is_digit(b) then
      local j = i + 1
      while j <= n and (is_digit(line:byte(j)) or line:byte(j) == 46) do
        j = j + 1
      end
      vim.api.nvim_buf_set_extmark(buf, ns_sql, row, i - 1, {
        end_col = j - 1,
        hl_group = "@number.sql",
        priority = 210,
      })
      i = j
    else
      i = i + 1
    end
  end
end

local function refresh_sql_highlights(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local ft = vim.bo[buf].filetype
  if ft ~= "markdown" and ft ~= "sql" and ft ~= "googlesql" then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns_sql, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if ft == "sql" or ft == "googlesql" then
    for idx, line in ipairs(lines) do
      highlight_sql_line(buf, idx - 1, line)
    end
    return
  end
  -- ft == "markdown": scan fenced ```sql / ```bigquery / ```spark / ```expected blocks
  local fence = nil
  for idx, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if vim.startswith(trimmed, "```") then
      if not fence then
        local info = vim.trim(trimmed:sub(4)):lower()
        local first_word = info:match("^(%S+)") or ""
        if first_word == "sql" or first_word == "bigquery" or first_word == "spark" or first_word == "sparksql" or first_word == "googlesql" then
          fence = "sql"
        elseif first_word == "expected" then
          fence = "expected"
        else
          fence = "other"
        end
      else
        fence = nil
      end
      vim.api.nvim_buf_set_extmark(buf, ns_sql, idx - 1, 0, {
        end_col = #line,
        hl_group = "@punctuation.special.markdown",
        priority = 210,
      })
    elseif fence == "sql" then
      highlight_sql_line(buf, idx - 1, line)
    elseif fence == "expected" then
      vim.api.nvim_buf_set_extmark(buf, ns_sql, idx - 1, 0, {
        end_col = #line,
        hl_group = "@string.special",
        priority = 205,
      })
    end
  end
end

local function fix_markdown_codeblock_hl()
  vim.api.nvim_set_hl(0, "@markup.raw.block.markdown", { link = "Normal" })
end

fix_markdown_codeblock_hl()

local grp = vim.api.nvim_create_augroup("markdown_sql_hl", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = grp,
  callback = function()
    fix_markdown_codeblock_hl()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        refresh_sql_highlights(buf)
      end
    end
  end,
})

vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWinEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
  group = grp,
  callback = function(ev)
    refresh_sql_highlights(ev.buf)
  end,
})

for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) then
    refresh_sql_highlights(buf)
  end
end
