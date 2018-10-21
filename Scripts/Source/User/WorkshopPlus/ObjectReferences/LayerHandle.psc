; ---------------------------------------------
; WorkshopPlus:ObjectReferences:LayerHandle.psc - by kinggath
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

Scriptname WorkshopPlus:ObjectReferences:LayerHandle extends WorkshopFramework:ObjectRefs:InvisibleWorkshopObject
{ Allows picking up all items on a layer }

import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:Library:DataStructures

; ---------------------------------------------
; Consts 
; ---------------------------------------------


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopPlus:LayerManager Property LayerManager Auto Const Mandatory
EndGroup

Group Keywords
	Keyword Property LayerHandleKeyword Auto Const Mandatory
	Keyword Property WorkshopStackedItemParentKEYWORD Auto Const Mandatory
	Keyword Property LayerItemLinkChainKeyword Auto Const Mandatory
	{ Same as LayerItemLinkChainKeyword on LayerManager }
	Keyword Property AddedToLayerKeyword Auto Const Mandatory
	{ Same as AddedToLayerKeyword on LayerManager }
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
EndGroup

Group ActorValues
	ActorValue Property LayerIDAV Auto Const Mandatory
EndGroup

Group Assets
	EffectShader Property AttachingShader Auto Const Mandatory
	{ Shader that will show on the handle while it is grabbing items and will also flash on each item as it is added }
	EffectShader Property BusyShader Auto Const Mandatory
	{ Shader that will appear on the handle when it should not be moved }
	EffectShader Property ReadyShader Auto Const Mandatory
	{ Shader that will appear on the handle when it has finished it's task }
EndGroup

Group Settings
	Float Property fLinkRadius Auto Const Mandatory
	{ Radius around the handle to link items. }
EndGroup



; ---------------------------------------------
; Vars
; ---------------------------------------------

Int Property iLayerID = -1 Auto Hidden
WorkshopPlus:WorkshopLayer Property LayerRef Auto Hidden
Bool bFirstLoad = true

; ---------------------------------------------
; Events
; ---------------------------------------------

Event OnInit()
	Parent.OnInit()
	
	kControlledRef.SetLinkedRef(Self, LayerHandleKeyword) ; Link to the controlled ref from InvisibleWorkshopObject so we can access it from ActionManager
	AddKeyword(LayerHandleKeyword)	
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
		
		WorkshopPlus:SettlementLayers thisSettlementLayers = LayerManager.GetCurrentSettlementLayers()
		LayerRef = thisSettlementLayers.ActiveLayer
		
		
		if(LayerRef)
			LayerRef.LayerHandle = Self
			iLayerID = LayerRef.iLayerID
			AttachObjects()
		endif
	endif
EndEvent


; ---------------------------------------------
; Functions
; ---------------------------------------------

Function AttachObjects()
	PlayBusyShader()
	
	Float fRadius = fLinkRadius
	
	if(fRadius > 0)
		; Grab items within radius and test for layerID
		ObjectReference[] NearbyRefs = FindAllReferencesWithKeyword(AddedToLayerKeyword, fRadius)
		
		int i = 0
		while(i < NearbyRefs.Length)
			if(NearbyRefs[i].GetValue(LayerIDAV) == iLayerID)
				AttachingShader.Play(NearbyRefs[i], 1.0)
				NearbyRefs[i].SetLinkedRef(Self, WorkshopStackedItemParentKEYWORD)
			endif
			
			i += 1
		endWhile
	else
		; Just attach all items on layer
		ObjectReference kNextRef = LayerRef.kLastCreatedItem
		while(kNextRef)
			AttachingShader.Play(kNextRef, 1.0)
			kNextRef.SetLinkedRef(Self, WorkshopStackedItemParentKEYWORD)
			kNextRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)
		endWhile
	endif
	
	PlayReadyShader()
EndFunction

Function PlayBusyShader(Float afTime = -1.0)
	if(Self.kControlledRef)
		BusyShader.Play(Self.kControlledRef, afTime)
	endif
EndFunction

Function PlayReadyShader(Float afTime = 1.0)
	if(Self.kControlledRef)
		BusyShader.Stop(Self.kControlledRef) ; Clear busy shader
	endif
	
	Utility.Wait(2.0) ; wait for busy shader to fade out
	
	if(Self.kControlledRef)
		ReadyShader.Play(Self.kControlledRef, afTime)
	endif
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
	kControlledRef.MoveTo(Self)
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
	Parent.Cleanup()
	
	if(LayerRef && LayerRef.LayerHandle == Self)
		LayerRef.LayerHandle = None
	endif
	
	DetachObjects()
	
	kControlledRef = None
	LayerRef = None
EndFunction