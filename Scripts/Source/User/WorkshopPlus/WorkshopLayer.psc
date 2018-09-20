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
Bool Property bActive = true Auto Hidden
EffectShader Property CurrentHighlightShader = None Auto Hidden

Bool Property bDeletedByManager = false Auto Hidden ; Used by LayerManager to tell the layer it has already taken care of the link chain


Function Disable(Bool abFade = false)
	Cleanup()
EndFunction

Function DisableNoWait(Bool abFade = false)
	Cleanup()
EndFunction

Function Cleanup()
	if( ! bDeletedByManager)
		LayerManager.LayerDeleted(Self, abPlayerInitiatedDeletion = false)
	endif
	
	kLastCreatedItem = None
EndFunction