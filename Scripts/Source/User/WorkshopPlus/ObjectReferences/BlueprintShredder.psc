; ---------------------------------------------
; WorkshopPlus:ObjectReferences:BlueprintShredder.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below).
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDITS
; N/A
; ---------------------------------------------

Scriptname WorkshopPlus:ObjectReferences:BlueprintShredder extends ObjectReference

Group Keywords
	Keyword Property BlueprintKeyword Auto Const Mandatory
EndGroup

Group Messages
	Message Property ConfirmShred Auto Const Mandatory
EndGroup


Event OnInit()
	AddInventoryEventFilter(BlueprintKeyword)
EndEvent


Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	int iConfirm = ConfirmShred.Show()
	
	if(iConfirm == 1)
		RemoveItem(akBaseItem, aiItemCount)
	else
		RemoveItem(akBaseItem, aiItemCount, Game.GetPlayer()) ; Return to player
	endif
EndEvent