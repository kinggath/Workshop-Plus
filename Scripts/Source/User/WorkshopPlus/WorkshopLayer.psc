; ---------------------------------------------
; WorkshopPlus:WorkshopLayer.psc - by kinggath
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

Scriptname WorkshopPlus:WorkshopLayer extends ObjectReference

WorkshopPlus:LayerManager Property LayerManager Auto Const Mandatory

ObjectReference Property kLastCreatedItem Auto Hidden
Int Property iLayerID = -1 Auto Hidden
Bool Property bShown = true Auto Hidden
Bool Property bActive = false Auto Hidden
Bool Property bEnabled = true Auto Hidden
Bool Property bLinked = true Auto Hidden
Int Property iWorkshopID = -1 Auto Hidden ; 1.0.1 - Ensure we can figure out where this layer came from if we end up with a ref and aren't positive we're in the CurrentSettlementLayers workshop

Int Property iItemCount = 0 Auto Hidden ; 1.0.3 - This will help us to thread things out

EffectShader Property CurrentHighlightShader = None Auto Hidden

Bool Property bDeletedByManager = false Auto Hidden ; Used by LayerManager to tell the layer it has already taken care of the link chain

; 1.0.2 - Storing the latest handle in the layer so we can attach/remove any items as they are added
ObjectReference Property LayerHandle Auto Hidden

Function Disable(Bool abFade = false)
	Cleanup()
	
	Parent.Disable(abFade) ; 1.0.2 - Ensure actual disable takes place
EndFunction

Function DisableNoWait(Bool abFade = false)
	Cleanup()
	
	Parent.DisableNoWait(abFade) ; 1.0.2 - Ensure actual disable takes place
EndFunction

Function Cleanup()
	if( ! bDeletedByManager)
		LayerManager.LayerDeleted(Self, abPlayerInitiatedDeletion = false)
	endif
	
	LayerHandle = None
	kLastCreatedItem = None
EndFunction