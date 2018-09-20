; ---------------------------------------------
; WorkshopPlus:MainQuest.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below.
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDIT
; N/A
; ---------------------------------------------

Scriptname WorkshopPlus:MainQuest extends WorkshopFramework:Library:MasterQuest
{ Primarily using this for the FrameworkStartQuests so we aren't launching all of our quests immediately }

; ---------------------------------------------
; Consts
; ---------------------------------------------

Float fFallDamagePreventionTime = 10.0 Const

Int DelayedFallDamageTimerID = 100 Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Assets
	Race Property FloatingRace Auto Const Mandatory
	Race Property HumanRace Auto Const Mandatory
	Spell[] Property SpeedSpells Auto Const
	Perk Property ModFallingDamage Auto Const Mandatory
	{ Autofill }
	Form Property XMarkerForm Auto Const Mandatory
EndGroup

Group ActorValues
	ActorValue Property FallingDamageMod Auto Const Mandatory
	{ Autofill }
EndGroup

Group Messages
	Message Property MustBeInWorkshopModeToUseHotkeys Auto Const Mandatory
EndGroup

Group Settings
	GlobalVariable Property Setting_PreventFallDamageInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_MoveSpeedInWorkshopMode Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool Property PreventFallDamageInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_PreventFallDamageInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_PreventFallDamageInWorkshopMode.SetValue(1.0)
		else
			Setting_PreventFallDamageInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty


Bool bFlyInWorkshopMode = true
Bool Property FlyInWorkshopMode Hidden
	Bool Function Get()
		return bFlyInWorkshopMode
	EndFunction
	
	Function Set(Bool value)
		bFlyInWorkshopMode = value
	EndFunction
EndProperty


Bool bIncreaseSpeedInWorkshopMode = true
Bool Property IncreaseSpeedInWorkshopMode Hidden
	Bool Function Get()
		if( ! bIncreaseSpeedInWorkshopMode || Setting_MoveSpeedInWorkshopMode.GetValue() == 0)
			return false
		else
			return true
		endif
	EndFunction
	
	Function Set(Bool value)
		bIncreaseSpeedInWorkshopMode = value
	EndFunction
EndProperty


Int iSpeedSpellIndex = 0
Int Property SpeedSpellIndex Hidden
	Int Function Get()
		Float fSpeedSetting = Setting_MoveSpeedInWorkshopMode.GetValue()
		
		if(fSpeedSetting == 0)
			iSpeedSpellIndex = -1
		elseif(fSpeedSetting == 1)
			iSpeedSpellIndex = 0
		else
			iSpeedSpellIndex = 1
		endif
		
		return iSpeedSpellIndex
	EndFunction
EndProperty

; ---------------------------------------------
; Vars
; ---------------------------------------------

InputEnableLayer controlLayer
Bool bSpeedBuffApplied = false
Bool bFirstTimeEnteringEver = true
Race LastKnownRace = None
Float fFallDamageModdedBy = 0.0

; ---------------------------------------------
; Events
; --------------------------------------------- 

Event OnTimer(Int aiTimerID)
	Parent.OnTimer(aiTimerID)
	
	if(aiTimerID == DelayedFallDamageTimerID)
		if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
			AllowFallDamage()
		endif
	endif
EndEvent


Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if(asMenuName== "WorkshopMenu")
		if( ! abOpening) ; Leaving workshop menu
			DecreaseSpeed()
			DisableFlight()
			StartTimer(fFallDamagePreventionTime, DelayedFallDamageTimerID)
			
			; Do not restore controls until race is restored - otherwise player can get stuck in pipboy screen if they open it too quickly
			Utility.Wait(0.5)
			controlLayer.Delete()
			controlLayer = None
		else ; Player entered workshop mode
			controlLayer = InputEnableLayer.Create()
			controlLayer.EnableCamSwitch(false)
			controlLayer.EnableMenu(false)
	
			if(PreventFallDamageInWorkshopMode)
				PreventFallDamage()
			endif
			
			if(FlyInWorkshopMode)
				EnableFlight()
			endif
			
			if(IncreaseSpeedInWorkshopMode)
				IncreaseSpeed()
			endif
		endif
	endif	
EndEvent

; ---------------------------------------------
; Functions
; --------------------------------------------- 

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
EndFunction


Function ToggleFlight()
	if(PlayerRef.GetRace() == FloatingRace)
		DisableFlight()
	else
		EnableFlight()
	endif
EndFunction


Function ToggleSpeed()
	if(bSpeedBuffApplied)
		DecreaseSpeed()
	else
		IncreaseSpeed()
	endif
EndFunction


Function EnableFlight()
	FlyInWorkshopMode = true
	
	if(PlayerRef.GetRace() != FloatingRace)
		LastKnownRace = PlayerRef.GetRace()
	endif
	
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode() && PlayerRef.GetRace() == LastKnownRace)
		Game.ForceFirstPerson()
		PlayerRef.SetRace(FloatingRace)
		
		if(bFirstTimeEnteringEver)
			; For new users, let's show them you can fly
			ObjectReference kTemp = PlayerRef.PlaceAtMe(XMarkerForm)
			bFirstTimeEnteringEver = false
			PlayerRef.TranslateTo(PlayerRef.X, PlayerRef.Y, PlayerRef.Z + 512.0, PlayerRef.GetAngleX(), PlayerRef.GetAngleY(), PlayerRef.GetAngleZ(), 300.0) 
			
			Game.StartDialogueCameraOrCenterOnTarget(kTemp)
			
			kTemp.Disable()
			kTemp.Delete()
		endif
	endif
EndFunction

Function DisableFlight()
	FlyInWorkshopMode = false
	
	if(PlayerRef.GetRace() == FloatingRace)
		if(LastKnownRace)
			PlayerRef.SetRace(LastKnownRace)
			LastKnownRace = None
		else
			PlayerRef.SetRace(HumanRace)
		endif
	endif	
EndFunction


Function IncreaseSpeed()
	IncreaseSpeedInWorkshopMode = true
	
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		if(SpeedSpellIndex >= 0 && SpeedSpells.Length > SpeedSpellIndex)
			SpeedSpells[SpeedSpellIndex].Cast(PlayerRef)
		endif
		
		bSpeedBuffApplied = true
	endif
EndFunction

Function DecreaseSpeed()
	IncreaseSpeedInWorkshopMode = false
	
	int i = 0
	while(i < SpeedSpells.Length)
		PlayerRef.DispelSpell(SpeedSpells[i])
		
		i += 1
	endWhile
	
	bSpeedBuffApplied = false
EndFunction


Function PreventFallDamage()
	PlayerRef.AddPerk(ModFallingDamage)
	Float fBaseValue = PlayerRef.GetBaseValue(FallingDamageMod)
	if(fBaseValue < 100)
		PlayerRef.SetValue(FallingDamageMod, fBaseValue + 100.0) 
	else
		PlayerRef.ModValue(FallingDamageMod, 100.0) 
	endif
	
	fFallDamageModdedBy = 100.0
EndFunction


Function AllowFallDamage()
	PlayerRef.RemovePerk(ModFallingDamage)
	PlayerRef.ModValue(FallingDamageMod, (-1 * fFallDamageModdedBy))
	fFallDamageModdedBy = 0.0
EndFunction

; ---------------------------------------------
; MCM Functions - Easiest to avoid parameters for use with MCM's CallFunction, also we only want these hotkeys to work in WS mode
; ---------------------------------------------

Function Hotkey_ToggleFlight()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	ToggleFlight()
EndFunction


Function Hotkey_ToggleSpeed()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	ToggleSpeed()
EndFunction