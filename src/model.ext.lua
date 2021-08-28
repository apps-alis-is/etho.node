local _dataDir = path.combine(os.cwd(), "data")

local _which = proc.exec("which ip", { stdout = "pipe" })
IP_PATH="/usr/sbin/ip"
if _which.exitcode == 0 and _which.stdoutStream ~= nil then 
    IP_PATH = _which.stdoutStream:read("a"):gsub("^%s*(.-)%s*$", "%1")
end

am.app.set_model(
    {
        IPC_PATH = path.combine(_dataDir, ".ether1/geth.ipc"),
        CHAINDATA_DIR = path.combine(_dataDir, ".ether1/geth/chaindata/"),
        IS_GN = am.app.get_configuration("NODE_TYPE", ""):match("gn"),
        IP_PATH = IP_PATH
    },
    { merge = true, overwrite = true }
)

am.app.set_model({
    ["etho-geth"] = "__etho/assets/daemon.service"
}, "SERVICES")