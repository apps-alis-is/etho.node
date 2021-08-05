local _user = am.app.get("user")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)
local _ok, _uid = fs.safe_getuid(_user)
if not _ok or not _uid then
    log_info("Creating user - " .. _user .. "...")
    local _ok = os.execute('adduser --disabled-login --disabled-password --gecos "" ' .. _user)
    ami_assert(_ok, "Failed to create user - " .. _user, EXIT_INVALID_CONFIGURATION)
    log_info("User " .. _user .. " created.")
else
    log_info("User " .. _user .. " found.")
end

local DATA_PATH = am.app.get_model("DATA_DIR")
local _ok, _error = fs.safe_mkdirp(DATA_PATH)
local _ok, _uid = fs.safe_getuid(_user)
ami_assert(_ok, "Failed to get " .. _user .. "uid - " .. (_uid or ""))

local _ok, _error = fs.safe_chown(DATA_PATH, _uid, _uid, {recurse = true})
ami_assert(_ok, "Failed to chown " .. DATA_PATH .. " - " .. (_error or ""))

log_info "Configuring ETHO FS..."
local GETH_PATH = '"' .. path.combine("bin", "geth") .. '"'

local _home = env.get_env("HOME")
env.set_env("HOME", DATA_PATH)
ami_assert(os.execute(GETH_PATH .. " --ethofs=" .. am.app.get_config("NODE_TYPE") .. " --ethofsInit"), "Failed to initialize ETHO FS")
ami_assert(os.execute(GETH_PATH .. " --ethofs=" .. am.app.get_config("NODE_TYPE") .. " --ethofsConfig"), "Failed to configure ETHO FS")
env.set_env("HOME", _home)

log_success "ETHO FS configured."

log_info "Configuring ETHO services..."
-- we reuse ethereum base
am.execute_extension("__eth/configure.lua")

log_success "ETHO services configured"

--[[
      /usr/sbin/geth --ethofs=gn --ethofsInit

  /usr/sbin/geth --ethofs=gn --ethofsConfig
]]
