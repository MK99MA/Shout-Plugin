// ***********************************************************************************************************************
// ************************************************** COMMAND LISTENERS **************************************************
// ***********************************************************************************************************************

public void NameSet(int client, char type[32], char customname[64], int min, int max)
{
	if (strlen(customname) >= min && strlen(customname) <= max)
	{
		if (StrEqual(type, "CustomShoutName"))
		{
			if(!StrEqual(customname, "!cancel"))
			{
				RenameFunc(client, customname);
			}
			else 
			{
				if(!DupRename) OpenMenuShoutRename(client);
				else OpenMenuShoutAdd(client);
				PrintToChat(client, "[Shout] Input cancelled.");
				gNamebuffer = "cancelled";
			}
		}

		changeSetting[client] = "";
		if(!DupRename) OpenMenuShoutRename(client);
		else OpenMenuShoutAdd(client);
	}
	else PrintToChat(client, "[Shout] The command should be longer than %i and shorter than %i letters.", min, max);
}

// ***********************************************************************************************************************
// ************************************************** COMMAND LISTENERS **************************************************
// ***********************************************************************************************************************
public Action SayCommandListener(int client, char[] command, int argc)
{
	char cmdArg1[64];
	GetCmdArg(1, cmdArg1, sizeof(cmdArg1));

	char customname[64];
	customname = cmdArg1;

	if (StrEqual(changeSetting[client], "CustomName"))
	{
		NameSet(client, "CustomShoutName", customname, 3, 64);
		return Plugin_Handled;			
	}	

	return Plugin_Continue;
}


public void RenameFunc(int client, char customname[64])
{	
	kvConfig = new KeyValues("Shout List");
	kvConfig.ImportFromFile(shoutConfigFile);
	
	if(!DupRename)
	{
		kvConfig.JumpToKey(gNamebuffer, false);
		kvConfig.SetSectionName(customname);
		kvConfig.GoBack();
	}
	else
	{
		kvConfig.JumpToKey(customname, true);
		kvConfig.SetString("path", 					gFilebuffer);
		kvConfig.GoBack();
	}

	kvConfig.Rewind();
	kvConfig.ExportToFile(shoutConfigFile);
	kvConfig.Close();
		
	if(!DupRename)
	{
		int ArrayPos = FindStringInArray(fileArray_Added, gFilebuffer);
			
		SetArrayString(fileArray_Added, ArrayPos, gFilebuffer);
		SetArrayString(nameArray_Added, ArrayPos, customname);
		
		PrintToChat(client, "[Shout] Sound %s was renamed to %s.", gNamebuffer, customname);
		SoundSetup(gFilebuffer, customname);
		
		EmptyArrays(fileArray, nameArray);
		GetSounds("sound");
		OpenMenuShoutRename(client);
	}
	else
	{
		int ArrayPos = FindStringInArray(fileArray, gFilebuffer);
		RemoveFromArray(fileArray, ArrayPos);
		RemoveFromArray(nameArray, ArrayPos);
		
		PrintToChat(client, "[Shout] Sound added as %s with path %s.", customname, gFilebuffer);
		SoundSetup(gFilebuffer, customname);

		EmptyArrays(fileArray, nameArray);
		GetSounds("sound");
		OpenMenuShoutAdd(client);
	}
}