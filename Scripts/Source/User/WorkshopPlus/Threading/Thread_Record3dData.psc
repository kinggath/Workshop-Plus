; ---------------------------------------------
; WorkshopPlus:Threading:Thread_Record3dData.psc - by kinggath
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

Scriptname WorkshopPlus:Threading:Thread_Record3dData extends WorkshopFramework:Library:ObjectRefs:Thread

; -
; Consts
; -


; - 
; Editor Properties
; -

Group ActorValues
	ActorValue Property avLastPosX Auto Const
	ActorValue Property avLastPosY Auto Const
	ActorValue Property avLastPosZ Auto Const
	ActorValue Property avLastAngX Auto Const
	ActorValue Property avLastAngY Auto Const
	ActorValue Property avLastAngZ Auto Const
	ActorValue Property avLastScale Auto Const
EndGroup

; -
; Properties
; -

ObjectReference Property kRecordFromRef Auto Hidden

; -
; Events
; -

; - 
; Functions 
; -
	
Function ReleaseObjectReferences()
	kRecordFromRef = None
EndFunction


Function RunCode()
	if(kRecordFromRef.GetValue(avLastPosX) == 0)
		kRecordFromRef.SetValue(avLastPosX, kRecordFromRef.X)
		kRecordFromRef.SetValue(avLastPosY, kRecordFromRef.Y)
		kRecordFromRef.SetValue(avLastPosZ, kRecordFromRef.Z)
		kRecordFromRef.SetValue(avLastAngX, kRecordFromRef.GetAngleX())
		kRecordFromRef.SetValue(avLastAngY, kRecordFromRef.GetAngleY())
		kRecordFromRef.SetValue(avLastAngZ, kRecordFromRef.GetAngleZ())
		kRecordFromRef.SetValue(avLastScale, kRecordFromRef.GetScale())
	endif
EndFunction