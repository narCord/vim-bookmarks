local M = {}

-- Unico namespace para todas las extmarks de los bookmarks
M.ns = vim.api.nvim_create_namespace("bookmarks")

-- Texto y resalte del gutter
local SIGN_TEXT = "󰃃 " 
local SIGN_HL   = "BookmarkSign"

-- Resalte para el grupo al cargarse
function M.setup_hl()
  vim.api.nvim_set_hl(0, SIGN_HL, { fg = "#f5a623", bold = true })
end

-- Coloca un extmark de gutter
---@param bufnr integer
---@param line integer (1-indexed)
function M.place(bufnr, line)
  -- Los extmarks usan filas 0-indexed
  vim.api.nvim_buf_set_extmark(bufnr, M.ns, line - 1, 0, {
    sign_text     = SIGN_TEXT,
    sign_hl_group = SIGN_HL,
    priority      = 10,
  })
end

-- Elimina los extmarks de los bookmarks de bufnr y redibuja
---@param bufnr integer
---@param bookmark_list table  list of { line, note }
function M.refresh(bufnr, bookmark_list)
  -- Borra todas las marcas existentes para este bufer
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)

  for _, bm in ipairs(bookmark_list) do
    -- Protege contra numeros de linea "stale"
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if bm.line >= 1 and bm.line <= line_count then
      M.place(bufnr, bm.line)
    end
  end
end

-- Limpia los extmarks de los bookmark de bufnr
---@param bufnr integer
function M.clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
end

return M
