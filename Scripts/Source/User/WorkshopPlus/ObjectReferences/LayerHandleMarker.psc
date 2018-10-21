; ---------------------------------------------
; WorkshopPlus:ObjectReferences:LayerHandleMarker.psc - by kinggath
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

Scriptname WorkshopPlus:ObjectReferences:LayerHandleMarker extends WorkshopObjectScript
{ Actual object players interact with }


Keyword Property LinkHandleKeyword Auto Const Mandatory
Keyword Property WorkshopStackedItemParentKeyword Auto Const Mandatory
GlobalVariable Property Setting_HighlightLayerHandleSelectedObjects Auto Const Mandatory
EffectShader Property GrabbedShader Auto Const Mandatory


Event OnWorkshopObjectGrabbed(ObjectReference akWorkshopRef)
	WorkshopPlus:ObjectReferences:LayerHandle thisLayerHandle = GetLinkedRef(LinkHandleKeyword) as WorkshopPlus:ObjectReferences:LayerHandle
	
	if(thisLayerHandle)
		if(Setting_HighlightLayerHandleSelectedObjects.GetValue() == 1.0)
			; Highlight all objects
			ObjectReference[] AttachedObjects = thisLayerHandle.GetLinkedRefChildren(WorkshopStackedItemParentKEYWORD)
		
			int i = 0
			while(i < AttachedObjects.Length)
				GrabbedShader.Play(AttachedObjects[i], -1.0)
				
				i += 1
			endWhile
		endif
	endif
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akWorkshopRef)
	WorkshopPlus:ObjectReferences:LayerHandle thisLayerHandle = GetLinkedRef(LinkHandleKeyword) as WorkshopPlus:ObjectReferences:LayerHandle
	
	; Disconnect in case the player stores it - that way the objects attached won't get stored
	if(thisLayerHandle)
		; Make sure the handle stays linked in case we pick up the marker again
		thisLayerHandle.SetLinkedRef(Self, WorkshopStackedItemParentKEYWORD)
		
		; Unhighlight all objects
		if(Setting_HighlightLayerHandleSelectedObjects.GetValue() == 1.0)
			; Highlight all objects
			ObjectReference[] AttachedObjects = thisLayerHandle.GetLinkedRefChildren(WorkshopStackedItemParentKEYWORD)
		
			int i = 0
			while(i < AttachedObjects.Length)
				GrabbedShader.Stop(AttachedObjects[i])
				
				i += 1
			endWhile
		endif
	endif
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akWorkshopRef)
	Self.Delete()
EndEvent


Function Delete()
	Cleanup()
	
	Parent.Delete()
EndFunction

Function Cleanup()
	WorkshopPlus:ObjectReferences:LayerHandle thisLayerHandle = GetLinkedRef(LinkHandleKeyword) as WorkshopPlus:ObjectReferences:LayerHandle
	
	Self.SetLinkedRef(None, LinkHandleKeyword)
	Self.SetLinkedRef(None, WorkshopStackedItemParentKEYWORD)
	
	thisLayerHandle.Cleanup()	
EndFunction