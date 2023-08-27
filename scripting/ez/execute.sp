static Regex configExtensionRegex;

void Init_Execute()
{
    configExtensionRegex = new Regex("\\.cfg$");

    RegServerCmd("sm_ezexec", SrvCmd_EZExec, "Executes script files whose path starts with substring")
}

public Action SrvCmd_EZExec(int args)
{
    if(args != 1)
    {
        PrintToServer("Usage: sm_ezexec <string>: executes script files whose path starts with substring");
        return Plugin_Handled;
    }

    char substring[PLATFORM_MAX_PATH];
    GetCmdArg(1, substring, sizeof(substring));

    ArrayList list = ListConfigs(substring);
    int length = list.Length;
    for(int i = 0; i < length; i++)
    {
        char path[PLATFORM_MAX_PATH];
        list.GetString(i, path, sizeof(path));

        ServerCommand("exec \"%s\"", path);
    }
    delete list;

    PrintToServer("[EZ] %d scripts files are executed", length);
    
    return Plugin_Handled;
}

stock ArrayList ListConfigs(const char[] startsWith)
{
    int startsWithLength = strlen(startsWith);

    ArrayList list = new ArrayList(PLATFORM_MAX_PATH / 4);

    char rootPath[PLATFORM_MAX_PATH] = "cfg";
    int rootPos = strlen(rootPath);

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
                    configExtensionRegex.Match(path[pos]);
                    if(!configExtensionRegex.MatchCount())
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