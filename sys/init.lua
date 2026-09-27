-- ============================================================
-- project: customOS
-- file: sys/init.lua
-- description: System initialization and launcher
-- ============================================================

print("Init: Starting session manager...")

-- For now, default to launching the shell.
-- In the future, this will check config (00_config) to determine whether
-- to launch CANVAS GUI, a headless service, or the standard shell.

local shell_env = setmetatable({
    PERMS = PERMS
}, { __index = _G })

os.run(shell_env, "/sys/shell.lua")
