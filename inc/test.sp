public Action Command_Test(int client, int args)
{
	if (IsValidClient(client) && !IsFakeClient(client)) {
		GetClientAuthId(client, AuthId_Steam3, g_strSteamId[client], PLATFORM_MAX_PATH);
		GetClientName(client, g_strName[client], MAX_NAME_LENGTH);

		char fastestTimeFormatted[512];
		if (g_iFastestTime[client] > 0)
			FormatTime(fastestTimeFormatted, sizeof(fastestTimeFormatted), "%H:%M:%S", g_nullTime + g_iFastestTime[client]);
		else
			fastestTimeFormatted = "None";
		
		PrintToChatAll("%s joined. Deaths: %i Wins: %i PB: %s", g_strName[client], g_iMapDeaths[client], g_iMapWins[client], fastestTimeFormatted);
	}
	
	return Plugin_Handled;
}

void TestFunction() {
	// char buffer[512];
	// FormatTime(buffer, sizeof(buffer), "%H:%M:%S", g_nullTime + 60);
	// PrintDebug("TestFunction: %s", buffer);
	
	PrintDebug("TestFunction");
}

public Action TestTimer(Handle timer) {
	PrintToServer("TestTimer");
	
	static int count;
	
	count++;
	
	if (count == 5) {
		PrintToServer("5 seconds have passed, stopping timer");
		return Plugin_Stop;
	}
	
	return Plugin_Handled;
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