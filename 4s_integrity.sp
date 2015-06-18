#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

#define RED 0
#define BLU 1
#define TEAM_OFFSET 2

#include <sourcemod>
#include <morecolors>
#include <tf2_stocks>

public Plugin:myinfo = {
	name = "4v4 Integrity",
	description = "A plugin meant to keep 4v4 lobbies integrity true.",
	version = PLUGIN_VERSION,
	author = "Luop90",
	url = ""
}

new String:names_of_classes[10][256] = {"Unknown", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};
new Handle: cvarVersion;

new total_classes[TFClassType][2]; // First is the number of classes, second is the team.
new bool:teamReadyState[2] = { false, false }; //Set both teams to false.

public OnPluginStart() {
	cvarVersion = CreateConVar("sm_4s_integrity", PLUGIN_VERSION, "Version of the plugin");
	HookConVarChange(cvarVersion, OnVersionChanged);

	HookEvent("teamplay_game_over", Event_GameOver);
	HookEvent("tf_game_over", Event_GameOver);
	AddCommandListener(Command_TournamentRestart, "mp_tournament_restart");
	HookEvent("tournament_stateupdate", Event_TournamentStateUpdate);
}

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if(strcmp(newVal, PLUGIN_VERSION, false) != 0) {
		SetConVarString(cvarVersion, PLUGIN_VERSION);
		LogMessage("[SM] Plugin version changed back to default.");
		return;
	}
	return;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new team = GetClientTeam(GetClientOfUserId(GetEventInt(event, "userid"))) - TEAM_OFFSET; //Get the team, convert it to the type we are using.

	CountClass(team);
}

CountClass(team) {
	for(new i = 0; i <= 9; i++) {
		total_classes[i][team] = 0; //Reset all class values together when you do a recount.
	}

	for(new i = 1; i < MaxClients; i++) {
		if(!IsClientInGame(i) || (GetClientTeam(i) - TEAM_OFFSET) != team)
			continue; //If they aren't in game, and they're not on the team we're checking, skip them.	

		total_classes[TF2_GetPlayerClass(i)][team] ++; //Add the class they're currently playing.
	}

	for(new i = 0; i <= 9; i++) {
		if(total_classes[i][team] > 1) { //More than one class - warn in chat.
			CPrintToChatAll("{red}>>{yellow}WARNING{red}<< {yellow}%s has more than one of class: {green}%s", team == 0 ? "Red" : "Blue", names_of_classes[i]);
		}
	}
	if(total_classes[5][team] > 0 && total_classes[6][team] > 0) { //Both heavy and medic - warn in chat.
		CPrintToChatAll("{red}>>{yellow}WARNING{red}<< {yellow}%s has both a {green}medic {yellow}and a {green}heavy.", team == 0 ? "Red" : "Blue");
	}
	return;
}
//// Enable / Disable plugin Events.

public Event_TournamentStateUpdate(Handle:event, const String:name[], bool:dontBroadcast) {
	new team = GetClientTeam(GetEventInt(event, "userid")) - TEAM_OFFSET; //Get z team.
	new bool:nameChange = GetEventBool(event, "namechange"); 
	new bool:readyState = GetEventBool(event, "readystate"); //The reason you need both is that a namechange also does a readystate change. Rarely do you actually want that.

	if(!nameChange) { //Not a nameChange.
		teamReadyState[team] = readyState; //Set the bool for the team to whatever it got changed too.
		if(teamReadyState[RED] && teamReadyState[BLU]) { //If both are ready, enable the plugin.
			EnablePlugin();
		} else { //Something else? Disable it just to be safe.
			DisablePlugin("Both teams are not ready");
		}
	}
}

public Event_GameOver(Handle:event, const String:name[], bool:dontBroadcast) {
	teamReadyState[RED] = false; //Reset both values on game over.
	teamReadyState[BLU] = false;

	DisablePlugin("Game ended.");
	//Game ended, no reason to keep tracking.
}

public Action:Command_TournamentRestart(client, const String:Commmand[], sArgs) {
	teamReadyState[RED] = false; //Reset both values.
	teamReadyState[BLU] = false;

	DisablePlugin("Game restarted."); //Game restarted, stop keeping track of classes.
	return Plugin_Continue;
}

//////////////////////////////////////
/////// Enable / Disable plugin. /////
//////////////////////////////////////

EnablePlugin() {
	//Start hooking spawns.
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	CPrintToChatAll("{lightgreen}[TF2C] {blue}4v4 Plugin enabled.");
	LogMessage("[SM] Plugin enabled!");
}

DisablePlugin(const String:reason[]) {
	//Stop hooking spawns.
	UnhookEvent("player_spawn", Event_PlayerSpawn);

	CPrintToChatAll("{lightgreen}[TF2C] {red}4v4 Plugin disabled: {orange}%s{red}", reason);
	LogMessage("[SM] Plugin Disabled!");
}