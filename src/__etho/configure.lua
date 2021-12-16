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
if not _ok then
	ami_error("Failed to chown " .. DATA_PATH .. " - " .. (_error or ""))
end

if am.app.get_configuration("OUTBOUND_ADDR") ~= nil then 
	log_info"OUTBOUND_ADDR specified. Downloading netns-cli..."
	local _tmpFile = os.tmpname()
    local _ok, _error = net.safe_download_file("https://github.com/alis-is/netns-cli/releases/download/0.0.4/netns-cli.lua", _tmpFile, {followRedirects = true})
    if not _ok then
        fs.remove(_tmpFile)
        ami_error("Failed to download: " .. tostring(_error))
    end
	fs.copy_file(_tmpFile, "bin/netns-cli.lua")
	fs.safe_remove(_tmpFile)
	log_success"netns-cli downloaded"
end

log_info "Configuring ETHO FS..."
local GETH_PATH = '"' .. path.combine("bin", "geth") .. '"'

local _home = env.get_env("HOME")
env.set_env("HOME", DATA_PATH)
if am.app.get_configuration("OUTBOUND_ADDR") ~= nil then 
	local _netnsId = am.app.get("id") .. "-netns"
	ami_assert(os.execute("eli bin/netns-cli.lua --force --id=" .. _netnsId .. " --outbound-addr=" .. am.app.get_configuration("OUTBOUND_ADDR")), "Failed to create netns!")
	local _ok = os.execute("ip netns exec " .. _netnsId .. " " .. GETH_PATH .. " --ethofs=" .. am.app.get_configuration("NODE_TYPE") .. " --ethofsInit")
	if _ok then 
		_ok = os.execute("ip netns exec " .. _netnsId .. " " ..GETH_PATH .. " --ethofs=" .. am.app.get_configuration("NODE_TYPE") .. " --ethofsConfig")
	end
	os.execute("eli bin/netns-cli.lua --id=" .. _netnsId .. " --remove")
	if not _ok then 
		ami_error("Failed to initialize ETHO FS")
	end
else
	ami_assert(os.execute(GETH_PATH .. " --ethofs=" .. am.app.get_configuration("NODE_TYPE") .. " --ethofsInit"), "Failed to initialize ETHO FS")
	ami_assert(os.execute(GETH_PATH .. " --ethofs=" .. am.app.get_configuration("NODE_TYPE") .. " --ethofsConfig"), "Failed to configure ETHO FS")
end
env.set_env("HOME", _home)

log_success "ETHO FS configured."

log_info "Configuring ETHO services..."
-- we reuse ethereum base
am.execute_extension("__eth/configure.lua")

log_success "ETHO services configured"

