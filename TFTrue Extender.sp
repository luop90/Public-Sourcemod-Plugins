#pragma semicolon 1

//HTML Checker partially from Logs.TF uploader by F2, Message changing from FunCommandsX. (The latter is not included yet - need to get it functioning.)
//Minor edits made to both for functionality reasons.

#include <sourcemod>
#include <morecolors>

#define PLUGIN_VERSION 	"1.0"

public Plugin:myinfo = {
	name = "TFTrue Extender",
	description = "Extends TFTrue's functionality.",
	author = "Luop90",
	version = PLUGIN_VERSION,
	url = ""
}

new Handle: cvarVersion;

public OnPluginStart() {
	cvarVersion = CreateConVar("sm_tftrue_extender_version", PLUGIN_VERSION, "TFTrue Extender version.");
	HookConVarChange(cvarVersion, OnVersionChanged);

	//HookEvent("round_start", OnRoundStart); Maybe will use later. This would allow a check whenever a round ends. Unsure if needed. 
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[]) {
	decl String: message1[256];
	strcopy(message1, sizeof(message1), sArgs);

	if(strcmp(message1, ".ss", false) == 0 || strcmp(message1, "!log", false) == 0 || strcmp(message1, "!logs", false) == 0 || strcmp(message1, "!ss", false) == 0) {
		QueryClientConVar(client, "cl_disablehtmlmotd", QueryConVar_DisableHtmlMotd);
		return Plugin_Continue;
	}

	return Plugin_Continue;
}

public QueryConVar_DisableHtmlMotd(QueryCookie: cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) {
	if(!IsClientConnected(client)) 
		return;

	if (result == ConVarQuery_Okay) {
		if (StringToInt(cvarValue) != 0) {
			decl String:nickname[32];
			GetClientName(client, nickname, sizeof(nickname));
			CPrintToChat(client, "{lightgreen}[TFTrue] {violet}%s{default}: To see logs in-game, you need to set: {aqua}cl_disablehtmlmotd {red}0", nickname);
			return;
		}
	}
}

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if(!StrEqual(newVal, PLUGIN_VERSION)) {
		SetConVarString(cvarVersion, PLUGIN_VERSION);
		CPrintToChatAll("{lightgreen}[TFTrue] {default}Version changed back to default.");
	}
}

/*public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	for(new i = 0; i < MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i)) {
			QueryClientConVar(i, "cl_disablehtmlmotd", QueryConVar_DisableHtmlMotd);
		}
	}
}*/
