local _dataDir = path.combine(os.cwd(), "data")

am.app.set_model(
    {
        SERVICE_NAME = "etho-geth",
        SERVICE_FILE = "__etho/assets/daemon.service",
        IPC_PATH = path.combine(_dataDir, ".ether1/geth.ipc"),
        CHAINDATA_DIR = path.combine(_dataDir, ".ether1/geth/chaindata/")
    },
    { merge = true, overwrite = true }
)
