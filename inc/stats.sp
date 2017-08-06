void loadStats() {
	for (int i = 1; i <= MaxClients; i++)
		loadPlayerStats(i);
}

void loadPlayerStats(int client) {
	if (IsValidClient(client) && !IsFakeClient(client)) {
		g_kvStats.Rewind();
		g_kvStats.JumpToKey(g_strSteamId[client]);
		g_iTotalDeaths[client] = g_kvStats.GetNum("totalDeaths");
		g_iTotalWins[client] = g_kvStats.GetNum("totalWins");
		g_kvStats.JumpToKey(g_strMapName);
		g_iMapDeaths[client] = g_kvStats.GetNum("deaths");
		g_iMapWins[client] = g_kvStats.GetNum("wins");
		g_iFastestTime[client] = g_kvStats.GetNum("fastestTime");
		
		// PrintToServer("loadPlayerStats: g_iMapWins[client]: %i", g_iMapWins[client]);
	}
}

void saveStats() {
	for (int i = 1; i <= MaxClients; i++)
		savePlayerStats(i);
		
	g_kvStats.Rewind();
	g_kvStats.ExportToFile(g_strStatsFile);
}

void savePlayerStats(int client) {
	if (IsValidClient(client) && !IsFakeClient(client)) {
		g_kvStats.Rewind();
		g_kvStats.JumpToKey(g_strSteamId[client], true);
		g_kvStats.SetNum("totalDeaths", g_iTotalDeaths[client]);
		g_kvStats.SetNum("totalWins", g_iTotalWins[client]);
		g_kvStats.JumpToKey(g_strMapName, true);
		g_kvStats.SetNum("deaths", g_iMapDeaths[client]);
		g_kvStats.SetNum("wins", g_iMapWins[client]);
		g_kvStats.SetNum("fastestTime", g_iFastestTime[client]);
		
		// PrintToServer("savePlayerStats: g_iMapWins[client]: %i", g_iMapWins[client]);
		
		g_iTotalDeaths[client] = 0;
		g_iTotalWins[client] = 0;
		g_iMapDeaths[client] = 0;
		g_iMapWins[client] = 0;
		g_iFinishTime[client] = 0;
		g_iFastestTime[client] = 0;
	}
}