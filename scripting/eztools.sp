#include <sourcemod>

#include <adt>
#include <regex>

#include "pluginsyswrapper"

#pragma newdecls required
#pragma semicolon 1

#include "ez/load.sp"
#include "ez/unload.sp"
#include "ez/execute.sp"

public Plugin myinfo =
{
    name = "EZ Tools",
    author = "Monera",
    description = "Plugin that allows easy management of plugins/configurations and so more",
    version = "1.0.0",
    url = ""
};

public void OnPluginStart()
{
    Init_Load();
    Init_Unload();

    Init_Execute();
}