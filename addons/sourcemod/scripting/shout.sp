// **************************************************************************************************************
// ************************************************** DEFINES ***************************************************
// **************************************************************************************************************
#define PLUGIN_VERSION "1.2"
#define UPDATE_URL "https://drv.tw/~raroger1975@gmail.com/gd/Sourcemod/shoutplugin/updatefile.txt"
#define CLIENT_SHOUTCD  (1<<1)

// **************************************************************************************************************
// ************************************************** VARIABLES *************************************************
// **************************************************************************************************************
//PATHS
char shoutConfigFile[PLATFORM_MAX_PATH]		= "cfg/sm_shout/shoutlist.cfg";
char shoutSetFile[PLATFORM_MAX_PATH]		= "cfg/sm_shout/shoutsettings.cfg";

//BOOL
bool DupRename;

//CHAR
char gFilebuffer[PLATFORM_MAX_PATH];
char gNamebuffer[64];
char changeSetting[MAXPLAYERS + 1][64];
char cdStatus[MAXPLAYERS+1];

//KEYVALUE
KeyValues kvConfig;
KeyValues kvSettings;

//INT
int shoutCD 		= 1;
int shoutCommand	= 0;
int shoutMode		= 0;
int shoutPitch 		= 100;
int shoutVolume		= 100;
int shoutMessage	= 2;
int shoutRadius		= 400; //25 feet
int shoutDebug		= 0;

//HANDLE
Handle fileArray;
Handle nameArray;
Handle fileArray_Added;
Handle nameArray_Added;

Handle shoutCDs[MAXPLAYERS+1];
Handle shoutAdvert[MAXPLAYERS+1];

// **************************************************************************************************************
// ************************************************** INCLUDES **************************************************
// **************************************************************************************************************
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <updater>

#include "shout\config.sp"
#include "shout\menu.sp"
#include "shout\listener.sp"

#pragma newdecls required

// *****************************************************************************************************************
// ************************************************** PLUGIN INFO **************************************************
// *****************************************************************************************************************
public Plugin myinfo =
{
	name		= "Simple Shout Plugin",
	author		= "Arturo",
	description	= "Recreation of an eventscripts soccermod feature",
	version		= PLUGIN_VERSION,
	url			= ""
};

// ******************************************************************************************************************
// ************************************************** PLUGIN START **************************************************
// ******************************************************************************************************************
public void OnPluginStart()
{
	CreateConVar("shout_version", PLUGIN_VERSION, "Shout plugin version", FCVAR_NOTIFY| FCVAR_DONTRECORD);
	
	AddCommandListener(SayCommandListener, "say");
	AddCommandListener(SayCommandListener, "say_team");
	
	fileArray 		= CreateArray(PLATFORM_MAX_PATH);
	fileArray_Added = CreateArray(PLATFORM_MAX_PATH);
	nameArray 		= CreateArray(64);
	nameArray_Added	= CreateArray(64);
	
	// Updater******************************************
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
	//**************************************************
	
	if (!DirExists("cfg/sm_shout"))			CreateDirectory("cfg/sm_shout", 511, false);
	if (!DirExists("sound/shout"))			CreateDirectory("sound/shout", 511, false);
	
	RegisterClientCommands();
}

public void OnMapStart()
{
	if(!FileExists(shoutConfigFile))		CreateConfig();
	if(!FileExists(shoutSetFile))			CreateSettings();
	
	ReadSettings();
	ReadConfig();
	
	for (int player = 1; player <= MaxClients; player++)
	{
		if(GetClientMenu(player) != MenuSource_None )	CancelClientMenu(player,true);
		SetDefaultClientSettings(player);
	}
}

public void OnClientConnected(int client)
{
	SetDefaultClientSettings(client);

	if(shoutMessage == 1) shoutAdvert[client] = CreateTimer(10.0, shoutAD_Timer, client);
	else shoutAdvert[client] = INVALID_HANDLE;
	
	return;
}

public void SetDefaultClientSettings(int client)
{
	cdStatus[client] = 0;

	shoutCDs[client] = INVALID_HANDLE;

	return;
}

// Updater******************************************
public void OnLibraryAdded(const char []name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
//**************************************************

// ******************************************************************************************************************
// **************************************************** COMMANDS ****************************************************
// ******************************************************************************************************************
public void RegisterClientCommands()
{
	RegConsoleCmd("sm_shout", ShoutMenu, "Opens the Shout list");
	RegAdminCmd("sm_shoutset", ShoutSettings, ADMFLAG_GENERIC, "Opens the Shout settings menu");
}

public Action ShoutMenu(int client, int args)
{
	OpenMenuShout(client);

	return Plugin_Handled;
}

public Action ShoutCommand(int client, int args)
{
	char cmd[64];
	GetCmdArg(0, cmd, sizeof(cmd));
	int iVolume, iPitch;
	char sound[PLATFORM_MAX_PATH]
	
	strcopy(cmd, sizeof(cmd), cmd[3]);
	
	kvConfig = new KeyValues("Shout List");
	kvConfig.ImportFromFile(shoutConfigFile);
	if(kvConfig.JumpToKey(cmd, false))
	{
		kvConfig.GetString("path", sound, sizeof(sound), "shout/godlike.mp3")
		iVolume = kvConfig.GetNum("volume", shoutVolume);
		iPitch 	= kvConfig.GetNum("pitch", shoutPitch);
	}
	PlaySound(client, sound, cmd, iVolume, iPitch);
		
	kvConfig.Rewind();
	kvConfig.Close();
	
	return Plugin_Handled;
}

public Action ShoutSettings(int client, int args)
{
	OpenMenuShoutSet(client);

	return Plugin_Handled;
}

// ******************************************************************************************************************
// **************************************************** FUNCTIONS ***************************************************
// ******************************************************************************************************************
public void SoundSetup(char sound[PLATFORM_MAX_PATH], char soundName[64])
{
	char checksound[PLATFORM_MAX_PATH];
	char soundCMD[64];
	
	Format(checksound, sizeof(checksound), "sound/%s", sound);
	Format(soundCMD, sizeof(soundCMD), "sm_%s", soundName);
	
	//PrintToServer("check: %s | sm: %s | sound: %s | soundName: %s",checksound, soundCMD, sound, soundName)
	if (FileExists(checksound))		
	{
		AddFileToDownloadsTable(checksound);
		PrecacheSound(sound)
		if(shoutCommand == 1 && !(CommandExists(soundCMD)))		
		{
			PrintToServer("%s added", soundCMD);
			RegConsoleCmd(soundCMD, ShoutCommand, "Plays a sound");
		}
	}
	else 
	{
		PrintToServer("Soundfile %s not found!", sound);
		RemoveShout(soundName);
	}
}


public void PlaySound(int client, char sound[PLATFORM_MAX_PATH], char soundName[64], int iVolume, int iPitch)
{
	float floatCD = float(shoutCD);
	float floatRadius = float(shoutRadius);
	if(shoutVolume != 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
		{
			if(!(cdStatus[client] & CLIENT_SHOUTCD))
			{
				cdStatus[client] |= CLIENT_SHOUTCD;
				
				// client position holen
				float pos[3];
				GetClientAbsOrigin(client, pos);
				
				int modVolume = RoundToCeil(float(iVolume)/100);
				float floatVolume = float(iVolume)/(modVolume*100);

				if(shoutMode == 0)	
				{
					for(int i = 1; i <= modVolume; i++)						EmitAmbientSound(sound, pos, SOUND_FROM_PLAYER, _, _, floatVolume, iPitch);	
				}
				else if (shoutMode == 1) 
				{					
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i)) 
						{
							if(GetClientTeam(i) == GetClientTeam(client))	
							{
								for(int k = 1; k <= modVolume; k++)			EmitSoundToClient(i, sound, _, _, _, _, floatVolume, iPitch, _, pos, _, true, _);
							}
						}
					}
				}
				else if (shoutMode == 2)
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i)) 
						{
							float pos2[3];
							GetClientAbsOrigin(i, pos2);
							char namebuffer[MAX_NAME_LENGTH];
							GetClientName(i, namebuffer, sizeof(namebuffer));

							if(shoutDebug == 1)	if(GetVectorDistance(pos, pos2, false) > 0.0)PrintToChatAll("Player %s is %.0f away. Current radius: %.0f", namebuffer, GetVectorDistance(pos, pos2, false), floatRadius);
							
							if(GetVectorDistance(pos, pos2, false) <= floatRadius)
							{
								for(int k = 1; k <= modVolume; k++)			EmitSoundToClient(i, sound, _, _, _, _, floatVolume, iPitch, _, pos, _, true, _);
							}
						}
					}
				}
				else if (shoutMode == 3)
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i)) 
						{
							float pos2[3];
							GetClientAbsOrigin(i, pos2);
							char namebuffer[MAX_NAME_LENGTH];
							GetClientName(i, namebuffer, sizeof(namebuffer));
							
							if(shoutDebug == 1)	if(GetVectorDistance(pos, pos2, false) > 0.0)PrintToChatAll("Player %s is %.0f away. Current radius: %.0f", namebuffer, GetVectorDistance(pos, pos2, false), floatRadius);
							
							if((GetVectorDistance(pos, pos2, false) <= floatRadius) && (GetClientTeam(i) == GetClientTeam(client)))
							{
								for(int k = 1; k <= modVolume; k++)			EmitSoundToClient(i, sound, _, _, _, _, floatVolume, iPitch, _, pos, _, true, _);
							}
						}
					}
				}
				shoutCDs[client] = CreateTimer(floatCD, shoutCD_Timer, client);
			}
			else PrintToChat(client, "[Shout] Shout is on cooldown.");
		}
		else PrintToChat(client, "[Shout] Only living players can shout.");
	}
	else if(iVolume == 0) PrintToChat(client, "[Shout] Shout is currently disabled.");
	else PrintToChat(client, "[Shout] Shouts are currently disabled.");
}

public Action shoutCD_Timer(Handle timer, int client)
{
	shoutCDs[client] = INVALID_HANDLE;
	if(IsClientInGame(client) && (cdStatus[client] & CLIENT_SHOUTCD))
	{
		cdStatus[client] &= ~ CLIENT_SHOUTCD;
	}

	return;
}

// *************************************************** SOUNDLISTS ***************************************************
public void GetSounds(char path[PLATFORM_MAX_PATH])
{
	Handle dir = OpenDirectory(path);

	if (dir != INVALID_HANDLE)
	{
		char filename[64];
		FileType type;
		char full[PLATFORM_MAX_PATH];

		while (ReadDirEntry(dir, filename, sizeof(filename), type))
		{
			if (!StrEqual(filename, ".") && !StrEqual(filename, ".."))
			{
				Format(full, sizeof(full), "%s/%s", path, filename);
				
				if (type == FileType_File) 
				{
					if(StrContains(full, ".ztmp") == -1)			
					{
						if(!IsShout(full))
						{
							PushArrayString(fileArray, full);
							if(StrContains(filename, ".wav") != -1) ReplaceString(filename, sizeof(filename), ".wav", "", false);
							else if(StrContains(filename, ".mp3") != -1) ReplaceString(filename, sizeof(filename), ".mp3", "", false);
							PushArrayString(nameArray, filename);
						}
					}
				}
				else if (type == FileType_Directory) GetSounds(full);
			}
		}

		dir.Close();
	}
	else PrintToServer("[Shout] Can't add file %s.", path);
}

public void ShoutList()
{
	char soundName[64];
	char sound[PLATFORM_MAX_PATH];
	
	kvConfig = new KeyValues("Shout List");
	kvConfig.ImportFromFile(shoutConfigFile);
	
	kvConfig.GotoFirstSubKey();
	do
	{
		kvConfig.GetSectionName(soundName, sizeof(soundName));
		kvConfig.GetString("path", sound, sizeof(sound), "shout/godlike.mp3");
		PushArrayString(fileArray_Added, sound);
		PushArrayString(nameArray_Added, soundName);
	}
	while(kvConfig.GotoNextKey());
	
	kvConfig.Rewind();
	kvConfig.Close();
}

// ******************************************************************************************************************
// ***************************************************** UTILITY ****************************************************
// ******************************************************************************************************************

public bool IsShout(char compare[PLATFORM_MAX_PATH])
{
	EmptyArrays(fileArray_Added, nameArray_Added);
	ShoutList();
	
	ReplaceString(compare, sizeof(compare), "sound/", "",false);
	
	if(FindStringInArray(fileArray_Added, compare) != -1) return true;
	return false;
}

public bool NameTaken(char compare[64])
{
	EmptyArrays(fileArray_Added, nameArray_Added);
	ShoutList();
	
	if(FindStringInArray(nameArray_Added, compare) != -1) return true;
	return false;
}

public Action shoutAD_Timer(Handle timer, int client)
{
	shoutAdvert[client] = INVALID_HANDLE;

	if(IsClientInGame(client) && GetClientTeam(client) > 1)
	{
		if(CheckCommandAccess(client, "generic_admin", ADMFLAG_RCON, true)) PrintToChat(client, "[Shout] Use !shout to shout or !shoutset to manage them.");
		else PrintToChat(client, "[Shout] Use !shout to bring up the shout menu.");
	}

	return;
}

public void RemoveShout(char soundName[64])
{
	kvConfig = new KeyValues("Shout List");
	kvConfig.ImportFromFile(shoutConfigFile);
	
	kvConfig.JumpToKey(soundName, false);
	kvConfig.DeleteThis();
	kvConfig.GoBack();

	kvConfig.Rewind();
	kvConfig.ExportToFile(shoutConfigFile);
	kvConfig.Close();
}

public int GetVolOrPit(char shoutname[64], char StrToGet[32])
{
	int iVolume, iPitch;
		
	kvConfig = new KeyValues("Shout List");
	kvConfig.ImportFromFile(shoutConfigFile);
	kvConfig.JumpToKey(shoutname);

	iVolume = kvConfig.GetNum("volume", shoutVolume);
	iPitch	= kvConfig.GetNum("pitch", shoutPitch);
	
	kvConfig.Rewind();
	kvConfig.Close();	
	
	if(StrEqual(StrToGet, "volume")) return iVolume;
	else if(StrEqual(StrToGet, "pitch")) return iPitch;
	
	return 100;
}

public void EmptyArrays(Handle array1, Handle array2)
{
 	ClearArray(array1);
	ClearArray(array2);
}