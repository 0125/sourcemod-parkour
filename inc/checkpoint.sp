// use SetVector(const char[] key, const float vec[3])
// 		https://sm.alliedmods.net/new-api/keyvalues/KeyValues/SetVector

void resetCheckpoints() {
	for (int i = 1; i <= MaxClients; i++)
		resetPlayerCheckpoints(i);
}

void resetPlayerCheckpoints(int client) {
	int checkpoint;
	char checkpointName[128];
	
	if (IsValidClient(client) && !IsFakeClient(client)) {
		checkpoint = 0;
		g_hChk.Rewind();
		g_hChk.JumpToKey(g_strMapName);
		g_hChk.GotoFirstSubKey();
		do {
			checkpoint++;
			g_hChk.GetSectionName(checkpointName, sizeof(checkpointName));
			g_bHasCheckpoint[client][checkpoint] = false;
		} while (g_hChk.GotoNextKey());
		g_iCurrentCheckpoint[client] = 0;
		g_iCurrentCheckpointName[client] = "";
	}
}

bool isPlayerNearCoordinates(int client, int checkpointX, int checkpointY, int checkpointZ) {
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	int playerX = RoundFloat(pos[0]);
	int playerY = RoundFloat(pos[1]);
	int playerZ = RoundFloat(pos[2]);
	
	int radius = 150;
	
	bool xInRange = (playerX > (checkpointX - radius) && playerX < (checkpointX + radius));
	bool yInRange = (playerY > (checkpointY - radius) && playerY < (checkpointY + radius));
	bool zInRange = (playerZ > (checkpointZ - radius) && playerZ < (checkpointZ + radius));
	
	if (xInRange && yInRange && zInRange)
		return true;
	else
		return false;
}

void checkpointTimer(char[] args) {
	if (StrEqual(args, "start", false)) {
		if (g_checkpointTimer == null) {
			g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
			PrintToServer("Started checkpoint timer");
		}
	}
	if (StrEqual(args, "stop", false)) {
		if (g_checkpointTimer != null) {
			KillTimer(g_checkpointTimer);
			g_checkpointTimer = null;
			PrintToServer("Stopped checkpoint timer");
		}
	}
}

public Action checkCheckpoint(Handle timer) {
	PrintToServer("checkCheckpoint");
	int checkpoint;
	char checkpointName[128];
	float pos[3];
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && !IsFakeClient(i)) {
			int client = i;
			GetClientAbsOrigin(client, pos);
			checkpoint = 0;
			g_hChk.Rewind();
			g_hChk.JumpToKey(g_strMapName);
			if (g_hChk.GotoFirstSubKey()) {
				do {
					checkpoint++;
					
					if (g_bHasCheckpoint[client][checkpoint] == false) {
						g_hChk.GetSectionName(checkpointName, sizeof(checkpointName));
						g_hChk.JumpToKey("position");
						float xPos = g_hChk.GetFloat("x");
						float yPos = g_hChk.GetFloat("y");
						float zPos = g_hChk.GetFloat("z");
						g_hChk.GoBack();
						
						if (isPlayerNearCoordinates(client, RoundFloat(xPos), RoundFloat(yPos), RoundFloat(zPos))) {
							g_bHasCheckpoint[client][checkpoint] = true;
							
							if (checkpoint > g_iCurrentCheckpoint[client]) {
								g_iCurrentCheckpoint[client] = checkpoint;
								g_iCurrentCheckpointName[client] = checkpointName;
							}

							if (StrEqual(checkpointName, "start", false)) {
								g_iStartTime[client] = GetTime();
							}
							
							if (StrEqual(checkpointName, "finish", false)) {
								if (g_iStartTime[client] == 0) {
									PrintToServer("finish checkpoint was unlocked without starting checkpoint being unlocked");
									return Plugin_Handled;
								}
								checkpointTimer("stop");
								
								g_iTotalWins[client]++;
								g_iMapWins[client]++;
								g_iFinishTime[client] = GetTime() - g_iStartTime[client];
								if (g_iFinishTime[client] < g_iFastestTime[client] || g_iFastestTime[client] == 0) // save if faster then previous, or nothing yet saved
									g_iFastestTime[client] = g_iFinishTime[client];

								char fastestTimeFormatted[512];
								FormatTime(fastestTimeFormatted, sizeof(fastestTimeFormatted), "%H:%M:%S", g_nullTime + g_iFastestTime[client]);
								
								char currentTimeFormatted[512];
								FormatTime(currentTimeFormatted, sizeof(currentTimeFormatted), "%H:%M:%S", g_nullTime + g_iFinishTime[client]);
									
								PrintToChatAll("[CHECKPOINT] %s finished in %s! PB: %s Wins: %i Deaths: %i", g_strName[client], currentTimeFormatted, fastestTimeFormatted, g_iMapWins[client], g_iMapDeaths[client]);
								
								if (!g_iDebugMode)
									CreateTimer(10.0, loadNextMap);
									
								// PrintToServer("checkCheckpoint: g_iMapWins[client]: %i", g_iMapWins[client]);
								return Plugin_Handled;
							}
							
							PrintToChatAll("[CHECKPOINT] %s reached checkpoint %s", g_strName[client], checkpointName);
						}
					}
				} while (g_hChk.GotoNextKey());
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_Checkpoint_Save(int client, int args) {
	if (client == 0) { // disallow console because this command needs the player position
		ReplyToCommand(client, "[CHECKPOINT] Cannot use this command through console.");
		return Plugin_Handled;
	}
	char arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	if (arg1[0] == 0) {
		ReplyToCommand(client, "[CHECKPOINT] Usage: chk_save <checkpoint>");
		return Plugin_Handled;
	}
	checkpointTimer("stop");
	resetCheckpoints();
	float checkpointPos[3];
	GetClientAbsOrigin(client, checkpointPos);
	float checkpointAngle[3];
	GetClientEyeAngles(client, checkpointAngle);

	g_hChk.Rewind();
	g_hChk.JumpToKey(g_strMapName, true);
	g_hChk.JumpToKey(arg1, true);
	g_hChk.JumpToKey("position", true);
	g_hChk.SetFloat("x", checkpointPos[0]);
	g_hChk.SetFloat("y", checkpointPos[1]);
	g_hChk.SetFloat("z", checkpointPos[2]);
	g_hChk.GoBack();
	g_hChk.JumpToKey("angle", true);
	g_hChk.SetFloat("pitch", checkpointAngle[0]);
	g_hChk.SetFloat("yaw", checkpointAngle[1]);
	g_hChk.SetFloat("roll", checkpointAngle[2]);

	g_hChk.Rewind();
	g_hChk.ExportToFile(g_strCheckpointsFile);
	ReplyToCommand(client, "[CHECKPOINT] Saved checkpoint");
	checkpointTimer("start");
	return Plugin_Handled;
}

public Action Command_Checkpoint_Delete(int client, int args) {
	char arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	if (arg1[0] == 0) {
		ReplyToCommand(client, "[CHECKPOINT] Usage: chk_delete <checkpoint>");
		return Plugin_Handled;
	}
	checkpointTimer("stop");
	resetCheckpoints();
	g_hChk.Rewind();
	if (!g_hChk.JumpToKey(g_strMapName)) {
		ReplyToCommand(client, "[CHECKPOINT] Could not find current map (%s) section.", g_strMapName);
		checkpointTimer("start");
		return Plugin_Handled;
	}
	if (!g_hChk.JumpToKey(arg1)) {
		ReplyToCommand(client, "[CHECKPOINT] Could not find checkpoint (%s) section.", arg1);
		checkpointTimer("start");
		return Plugin_Handled;
	}
	g_hChk.DeleteThis();
	g_hChk.Rewind();
	g_hChk.ExportToFile(g_strCheckpointsFile);
	ReplyToCommand(client, "[CHECKPOINT] Deleted checkpoint");
	checkpointTimer("start");
	return Plugin_Handled;
}

public Action Command_Checkpoint_DeleteAll(int client, int args) {
	checkpointTimer("stop");
	resetCheckpoints();
	g_hChk.Rewind();
	if (!g_hChk.JumpToKey(g_strMapName)) {
		ReplyToCommand(client, "[CHECKPOINT] Could not find current map (%s) section.", g_strMapName);
		checkpointTimer("start");
		return Plugin_Handled;
	}
	g_hChk.DeleteThis();
	g_hChk.Rewind();
	g_hChk.ExportToFile(g_strCheckpointsFile);
	ReplyToCommand(client, "[CHECKPOINT] Deleted all checkpoints on the current map");
	checkpointTimer("start");
	return Plugin_Handled;
}

public Action Command_Checkpoint_Show(int client, int args) {
	checkpointTimer("stop");
	g_hChk.Rewind();
	if (!g_hChk.JumpToKey(g_strMapName)) {
		ReplyToCommand(client, "[CHECKPOINT] Could not find current map (%s) section.", g_strMapName);
		checkpointTimer("start");
		return Plugin_Handled;
	}
	if (!g_hChk.GotoFirstSubKey()) {
		ReplyToCommand(client, "[CHECKPOINT] No checkpoints saved on (%s)", g_strMapName);
		checkpointTimer("start");
		return Plugin_Handled;
	}
	
	char buffer[128];
	do {
		g_hChk.GetSectionName(buffer, sizeof(buffer));
		ReplyToCommand(client, "[CHECKPOINT] %s", buffer);
	} while (g_hChk.GotoNextKey());
	checkpointTimer("start");
	return Plugin_Handled;
}