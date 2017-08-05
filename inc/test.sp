public Action Command_Test(int client, int args)
{
	ReplyToCommand(client, "command_test");
	return Plugin_Handled;
}

void TestFunction() {
	int checkpoint;
	int checkpointsSaved;
	char checkpointName[128];
	float pos[3];
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i)) {
			int client = i;
			char clientName[MAX_NAME_LENGTH];
			GetClientName(client, clientName, MAX_NAME_LENGTH);
			GetClientAbsOrigin(client, pos);
			checkpoint = 0;
			chk.Rewind();
			chk.JumpToKey(g_strMapName);
			checkpointsSaved = chk.GotoFirstSubKey();
			if (checkpointsSaved) {
				do {
					checkpoint++;
					
					if (g_bHasCheckpoint[client][checkpoint] == false) {
						chk.GetSectionName(checkpointName, sizeof(checkpointName));
						chk.JumpToKey("position");
						float xPos = chk.GetFloat("x");
						float yPos = chk.GetFloat("y");
						float zPos = chk.GetFloat("z");
						chk.GoBack();
						
						if (isPlayerNearCoordinates(client, RoundFloat(xPos), RoundFloat(yPos), RoundFloat(zPos))) {
							g_bHasCheckpoint[client][checkpoint] = true;
							
							if (checkpoint > g_iCurrentCheckpoint[client]) {
								g_iCurrentCheckpoint[client] = checkpoint;
								g_iCurrentCheckpointName[client] = checkpointName;
							}
							
							PrintToServer("g_iCurrentCheckpoint = %i, g_iCurrentCheckpointName = %s", g_iCurrentCheckpoint[client], g_iCurrentCheckpointName[client]);
							PrintToServer("[CHECKPOINT] %s reached checkpoint %s", clientName, checkpointName);
						}
					}
				} while (chk.GotoNextKey());
			}
		}
	}
}

bool isPlayerNearCoordinates(int client, int chkX, int chkY, int chkZ) {
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	int playerX = RoundFloat(pos[0]);
	int playerY = RoundFloat(pos[1]);
	int playerZ = RoundFloat(pos[2]);
	
	int radius = 150;
	
	bool xInRange = (playerX > (chkX - radius) && playerX < (chkX + radius));
	bool yInRange = (playerY > (chkY - radius) && playerY < (chkY + radius));
	bool zInRange = (playerZ > (chkZ - radius) && playerZ < (chkZ + radius));
	
	if (xInRange && yInRange && zInRange)
		return true;
	else
		return false;
}

void BrowseKeyValues(KeyValues kv)
{
	do
	{
		// You can read the section/key name by using kv.GetSectionName here.
		char sectionBuffer[255];
		kv.GetSectionName(sectionBuffer, sizeof(sectionBuffer));
		PrintToServer("GetSectionName = %s", sectionBuffer);
		
 
		if (kv.GotoFirstSubKey(false))
		{
			// Current key is a section. Browse it recursively.
			BrowseKeyValues(kv);
			kv.GoBack();
		}
		else
		{
			// Current key is a regular key, or an empty section.
			if (kv.GetDataType(NULL_STRING) != KvData_None)
			{
				// Read value of key here (use NULL_STRING as key name). You can
				// also get the key name by using kv.GetSectionName here.
				
				char stringBuffer[255];
				kv.GetString(NULL_STRING, stringBuffer, sizeof(stringBuffer), "NOTFOUND");
				PrintToServer("GetString = %s", stringBuffer);
			}
			else
			{
				// Found an empty sub section. It can be handled here if necessary.
			}
		}
	} while (kv.GotoNextKey(false));
}