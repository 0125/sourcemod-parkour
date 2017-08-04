/*
	todo:
		when a player has activated a checkpoint, teleport them to it when they respawn

*/

#include <sourcemod>
#include <sdktools>
#include <l4d_myStocks>
#pragma newdecls required
#pragma semicolon 1

Handle		hGameConf			= null;		// Respawn file handle
Handle		hRoundRespawn		= null;		// Used by respawn function
char		g_strMapName[128];				// Current map name
char		g_strCheckpointsFile[128];		// Checkpints keyvalues file
KeyValues	chk;							// Checkpoints keyvalues handle
bool		bHasCheckpoint[MAXPLAYERS+1]; 	// Stores whether the player has activated the checkpoint for this map

float g_flArrCheckpoint[3] = {-6562.278320 , -6825.723633 , 377.972565};

public Plugin myinfo =
{
	name = "My First Plugin",
	author = "Me",
	description = "My first plugin ever",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

#include "inc/checkpoint.sp"

public void OnPluginStart() {
	// CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
	RegAdminCmd("chk_save", Command_Checkpoint_Save, ADMFLAG_ROOT);
	RegAdminCmd("chk_delete", Command_Checkpoint_Delete, ADMFLAG_ROOT);
	RegAdminCmd("chk_deleteAll", Command_Checkpoint_DeleteAll, ADMFLAG_ROOT);
	RegConsoleCmd("test", Command_Test);
	
	BuildPath(Path_SM, g_strCheckpointsFile, sizeof(g_strCheckpointsFile), "gamedata/checkpoints.cfg");
	chk = new KeyValues("Checkpoints");
	chk.ImportFromFile(g_strCheckpointsFile);
	
	hGameConf = LoadGameConfigFile("l4drespawn");
	if (hGameConf != INVALID_HANDLE) {
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
	}
	else {
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4drespawn.txt , you FAILED AT INSTALLING");
	}

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_PostNoCopy);
}

public void OnPluginEnd() {
	chk.ExportToFile(g_strCheckpointsFile);
	delete chk;
}

public void OnMapStart() {
	GetCurrentMap(g_strMapName, sizeof(g_strMapName));
	
	for (int i = 1; i <= MaxClients; i++)
		bHasCheckpoint[i] = false;
		
	TestFunction();
}

void TestFunction() {
}

public Action Command_Test(int client, int args)
{
	ReplyToCommand(client, "command_test");

	float posArray[3] = {-8693.033203, -6845.073730, -63.968750};
	float angArray[3] = {-25.053532, 95.928131, 0.098877};
	TeleportEntity(client, posArray, angArray, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, Respawn, client, 0);
	return Plugin_Continue;
}

public Action Respawn(Handle timer, int client) {
	if (client == 0)
		return;
	PrintToServer("RespawnPlayer client: %i", client);
	SDKCall(hRoundRespawn, client);
	return;
}