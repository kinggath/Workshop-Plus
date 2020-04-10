; ---------------------------------------------
; WorkshopPlus:Threading:Thread_CopyToBlueprint.psc - by kinggath
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

Scriptname WorkshopPlus:Threading:Thread_CopyToBlueprint extends WorkshopFramework:Library:ObjectRefs:Thread

import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:Library:DataStructures
; -
; Consts
; -


; - 
; Editor Properties
; -

WorkshopPlus:BlueprintManager Property BlueprintManager Auto Const Mandatory
WorkshopPlus:MainQuest Property WSPlusMain Auto Const Mandatory
EffectShader Property HighlightShader Auto Const
Form Property InvisibleWeaponsWorkbench Auto Const Mandatory
Form Property InvisibleFloorForm Auto Const Mandatory
Message Property SetBlueprintNameMessage Auto Const Mandatory

; -
; Properties
; -

WorkshopPlus:ObjectReferences:Blueprint Property kBlueprintRef Auto Hidden
ObjectReference[] Property kObjectsToCopy Auto Hidden
Int Property iBatchIndex = -1 Auto Hidden

Function RunCode()
	int iCount = kObjectsToCopy.Length
	WorldObject[] ObjectData = new WorldObject[0]
	Float fBatchLowestZ = 10000000.0
	Float fBatchLowestX = 10000000.0
	Float fBatchLowestY = 10000000.0
	Float fBatchHighestX = -10000000.0
	Float fBatchHighestY = -10000000.0
	int i = 0
	
	ModTrace("[WS+] Thread copying " + iCount + " items to blueprint on batch index " + iBatchIndex)
	while(i < iCount)
		ObjectReference kCopyRef = kObjectsToCopy[i]
		HighlightShader.Play(kCopyRef, 2.0)
		
		WorldObject thisObject = new WorldObject
		thisObject.ObjectForm = kCopyRef.GetBaseObject()
		thisObject.fPosX = kCopyRef.X
		thisObject.fPosY = kCopyRef.Y
		thisObject.fPosZ = kCopyRef.Z
		thisObject.fAngleX = kCopyRef.GetAngleX()
		thisObject.fAngleY = kCopyRef.GetAngleY()
		thisObject.fAngleZ = kCopyRef.GetAngleZ()
		thisObject.fScale = kCopyRef.GetScale()
		
		ObjectData.Add(thisObject)
		
		if(thisObject.fPosZ < fBatchLowestZ)
			fBatchLowestZ = thisObject.fPosZ
		endif
		
		if(thisObject.fPosX < fBatchLowestX)
			fBatchLowestX = thisObject.fPosX
		endif
		
		if(thisObject.fPosY < fBatchLowestY)
			fBatchLowestY = thisObject.fPosY
		endif
		
		if(thisObject.fPosX > fBatchHighestX)
			fBatchHighestX = thisObject.fPosX
		endif
		
		if(thisObject.fPosY > fBatchHighestY)
			fBatchHighestY = thisObject.fPosY
		endif
		
		i += 1
	endWhile
	
	if(fBatchLowestZ < kBlueprintRef.fLowestZ)
		kBlueprintRef.fLowestZ = fBatchLowestZ
	endif
	
	if(fBatchLowestX < kBlueprintRef.fLowestX)
		kBlueprintRef.fLowestX = fBatchLowestX
	endif
	
	if(fBatchLowestY < kBlueprintRef.fLowestY)
		kBlueprintRef.fLowestY = fBatchLowestY
	endif
	
	if(fBatchHighestX > kBlueprintRef.fHighestX)
		kBlueprintRef.fHighestX = fBatchHighestX
	endif
	
	if(fBatchHighestY > kBlueprintRef.fHighestY)
		kBlueprintRef.fHighestY = fBatchHighestY
	endif
	
	; Wait for return true - as it will return false if a compression is in progress
	while( ! kBlueprintRef.AddItems(ObjectData, iBatchIndex))
		Utility.Wait(Utility.RandomInt(1, 5) as Float)
	endWhile
EndFunction


Function ReleaseObjectReferences()
	int iTotalReceived = kBlueprintRef.iTotalItemCount
	int iTotalExpected = kBlueprintRef.iExpectedItems
	
	if(iTotalReceived >= iTotalExpected && Game.GetPlayer().GetItemCount(kBlueprintRef) == 0 && ! BlueprintManager.bBlueprintRenamePromptBlock)
		BlueprintManager.bBlueprintRenamePromptBlock = true
		
		kBlueprintRef.Compress()
		kBlueprintRef.FinalAnalysis()
		Game.GetPlayer().AddItem(kBlueprintRef)
		
		InputEnableLayer tempLayer = InputEnableLayer.Create()
		tempLayer.EnableMovement(false)
		Utility.Wait(0.1)
		
		int iConfirm = SetBlueprintNameMessage.Show()
		
		if(iConfirm == 0)
			ObjectReference PlayerRef = Game.GetPlayer()
			ObjectReference kTempFloor = PlayerRef.PlaceAtMe(InvisibleFloorForm)
			WSPlusMain.DisableFlight()
			
			ObjectReference kTemp = PlayerRef.PlaceAtMe(InvisibleWeaponsWorkbench)
			kTemp.Activate(PlayerRef as Actor)
			
			Utility.WaitMenuMode(3.0)
			kTempFloor.Disable(false)
			kTempFloor.Delete()
		endif
		
		tempLayer.Delete()
		
		BlueprintManager.HUDFrameworkManager.CompleteProgressBar(BlueprintManager, BlueprintManager.sProgressBar_CreateBlueprint)
		
		BlueprintManager.bBlueprintCreationBlock = false
		BlueprintManager.bBlueprintRenamePromptBlock = false
	endif
	
	kBlueprintRef = None

	Parent.ReleaseObjectReferences()
EndFunction