-- ============================================================
-- project: customOS
-- file: kernel.lua
-- author: Flench04
-- ============================================================
local master_perms = {
    protected_files = {}
}
local native_fs = {}
for k, v in pairs(fs) do
    native_fs[k] = v
end
local ROOT = "root"

if not native_fs.exists(ROOT) then
    native_fs.makeDir(ROOT)
end

local FULL_EXEMPT     = { "tmp" }        -- read + write
local READONLY_EXEMPT = { "rom", "sys" } -- read only, never write/delete/makeDir

local function matches(path, prefix)
    return path == prefix or string.sub(path, 1, #prefix + 1) == prefix .. "/"
end

local function exemptKind(path)
    for _, p in ipairs(FULL_EXEMPT) do
        if matches(path, p) then return "full" end
    end
    for _, p in ipairs(READONLY_EXEMPT) do
        if matches(path, p) then return "readonly" end
    end
    return nil
end

local function denied(path)
    -- uncomment to see what is being probed:
    -- native_fs.open("tmp_denied.log", "a").write(tostring(path) .. "\n")
    error("Perm Manager: denied \"" .. tostring(path) .. "\"", 0)
end

local function isRoot(path)
    return native_fs.combine("", path or "") == ""
end

-- Returns the real path, or nil if a READ falls outside the sandbox.
-- Writes outside the sandbox (or to read-only areas) raise an error.
local function toReal(path, needsWrite, perms)
    local hperms = false
    if perms and perms.protected_files == master_perms.protected_files then
        hperms = true
    end
    path = native_fs.combine("", path or "")
    local kind = exemptKind(path)
    if kind == "full" then return path end
    if kind == "readonly" then
        if needsWrite and not hperms then
            error("Perm Manager: \"" .. path .. "\" is read-only", 0)
        end
        return path
    end
    if matches(path, ROOT) then return path end
    if needsWrite then denied(path) end
    return nil
end

local overrides = {
    open = function(path, mode, perms)
        -- [wa+] also catches "r+"
        local write = mode ~= nil and mode:find("[wa+]") ~= nil
        local p = toReal(path, write, perms)
        if not p then return nil, "Permission denied" end
        return native_fs.open(p, mode)
    end,
    exists = function(path, perms)
        local p = toReal(path, false, perms)
        if not p then return isRoot(path) end
        return native_fs.exists(p)
    end,
    isDir = function(path, perms)
        local p = toReal(path, false, perms)
        if not p then return isRoot(path) end
        return native_fs.isDir(p)
    end,
    list = function(path, perms)
        local p = toReal(path, false, perms)
        if not p then
            if isRoot(path) then
                -- virtual root: only show the folders the sandbox allows
                local out = {}
                for _, name in ipairs(native_fs.list("")) do
                    if name == ROOT or exemptKind(name) then out[#out + 1] = name end
                end
                return out
            end
            denied(path)
        end
        return native_fs.list(p)
    end,
    getSize = function(path, perms)
        local p = toReal(path, false, perms)
        if not p then denied(path) end
        return native_fs.getSize(p)
    end,
    isReadOnly = function(path, perms)
        local p = toReal(path, false, perms)
        if not p then return true end
        return native_fs.isReadOnly(p)
    end,
    makeDir = function(path, perms) return native_fs.makeDir(toReal(path, true, perms)) end,
    delete  = function(path, perms) return native_fs.delete(toReal(path, true, perms)) end,
    copy = function(from, to, perms)
        local src = toReal(from, false, perms)
        if not src then denied(from) end
        return native_fs.copy(src, toReal(to, true, perms))
    end,
    move = function(from, to, perms)
        return native_fs.move(toReal(from, true, perms), toReal(to, true, perms))
    end,
    find = function(pattern, perms)
        local p = toReal(pattern, false, perms)
        if not p then return {} end
        return native_fs.find(p)
    end,
    isExempt = function(path, perms) return exemptKind(path) ~= nil end,
}

for name, func in pairs(overrides) do
    fs[name] = func
end

print("Kernel: sandbox ready, launching init...")
shell.setDir("/root")
shell.run("clear")
local init_perms = {
    protected_files = master_perms.protected_files
}
local init_env = setmetatable({
    PERMS = init_perms
}, { __index = _G })
os.run(init_env, "/sys/init.lua")
print("Kernel: init system exited.")
shell.run("shutdown")