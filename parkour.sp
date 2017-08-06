/*
	todo:
		when a player has activated a checkpoint, teleport them to it when they respawn
		
	float g_flArrCheckpoint[3] = {-6562.278320 , -6825.723633 , 377.972565};
*/

#include <sourcemod>
#include <sdktools>
#include <l4d_myStocks>
#pragma newdecls required
#pragma semicolon 1
#pragma dynamic 131072 // increase stack size

// misc
int 		g_nullTime = 1501970400;									// Unix 24 hr year-month-day stamp with 0 hours-minutes-seconds
int			g_iDebugMode = 1;											// Used to toggle debug messages
Handle		g_hGameConf;												// Respawn file handle
Handle		g_hRoundRespawn;											// Used by respawn function
char		g_strMapName[128];											// Current map name
char		g_strSteamId[MAXPLAYERS+1][PLATFORM_MAX_PATH]; 				// Stores a players steam id
char		g_strName[MAXPLAYERS+1][PLATFORM_MAX_PATH]; 				// Stores player name

// stats
char		g_strStatsFile[128];										// Stats keyvalues file
KeyValues	g_kvStats;													// Stats keyvalues handle
int			g_iTotalDeaths[MAXPLAYERS+1];								// Holds a player total deaths
int			g_iTotalWins[MAXPLAYERS+1];									// Holds a player total wins
int			g_iMapDeaths[MAXPLAYERS+1];									// Holds a player total wins for the current map
int			g_iMapWins[MAXPLAYERS+1];									// Holds a player total wins for the current map
int			g_iStartTime[MAXPLAYERS+1];									// Timestamp play reached checkpoint called 'start'
int			g_iFinishTime[MAXPLAYERS+1];								// Time in seconds between checkpoint called 'start' and 'end'
int			g_iFastestTime[MAXPLAYERS+1];								// Fastest time in seconds between checkpoint called 'start' and 'end'

// checkpoints
char		g_strCheckpointsFile[128];									// Checkpoints keyvalues file
KeyValues	g_hChk;														// Checkpoints keyvalues handle
bool		g_bHasCheckpoint[MAXPLAYERS+1][PLATFORM_MAX_PATH]; 			// Stores whether the player has activated the checkpoint for this map
int			g_iCurrentCheckpoint[MAXPLAYERS+1];							// Stores digit of the checkpoint the player should be teleported to on death
char		g_iCurrentCheckpointName[MAXPLAYERS+1][PLATFORM_MAX_PATH];	// Stores name of the checkpoint the player should be teleported to on death
Handle		g_checkpointTimer = null;									// Handle to stop & start checkpoint timer

public Plugin myinfo =
{
	name = "My First Plugin",
	author = "Me",
	description = "My first plugin ever",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

#include "inc/checkpoint.sp"
#include "inc/stats.sp"
#include "inc/test.sp"

public void OnPluginStart() {
	checkpointTimer("start");
	// CreateTimer(1.0, TestTimer, _, TIMER_REPEAT);
	// CreateTimer(0.25, checkCheckpoint, _, TIMER_REPEAT);
	// CreateTimer(1.0, checkCheckpoint);
	RegAdminCmd("chk_save", Command_Checkpoint_Save, ADMFLAG_ROOT);
	RegAdminCmd("chk_delete", Command_Checkpoint_Delete, ADMFLAG_ROOT);
	RegAdminCmd("chk_deleteall", Command_Checkpoint_DeleteAll, ADMFLAG_ROOT);
	RegAdminCmd("chk_show", Command_Checkpoint_Show, ADMFLAG_ROOT);
	RegConsoleCmd("test", Command_Test);
	
	BuildPath(Path_SM, g_strStatsFile, sizeof(g_strStatsFile), "gamedata/parkour_stats.cfg");
	g_kvStats = new KeyValues("Stats");
	g_kvStats.ImportFromFile(g_strStatsFile);
	BuildPath(Path_SM, g_strCheckpointsFile, sizeof(g_strCheckpointsFile), "gamedata/checkpoints.cfg");
	g_hChk = new KeyValues("Checkpoints");
	g_hChk.ImportFromFile(g_strCheckpointsFile);
	
	g_hGameConf = LoadGameConfigFile("l4drespawn");
	if (g_hGameConf != INVALID_HANDLE) {
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "RoundRespawn");
		g_hRoundRespawn = EndPrepSDKCall();
		if (g_hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
	}
	else {
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4drespawn.txt , you FAILED AT INSTALLING");
	}

	// HookEvent("player_death", Event_PlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && !IsFakeClient(i)) {
			GetClientAuthId(i, AuthId_Steam3, g_strSteamId[i], PLATFORM_MAX_PATH);
			GetClientName(i, g_strName[i], MAX_NAME_LENGTH);
		}
	}
	loadStats();
}

public void OnPluginEnd() {
	g_hChk.Rewind();
	g_hChk.ExportToFile(g_strCheckpointsFile);
	delete g_hChk;
	
	saveStats();
	delete g_kvStats;
}

public void OnMapStart() {
	GetCurrentMap(g_strMapName, sizeof(g_strMapName));
	TestFunction();
	checkpointTimer("start");
}

public void OnMapEnd() {
	checkpointTimer("stop");
	saveStats();
}

public void OnClientPostAdminCheck(int client) {
	if (IsValidClient(client) && !IsFakeClient(client)) {
		GetClientAuthId(client, AuthId_Steam3, g_strSteamId[client], PLATFORM_MAX_PATH);
		GetClientName(client, g_strName[client], MAX_NAME_LENGTH);
		resetPlayerCheckpoints(client);
		loadPlayerStats(client);
		
		char fastestTimeFormatted[512];
		if (g_iFastestTime[client] > 0)
			FormatTime(fastestTimeFormatted, sizeof(fastestTimeFormatted), "%H:%M:%S", g_nullTime + g_iFastestTime[client]);
		else
			fastestTimeFormatted = "None";
		
		PrintToChatAll("[CHECKPOINT] %s joined. PB: %s Wins: %i Deaths: %i", g_strName[client], fastestTimeFormatted, g_iMapWins[client], g_iMapDeaths[client]);
	}
}

public void OnClientDisconnect(int client) {
	savePlayerStats(client);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	CreateTimer(0.1, Respawn, client, 0);
	
	if (g_iCurrentCheckpoint[client]) {
		CreateTimer(0.1, Teleport, client, 0);
	}
	
	g_iTotalDeaths[client]++;
	g_iMapDeaths[client]++;
	return Plugin_Continue;
}

public Action Respawn(Handle timer, int client) {
	if (client == 0)
		return;
	SDKCall(g_hRoundRespawn, client);
	return;
}

public Action Teleport(Handle timer, int client) {
	if (client == 0)
		return;
	float pos[3];
	float angle[3];
	g_hChk.Rewind();
	g_hChk.JumpToKey(g_strMapName);
	g_hChk.JumpToKey(g_iCurrentCheckpointName[client]);
	g_hChk.JumpToKey("position");
	pos[0] = g_hChk.GetFloat("x");
	pos[1] = g_hChk.GetFloat("y");
	pos[2] = g_hChk.GetFloat("z");
	g_hChk.GoBack();
	g_hChk.JumpToKey("angle");
	angle[0] = g_hChk.GetFloat("pitch");
	angle[1] = g_hChk.GetFloat("yaw");
	angle[2] = g_hChk.GetFloat("roll");
	TeleportEntity(client, pos, angle, NULL_VECTOR);
	return;
}

void PrintDebug(const char[] format, any:...) {
	if (!g_iDebugMode)
		return;
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	char sTime[256];
	FormatTime(sTime, sizeof(sTime), "%m/%d/%Y - %H:%M:%S");
	// PrintToServer("%s: %s", sTime, buffer);
	PrintToServer("%s", buffer);
}

public Action loadNextMap(Handle timer)
{
	char g_strNextMap[PLATFORM_MAX_PATH];
	GetNextMap(g_strNextMap, sizeof(g_strNextMap));
	ServerCommand("sm_changemap %s", g_strNextMap);
}