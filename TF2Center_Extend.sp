#pragma semicolon 1

/*
******Plugin History******
----1.0---- (2014/11/02)
	-Original Release. Thanks to Lilith (https://forums.tf2center.com/user/1370-lilith/) for originally making this. The original sourcecode went down (http://spider.nikkii.us/#w0iJ8), and I had to recreate it as best as I can.

----1.1---- (2014/12/06)
	-Added [VServers] for Void.

----2.0---- (2015/03/15)
	-Added commands to start/stop a lobby.
	-Added ability to view logs that TF2C uploads, if the logs.tf plugin/tftrue aren't on the server.
	-Added version checker.	
	-Fixed those pesky Tag Mismatch warnings.
----2.1---- (2015/06/09)
	-Added auto-hooking when a lobby starts.
	-Code cleanup
*/

#include <sourcemod>
#include <morecolors>

#define PLUGIN_VERSION			"2.1"

public Plugin:myinfo = {
	name = "TF2Center Extender",
	author = "Luop90",
	description = "Extends TF2Center",
	version = PLUGIN_VERSION,
	url = "https://github.com/luop90"
}

new bool: inLobby = false;
new bool: showLog = false;
new bool: disableLogs = false;

new Handle: cvarVersion;
new Handle: cvarLogLink;
new Handle: logstf_autoupload = INVALID_HANDLE;
new Handle: tftrue_version = INVALID_HANDLE;

new String: g_sLogLink[128];

public OnPluginStart() {
	cvarVersion = CreateConVar("tf2center_extender_version", PLUGIN_VERSION, "Version of the plugin.");
	cvarLogLink = CreateConVar("tf2center_log_link", "", "After the lobby is over, set to the link that the logs are at.");
	HookConVarChange(cvarVersion, OnVersionChanged);

	RegAdminCmd("tf2center_start_lobby", 
				TF2C_Start, 
				ADMFLAG_RCON, 
				"Command used when a lobby is started.");
	RegAdminCmd("tf2center_end_lobby", 
				TF2C_End, 
				ADMFLAG_RCON, 
				"Command used when a lobby is ended.");

	AddCommandListener(SayCallBack, "say");

	//Check if the server already has logs.tf
	logstf_autoupload = FindConVar("logstf_autoupload");
	if(logstf_autoupload != INVALID_HANDLE) {
		disableLogs = true;
	}

	//Check if the server already has TFTrue
	tftrue_version = FindConVar("tftrue_version"); 
	if(tftrue_version != INVALID_HANDLE) {
		disableLogs = true;
	}
}

//Events
public OnMapStart() {
	g_sLogLink = ""; //Used to stop previous logs from being shown.
}
public OnMapEnd() {
	//Disabled everything.
	inLobby = false;
	showLog = false;
}

public OnVersionChanged(Handle:event, const String:oldVal[], const String:newVal[]) {
	if(!StrEqual(newVal, PLUGIN_VERSION, false)) {
		SetConVarString(cvarVersion, PLUGIN_VERSION);
		CPrintToChatAll("{lightgreen}[TF2Center] {default}Plugin version changed back to {red}default.");
	}
}
public Action: SayCallBack(client, const String:command[], argc) {
	decl String: strChat[256];
	GetCmdArgString(strChat, sizeof(strChat));
	//Auto detect when a lobby starts.
	if(!inLobby && StrContains(strChat, "TF2Center Lobby #", false) == 0) {
		startLobby();
		return Plugin_Continue;
	}

	else if(inLobby) {
		//Auto detect when a lobby ends.
		if(StrContains(strChat, "Lobby Closed: ", false) == 0) {
			endLobby();
		}
		//Detect normal TF2C outputs.
		if(StrContains(strChat, "TF2Center", false) == 0) {
			//TF2Center: -skip 11. If its [TF2Center] -skip 13.
			decl String:msg[256];
			strcopy(msg, sizeof(msg), strChat[strChat[0] == '[' ? 13 : 11]);
			CPrintToChatAll("{lightgreen}[TF2Center] {blue}%s", msg);
			return Plugin_Handled;
		}
		//VServers hook for Void.
		else if(StrContains(strChat, "[VServers]", false) == 0) {
			//[VServers] -skip 10.
			decl String:msg[256];
			strcopy(msg, sizeof(msg), strChat[10]);
			CPrintToChatAll("{red}[VServers] {blue}%s", msg);
			return Plugin_Handled;
		}
	}
	//Check if logs should exist.
	if(!disableLogs) {
		if(strcmp(strChat, "!log", false) || strcmp(strChat, "!logs", false)) {
			if(showLog) {
				//Check the cvar. (Inside of this is when the logs are shown.)
				QueryClientConVar(client, "cl_disablehtmlmotd", QueryConVar_DisableHtmlMotd);
				return Plugin_Continue;
			}
			CPrintToChat(client, "{lightgreen}[TF2Center] {default}The logs haven't been uploaded yet.");
			return Plugin_Continue;
		}
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
			CPrintToChat(client, "{lightgreen}[TF2Center] {violet}%s{default}: To see logs in-game, you need to set: {aqua}cl_disablehtmlmotd {red}0", nickname);
			return;
		}
	}
	if(!IsClientInGame(client))
		return;

	decl String:num[3];
	new Handle:Kv = CreateKeyValues("data");
	IntToString(MOTDPANEL_TYPE_URL, num, sizeof(num));
	KvSetString(Kv, "title", "Logs");
	KvSetString(Kv, "type", num);
	KvSetString(Kv, "msg", g_sLogLink);
	KvSetNum(Kv, "customsvr", 1);
	ShowVGUIPanel(client, "info", Kv);
	CloseHandle(Kv);
}
new Float:timesDone = 0.0;
public Action:logsmessage(Handle:timer) {
	GetConVarString(cvarLogLink, g_sLogLink, sizeof(g_sLogLink));
	Format(g_sLogLink, sizeof(g_sLogLink), "%s%s", "http://", g_sLogLink);

	if(!StrEqual(g_sLogLink, "", false)) {
		CPrintToChatAll("{lightgreen}[TF2Center] {default}The logs have been uploaded. Type {blue}!logs {default}to view.");
		showLog = true;
		return; 
	}
	if(timesDone <= 5.0) {
		timesDone++;
		CreateTimer(5.0, logsmessage); //If it wasn't uploaded in 10 seconds, lets try again...
	}
}

//Commands
public Action:TF2C_Start(client, args) {
	startLobby();
	return Plugin_Handled;
}
public Action:TF2C_End(client, args) {
	endLobby();
	return Plugin_Handled;
}

//Custom functions.
startLobby() {
	if(inLobby) {
		CPrintToChatAll("{lightgreen}[TF2Center] {default}There is already a lobby in progress.");
		return;
	}
	SetConVarString(cvarLogLink, "");
	LogMessage("[TF2Center] Lobby initiated.");
	CPrintToChatAll("{lightgreen}[TF2Center] {default}Lobby started. {green}Enabling plugin.");
	inLobby = true;
}
endLobby() {
	if(!inLobby) {
		CPrintToChatAll("{lightgreen}[TF2Center] {default}There is no lobby in progress!");
		return;
	}
	LogMessage("[TF2Center] Lobby ended.");
	if(!disableLogs) {
		CPrintToChatAll("{lightgreen}[TF2Center] {default}Lobby ended. {red}Uploading logs...");
		CreateTimer(10.0, logsmessage); //10 seconds should be more than long enough for the logs to upload.
		inLobby = false;
		return;
	}
	CPrintToChatAll("{lightgreen}[TF2Center] {default}Lobby ended. {red}Disabling plugin.");
	inLobby = false;
}