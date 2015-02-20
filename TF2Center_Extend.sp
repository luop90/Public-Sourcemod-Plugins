#pragma semicolon 1

//-----Plugin history-----
//1.0 Original Release. Thanks to Lilith (https://forums.tf2center.com/user/1370-lilith/) for originally making this. The original sourcecode went down (http://spider.nikkii.us/#w0iJ8), and I had to recreate it as best as I can.
//1.1 Added [VServers] for Void.

#include <sourcemod>
#include <morecolors>

#define PLUGIN_VERSION			"1.1"

public Plugin:myinfo = {
	name = "TF2Center Extender",
	author = "Luop90",
	description = "Extends TF2C.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart() {
	AddCommandListener(SayCallBack, "say");
}

public Action: SayCallBack(client, const String:command[], argc) {
	decl String: strChat[256];
	GetCmdArgString(strChat, sizeof(strChat));
	
	if(StrContains(strChat, "TF2Center", false) == 0) {
		//TF2Center: -skip 11. If its [TF2Center] -skip 13.
		decl String:msg[256];
		strcopy(msg, sizeof(msg), strChat[strChat[0] == '[' ? 13 : 11]);
		CPrintToChatAll("{lightgreen}[TF2Center] {blue}%s", msg);
		return Plugin_Handled;
	}
	if(StrContains(strChat, "[VServers]", false) == 0) {
		//[VServers] -skip 10.
		decl String:msg[256];
		strcopy(msg, sizeof(msg), strChat[10]);
		CPrintToChatAll("{red}[VServers] {blue}%s", msg);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}