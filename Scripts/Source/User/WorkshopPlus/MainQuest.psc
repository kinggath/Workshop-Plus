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

import WorkshopFramework:Library:UtilityFunctions

; ---------------------------------------------
; Consts
; ---------------------------------------------

Float fFallDamagePreventionTime = 10.0 Const
Float fFrozenTimeScale = 0.1 Const
Float fDefaultTimeScale = 20.0 Const

Int DelayedFallDamageTimerID = 100 Const
Int WorkshopModeAutoSaveTimerID = 101 Const
Int iObjective_OwnershipTracking = 10 Const

Struct ResourceObjectiveMap
	ActorValue ResourceAV
	Int iObjective
EndStruct

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
	GlobalVariable Property WSFWVersion Auto Const Mandatory
	{ 1.0.2 - Point to WSFW version global }
	GlobalVariable Property RequiredWSFWVersion Auto Const Mandatory
	{ 1.0.2 - Warn player if they have a version mismatch with WSFW }
	ResourceObjectiveMap[] Property ResourceTrackingMaps Auto Const Mandatory
EndGroup

Group Aliases
	RefCollectionAlias Property OwnershipTracking Auto Const Mandatory
	RefCollectionAlias Property ResourceTracking Auto Const Mandatory
EndGroup

Group Assets
	SoundCategory Property PlayerFootsteps Auto Const Mandatory
	{ 1.0.3 - Disabling footsteps while flight is on }
	Race Property FloatingRace Auto Const Mandatory
	Race Property HumanRace Auto Const Mandatory
	Spell Property InvisibilitySpell Auto Const Mandatory
	Spell[] Property SpeedSpells Auto Const
	Perk Property UndetectablePerk Auto Const Mandatory
	Perk Property ModFallingDamage Auto Const Mandatory
	{ Autofill }
	Perk Property ImmuneToRadiation Auto Const Mandatory
	{ Autofill }
	Perk Property ActivationsPerk Auto Const Mandatory
	Form Property XMarkerForm Auto Const Mandatory
	MagicEffect Property ArmorFallingEffect Auto Const Mandatory
	GlobalVariable Property TimeScale Auto Const Mandatory
	Spell Property BoostCarryWeightSpell Auto Const Mandatory
	Spell Property FreezeTimeSpell Auto Const Mandatory
	Spell Property RadResistSpell Auto Const Mandatory
	{ 1.0.3 - Adding rad resistance to invulnerability }
	Keyword Property JetpackKeyword Auto Const Mandatory
	Weather Property CommonwealthClear Auto Const Mandatory
	Keyword Property WorkshopFreeBuild Auto Const Mandatory
	Keyword Property VRWorkshopKeyword Auto Const Mandatory
EndGroup

Group ActorValues
	ActorValue Property FallingDamageMod Auto Const Mandatory
	{ Autofill }	
EndGroup

Group Keywords
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	{ Autofill }
	Keyword Property WorkshopWorkObject Auto Const Mandatory
	{ Autofill }
EndGroup

Group Messages
	Message Property MustBeInWorkshopModeToUseHotkeys Auto Const Mandatory
	Message Property CouldNotAutoSave Auto Const Mandatory
	Message Property WSFWVersionMismatch Auto Const Mandatory
	Message Property NoOwnerFound Auto Const Mandatory
	Message Property NoItemsFound Auto Const Mandatory
	Message Property NotInSettlement Auto Const Mandatory
EndGroup

Group Settings
	GlobalVariable Property Setting_PreventFallDamageInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_MoveSpeedInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_FlyInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_InvisibleInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_InvulnerableInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_AutoSaveTimer Auto Const Mandatory
	GlobalVariable Property Setting_AutoSaveReturnToWorkshopModeDelay Auto Const Mandatory
	GlobalVariable Property Setting_FreezeTimeInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_BoostCarryWeightInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Settings_ShowHotkeyWarnings Auto Const Mandatory
	{ 1.0.4 }
	GlobalVariable Property Setting_AutoClearWeatherInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_FreeBuildInAllSettlements Auto Const Mandatory
EndGroup


; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool Property IsGameSaving = false Auto Hidden


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
	

Bool Property FreezeTimeInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_FreezeTimeInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_FreezeTimeInWorkshopMode.SetValue(1.0)
		else
			Setting_FreezeTimeInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty


Bool Property ClearWeatherInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_AutoClearWeatherInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_AutoClearWeatherInWorkshopMode.SetValue(1.0)
		else
			Setting_AutoClearWeatherInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty


Bool Property BoostCarryWeightInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_BoostCarryWeightInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_BoostCarryWeightInWorkshopMode.SetValue(1.0)
		else
			Setting_BoostCarryWeightInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty

Bool Property FlyInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_FlyInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_FlyInWorkshopMode.SetValue(1.0)
		else
			Setting_FlyInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty

Bool Property InvisibleInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_InvisibleInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_InvisibleInWorkshopMode.SetValue(1.0)
		else
			Setting_InvisibleInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty


Bool Property InvulnerableInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_InvulnerableInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_InvulnerableInWorkshopMode.SetValue(1.0)
		else
			Setting_InvulnerableInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty


; Setting this up a little differently so that we can give the player just one setting, but still control the speed and wether or not it's turned on independently via a hotkey to toggle the buff on or off
Bool bIncreaseSpeedInWorkshopMode = true
Bool Property IncreaseSpeedInWorkshopMode Hidden
	Bool Function Get()
		if( ! bIncreaseSpeedInWorkshopMode || Setting_MoveSpeedInWorkshopMode.GetValue() <= 0)
			return false
		else
			return true
		endif
	EndFunction
	
	Function Set(Bool value)
		bIncreaseSpeedInWorkshopMode = value
	EndFunction
EndProperty


Int iSpeedSpellIndex = 1
Int Property SpeedSpellIndex Hidden
	Int Function Get()
		Float fSpeedSetting = Setting_MoveSpeedInWorkshopMode.GetValue()
		
		if(fSpeedSetting == 0)
			iSpeedSpellIndex = -1
		elseif(fSpeedSetting == 1)
			iSpeedSpellIndex = 0
		elseif(fSpeedSetting == 2)
			iSpeedSpellIndex = 1
		else
			iSpeedSpellIndex = 2
		endif
		
		return iSpeedSpellIndex
	EndFunction
EndProperty

; ---------------------------------------------
; Vars
; ---------------------------------------------

InputEnableLayer controlLayer
Bool bSpeedBuffApplied = false
Bool bInvisibilityBuffApplied = false
Bool bFirstTimeEnteringEver = true
Race LastKnownRace = None
Float fFallDamageModdedBy = 0.0
Bool bBoostCarryWeightBuffApplied = false
Float fPreviousTimeScale = 0.0
Bool bTimeFrozen = false

; ---------------------------------------------
; Events
; --------------------------------------------- 

Event OnTimer(Int aiTimerID)
	Parent.OnTimer(aiTimerID)
	
	if(aiTimerID == DelayedFallDamageTimerID)
		if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
			AllowFallDamage()
		endif
	elseif(aiTimerID == WorkshopModeAutoSaveTimerID)
		if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
			ExitWorkshopModeAndSave()			
		endif
		
		Float fAutoSaveTime = Setting_AutoSaveTimer.GetValue() * 60
		
		if(fAutoSaveTime > 0)
			StartTimer(fAutoSaveTime, WorkshopModeAutoSaveTimerID)
		endif
	endif
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if(asMenuName== "WorkshopMenu")
		if( ! abOpening) ; Leaving workshop menu
			if(IsGameSaving)
				Utility.Wait(1.0) ; Give other quests a chance to react to the IsGameSaving state
				IsGameSaving = false
			else
				Bool bWasFlying = (PlayerRef.GetRace() == FloatingRace)
				DecreaseSpeed()
				DisableFlight()
				DisableInvisibility()
				DisableCarryWeightBoost()
				UnfreezeTime()
				PlayerRef.SetGhost(false)
				PlayerRef.RemovePerk(ImmuneToRadiation)
				StartTimer(fFallDamagePreventionTime, DelayedFallDamageTimerID)		

				if(bWasFlying)
					; Give time for race swap to complete
					Utility.Wait(1.0)
				endif
				
				controlLayer.Delete()
				controlLayer = None
				
				CancelTimer(WorkshopModeAutoSaveTimerID)
			endif
		else ; Player entered workshop mode
			if( ! IsGameSaving)
				Float fAutoSaveTime = Setting_AutoSaveTimer.GetValue() * 60
			
				if(fAutoSaveTime > 0)
					StartTimer(fAutoSaveTime, WorkshopModeAutoSaveTimerID)
				endif
			
				controlLayer = InputEnableLayer.Create()
				controlLayer.EnableCamSwitch(false)
				controlLayer.EnableMenu(false)
						
				if(FlyInWorkshopMode)
					EnableFlight()
					Utility.Wait(1.0) ; Need to wait for race swap before casting any spells
				endif
				
				if(PreventFallDamageInWorkshopMode)
					PreventFallDamage()
				endif
				
				if(InvisibleInWorkshopMode)
					EnableInvisibility()
				endif
				
				if(BoostCarryWeightInWorkshopMode)
					EnableCarryWeightBoost()
				endif
				
				if(FreezeTimeInWorkshopMode)
					FreezeTime()
				endif
				
				if(IncreaseSpeedInWorkshopMode)
					IncreaseSpeed()
				endif
				
				if(InvulnerableInWorkshopMode)
					PlayerRef.AddPerk(ImmuneToRadiation)
					PlayerRef.SetGhost(true)
				endif
				
				if(ClearWeatherInWorkshopMode)
					if(Game.IsPluginInstalled("DLCCoast.esm") && PlayerRef.GetWorldspace() == Game.GetFormFromFile(0x00000B0F, "DLCCoast.esm") as Worldspace)
						Weather FarHarborClear = Game.GetFormFromFile(0x00009962, "DLCCoast.esm") as Weather
						
						FarHarborClear.ForceActive(true)
					else
						CommonwealthClear.ForceActive(true)
					endif
				endif
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
	
	; 1.0.2 - We've started adding features that require a specific version of the framework
	if(RequiredWSFWVersion.GetValue() > WSFWVersion.GetValue())
		WSFWVersionMismatch.Show()
	endif
	
	if( ! PlayerRef.HasPerk(ActivationsPerk))
		PlayerRef.AddPerk(ActivationsPerk)
	endif
	
	IsGameSaving = false ; In case something caused this to get stuck on
EndFunction


Function TrackOwner(ObjectReference akObjectRef)
	if(OwnershipTracking.Find(akObjectRef) >= 0)
		ClearOwnershipTracking()
	else
		Actor thisActor = WorkshopFramework:WorkshopFunctions.GetAssignedActor(akObjectRef)
		
		if(thisActor == None)
			NoOwnerFound.Show()
			ClearOwnershipTracking()
		else
			OwnershipTracking.AddRef(akObjectRef)
			OwnershipTracking.AddRef(thisActor)	
			SetObjectiveDisplayed(iObjective_OwnershipTracking, true)
			SetActive()			
		endif
	endif
EndFunction


Function TrackItems(Actor akActorRef)
	if(OwnershipTracking.Find(akActorRef) >= 0)
		ClearOwnershipTracking()
	else
		WorkshopScript thisWorkshop = akActorRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		
		ObjectReference[] OwnedObjects
		if(thisWorkshop)
			OwnedObjects = thisWorkshop.GetWorkshopOwnedObjects(akActorRef)
		endif
		
		if(OwnedObjects == None || OwnedObjects.Length == 0)
			NoItemsFound.Show()
			ClearOwnershipTracking()
		else
			OwnershipTracking.AddRef(akActorRef)
		
			Keyword[] ExcludeKeywords = new Keyword[0]
			
			; Skip Sim Settlements plot objects
			if(Game.IsPluginInstalled("SimSettlements.esm"))
				Keyword PlotSpawnedKeyword = Game.GetFormFromFile(0x000039D4, "SimSettlements.esm") as Keyword
				ExcludeKeywords.Add(PlotSpawnedKeyword)
			endif
			
			int i = 0
			while(i < OwnedObjects.Length)
				bool bTrackItem = OwnedObjects[i].HasKeyword(WorkshopWorkObject)
				
				int j = 0
				while(j < ExcludeKeywords.Length && bTrackItem)
					if(OwnedObjects[i].HasKeyword(ExcludeKeywords[j]))
						bTrackItem = false
					endif
					
					j += 1
				endWhile
				
				if(bTrackItem)
					OwnershipTracking.AddRef(OwnedObjects[i])
				endif
				
				i += 1
			endWhile
			
			SetObjectiveDisplayed(iObjective_OwnershipTracking, true)
			SetActive()
		endif
	endif
EndFunction


Function ClearOwnershipTracking()
	OwnershipTracking.RemoveAll()
	SetObjectiveDisplayed(iObjective_OwnershipTracking, false)
EndFunction


Function ToggleFlight()
	if(PlayerRef.GetRace() == FloatingRace)
		FlyInWorkshopMode = false
		DisableFlight()
	else
		FlyInWorkshopMode = true
		EnableFlight()
	endif
EndFunction


Function ToggleSpeed()
	if(bSpeedBuffApplied)
		IncreaseSpeedInWorkshopMode = false
		DecreaseSpeed()
	else
		IncreaseSpeedInWorkshopMode = true
		IncreaseSpeed()
	endif
EndFunction


Function ToggleInvisible()
	if(bInvisibilityBuffApplied)
		InvisibleInWorkshopMode = false
		DisableInvisibility()
	else
		InvisibleInWorkshopMode = true
		EnableInvisibility()
	endif
EndFunction


Function ToggleInvulnerable()
	if(PlayerRef.IsGhost())
		InvulnerableInWorkshopMode = false
		PlayerRef.SetGhost(false)
		PlayerRef.RemovePerk(ImmuneToRadiation)
	else
		InvulnerableInWorkshopMode = true
		PlayerRef.AddPerk(ImmuneToRadiation)
		PlayerRef.SetGhost(true)		
	endif
EndFunction


Function ToggleFreezeTime()
	if(bTimeFrozen)
		FreezeTimeInWorkshopMode = false
		UnfreezeTime()
	else
		FreezeTimeInWorkshopMode = true
		FreezeTime()
	endif
EndFunction


Function FreezeTime()
	if(fPreviousTimeScale == 0.0 || fFrozenTimeScale != fPreviousTimeScale)
		fPreviousTimeScale = TimeScale.GetValue()
	endif
	
	TimeScale.SetValue(fFrozenTimeScale)
	
	Bool bIsGhost = PlayerRef.IsGhost()
	
	if(bIsGhost)
		PlayerRef.SetGhost(false)
	endif
	
	FreezeTimeSpell.Cast(PlayerRef)
	
	bTimeFrozen = true
	
	if(bIsGhost)
		PlayerRef.SetGhost(true)
	endif
EndFunction


Function UnfreezeTime()
	if(fPreviousTimeScale > 0.0)
		if(fFrozenTimeScale == fPreviousTimeScale)
			TimeScale.SetValue(fDefaultTimeScale)
		else
			TimeScale.SetValue(fPreviousTimeScale)
		endif
	endif
	
	PlayerRef.DispelSpell(FreezeTimeSpell)
	
	bTimeFrozen = false
EndFunction


Function EnableFlight()
	if(PlayerRef.WornHasKeyword(JetpackKeyword))
		; Jetpacks are incompatible with the race swap 
		return
	endif
	
	if(PlayerRef.GetRace() != FloatingRace)
		LastKnownRace = PlayerRef.GetRace()
	endif
	
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode() && PlayerRef.GetRace() == LastKnownRace)
		Game.ForceFirstPerson()
		PlayerRef.SetRace(FloatingRace)
		PlayerFootsteps.Mute()
		
		if(bFirstTimeEnteringEver && ! PlayerRef.IsInInterior())
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
	if(PlayerRef.GetRace() == FloatingRace)
		PlayerFootsteps.UnMute()
		
		if(LastKnownRace)
			PlayerRef.SetRace(LastKnownRace)
			LastKnownRace = None
		else
			PlayerRef.SetRace(HumanRace)
		endif
	endif		
EndFunction


Function EnableInvisibility()
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		Bool bIsGhost = PlayerRef.IsGhost()
		
		if(bIsGhost)
			PlayerRef.SetGhost(false)
		endif
	
		InvisibilitySpell.Cast(PlayerRef)
		PlayerRef.AddPerk(UndetectablePerk)
		
		bInvisibilityBuffApplied = true
		
		if(bIsGhost)
			PlayerRef.SetGhost(true)
		endif
	endif
EndFunction

Function DisableInvisibility()
	PlayerRef.DispelSpell(InvisibilitySpell)
	PlayerRef.RemovePerk(UndetectablePerk)
	
	bInvisibilityBuffApplied = false
EndFunction


Function EnableCarryWeightBoost()
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		Bool bIsGhost = PlayerRef.IsGhost()
		
		if(bIsGhost)
			PlayerRef.SetGhost(false)
		endif
		
		BoostCarryWeightSpell.Cast(PlayerRef)
		bBoostCarryWeightBuffApplied = true
		
		if(bIsGhost)
			PlayerRef.SetGhost(true)
		endif
	endif
EndFunction

Function DisableCarryWeightBoost()
	PlayerRef.DispelSpell(BoostCarryWeightSpell)
	
	bBoostCarryWeightBuffApplied = false
EndFunction


Function IncreaseSpeed()
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		if(SpeedSpellIndex >= 0 && SpeedSpells.Length > SpeedSpellIndex)
			Bool bIsGhost = PlayerRef.IsGhost()
		
			if(bIsGhost)
				PlayerRef.SetGhost(false)
			endif
			
			SpeedSpells[SpeedSpellIndex].Cast(PlayerRef)
			
			if(bIsGhost)
				PlayerRef.SetGhost(true)
			endif
		endif
		
		bSpeedBuffApplied = true
	endif
EndFunction

Function DecreaseSpeed()
	int i = 0
	while(i < SpeedSpells.Length)
		PlayerRef.DispelSpell(SpeedSpells[i])
		
		i += 1
	endWhile
	
	bSpeedBuffApplied = false
EndFunction


Float Property fTemporaryFalldamageReduction = 0.0 Auto Hidden
Bool bAdjustingFallDamageAV = false
Function PreventFallDamage()
	if(bAdjustingFallDamageAV)
		return
	endif
	
	bAdjustingFallDamageAV = true
	
	if( ! PlayerRef.HasMagicEffect(ArmorFallingEffect))
		PlayerRef.AddPerk(ModFallingDamage)
		Float fBaseValue = PlayerRef.GetBaseValue(FallingDamageMod)
		
		if(fBaseValue < 100) ; Need to make sure we push this AV's Max up to at least 100
			PlayerRef.SetValue(FallingDamageMod, 100.0 - fBaseValue)
		else
			; We'll just mod up by 100 to make sure the actual value, and not just base value is high
			PlayerRef.ModValue(FallingDamageMod, 100.0) 
		endif
	else
		Float fBaseValue = PlayerRef.GetBaseValue(FallingDamageMod)
		Float fValue = PlayerRef.GetValue(FallingDamageMod)
		
		if(fValue < 100)
			if(fTemporaryFalldamageReduction > 0)
				fTemporaryFalldamageReduction = 100.0 - fTemporaryFalldamageReduction - fValue
			else
				fTemporaryFalldamageReduction = 100.0 - fValue
			endif
			
			if(fTemporaryFalldamageReduction > 0)
				PlayerRef.ModValue(FallingDamageMod, fTemporaryFalldamageReduction)
			endif
		endif
	endif
	
	bAdjustingFallDamageAV = false
EndFunction



Function AllowFallDamage()
	if(bAdjustingFallDamageAV)
		return
	endif
	
	bAdjustingFallDamageAV = true
	
	if( ! PlayerRef.HasMagicEffect(ArmorFallingEffect))
		Float fFDMod = PlayerRef.GetValue(FallingDamageMod)
				
		if(fFDMod < 0)
			fFDMod = 0
		endif
		
		PlayerRef.ModValue(FallingDamageMod, (-1 * (fFDMod)))
	elseif(fTemporaryFalldamageReduction > 0)
		PlayerRef.ModValue(FallingDamageMod, (-1 * fTemporaryFalldamageReduction))
		
		fTemporaryFalldamageReduction = 0.0
	endif
	
	bAdjustingFallDamageAV = false
EndFunction


Function ExitWorkshopModeAndSave(Bool abAutoSave = true)
	WorkshopScript thisWorkshop
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		thisWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
		
		if( ! thisWorkshop)
			; Warn user since they are expecting a save
			CouldNotAutoSave.Show()
			
			return
		endif
		
		IsGameSaving = true
		thisWorkshop.StartWorkshop(false)
	endif
	
	Game.RequestSave()
	
	Debug.Notification("Requesting game save.")
	
	if(thisWorkshop != None)
		Utility.Wait(Setting_AutoSaveReturnToWorkshopModeDelay.GetValue()) ; Give it a short time to finish saving
		thisWorkshop.StartWorkshop(true)
	endif
EndFunction


Function ToggleFreeBuildMode(WorkshopScript akWorkshopRef = None, Bool abEnableFreeBuild = true)
	if(akWorkshopRef == None)
		; Toggle on all settlements
		if(Setting_FreeBuildInAllSettlements.GetValueInt() != 1)
			abEnableFreeBuild = false
		endif		
		
		WorkshopScript[] kWorkshops = WorkshopParent.Workshops
		
		int i = 0
		while(i < kWorkshops.Length)
			if(kWorkshops[i] != None && ! kWorkshops[i].HasKeyword(VRWorkshopKeyword))
				if(abEnableFreeBuild)
					kWorkshops[i].AddKeyword(WorkshopFreeBuild)
				else
					kWorkshops[i].RemoveKeyword(WorkshopFreeBuild)
				endif
			endif
			
			i += 1
		endWhile
	else
		if(akWorkshopRef != None && ! akWorkshopRef.HasKeyword(VRWorkshopKeyword))
			if(abEnableFreeBuild)
				akWorkshopRef.AddKeyword(WorkshopFreeBuild)
			else
				akWorkshopRef.RemoveKeyword(WorkshopFreeBuild)
			endif
		endif		
	endif
EndFunction


Function MCM_TrackResource(Int aiTrackIndex)
	TrackResource(aiResourceIndex = aiTrackIndex)
EndFunction

Function ClearResourceTracking()
	ResourceTracking.RemoveAll()
	
	int i = 0
	while(i < ResourceTrackingMaps.Length)
		SetObjectiveDisplayed(ResourceTrackingMaps[i].iObjective, false)
		
		i += 1
	endWhile
EndFunction

Function TrackResource(WorkshopScript akWorkshopRef = None, ActorValue aResourceForm = None, Int aiResourceIndex = -1)
	ClearResourceTracking()
	
	if(akWorkshopRef == None)
		akWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
		
		if( ! akWorkshopRef)
			NotInSettlement.Show()
			
			return
		endif
	endif
	
	int iObjectiveToShow = -1
	if(aResourceForm == None)
		if(aiResourceIndex > -1)
			aResourceForm = ResourceTrackingMaps[aiResourceIndex].ResourceAV
			iObjectiveToShow = ResourceTrackingMaps[aiResourceIndex].iObjective
		endif
	else
		int iIndex = ResourceTrackingMaps.FindStruct("ResourceAV", aResourceForm)
		if(iIndex >= 0)
			iObjectiveToShow = ResourceTrackingMaps[iIndex].iObjective
		endif		
	endif
	
	if(aResourceForm == None)
		return
	endif
	
	ObjectReference[] kResourceObjects = akWorkshopRef.GetWorkshopResourceObjects(aResourceForm)
	int i = 0
	while(i < kResourceObjects.Length)
		if(kResourceObjects[i].GetValue(aResourceForm) > 0)
			ResourceTracking.AddRef(kResourceObjects[i])
		endif
		
		i += 1
	endWhile
	
	SetObjectiveDisplayed(iObjectiveToShow, true)
	SetActive(true)
EndFunction


; ---------------------------------------------
; MCM Functions - Easiest to avoid parameters for use with MCM's CallFunction, also we only want these hotkeys to work in WS mode
; ---------------------------------------------

Function Hotkey_ToggleFlight()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	ToggleFlight()
EndFunction


Function Hotkey_ToggleSpeed()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	ToggleSpeed()
EndFunction


Function Hotkey_ToggleFreezeTime()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	ToggleFreezeTime()
EndFunction


Function Hotkey_ToggleFreeBuildMode()
	WorkshopScript kWorkshopRef = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
	
	if(kWorkshopRef != None)
		ToggleFreeBuildMode(kWorkshopRef, abEnableFreeBuild = ( ! kWorkshopRef.HasKeyword(WorkshopFreeBuild)))
	endif
EndFunction


Function MCM_ChangeFreeBuildMode()
	; Global will be set just before this is called
	ToggleFreeBuildMode(None, abEnableFreeBuild = (Setting_FreeBuildInAllSettlements.GetValueInt() == 1))
EndFunction



Function Hotkey_ExitWorkshopModeAndSave()
	ExitWorkshopModeAndSave()
EndFunction


; Added 1.0.4
Function ShowHotkeyWarning()
	if(Settings_ShowHotkeyWarnings.GetValue() == 1.0)
		ShowHotkeyWarning()
	endif
EndFunction