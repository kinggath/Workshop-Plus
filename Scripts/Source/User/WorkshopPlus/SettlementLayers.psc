; ---------------------------------------------
; WorkshopPlus:SettlementLayers.psc - by kinggath
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

Scriptname WorkshopPlus:SettlementLayers extends ObjectReference
{ Holds all workshop layers for a particular settlement }


WorkshopPlus:LayerManager Property LayerManager Auto Const Mandatory



WorkshopPlus:WorkshopLayer[] Property Layers Auto Hidden
WorkshopPlus:WorkshopLayer Property DefaultLayer Auto Hidden
WorkshopPlus:WorkshopLayer Property ActiveLayer Auto Hidden
Int Property iWorkshopID = -1 Auto Hidden


Bool Property bDeletedByManager = false Auto Hidden ; Flag in case we need to delete this for some reason and don't want to trigger an infinite loop

Function Disable(Bool abFade = false)
	Cleanup()
EndFunction

Function DisableNoWait(Bool abFade = false)
	Cleanup()
EndFunction

Function Cleanup()
	if( ! bDeletedByManager)
		LayerManager.LayerHolderDeleted(Self, abIntentionalDeletion = false)
	endif
	
	Layers = None
	ActiveLayer = None
	DefaultLayer = None
EndFunction