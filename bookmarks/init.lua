-- Punto de entrada para el plugin 

local M = {}

local store = require("bookmarks.store")
local marks  = require("bookmarks.marks")
local ui     = require("bookmarks.ui")

-- Keymaps por defecto
local defaults = {
  add    = "<leader>ba", -- Add / update bookmark on current line
  delete = "<leader>bd", -- Delete bookmark on current line
  list   = "<leader>bl", -- Open bookmark list float
}

-- Añade un bookmark a la linea actual
local function add_bookmark()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  vim.ui.input({ prompt = "Bookmark note: " }, function(note)
    if not note or note == "" then return end
    store.add(line, note)
    marks.place(vim.api.nvim_get_current_buf(), line)
    vim.notify(string.format("Bookmark added at line %d", line), vim.log.levels.INFO)
  end)
end

-- Borra la bookmark de la linea actual 
local function delete_bookmark()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  store.remove(line)
  -- Refresca todas las bookmarks del bufer 
  marks.refresh(vim.api.nvim_get_current_buf(), store.get_for_current_file())
  vim.notify(string.format("Bookmark removed from line %d", line), vim.log.levels.INFO)
end

-- Redibuja las gutter marks cuando se añade o se escribe un bufer 
local function refresh_current_buf()
  local bufnr = vim.api.nvim_get_current_buf()
  -- Actua solo en buferes de archivos normales
  if vim.bo[bufnr].buftype ~= "" then return end
  marks.refresh(bufnr, store.get_for_current_file())
end

-- Configuracion del plugin 
---@param opts table|nil  Optional overrides: { keymaps = { add, delete, list } }
function M.setup(opts)
  opts = opts or {}
  local km = vim.tbl_deep_extend("force", defaults, opts.keymaps or {})

  -- Resaltar grupos 
  marks.setup_hl()

  -- Keymaps (modo normal, silencioso)
  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { silent = true, desc = desc })
  end

  map(km.add,    add_bookmark,    "Bookmark: add/update")
  map(km.delete, delete_bookmark, "Bookmark: delete")
  map(km.list,   ui.open,         "Bookmark: list")

  -- Autocomandos
  local group = vim.api.nvim_create_augroup("Bookmarks", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group    = group,
    callback = refresh_current_buf,
    desc     = "Refresh bookmark gutter marks",
  })

  -- Reaplica los resaltes tras cambiar colorschemes
  vim.api.nvim_create_autocmd("ColorScheme", {
    group    = group,
    callback = marks.setup_hl,
    desc     = "Re-apply bookmark highlight after colorscheme change",
  })
end

return M
