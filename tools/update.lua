-- ME2 live updater: pulls the repo's Lua source from GitHub onto this computer.
--
-- One-time bootstrap (public repo), run in the OC shell with an Internet Card present:
--   wget -f https://raw.githubusercontent.com/EshwarKo/ME2/main/tools/update.lua /home/update.lua
-- Then after every `git push`, just run:
--   update.lua
--
-- Optional config at /etc/me2.cfg (a serialized Lua table), e.g.:
--   {owner="EshwarKo", repo="ME2", branch="main", root="/home/me2", token="ghp_xxx"}
-- A token is only needed while the repo is PRIVATE. Making the repo public removes
-- all auth friction and lets the bootstrap wget above work as-is.

local component = require("component")
local internet  = require("internet")
local fs        = require("filesystem")
local ser       = require("serialization")

assert(component.isAvailable("internet"), "ME2 update: no Internet Card present")

local cfg = { owner = "EshwarKo", repo = "ME2", branch = "main", root = "/home/me2", token = nil }
do
  local path = "/etc/me2.cfg"
  if fs.exists(path) then
    local f = io.open(path, "r")
    local ok, t = pcall(ser.unserialize, f:read("*a"))
    f:close()
    if ok and type(t) == "table" then
      for k, v in pairs(t) do cfg[k] = v end
    end
  end
end

local function headers()
  local h = { ["User-Agent"] = "ME2-Updater" }
  if cfg.token then h["Authorization"] = "token " .. cfg.token end
  return h
end

local function httpGet(url)
  local ok, result = pcall(function()
    local buf = {}
    for chunk in internet.request(url, nil, headers()) do
      buf[#buf + 1] = chunk
    end
    return table.concat(buf)
  end)
  if not ok then
    error("ME2 update: request failed for " .. url .. " (" .. tostring(result) .. ")")
  end
  return result
end

-- Discover every .lua file in the repo via the git tree API — no manifest to maintain.
local function listLuaPaths()
  local api = string.format(
    "https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1",
    cfg.owner, cfg.repo, cfg.branch)
  local body = httpGet(api)
  local paths = {}
  for p in body:gmatch('"path":"(.-)"') do
    if p:sub(-4) == ".lua" then paths[#paths + 1] = p end
  end
  return paths
end

local function writeFile(dest, data)
  local dir = fs.path(dest)
  if dir and not fs.exists(dir) then fs.makeDirectory(dir) end
  local f = assert(io.open(dest, "w"))
  f:write(data)
  f:close()
end

local base = string.format("https://raw.githubusercontent.com/%s/%s/%s/",
  cfg.owner, cfg.repo, cfg.branch)

local paths = listLuaPaths()
if #paths == 0 then
  print("ME2 update: no .lua files found in "
    .. cfg.owner .. "/" .. cfg.repo .. "@" .. cfg.branch)
  return
end

for _, p in ipairs(paths) do
  local data = httpGet(base .. p)
  local dest = fs.concat(cfg.root, p)
  writeFile(dest, data)
  print("  " .. dest)
end

print(string.format("ME2 update: synced %d file(s) into %s", #paths, cfg.root))
