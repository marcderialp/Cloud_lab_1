NFS_CORE_PARAM {
    NFS_Protocols = 4;
    NFS_Port = 2049;
    Enable_NLM = false;
    Enable_RQUOTA = false;
    Enable_UDP = false;
    mount_path_pseudo = true;
}
NFSV4 {
    Grace_Period = 30;
    Lease_Lifetime = 30;
    Only_Numeric_Owners = true;
}
EXPORT {
    Export_Id = 1;
    Path = /exports;
    Pseudo = /;
    Access_Type = NONE;
    Squash = No_Root_Squash;
    SecType = sys;
    Transports = TCP;
    Protocols = 4;
    Disable_ACL = true;
    CLIENT { Clients = @CLIENTS@; Access_Type = RW; }
    FSAL { Name = VFS; }
}
LOG { Default_Log_Level = EVENT; }
