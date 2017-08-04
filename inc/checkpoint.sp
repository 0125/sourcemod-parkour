// int Checkpoint_getCheckpoints() {
	// char line[128];
	// int checkpoints;
	
	// File file = OpenFile(g_strCheckpointsFile, "r");
	// while (!file.EndOfFile()) {
		// file.ReadLine(line, sizeof(line));
		// checkpoints++;
	// }
	// file.Close();
	
	// PrintToServer("nig nig nig nig nig nig nig nig");
	
	// return checkpoints;
// }

public Action Command_Checkpoint_Save(int client, int args)
{
	if (client == 0) {
		ReplyToCommand(client, "[CHECKPOINT] Cannot use this command through console.");
		return Plugin_Handled;
	}
	char arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	if (arg1[0] == 0) {
		ReplyToCommand(client, "[CHECKPOINT] Title parameter not specified.");
		return Plugin_Handled;
	}
	float chkPos[3];
	GetClientAbsOrigin(client, chkPos);
	float chkAngle[3];
	GetClientEyeAngles(client, chkAngle);

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
	return Plugin_Handled;
}

public Action Command_Checkpoint_Delete(int client, int args)
{
	char arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	if (arg1[0] == 0) {
		ReplyToCommand(client, "[CHECKPOINT] Title parameter not specified.");
		return Plugin_Handled;
	}
	
	GetNameFromSteamID(arg1);
	
	chk.Rewind();
	chk.ExportToFile(g_strCheckpointsFile);
	
	// if (!chk.GotoFirstSubKey()) // Jump into the first subsection
	// {
		// return Plugin_Handled;
	// }
 
	// char buffer[255]; // Iterate over subsections at the same nesting level
	// do {
		// chk.GetSectionName(buffer, sizeof(buffer));
		// if (StrEqual(buffer, arg1)) {
			// int result = chk.DeleteThis()
			// delete kv;
			// return Plugin_Handled;
		// }
	// }
	// while {
		// (chk.GotoNextKey());
	// }
	
	// ReplyToCommand(client, "debug: arg1 = %s result = %i", arg1, result);
	ReplyToCommand(client, "end of command_checkpoint_delete");
	return Plugin_Handled;
}

bool GetNameFromSteamID(const char[] sectionName)
{
	KeyValues kv = new KeyValues("MyFile");
	kv.ImportFromFile("myfile.txt");
 
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		return false;
	}
 
	// Iterate over subsections at the same nesting level
	char buffer[255];
	do
	{
		chk.GetSectionName(buffer, sizeof(buffer));
		if (StrEqual(buffer, sectionName))
		{
			chk.DeleteThis();
			return true;
		}
	} while (chk.GotoNextKey());

	return false;
}

public Action Command_Checkpoint_DeleteAll(int client, int args)
{
	chk = new KeyValues("Checkpoints");
	chk.ExportToFile(g_strCheckpointsFile);
	ReplyToCommand(client, "deleted & rewrote checkpoints file");
	return Plugin_Handled;
}

public Action checkCheckpoint(Handle timer) {
	// PrintToServer("checkCheckpoint");
	
	float positionAngle[3];
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && !bHasCheckpoint[i]) {
			char clientName[MAX_NAME_LENGTH];
			GetClientName(i, clientName, MAX_NAME_LENGTH);
			GetClientAbsOrigin(i, positionAngle);
			if (RoundFloat(positionAngle[0]) == RoundFloat(g_flArrCheckpoint[0])) {
				PrintToChatAll("[PARKOUR] %s reached the checkpoint", clientName);
				bHasCheckpoint[i] = true;
			}
			
			PrintToServer("client: %i, clientName: %s, coordinates: %f %f %f, bHasCheckpoint = %i", i, clientName, positionAngle[0], positionAngle[1], positionAngle[2], bHasCheckpoint[i]);
		}
	}
	return Plugin_Continue;
}