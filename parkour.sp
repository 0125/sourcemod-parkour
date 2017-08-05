/*
	todo:
		when a player has activated a checkpoint, teleport them to it when they respawn
*/

#include <sourcemod>
#include <sdktools>
#include <l4d_myStocks>
#pragma newdecls required
#pragma semicolon 1
#pragma dynamic 131072 // increase stack size

Handle		hGameConf			= null;						// Respawn file handle
Handle		hRoundRespawn		= null;						// Used by respawn function
char		g_strMapName[128];								// Current map name
char		g_strCheckpointsFile[128];						// Checkpints keyvalues file
KeyValues	chk;											// Checkpoints keyvalues handle
bool		g_bHasCheckpoint[MAXPLAYERS+1][10]; 			// Stores whether the player has activated the checkpoint for this map
int			g_iCurrentCheckpoint[MAXPLAYERS+1];				// Stores digit of the checkpoint the player should be teleported to on death
char		g_iCurrentCheckpointName[MAXPLAYERS+1][128];	// Stores name of the checkpoint the player should be teleported to on death
Handle		g_checkpointTimer;								// Handle to stop & start checkpoint timer

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
#include "inc/test.sp"

public void OnPluginStart() {
	g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
	// CreateTimer(0.25, checkCheckpoint, _, TIMER_REPEAT);
	// CreateTimer(1.0, checkCheckpoint);
	RegAdminCmd("chk_save", Command_Checkpoint_Save, ADMFLAG_ROOT);
	RegAdminCmd("chk_delete", Command_Checkpoint_Delete, ADMFLAG_ROOT);
	RegAdminCmd("chk_deleteall", Command_Checkpoint_DeleteAll, ADMFLAG_ROOT);
	RegAdminCmd("chk_show", Command_Checkpoint_Show, ADMFLAG_ROOT);
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

	// HookEvent("player_death", Event_PlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnPluginEnd() {
	chk.Rewind();
	chk.ExportToFile(g_strCheckpointsFile);
	delete chk;
}

public void OnMapStart() {
	GetCurrentMap(g_strMapName, sizeof(g_strMapName));
	
	// for (int i = 1; i <= MaxClients; i++)
		// bHasCheckpoint[i] = false;
		
	// TestFunction();
	// ClientCommand(1, "say !chk_delete start");
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	KillTimer(g_checkpointTimer);
	
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	CreateTimer(0.1, Respawn, client, 0);
	CreateTimer(0.1, Teleport, client, 0);
	
	g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
	return Plugin_Continue;
}

public Action Respawn(Handle timer, int client) {
	if (client == 0)
		return;
	SDKCall(hRoundRespawn, client);
	return;
}

public Action Teleport(Handle timer, int client) {
	if (client == 0)
		return;
	float pos[3];
	float angle[3];
	chk.Rewind();
	chk.JumpToKey(g_strMapName);
	chk.JumpToKey(g_iCurrentCheckpointName[client]);
	chk.JumpToKey("position");
	pos[0] = chk.GetFloat("x");
	pos[1] = chk.GetFloat("y");
	pos[2] = chk.GetFloat("z");
	chk.GoBack();
	chk.JumpToKey("angle");
	angle[0] = chk.GetFloat("pitch");
	angle[1] = chk.GetFloat("yaw");
	angle[2] = chk.GetFloat("roll");
	TeleportEntity(client, pos, angle, NULL_VECTOR);
	PrintToServer("this float value = %f, this other float value = %f", pos[0], angle[0]);
	return;
}