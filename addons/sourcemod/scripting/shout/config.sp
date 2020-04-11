// ******************************************************************************************************************
// ***************************************************** CONFIG *****************************************************
// ******************************************************************************************************************
public void CreateConfig()
{
	if(!FileExists(shoutConfigFile))
	{
		File hFile = OpenFile(shoutConfigFile, "w");
		hFile.Close();
	}
		
	// Scan shout folder -> add them
	GetSounds("sound/shout");
	
	char filebuffer[PLATFORM_MAX_PATH], namebuffer[64];
	
	kvConfig = new KeyValues("Shout List");
	kvConfig.ImportFromFile(shoutConfigFile);
	
	for(int i = 0; i < GetArraySize(nameArray); i++)
	{
		GetArrayString(fileArray, i, filebuffer, sizeof(filebuffer));
		GetArrayString(nameArray, i, namebuffer, sizeof(namebuffer));
				
		//ReplaceString(filebuffer, sizeof(filebuffer), "sound/", "",false);
		//PrintToServer(filebuffer);

		kvConfig.JumpToKey(namebuffer, true);
		kvConfig.SetString("path", 					filebuffer);
		kvConfig.GoBack();

		SoundSetup(filebuffer, namebuffer);
	}

	kvConfig.Rewind();
	kvConfig.ExportToFile(shoutConfigFile);
	kvConfig.Close();
}

public void ReadConfig()
{
	if(!FileExists(shoutConfigFile)) CreateConfig();
	char soundName[64];
	char sound[PLATFORM_MAX_PATH];
	
	kvConfig = new KeyValues("Shout List");
	kvConfig.ImportFromFile(shoutConfigFile);
	
	kvConfig.GotoFirstSubKey();
	do
	{
		kvConfig.GetSectionName(soundName, sizeof(soundName));
		kvConfig.GetString("path", sound, sizeof(sound), "shout/godlike.mp3");
		SoundSetup(sound, soundName);
	}
	while(kvConfig.GotoNextKey());
	
	kvConfig.Rewind();
	kvConfig.Close();
}

// *************************************************** SETTINGS ****************************************************

public void CreateSettings()
{
	File hFile = OpenFile(shoutSetFile, "w");
	hFile.Close();
	
	kvSettings = new KeyValues("Shout Settings");
	kvSettings.ImportFromFile(shoutSetFile);
	
	kvSettings.SetNum("cooldown", 					shoutCD);
	kvSettings.SetNum("volume", 					shoutVolume);
	kvSettings.SetNum("pitch", 						shoutPitch);
	kvSettings.SetNum("commands", 					shoutCommand);
	kvSettings.SetNum("mode",						shoutMode);
	kvSettings.SetNum("message",					shoutMessage);
	kvSettings.GoBack();

	kvSettings.Rewind();
	kvSettings.ExportToFile(shoutSetFile);
	kvSettings.Close();
}

public void ReadSettings()
{
	kvSettings = new KeyValues("Shout Settings");
	kvSettings.ImportFromFile(shoutSetFile);
	
	shoutCD			= kvSettings.GetNum("cooldown", 1);
	shoutVolume		= kvSettings.GetNum("volume", 100);
	shoutPitch 		= kvSettings.GetNum("pitch", 100);
	shoutCommand	= kvSettings.GetNum("commands", 0);
	shoutMode		= kvSettings.GetNum("mode", 0);
	shoutMessage	= kvSettings.GetNum("message", 2);
	kvSettings.GoBack();

	kvSettings.Rewind();
	kvSettings.Close();
}

// *************************************************** UPDATE ****************************************************

public void UpdateSettingsInt(char type[50], int value)
{
	if(!FileExists(shoutSetFile)) CreateSettings();
	kvSettings = new KeyValues("Shout Settings");
	kvSettings.ImportFromFile(shoutSetFile);
	kvSettings.SetNum(type, value);
	
	kvSettings.Rewind();
	kvSettings.ExportToFile(shoutSetFile);
	kvSettings.Close();
}

public void UpdateConfigInt(char section[64], char type[32], int value)
{
	kvConfig = new KeyValues("Shout List");
	kvConfig.ImportFromFile(shoutConfigFile);
	
	kvConfig.JumpToKey(section, false);
	kvConfig.SetNum(type, value);
	
	kvConfig.Rewind();
	kvConfig.ExportToFile(shoutConfigFile);
	kvConfig.Close();
}