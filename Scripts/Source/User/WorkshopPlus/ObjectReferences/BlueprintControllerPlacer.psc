; ---------------------------------------------
; WorkshopPlus:ObjectReferences:BlueprintControllerPlacer.psc - by kinggath
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

Scriptname WorkshopPlus:ObjectReferences:BlueprintControllerPlacer extends ObjectReference Const
{ Moves the BlueprintController object - this is used for interacting with the blueprint system and as the reference point for created blueprints }


import WorkshopFramework:WorkshopFunctions

Form Property BlueprintControllerForm Auto Const Mandatory
WorkshopPlus:BlueprintManager Property BlueprintManager Auto Const Mandatory
Keyword Property WorkshopItemKeyword Auto Const Mandatory
GlobalVariable Property Setting_ShowBlueprintControlMenuOnBuild Auto Const Mandatory

Event OnInit()
	ObjectReference kController
	
	; Search the settlement for the controller
	WorkshopScript thisWorkshop = GetNearestWorkshop(Self)
	
	if(thisWorkshop)
		ObjectReference[] kFound = thisWorkshop.FindAllReferencesOfType(BlueprintControllerForm, 20000.0)
		
		if(kFound.Length)
			int i = 0
			while(i < kFound.Length)
				if(kFound[i].GetLinkedRef(WorkshopItemKeyword) == thisWorkshop)
					kController = kFound[i]
				endif
				
				i += 1
			endWhile
		endif
	
		if( ! kController)
			kController = PlaceAtMe(BlueprintControllerForm, abInitiallyDisabled = true, abDeleteWhenAble = false)
			kController.SetLinkedRef(thisWorkshop, WorkshopItemKeyword)
			kController.Enable(false)
		else ; Bring the existing handle over to the player
			kController.MoveTo(Self)
		endif
	endif
	
	if(Setting_ShowBlueprintControlMenuOnBuild.GetValue() == 1)
		Utility.Wait(2.0) ; Give it time to load
		
		BlueprintManager.ShowBlueprintControlMenu(kController as WorkshopPlus:ObjectReferences:BlueprintController)
	endif
	
	Disable(false)
	Delete()
EndEvent