#include <sourcemod>
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

int iTargets[MAXPLAYERS+1];
ArrayList aCommands, aNames;

public Plugin myinfo ={
	name = "Admin Target",
	author = "XTANCE",
	description = "...",
	version = "0.1",
	url = "https://t.me/xtance"
}

public void OnPluginStart() {
	RegAdminCmd("sm_tar", Command_Target, ADMFLAG_GENERIC, "Target menu");
	RegAdminCmd("sm_target", Command_Target, ADMFLAG_GENERIC, "Target menu");
	aCommands = new ArrayList(ByteCountToCells(128));
	aCommands.Clear();
	aNames = new ArrayList(ByteCountToCells(128));
	aNames.Clear();
	char szKV[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szKV, sizeof(szKV), "configs/admtarget.ini");
	KeyValues kv = new KeyValues("AdmTarget");
	if (!FileExists(szKV, false)){
		// Examples of commands // Образцы команд
		// TARGET will be used as userid // TARGET будет использоваться как userid
		kv.SetString("Опознать", "sm_who TARGET");
		kv.SetString("Шлёпнуть", "sm_slap TARGET 0");
		kv.SetString("Убить", "sm_slay TARGET");
		kv.SetString("Забанить (навсегда)", "sm_ban TARGET 0 \"Бан просто так\" ");
		kv.SetString("Кикнуть", "sm_kick TARGET \"Кик просто так\" ");
		kv.Rewind();
		kv.ExportToFile(szKV);
	}
	
	kv.ImportFromFile(szKV);
	char sCommand[128],sName[128];
	kv.GotoFirstSubKey(false);
	do {
		kv.GetSectionName(sName, sizeof(sName));
		kv.GetString(NULL_STRING, sCommand, sizeof(sCommand));
		PushArrayString(aCommands, sCommand);
		PushArrayString(aNames, sName);
	} while (kv.GotoNextKey(false));
	delete kv;
}

public Action Command_Target(int iClient, int iArgs){
	if (iClient > 0 && iClient <= MAXPLAYERS) {
		Chooser(iClient);
	}
	return Plugin_Handled;
}

void Chooser(int iClient){
	iTargets[iClient] = 0;
	if (IsClientInGame(iClient)){
		Menu mchooser = new Menu(hchooser, MenuAction_Cancel);
		mchooser.AddItem("itemupdate","Обновить цель");
		int iSpecMode = GetEntProp(iClient, Prop_Send, "m_iObserverMode");
		if (iSpecMode == 4){
			mchooser.SetTitle("Выбор цели");
			int iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
			if ((MAXPLAYERS >= iTarget > 0) && IsClientInGame(iTarget)){
				char sItem[16], sName[256];
				FormatEx(sItem, sizeof(sItem), "%i", GetClientUserId(iTarget));
				if (CanUserTarget(iClient, iTarget)){
					FormatEx(sName, sizeof(sName), "Игрок: %N", iTarget);
					mchooser.AddItem(sItem, sName);
				}
				else{
					FormatEx(sName, sizeof(sName), "Игрок: %N\n(Невозможно выбрать)", iTarget);
					mchooser.AddItem(sItem, sName, ITEMDRAW_DISABLED);
				}
			}
		}
		else{
			mchooser.SetTitle("Управление целью недоступно:\nНеобходимо наблюдать за кем-нибудь.");
		}
		mchooser.ExitBackButton = true;
		mchooser.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int hchooser(Menu mchooser, MenuAction action, int param1, int param2){
	switch (action)
	{
		case MenuAction_Cancel:{
			if (param2 == MenuCancel_ExitBack) {
				Chooser(param1);
			}
		}
		case MenuAction_Select: {
			char sItem[16];
			mchooser.GetItem(param2, sItem, sizeof(sItem));
			if (StrEqual(sItem, "itemupdate")){
				Chooser(param1);
			}
			else{
				iTargets[param1] = StringToInt(sItem);
				CommandMenu(param1);
			}
		}
	}
}

void CommandMenu(int iClient){
	if (GetClientOfUserId(iTargets[iClient]) == 0) Chooser(iClient);
	else{
		Menu mcommands = new Menu(hcommands, MenuAction_Cancel);
		mcommands.SetTitle("Выбор команды\nЦель: %N",GetClientOfUserId(iTargets[iClient]));
		char sCommand[128],sName[128];
		for (int i = 0; i < aCommands.Length; i++){
			aCommands.GetString(i, sCommand, sizeof(sCommand));
			aNames.GetString(i, sName, sizeof(sName));
			mcommands.AddItem(sCommand, sName);
		}
		mcommands.ExitBackButton = true;
		mcommands.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int hcommands(Menu mcommands, MenuAction action, int param1, int param2){
	switch (action){
		case MenuAction_Cancel:{
			if (param2 == MenuCancel_ExitBack) {
				Chooser(param1);
			}
		}
		case MenuAction_Select: {
			char sItem[128], sId[16];
			mcommands.GetItem(param2, sItem, sizeof(sItem));
			FormatEx(sId, sizeof(sId), "#%i", iTargets[param1]);
			ReplaceString(sItem, sizeof(sItem), "TARGET", sId, false);
			PrintToChat(param1, " \x04>> \x01Выполнена команда: \x04%s", sItem);
			FakeClientCommandEx(param1, sItem);
			CommandMenu(param1);
		}
	}
}