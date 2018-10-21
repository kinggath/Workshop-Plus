; ---------------------------------------------
; WorkshopPlus:Threading:Thread_CopyObject.psc - by kinggath
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

Scriptname WorkshopPlus:Threading:Thread_CopyObject extends WorkshopFramework:ObjectRefs:Thread_PlaceObject

; -
; Consts
; -


; - 
; Editor Properties
; -

EffectShader Property HighlightShader Auto Const

; -
; Properties
; -

ObjectReference Property kCopyRef Auto Hidden
RefCollectionAlias Property LayerCollection Auto Hidden

Function RunCode()
	; Gather data for sending to the parent Thread_PlaceObject version
	Self.SpawnMe = kCopyRef.GetBaseObject()
	Self.fPosX = kCopyRef.X
	Self.fPosY = kCopyRef.Y
	Self.fPosZ = kCopyRef.Z
	Self.fAngleX = kCopyRef.GetAngleX()
	Self.fAngleY = kCopyRef.GetAngleY()
	Self.fAngleZ = kCopyRef.GetAngleZ()
	Self.fScale = kCopyRef.GetScale()
	
	; Call parent version	
	Parent.RunCode()
	if(kResult != None)
		ObjectReference kTemp = kResult
		
		if(HighlightShader)
			HighlightShader.Play(kTemp, 2.0)
		endif
		
		LayerCollection.AddRef(kTemp)
	endif
	
	SelfDestruct()
EndFunction


Function ReleaseObjectReferences()
	kCopyRef = None

	Parent.ReleaseObjectReferences()
EndFunction