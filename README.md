# Shout Plugin  (Current Version: 1.1)  
A recreation of an eventscripts soccermod feature with some additional options.  
This was a request and due to certain reasons I was bored enough to do it. However I'm still far from being an expert in SourcePawn  
so, again, expect some heavily improvable code.   

### Features
  ● Modes: Ambient, Team only, Distance-based (All & Team)  
  ● Manager: Ingame manager to add, remove or edit the available shouts    
  ● Configuration: While it comes with config files, everything can be configured ingame  
  ● Options:  
     ● Volume, Pitch (global & per shout)  
     ● Cooldown between uses  
     ● Radius for the 2 radius-modes (Default: 400; 25 feet / 7,62m)    
  ● Menu & Commands: Shouts can be played from a menu or by individual commands (if enabled)  
  ● In case you want to bulk-add several sounds at once, simply drop them into the sound/shout folder and use the rescan option.  
    Any sound in sound/shout will be added automatically to the list.  
  ● Commands: !shout | !shoutset (requires GENERIC flag for most settings; RCON flag for manager and commands setting)  
  ● Advert: One-time adver after a player joins - Can be toggled in Help & Credits submenu  
  ● "Debug": So far only used for chatoutput to find suitable radius-settings

## Installation
### 1. Download the required plugins
To run the plugin on your server you need the following plugins:  
 ● Metamod:Source 1.10 or higher  
http://www.sourcemm.net/downloads.php?branch=stable  
  
 ● SourceMod 1.7 or higher  
https://www.sourcemod.net/downloads.php?branch=stable  
  
 ● (OPTIONAL BUT RECOMMENDED) Updater.smx  
Adding this to your server will allow you to automatically update the plugin whenever a new version is uploaded. For more information check the [alliedmodders thread](https://forums.alliedmods.net/showthread.php?p=1570806).  
[Steamworks](http://users.alliedmods.net/~kyles/builds/SteamWorks/)  
[Updater](https://bitbucket.org/GoD_Tony/updater/downloads/updater.smx)  
  
 ● Shout Plugin  
[>>DOWNLOAD with sounds<<](https://github.com/MK99MA/Shout-Plugin/releases/tag/1.0)  

[>>DOWNLOAD without sounds<<](https://github.com/MK99MA/Shout-Plugin/blob/master/addons/sourcemod/plugins/shout.smx)  
