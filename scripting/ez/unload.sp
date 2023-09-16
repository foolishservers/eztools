void Init_Unload()
{
    RegServerCmd("sm_ezunload", SvrCmd_EZUnload, "Unload plugins whose path starts with given substring");
}

public Action SvrCmd_EZUnload(int args)
{
    if(args != 1)
    {
        PrintToServer("Usage: sm_ezunload <string>: Unload plugins whose path starts with given substring");
        return Plugin_Handled;
    }

    char substring[PLATFORM_MAX_PATH];
    GetCmdArg(1, substring, sizeof(substring));

    ArrayList list = ListLoadedPlugins(substring);
    int length = list.Length;
    int failure = 0;
    Handle myself = GetMyHandle();
    for(int i = 0; i < length; i++)
    {
        Handle plugin = list.Get(i);
        if(plugin == myself)
        {
            char path[PLATFORM_MAX_PATH];
            GetPluginFilename(null, path, sizeof(path));
            PrintToServer("[EZ] Plugin %s failed to unload: Unloading itself is not allowed", path);
            failure += 1;
            continue;
        }
        UnloadPlugin(plugin);
    }
    delete list;

    PrintToServer("[EZ] %d plugins are unloaded", length - failure);

    return Plugin_Handled;
}

stock ArrayList ListLoadedPlugins(const char[] startsWith)
{
    int startsWithLength = strlen(startsWith);
    
    ArrayList list = new ArrayList();

    Handle it = GetPluginIterator();
    while(MorePlugins(it))
    {
        Handle plugin = ReadPlugin(it);

        char path[PLATFORM_MAX_PATH];
        GetPluginFilename(plugin, path, sizeof(path));

        if(strncmp(path, startsWith, startsWithLength) != 0)
        {
            continue;
        }
        list.Push(plugin);
    }
    delete it;

    return list;
}
