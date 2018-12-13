; ---------------------------------------------
; WorkshopPlus:ObjectReferences:BlueprintController.psc - by kinggath
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

Scriptname WorkshopPlus:ObjectReferences:BlueprintController extends WorkshopObjectScript
{ Allows managing blueprints, generating new blueprints, and spawning copies of existing blueprints }

import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:Library:DataStructures

; ---------------------------------------------
; Consts 
; ---------------------------------------------


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopPlus:BlueprintManager Property BlueprintManager Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property BlueprintControllerKeyword Auto Const Mandatory
	Keyword Property WorkshopStackedItemParentKEYWORD Auto Const Mandatory
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
EndGroup

Group Assets
	EffectShader Property AttachingShader Auto Const Mandatory
	{ Shader that will show on the controller while it is grabbing items and will also flash on each item as it is added }
	EffectShader Property BusyShader Auto Const Mandatory
	{ Shader that will appear on the controller when it should not be moved }
	EffectShader Property ReadyShader Auto Const Mandatory
	{ Shader that will appear on the controller when it has finished it's task }
EndGroup



; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bFirstLoad = true

; ---------------------------------------------
; Events
; ---------------------------------------------

Event OnInit()
	Parent.OnInit()
	
	AddKeyword(BlueprintControllerKeyword)	
EndEvent


Event OnLoad()
	Parent.OnLoad()
	
	if(bFirstLoad)
		bFirstLoad = false
		
		; Check for layerID and workshopID
		WorkshopScript thisWorkshop = GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
			
		if(workshopID < 0)				
			workshopID = thisWorkshop.GetWorkshopID()
		endif
	endif
EndEvent


Event OnActivate(ObjectReference akActivatedBy)
	BlueprintManager.ShowBlueprintControlMenu(Self)
EndEvent


; ---------------------------------------------
; Functions
; ---------------------------------------------



Function PlayBusyShader(Float afTime = -1.0)
	BusyShader.Play(Self, afTime)
EndFunction

Function PlayReadyShader(Float afTime = 1.0)
	BusyShader.Stop(Self) ; Clear busy shader
	
	Utility.Wait(2.0) ; wait for busy shader to fade out
	
	ReadyShader.Play(Self, afTime)
EndFunction

Function DetachObjects()
	ObjectReference[] StackedRefs = GetLinkedRefChildren(WorkshopStackedItemParentKEYWORD)
	
	int i = 0
	while(i < StackedRefs.Length)
		StackedRefs[i].SetLinkedRef(None, WorkshopStackedItemParentKEYWORD)
		
		i += 1
	endWhile
EndFunction


Function Hide()
	Self.MoveTo(Self, 0.0, 0.0, -10000.0)
	DetachObjects()
EndFunction


Function Disable(Bool abFade = false)
	Cleanup()
	
	Parent.Disable(abFade)
EndFunction

Function DisableNoWait(Bool abFade = false)
	Cleanup()
	
	Parent.DisableNoWait(abFade)
EndFunction

Function Cleanup()
	DetachObjects()
EndFunction