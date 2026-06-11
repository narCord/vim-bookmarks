-- Renderiza la ventana flotante

local M = {}

local store = require("bookmarks.store")
local marks  = require("bookmarks.marks")

-- Formatea las bookmarks en cada linea
---@param bm table  { line, note }
---@return string
local function fmt(bm)
  return string.format("  [%d] %s", bm.line, bm.note)
end

-- Abre la lista en la ventan flotante
function M.open()
  local bookmarks = store.get_for_current_file()
  local source_buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()

  if #bookmarks == 0 then
    vim.notify("No bookmarks for this file.", vim.log.levels.INFO)
    return
  end

  -- Construye las lineas
  local lines = { "  Bookmarks — <CR> jump  d delete  q close", "" }
  for _, bm in ipairs(bookmarks) do
    table.insert(lines, fmt(bm))
  end

  -- Ajusta la ventana
  local width  = 0
  for _, l in ipairs(lines) do width = math.max(width, #l) end
  width = math.min(width + 4, math.floor(vim.o.columns * 0.8))
  local height = math.min(#lines, math.floor(vim.o.lines * 0.6))

  -- Crea un bufer nuevo para la ventana
  local float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
  vim.bo[float_buf].modifiable = false
  vim.bo[float_buf].filetype   = "bookmarks"

  -- Centra la ventana
  local row = math.floor((vim.o.lines   - height) / 2)
  local col = math.floor((vim.o.columns - width)  / 2)

  local float_win = vim.api.nvim_open_win(float_buf, true, {
    relative = "editor",
    row      = row,
    col      = col,
    width    = width,
    height   = height,
    style    = "minimal",
    border   = "rounded",
    title    = " 󰃃 Bookmarks ",
    title_pos = "center",
  })

  -- Resalta la cabecera
  vim.api.nvim_buf_add_highlight(float_buf, -1, "Comment", 0, 0, -1)

  -- El cursor comienza en la primera entrada real
  vim.api.nvim_win_set_cursor(float_win, { 3, 0 })

  -- Resuelve el bookmark bajo el cursor 
  -- Devuelve nulo si el cursor esta en una entrada vacia
  ---@return table|nil  { line, note }
  local function entry_under_cursor()
    local row_idx = vim.api.nvim_win_get_cursor(float_win)[1]
    -- Primeras dos filas son la cabecera y blanca
    local bm_idx = row_idx - 2
    if bm_idx < 1 or bm_idx > #bookmarks then return nil end
    return bookmarks[bm_idx], bm_idx
  end

  local opts = { buffer = float_buf, nowait = true, silent = true }

  -- <CR>: salta a la linea seleccionada
  vim.keymap.set("n", "<CR>", function()
    local bm = entry_under_cursor()
    if not bm then return end
    vim.api.nvim_win_close(float_win, true)
    vim.api.nvim_set_current_win(source_win)
    vim.api.nvim_win_set_cursor(source_win, { bm.line, 0 })
    vim.cmd("normal! zz") 
  end, opts)

  -- d: borra la entrada bajo el cursor 
  vim.keymap.set("n", "d", function()
    local current_row = vim.api.nvim_win_get_cursor(float_win)[1]
    local bookmark_index = current_row - 2
    if bookmark_index < 1 or bookmark_index > #bookmarks then 
        return 
    end
    local bookmark = bookmarks[bookmark_index]

    store.remove(bookmark.line)
    table.remove(bookmarks, bookmark_index)
    marks.refresh(source_buf, bookmarks)

    local new_lines = { "  Bookmarks - <CR> ir a linea  d delete  q close", "" }
    for _, b in ipairs(bookmarks) do
        table.insert(new_lines, fmt(b))
    end

    vim.bo[float_buf].modifiable = true
    vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, new_lines)
    vim.bo[float_buf].modifiable = false

    if #bookmarks == 0 then
      vim.api.nvim_win_close(float_win, true)
      vim.notify("No hay mas bookmarks", vim.log.levels.INFO)
    end
  end, opts)

  -- q / <Esc>: cerrar 
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      vim.api.nvim_win_close(float_win, true)
    end, opts)
  end
end

return M
