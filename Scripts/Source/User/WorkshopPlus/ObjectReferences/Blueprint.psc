; ---------------------------------------------
; WorkshopPlus:ObjectReferences:Blueprint.psc - by kinggath
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

Scriptname WorkshopPlus:ObjectReferences:Blueprint extends ObjectReference
{ Dynamically generated objects to hold information for rebuilding structures anywhere }

import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions

ReferenceAlias Property BlueprintCentralStorage Auto Const Mandatory
Int Property REQUIRES_COMPRESSION = -1 Auto Const

; Start at ridiculous numbers that will always be incorrect per the labels (ie. a Lowest anything should start high)
Float Property fLowestZ = 10000000.0 Auto Hidden ; We don't care about highest Z
Float Property fLowestX = 10000000.0 Auto Hidden 
Float Property fLowestY = 10000000.0 Auto Hidden 
Float Property fHighestX = -10000000.0 Auto Hidden 
Float Property fHighestY = -10000000.0 Auto Hidden

WorldObject[] Property ObjectBatch01 Auto Hidden
WorldObject[] Property ObjectBatch02 Auto Hidden
WorldObject[] Property ObjectBatch03 Auto Hidden
WorldObject[] Property ObjectBatch04 Auto Hidden
WorldObject[] Property ObjectBatch05 Auto Hidden
WorldObject[] Property ObjectBatch06 Auto Hidden
WorldObject[] Property ObjectBatch07 Auto Hidden
WorldObject[] Property ObjectBatch08 Auto Hidden
WorldObject[] Property ObjectBatch09 Auto Hidden
WorldObject[] Property ObjectBatch10 Auto Hidden
WorldObject[] Property ObjectBatch11 Auto Hidden
WorldObject[] Property ObjectBatch12 Auto Hidden
WorldObject[] Property ObjectBatch13 Auto Hidden
WorldObject[] Property ObjectBatch14 Auto Hidden
WorldObject[] Property ObjectBatch15 Auto Hidden
WorldObject[] Property ObjectBatch16 Auto Hidden

; Max 2048 items, batch count also represents max threads that can be operating on a blueprint
int Property iMaxBatches = 16 Auto Const


Int iNextBatchIndex = 0
Int Property NextBatchIndex
	Int Function Get()
		iTotalItemCount = REQUIRES_COMPRESSION ; As soon as a batch is requested, we'll invalidate our old data until Compress is run again
		
		iNextBatchIndex += 1
		
		if(iNextBatchIndex > iMaxBatches)
			iNextBatchIndex = REQUIRES_COMPRESSION ; will be reset by Compress
		endif
		
		return iNextBatchIndex
	EndFunction
EndProperty

Int Property iTotalItemCount = 0 Auto Hidden 
Int Property iExpectedItems = 0 Auto Hidden

Bool bCompressBlock = false
Int iBatchesAdded = 0


Event OnInit()
	ObjectBatch01 = new WorldObject[0]
	ObjectBatch02 = new WorldObject[0]
	ObjectBatch03 = new WorldObject[0]
	ObjectBatch04 = new WorldObject[0]
	ObjectBatch05 = new WorldObject[0]
	ObjectBatch06 = new WorldObject[0]
	ObjectBatch07 = new WorldObject[0]
	ObjectBatch08 = new WorldObject[0]
	ObjectBatch09 = new WorldObject[0]
	ObjectBatch10 = new WorldObject[0]
	ObjectBatch11 = new WorldObject[0]
	ObjectBatch12 = new WorldObject[0]
	ObjectBatch13 = new WorldObject[0]
	ObjectBatch14 = new WorldObject[0]
	ObjectBatch15 = new WorldObject[0]
	ObjectBatch16 = new WorldObject[0]
EndEvent


Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	if(akOldContainer == Game.GetPlayer() && akNewContainer == None)
		ObjectReference CentralStorageRef = BlueprintCentralStorage.GetRef()
		if(CentralStorageRef)
			; Move blueprint to storage
			CentralStorageRef.AddItem(Self)
		endif
	endif
EndEvent


Bool Function IsAtFinalBatch()
	return (iNextBatchIndex == iMaxBatches)
EndFunction

Int Function RequestBatchIndex()
	if( ! IsAtFinalBatch())
		return NextBatchIndex ; returning property version to trigger an increment
	else
		return -1 ; No available batches to thread to right now
	endif
EndFunction

Bool Function AddItems(WorldObject[] aObjectBatch, Int aiBatchIndex = -1, Bool abAutoCompress = true)
	if(bCompressBlock)
		ModTrace("[WS+] Attempted batch " + aiBatchIndex + ", blueprint was busy. Trying again shortly.")
		return false
	endif	
	
	if(aiBatchIndex == 1)
		int i = 0

		ObjectBatch01 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch01[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 2)
		int i = 0

		ObjectBatch02 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch02[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 3)
		int i = 0

		ObjectBatch03 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch03[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 4)
		int i = 0

		ObjectBatch04 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch04[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 5)
		int i = 0

		ObjectBatch05 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch05[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 6)
		int i = 0

		ObjectBatch06 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch06[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 7)
		int i = 0

		ObjectBatch07 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch07[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 8)
		int i = 0

		ObjectBatch08 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch08[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 9)
		int i = 0

		ObjectBatch09 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch09[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 10)
		int i = 0

		ObjectBatch10 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch10[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 11)
		int i = 0

		ObjectBatch11 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch11[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 12)
		int i = 0

		ObjectBatch12 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch12[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 13)
		int i = 0

		ObjectBatch13 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch13[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 14)
		int i = 0

		ObjectBatch14 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch14[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 15)
		int i = 0

		ObjectBatch15 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch15[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == 16)
		int i = 0

		ObjectBatch16 = new WorldObject[aObjectBatch.Length]		
		while(i < aObjectBatch.Length)
			ObjectBatch16[i] = aObjectBatch[i]
			
			i += 1
		endWhile
	elseif(aiBatchIndex == -1)
		; Fill in one at a time
		Bool bFoundRoom = true
		int i = 0
		while(i < aObjectBatch.Length && bFoundRoom)
			bFoundRoom = AddItemSingle(aObjectBatch[i])
			
			i += 1
		endWhile
	else
		return true ; Need this thread to stop making the request as it's sending invalid data
	endif
	
	iBatchesAdded += 1
	
	if(abAutoCompress && iBatchesAdded >= iNextBatchIndex || (iBatchesAdded == iMaxBatches && iNextBatchIndex == REQUIRES_COMPRESSION))
		; This was the last expected batch of items, go ahead and compress
		Compress()
	endif
	
	return true
EndFunction


Bool Function AddItemSingle(WorldObject aObjectBatch)
	if(ObjectBatch01.Length < 128)
		ObjectBatch01.Add(aObjectBatch)
	elseif(ObjectBatch02.Length < 128)
		ObjectBatch02.Add(aObjectBatch)
	elseif(ObjectBatch03.Length < 128)
		ObjectBatch03.Add(aObjectBatch)
	elseif(ObjectBatch04.Length < 128)
		ObjectBatch04.Add(aObjectBatch)
	elseif(ObjectBatch05.Length < 128)
		ObjectBatch05.Add(aObjectBatch)
	elseif(ObjectBatch06.Length < 128)
		ObjectBatch06.Add(aObjectBatch)
	elseif(ObjectBatch07.Length < 128)
		ObjectBatch07.Add(aObjectBatch)
	elseif(ObjectBatch08.Length < 128)
		ObjectBatch08.Add(aObjectBatch)
	elseif(ObjectBatch09.Length < 128)
		ObjectBatch09.Add(aObjectBatch)
	elseif(ObjectBatch10.Length < 128)
		ObjectBatch10.Add(aObjectBatch)
	elseif(ObjectBatch11.Length < 128)
		ObjectBatch11.Add(aObjectBatch)
	elseif(ObjectBatch12.Length < 128)
		ObjectBatch12.Add(aObjectBatch)
	elseif(ObjectBatch13.Length < 128)
		ObjectBatch13.Add(aObjectBatch)
	elseif(ObjectBatch14.Length < 128)
		ObjectBatch14.Add(aObjectBatch)
	elseif(ObjectBatch15.Length < 128)
		ObjectBatch15.Add(aObjectBatch)
	elseif(ObjectBatch16.Length < 128)
		ObjectBatch16.Add(aObjectBatch)
	else
		return false
	endif
	
	return true
EndFunction


Function Compress()
	if(bCompressBlock)
		return
	endif
	
	bCompressBlock = true
	
	ModTrace("[WS+] >>>>>>>>>>>>> Compressing")
	; Loop through all batches and start pushing items to the lowest possible batch storage
	Bool bMoreToCompress = false
	Int iLastFilled = 0
	Int iLastFilledIndex = 0
	
	if(ObjectBatch01.Length > 0)
		if(ObjectBatch01.Length < 128)
			bMoreToCompress = FillBatch_Private(ObjectBatch01, 1)
		else
			bMoreToCompress = true
		endif
		
		iLastFilled = 1
		iLastFilledIndex += ObjectBatch01.Length
		
		ModTrace("[WS+] >>>>>>>>>>>>> Batch 01: " + ObjectBatch01.Length)
	endif
	
	if(bMoreToCompress)
		if(ObjectBatch02.Length < 128)
			bMoreToCompress = FillBatch_Private(ObjectBatch02, 2)
		else
			bMoreToCompress = true
		endif
		
		iLastFilled = 2
		iLastFilledIndex += ObjectBatch02.Length
		
		ModTrace("[WS+] >>>>>>>>>>>>> Batch 02: " + ObjectBatch02.Length)
		if(bMoreToCompress)
			if(ObjectBatch03.Length < 128)
				bMoreToCompress = FillBatch_Private(ObjectBatch03, 3)
			else
				bMoreToCompress = true
			endif
			
			iLastFilled = 3
			iLastFilledIndex += ObjectBatch03.Length
			
			ModTrace("[WS+] >>>>>>>>>>>>> Batch 03: " + ObjectBatch03.Length)			
			if(bMoreToCompress)
				if(ObjectBatch04.Length < 128)
					bMoreToCompress = FillBatch_Private(ObjectBatch04, 4)
				else
					bMoreToCompress = true
				endif
							
				iLastFilled = 4
				iLastFilledIndex += ObjectBatch04.Length
						
				ModTrace("[WS+] >>>>>>>>>>>>> Batch 04: " + ObjectBatch04.Length)
				if(bMoreToCompress)
					if(ObjectBatch05.Length < 128)
						bMoreToCompress = FillBatch_Private(ObjectBatch05, 5)
					else
						bMoreToCompress = true
					endif
									
					iLastFilled = 5
					iLastFilledIndex += ObjectBatch05.Length
					
					ModTrace("[WS+] >>>>>>>>>>>>> Batch 05: " + ObjectBatch05.Length)
					if(bMoreToCompress)
						if(ObjectBatch06.Length < 128)
							bMoreToCompress = FillBatch_Private(ObjectBatch06, 6)
						else
							bMoreToCompress = true
						endif
											
						iLastFilled = 6
						iLastFilledIndex += ObjectBatch06.Length
							
						ModTrace("[WS+] >>>>>>>>>>>>> Batch 06: " + ObjectBatch06.Length)
						if(bMoreToCompress)
							if(ObjectBatch07.Length < 128)
								bMoreToCompress = FillBatch_Private(ObjectBatch07, 7)
							else
								bMoreToCompress = true
							endif
							
							iLastFilled = 7
							iLastFilledIndex += ObjectBatch07.Length
									
							ModTrace("[WS+] >>>>>>>>>>>>> Batch 07: " + ObjectBatch07.Length)
							if(bMoreToCompress)
								if(ObjectBatch08.Length < 128)
									bMoreToCompress = FillBatch_Private(ObjectBatch08, 8)
								else
									bMoreToCompress = true
								endif
														
								iLastFilled = 8
								iLastFilledIndex += ObjectBatch08.Length
								
								ModTrace("[WS+] >>>>>>>>>>>>> Batch 08: " + ObjectBatch08.Length)
								if(bMoreToCompress)
									if(ObjectBatch09.Length < 128)
										bMoreToCompress = FillBatch_Private(ObjectBatch09, 9)
									else
										bMoreToCompress = true
									endif
																
									iLastFilled = 9
									iLastFilledIndex += ObjectBatch09.Length
									
									ModTrace("[WS+] >>>>>>>>>>>>> Batch 09: " + ObjectBatch09.Length)
									if(bMoreToCompress)
										if(ObjectBatch10.Length < 128)
											bMoreToCompress = FillBatch_Private(ObjectBatch10, 10)
										else
											bMoreToCompress = true
										endif
										
										iLastFilled = 10
										iLastFilledIndex += ObjectBatch10.Length
											
										ModTrace("[WS+] >>>>>>>>>>>>> Batch 10: " + ObjectBatch10.Length)
										if(bMoreToCompress)
											if(ObjectBatch11.Length < 128)
												bMoreToCompress = FillBatch_Private(ObjectBatch11, 11)
											else
												bMoreToCompress = true
											endif
																				
											iLastFilled = 11
											iLastFilledIndex += ObjectBatch11.Length
											
											ModTrace("[WS+] >>>>>>>>>>>>> Batch 11: " + ObjectBatch11.Length)
											if(bMoreToCompress)
												if(ObjectBatch12.Length < 128)
													bMoreToCompress = FillBatch_Private(ObjectBatch12, 12)
												else
													bMoreToCompress = true
												endif
																						
												iLastFilled = 12
												iLastFilledIndex += ObjectBatch12.Length
												
												ModTrace("[WS+] >>>>>>>>>>>>> Batch 12: " + ObjectBatch12.Length)
												if(bMoreToCompress)
													if(ObjectBatch13.Length < 128)
														bMoreToCompress = FillBatch_Private(ObjectBatch13, 13)
													else
														bMoreToCompress = true
													endif
																								
													iLastFilled = 13
													iLastFilledIndex += ObjectBatch13.Length
													
													ModTrace("[WS+] >>>>>>>>>>>>> Batch 13: " + ObjectBatch13.Length)
													if(bMoreToCompress)
														if(ObjectBatch14.Length < 128)
															bMoreToCompress = FillBatch_Private(ObjectBatch14, 14)
														else
															bMoreToCompress = true
														endif
																										
														iLastFilled = 14
														iLastFilledIndex += ObjectBatch14.Length
														
														ModTrace("[WS+] >>>>>>>>>>>>> Batch 14: " + ObjectBatch14.Length)
														if(bMoreToCompress)
															if(ObjectBatch15.Length < 128)
																bMoreToCompress = FillBatch_Private(ObjectBatch15, 15)
															else
																bMoreToCompress = true
															endif
																												
															iLastFilled = 15
															iLastFilledIndex += ObjectBatch15.Length

															ModTrace("[WS+] >>>>>>>>>>>>> Batch 15: " + ObjectBatch15.Length)
															if(bMoreToCompress)
																iLastFilled = 16
																iLastFilledIndex += ObjectBatch16.Length
																
																ModTrace("[WS+] >>>>>>>>>>>>> Batch 16: " + ObjectBatch16.Length)
															endif
														endif
													endif
												endif
											endif
										endif
									endif
								endif
							endif
						endif
					endif
				endif
			endif
		endif
	endif
	
	; Finally reset iTotalItemCount and iNextBatchIndex to make it easier to operate on these externally
	iNextBatchIndex = iLastFilled
	iTotalItemCount = iLastFilledIndex
	
	bCompressBlock = false
	iBatchesAdded = iLastFilled 
EndFunction


Bool Function FillBatch_Private(WorldObject[] aObjectBatch, Int aiBatchIndex)
	int iIndexCounter = aObjectBatch.Length
	bool bCheckedAll = false
	bool bLeftOvers = false
	
	while(aObjectBatch.Length < 128 && ! bCheckedAll && ! bLeftOvers)
		if(aiBatchIndex <= 1)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch02)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 2)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch03)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 3)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch04)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 4)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch05)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 5)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch06)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 6)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch07)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 7)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch08)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 8)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch09)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 9)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch10)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 10)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch11)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 11)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch12)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 12)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch13)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 13)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch14)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 14)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch15)
		endif
		
		if( ! bLeftOvers && aiBatchIndex <= 15)
			bLeftOvers = MergeBatch_Private(aObjectBatch, ObjectBatch16)
		endif
		
		bCheckedAll = true
	endWhile
	
	return bLeftOvers
EndFunction


Bool Function MergeBatch_Private(WorldObject[] aObjectBatchA, WorldObject[] aObjectBatchB)
	while(aObjectBatchA.Length < 128 && aObjectBatchB.Length > 0)
		WorldObject thisObject = aObjectBatchB[0]
		
		aObjectBatchA.Add(thisObject)
		
		if(aObjectBatchB.Length == 1)
			aObjectBatchB.Clear()
		else
			aObjectBatchB.Remove(0)
		endif
	endWhile
	
	if(aObjectBatchB.Length > 0) ; Return true if we have remaining objects in ObjectBatchB, which says we filled ObjectBatchA
		return true
	else
		return false
	endif
EndFunction


Function FinalAnalysis()
	; TODO - Not only should we set up the low point, we should also pick a point near the center of either X or Y axis at the furthest point of the other axis, so that our blueprint handle doesn't get buried in the construction
	Float[] AnchorPointPosition = new Float[3]
	; Calculate simple center point that's at our lowest Z
	AnchorPointPosition[0] = (fLowestX + fHighestX) / 2
	AnchorPointPosition[1] = (fLowestY + fHighestY) / 2
	AnchorPointPosition[2] = fLowestZ
	
	; Use the anchor point to reframe all of the stored data to local coordinates
	ConvertToLocalCoordinates(ObjectBatch01, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch02, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch03, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch04, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch05, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch06, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch07, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch08, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch09, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch10, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch11, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch12, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch13, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch14, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch15, AnchorPointPosition)
	ConvertToLocalCoordinates(ObjectBatch16, AnchorPointPosition)
EndFunction


Function ConvertToLocalCoordinates(WorldObject[] aObjectBatch, Float[] afAnchorPoint)
	int i = 0
	while(i < aObjectBatch.Length)
		aObjectBatch[i].fPosX = aObjectBatch[i].fPosX - afAnchorPoint[0]
		aObjectBatch[i].fPosY = aObjectBatch[i].fPosY - afAnchorPoint[1]
		aObjectBatch[i].fPosZ = aObjectBatch[i].fPosZ - afAnchorPoint[2]
		
		i += 1
	endWhile
EndFunction