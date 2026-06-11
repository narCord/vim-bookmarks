-- Maneja la escritura y lectura de las bookmarks al archivo bookmarks.json 

local M = {}

-- Encuentra la raiz del proyecto
---@return string
local function get_root()
  local markers = { ".git", ".hg", "package.json", "Makefile", "pyproject.toml" }
  local path = vim.fn.expand("%:p:h")

  while path ~= "/" do
    for _, marker in ipairs(markers) do
      if vim.loop.fs_stat(path .. "/" .. marker) then
        return path
      end
    end
    path = vim.fn.fnamemodify(path, ":h")
  end

  return vim.fn.getcwd()
end

-- Devuelve la ruta completa al archivo de bookmarks
---@return string
function M.bookmarks_path()
  return get_root() .. "/.bookmarks.json"
end

-- Carga todas las bookmarks
-- Devuelve una tabla "claveada" con la ruta relativa
-- { ["src/main.lua"] = { { line = 10, note = "..." }, ... } }
---@return table
function M.load()
  local path = M.bookmarks_path()
  local fd = io.open(path, "r")
  if not fd then return {} end

  local raw = fd:read("*a")
  fd:close()

  if not raw or raw == "" then return {} end

  local ok, data = pcall(vim.fn.json_decode, raw)
  if not ok or type(data) ~= "table" then return {} end

  return data
end

-- Guarda todos los bookmarks
---@param data table
function M.save(data)
  local path = M.bookmarks_path()
  local fd = io.open(path, "w")
  if not fd then
    vim.notify("bookmarks: could not write " .. path, vim.log.levels.ERROR)
    return
  end

  fd:write(vim.fn.json_encode(data))
  fd:close()
end

-- Obtiene la clave usada para indexar los bookmarks, ruta relativa a la raiz del proyecto
---@return string
function M.file_key()
  local root = get_root()
  local abs = vim.fn.expand("%:p")
  -- Desmonta el prefijo de la raiz para obtener la ruta relativa 
  local rel = abs:sub(#root + 2)
  return rel ~= "" and rel or abs
end

-- Añade o actualiza el bookmark para la linea dado el archivo actual
---@param line integer (1-indexed)
---@param note string
function M.add(line, note)
  local data = M.load()
  local key = M.file_key()

  data[key] = data[key] or {}

  -- Reemplaza bookmarks existentes en la misma linea
  for i, bm in ipairs(data[key]) do
    if bm.line == line then
      data[key][i].note = note
      M.save(data)
      return
    end
  end

  table.insert(data[key], { line = line, note = note })
  -- Mantiene ordenado el numero de linea
  table.sort(data[key], function(a, b) return a.line < b.line end)

  M.save(data)
end

-- Elimina el bookmark de la linea en el archivo actual
---@param line integer (1-indexed)
function M.remove(line)
  local data = M.load()
  local key = M.file_key()

  if not data[key] then return end

  for i, bm in ipairs(data[key]) do
    if bm.line == line then
      table.remove(data[key], i)
      break
    end
  end

  -- Limpia las entradas vacias
  if #data[key] == 0 then
    data[key] = nil
  end

  M.save(data)
end

-- Obtiene todos los bookmarks del archivo actual
---@return table  list of { line, note }
function M.get_for_current_file()
  local data = M.load()
  return data[M.file_key()] or {}
end

return M
