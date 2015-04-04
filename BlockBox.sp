#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION 	"2.2"

/* 		Release Notes
	-----1.0----- (2014/09/04)
	Lotus exclusive, initial release.
	-----2.0----- (2015/02/07)
	Lotus exclusive, massive source clean-up, added WarnAdmin(), added cvarReason/cvarWarn, implemented non-case sensitive checking, removed unneeded include.
	-----2.1----- (2015/03/13) 
	Public release, added SteamIdType CVar, added cvarVersion change detection, fixed tag mismatch warnings, removed unneeded definition.
	-----2.2----- (2015/4/4)
	Added a bool to prevent duplicate bans, fixed small bug regarding ban reasons. 
*/

public Plugin:myinfo = {
	name = "BlockBox",	
	author = "Luop90",
	description = "Block LMAOBox spam.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561198071430088"
}

new Handle: cvarEnable;
new Handle: cvarVersion;
new Handle: cvarReason;
new Handle: cvarBan;
new Handle: cvarWarn;
new Handle: cvarLog;
new Handle: cvarSteamIdType;

new bool:detected[MAXPLAYERS];
public OnPluginStart() {
	//Global cvars
	cvarEnable = 		CreateConVar("sm_blockbox_enable", "1", "1(on) or 0(off). Default is 1(on).");
	cvarVersion = 		CreateConVar("sm_blockbox_version", PLUGIN_VERSION, "Plugin version.");
	HookConVarChange(cvarVersion, OnVersionChanged);
	
	//Control cvars
	cvarReason = 		CreateConVar("sm_blockbox_ban_reason", "[BlockBox] Auto-banned for LMAOBox Spam.", "Ban reason. (Only player banned/admins see this.)");
	cvarBan = 			CreateConVar("sm_blockbox_ban_enable", "1", "Ban player on detection. Default is 1 (on).");
	cvarWarn = 			CreateConVar("sm_blockbox_warn_admin", "1", "Alert admin(s) (if on server) on detection. Default is 1 (on).");
	cvarLog = 			CreateConVar("sm_blockbox_log",  "1", "Log ban in server logs. Default 1 (on).");
	cvarSteamIdType = 	CreateConVar("sm_blockbox_steamid_type", "0", "Sets the SteamID type. 0 = SteamID, 1 = SteamID3. Default is 0 (SteamID)");
}
public OnClientConnected(client) {
	detected[client] = false;
}
public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[]) {
	if(!GetConVarBool(cvarEnable))
		return Plugin_Continue;
	
	if(detected[client])
		return Plugin_Continue;
		
	new messageSize = strlen(sArgs);
	if(messageSize < 6) //Small optimization.
		return Plugin_Continue;
	
	decl String: message1[200];
	strcopy(message1, sizeof(message1), sArgs);
	
	decl String: message[200];
	String_ToLower(message1, message, sizeof(message)); //Convert to lowercase. Probably not needed.
	
	if(strcmp(message, "get good, get lmaobox!", false) == 0 || strcmp(message, "www.lmaobox.net - best free tf2 hack!", false) == 0) { 
			Log_Action(client);
			BanPlayer(client);
			return Plugin_Continue; //For logging purposes
	}
	if(StrContains(message, "lmaobox", false) == -1) {
			decl String: nickname[60];
			GetClientName(client, nickname, sizeof(nickname));
			WarnAdmin(nickname, "triggered LMAOBox detection.");
			return Plugin_Handled; //If it isn't a hack, and you've warned admins (if any), why let it be shown?
	}
	
	return Plugin_Continue;
}

public OnVersionChanged(Handle:event, const String: oldVal[], const String: newVal[]) {
	if(!StrEqual(newVal, PLUGIN_VERSION, false)) {
		SetConVarString(cvarVersion, PLUGIN_VERSION);
		LogMessage("[BlockBox] Plugin version changed back to %s", PLUGIN_VERSION);
	}
}

Log_Action(client) {
	if(!GetConVarBool(cvarLog))
		return;
	
	decl String: c_name[60];	
	decl String: c_ip[30];
	decl String: c_authid[19];
	
	GetClientName(client, c_name, sizeof(c_name));
	GetClientIP(client, c_ip, sizeof(c_ip));
	if(!GetConVarBool(cvarSteamIdType))
		GetClientAuthId(client, AuthIdType:AuthId_Steam2, c_authid, sizeof(c_authid));
	else
		GetClientAuthId(client, AuthIdType:AuthId_Steam3, c_authid, sizeof(c_authid));
	
	LogMessage("[BlockBox] Banned: %s <%s> (IP: %s).", c_name, c_authid, c_ip);
	return;
}

BanPlayer(client) {
	if(!GetConVarBool(cvarBan))
		return;
	if(detected[client]) //To prevent duplicate bans.
		return;
	
	detected[client] = true;
	decl String: nickname[60];
	decl String: c_authid[19];
	decl String: b_reason[256];

	GetClientName(client, nickname, sizeof(nickname));
	if(!GetConVarBool(cvarSteamIdType))
		GetClientAuthId(client, AuthIdType:AuthId_Steam2, c_authid, sizeof(c_authid));
	else
		GetClientAuthId(client, AuthIdType:AuthId_Steam3, c_authid, sizeof(c_authid));
	GetConVarString(cvarReason, b_reason, sizeof(b_reason));
	WarnAdmin(nickname, "triggered auto-ban for LMAOBox spam.");
	ServerCommand("sm_ban \"%s\" 0 \"%s\"", c_authid, b_reason);
	
	return;
}

WarnAdmin(const String: client_name[], const String: message[]) { 
	if(!GetConVarBool(cvarWarn))
		return;
	
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && CheckCommandAccess(i, "admin_generic", ADMFLAG_GENERIC, false)) {
			PrintToChat(i,"\x05[BlockBox] \x01%s %s", client_name, message);
		}
	}
	return;
} 
