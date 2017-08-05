void resetCheckpoints() {
	int checkpoint;
	char checkpointName[128];
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i)) {
			int client = i;
			checkpoint = 0;
			chk.Rewind();
			chk.JumpToKey(g_strMapName);
			chk.GotoFirstSubKey();
			do {
				checkpoint++;
				chk.GetSectionName(checkpointName, sizeof(checkpointName));
				PrintToServer("checkpointName = %s", checkpointName);
				g_bHasCheckpoint[client][checkpoint] = false;
				g_iCurrentCheckpoint[client] = 0;
				g_iCurrentCheckpointName[client] = "";
			} while (chk.GotoNextKey());
		}
	}
	PrintToServer("resetCheckpoints");
}

public Action checkCheckpoint(Handle timer) {
	TestFunction();
	
	// char buffer[128];
	// buffer = "this is a test";
	// PrintToServer("test: %s", buffer);
	
	// float positionAngle[3];
	// for (int i = 1; i <= MaxClients; i++) {
		// if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i)) {
			// char clientName[MAX_NAME_LENGTH];
			// GetClientName(i, clientName, MAX_NAME_LENGTH);
			// GetClientAbsOrigin(i, positionAngle);
			// if (RoundFloat(positionAngle[0]) == RoundFloat(g_flArrCheckpoint[0])) {
				// PrintToChatAll("[PARKOUR] %s reached the checkpoint", clientName);
				// bHasCheckpoint[i][buffer] = true;
			// }
			// PrintToServer("client: %i, clientName: %s, coordinates: %f %f %f, bHasCheckpoint = %i", i, clientName, positionAngle[0], positionAngle[1], positionAngle[2], bHasCheckpoint[i]);
		// }
	// }
	
	// float positionAngle[3];
	// for (int i = 1; i <= MaxClients; i++) {
		// if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && !bHasCheckpoint[i]) {
			// char clientName[MAX_NAME_LENGTH];
			// GetClientName(i, clientName, MAX_NAME_LENGTH);
			// GetClientAbsOrigin(i, positionAngle);
			// if (RoundFloat(positionAngle[0]) == RoundFloat(g_flArrCheckpoint[0])) {
				// PrintToChatAll("[PARKOUR] %s reached the checkpoint", clientName);
				// bHasCheckpoint[i] = true;
			// }
			// PrintToServer("client: %i, clientName: %s, coordinates: %f %f %f, bHasCheckpoint = %i", i, clientName, positionAngle[0], positionAngle[1], positionAngle[2], bHasCheckpoint[i]);
		// }
	// }
	return Plugin_Continue;
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
	KillTimer(g_checkpointTimer);
	resetCheckpoints();
	float chkPos[3];
	GetClientAbsOrigin(client, chkPos);
	float chkAngle[3];
	GetClientEyeAngles(client, chkAngle);

	chk.Rewind();
	chk.JumpToKey(g_strMapName, true);
	chk.JumpToKey(arg1, true);
	chk.JumpToKey("position", true);
	chk.SetFloat("x", chkPos[0]);
	chk.SetFloat("y", chkPos[1]);
	chk.SetFloat("z", chkPos[2]);
	chk.GoBack();
	chk.JumpToKey("angle", true);
	chk.SetFloat("pitch", chkAngle[0]);
	chk.SetFloat("yaw", chkAngle[1]);
	chk.SetFloat("roll", chkAngle[2]);

	chk.Rewind();
	chk.ExportToFile(g_strCheckpointsFile);
	ReplyToCommand(client, "[CHECKPOINT] Saved checkpoint");
	g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
	return Plugin_Handled;
}

public Action Command_Checkpoint_Delete(int client, int args) {
	char arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	if (arg1[0] == 0) {
		ReplyToCommand(client, "[CHECKPOINT] Usage: chk_delete <checkpoint>");
		return Plugin_Handled;
	}
	KillTimer(g_checkpointTimer);
	resetCheckpoints();
	chk.Rewind();
	if (!chk.JumpToKey(g_strMapName)) {
		ReplyToCommand(client, "[CHECKPOINT] Could not find current map (%s) section.", g_strMapName);
		g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
		return Plugin_Handled;
	}
	if (!chk.JumpToKey(arg1)) {
		ReplyToCommand(client, "[CHECKPOINT] Could not find checkpoint (%s) section.", arg1);
		g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
		return Plugin_Handled;
	}
	chk.DeleteThis();
	chk.Rewind();
	chk.ExportToFile(g_strCheckpointsFile);
	ReplyToCommand(client, "[CHECKPOINT] Deleted checkpoint");
	g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
	return Plugin_Handled;
}

public Action Command_Checkpoint_DeleteAll(int client, int args) {
	KillTimer(g_checkpointTimer);
	resetCheckpoints();
	chk.Rewind();
	if (!chk.JumpToKey(g_strMapName)) {
		ReplyToCommand(client, "[CHECKPOINT] Could not find current map (%s) section.", g_strMapName);
		g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
		return Plugin_Handled;
	}
	chk.DeleteThis();
	chk.Rewind();
	chk.ExportToFile(g_strCheckpointsFile);
	ReplyToCommand(client, "[CHECKPOINT] Deleted all checkpoints on the current map");
	g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
	return Plugin_Handled;
}

public Action Command_Checkpoint_Show(int client, int args) {
	KillTimer(g_checkpointTimer);
	chk.Rewind();
	if (!chk.JumpToKey(g_strMapName)) {
		ReplyToCommand(client, "[CHECKPOINT] Could not find current map (%s) section.", g_strMapName);
		g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
		return Plugin_Handled;
	}
	if (!chk.GotoFirstSubKey()) {
		ReplyToCommand(client, "[CHECKPOINT] No checkpoints saved on (%s)", g_strMapName);
		g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
		return Plugin_Handled;
	}
	
	char buffer[128];
	do {
		chk.GetSectionName(buffer, sizeof(buffer));
		ReplyToCommand(client, "[CHECKPOINT] %s", buffer);
	} while (chk.GotoNextKey());
	g_checkpointTimer = CreateTimer(1.0, checkCheckpoint, _, TIMER_REPEAT);
	return Plugin_Handled;
}