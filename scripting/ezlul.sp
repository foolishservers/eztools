#include <sourcemod>
#include <adt>
#include <regex>
#include "pluginsyswrapper"

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
    name = "EZ Load Unload",
    author = "Monera",
    description = "Plugin that allows easy load/unload plugins by utilizing pluginsys wrapper",
    version = "0.0.1",
    url = ""
};

Regex pluginExtensionRegex;

public void OnPluginStart()
{
    pluginExtensionRegex = new Regex("\\.smx$");

    RegServerCmd("sm_ezload", SvrCmd_EZLoad, "Load plugins whose path starts with given substring");
    RegServerCmd("sm_ezunload", SvrCmd_EZUnload, "Unload plugins whose path starts with given substring");
}

public Action SvrCmd_EZLoad(int args)
{
    if(args != 1)
    {
        PrintToServer("Usage: sm_ezload (string)");
        return Plugin_Handled;
    }

    char substring[PLATFORM_MAX_PATH];
    GetCmdArg(1, substring, sizeof(substring));

    ArrayList list = ListPlugins(substring);
    int length = list.Length;
    int failure = 0;
    for(int i = 0; i < length; i++)
    {
        char path[PLATFORM_MAX_PATH];
        char err[256];
        bool wasloaded;

        list.GetString(i, path, sizeof(path));
        Handle plugin = LoadPluginEx(path, err, sizeof(err), wasloaded);

        if(plugin == null)
        {
            PrintToServer("[EZ] Plugin %s failed to load: %s", path, err);
            failure += 1;
        }
        else if(wasloaded)
        {
            failure += 1;
        }
    }

    PrintToServer("[EZ] %d plugins are loaded", length - failure);

    return Plugin_Handled;
}

public Action SvrCmd_EZUnload(int args)
{
    if(args != 1)
    {
        PrintToServer("Usage: sm_ezunload (string)");
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
        UnloadPlugin(list.Get(i));
    }

    PrintToServer("[EZ] %d plugins are unloaded", length - failure);

    return Plugin_Handled;
}

// BFS
stock ArrayList ListPlugins(const char[] startsWith)
{
    int startsWithLength = strlen(startsWith);

    ArrayList list = new ArrayList(PLATFORM_MAX_PATH / 4);

    char rootPath[PLATFORM_MAX_PATH];
    int rootPos;
    rootPos = BuildPath(Path_SM, rootPath, sizeof(rootPath), "plugins");

    ArrayStack stack = new ArrayStack(PLATFORM_MAX_PATH / 4);
    stack.PushString(rootPath);
    while(!stack.Empty)
    {
        char path[PLATFORM_MAX_PATH];
        int pos;
        stack.PopString(path, sizeof(path), pos);

        if(pos + 1 == PLATFORM_MAX_PATH)
        {
            continue;
        }
        path[pos++] = '/';

        DirectoryListing directoryListing = OpenDirectory(path);
        FileType type;
        while(directoryListing.GetNext(path[pos], sizeof(path) - pos, type))
        {
            switch(type)
            {
                case FileType_File:
                {
                    pluginExtensionRegex.Match(path[pos]);
                    if(!pluginExtensionRegex.MatchCount())
                    {
                        continue;
                    }
                    if(strncmp(path[rootPos + 1], startsWith, startsWithLength) != 0)
                    {
                        continue;
                    }
                    list.PushString(path[rootPos + 1]);
                }
                case FileType_Directory:
                {
                    if(strcmp(path[pos], ".") != 0 && strcmp(path[pos], "..") != 0)
                    {
                        stack.PushString(path);
                    }
                }
            }
        }
        delete directoryListing;
    }
    delete stack;

    return list;
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
