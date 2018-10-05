; ---------------------------------------------
; WorkshopPlus:ActionManager.psc - by kinggath
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

Scriptname WorkshopPlus:ActionManager extends WorkshopFramework:Library:SlaveQuest
{ Handles undo/redo }


import WorkshopPlus:DataStructures
import WorkshopFramework:Library:UtilityFunctions

; ---------------------------------------------
; Consts 
; ---------------------------------------------

Int Property Action_Create = 1 autoReadOnly
Int Property Action_Destroy = 2 autoReadOnly
Int Property Action_Move = 3 autoReadOnly


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopFramework:MainQuest Property WSFW_Main Auto Const Mandatory
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
	WorkshopPlus:LayerManager Property LayerManager Auto Const Mandatory
	Quest Property ObjectFinderQuest Auto Const Mandatory
	Keyword Property FindObjectsEventKeyword Auto Const Mandatory
EndGroup

Group Assets
	Form Property XMarker Auto Const
	FormList Property SkipForms Auto Const
	{ Formlist of objects we won't record history on }
	Form Property Thread_RecordPosition Auto Const
EndGroup

Group ActorValues
	ActorValue Property avLastPosX Auto Const
	ActorValue Property avLastPosY Auto Const
	ActorValue Property avLastPosZ Auto Const
	ActorValue Property avLastAngX Auto Const
	ActorValue Property avLastAngY Auto Const
	ActorValue Property avLastAngZ Auto Const
	ActorValue Property avLastScale Auto Const
	ActorValue Property PowerRequired Auto Const
EndGroup

Group Keywords
	Keyword Property WorkshopCanBePowered Auto Const
	Keyword Property PowerConnection Auto Const
	Keyword Property WorkshopItemKeyword Auto Const
	Keyword Property TemporarilyMoved Auto Const Mandatory
EndGroup

Group Aliases
	RefCollectionAlias Property ScrappableCollection Auto Const
	{ Scrappable objects found by our ObjectFinder quest so we can record the location for the sake of Undo records }
EndGroup


Group Messages
	Message Property UndoSupportReady Auto Const
	Message Property MustBeInWorkshopModeToUseHotkeys Auto Const Mandatory
EndGroup



; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool[] bRecordInitialPositionsBlock
Bool bRegisterWorkshopsBlock = false

BuildAction[] History01
BuildAction[] History02
BuildAction[] History03
BuildAction[] History04
BuildAction[] History05
BuildAction[] History06
BuildAction[] History07
BuildAction[] History08
BuildAction[] History09
BuildAction[] History10

Bool[] InitialPositionsRecorded

Int iMaxArrays = 10 ; Should always be equal to the number of history arrays

ArraySlot LastUsed ; Used to determine where to record next
ArraySlot Pointer ; Used to prevent Undo/Redo from going to far

ObjectReference kGrabbedRef

; ---------------------------------------------
; Events
; --------------------------------------------- 

Event ObjectReference.OnWorkshopObjectGrabbed(ObjectReference akWorkshopRef, ObjectReference akReference)
	kGrabbedRef = akReference
EndEvent


Event ObjectReference.OnWorkshopObjectPlaced(ObjectReference akWorkshopRef, ObjectReference akReference)
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	CreateHistory(akReference, asWorkshop.GetWorkshopID(), Action_Create)
EndEvent

Event ObjectReference.OnWorkshopObjectMoved(ObjectReference akWorkshopRef, ObjectReference akReference)
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	CreateHistory(akReference, asWorkshop.GetWorkshopID(), Action_Move)
EndEvent

Event ObjectReference.OnWorkshopObjectDestroyed(ObjectReference akWorkshopRef, ObjectReference akReference)
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	CreateHistory(akReference, asWorkshop.GetWorkshopID(), Action_Destroy)
EndEvent


Event WorkshopFramework:MainQuest.PlayerEnteredSettlement(WorkshopFramework:MainQuest akQuestRef, Var[] akArgs)
	WorkshopScript kThisWorkshopRef = akArgs[0] as WorkshopScript
	WorkshopScript kPreviousWorkshopRef = akArgs[1] as WorkshopScript
	Bool bThisWorkshopPreviouslyUnloaded = akArgs[2] as Bool
	
	RecordInitialPositions(kThisWorkshopRef)
	
	if(kThisWorkshopRef != kPreviousWorkshopRef || bThisWorkshopPreviouslyUnloaded)
		ModTrace("[WS Plus] Entered new settlement (or returned after a long time away), clearing Undo/Redo history.")
		
		ClearHistory()
	endif
EndEvent

Event WorkshopFramework:MainQuest.PlayerExitedSettlement(WorkshopFramework:MainQuest akQuestRef, Var[] akArgs)
	WorkshopScript kWorkshopRef = akArgs[0] as WorkshopScript
	Bool bStillLoaded = akArgs[1] as Bool
	
	if( ! bStillLoaded)
		ModTrace("[WS Plus] Left far enough from last settlement that it unloaded.")
	endif
EndEvent


; ---------------------------------------------
; Functions
; ---------------------------------------------

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; Init arrays
	ClearHistory() ; This will initialize all of our vars
	
	InitialPositionsRecorded = new Bool[128]
	bRecordInitialPositionsBlock = new Bool[128]
	
	; Register for events
	RegisterForCustomEvent(WSFW_Main, "PlayerEnteredSettlement")
	RegisterForCustomEvent(WSFW_Main, "PlayerExitedSettlement")
	
	RegisterForAllWorkshopEvents()
EndFunction	


Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	; New workshops might have been added, so we need to register for those events
	RegisterForAllWorkshopEvents()
	
	; Check if player started in a settlement
	WorkshopScript currentWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
	if(PlayerRef.IsWithinBuildableArea(currentWorkshop))
		RecordInitialPositions(currentWorkshop)
	endif
EndFunction





Function RegisterForAllWorkshopEvents()
	if(bRegisterWorkshopsBlock)
		return
	endif
	
	bRegisterWorkshopsBlock = true
	
	int i = 0
	WorkshopScript[] kWorkshops = ResourceManager.Workshops
	while(i < kWorkshops.Length)
		if(kWorkshops[i] && kWorkshops[i].IsBoundGameObjectAvailable())
			RegisterForRemoteEvent(kWorkshops[i], "OnWorkshopObjectGrabbed")
			RegisterForRemoteEvent(kWorkshops[i], "OnWorkshopObjectPlaced")
			RegisterForRemoteEvent(kWorkshops[i], "OnWorkshopObjectMoved")
			RegisterForRemoteEvent(kWorkshops[i], "OnWorkshopObjectDestroyed")
		endif
		
		i += 1
	endWhile
	
	bRegisterWorkshopsBlock = false
	
	;Debug.Notification("[Workshop Plus] Finished registering for workshop events.")
EndFunction


Function RecordInitialPositions(WorkshopScript akWorkshopRef)
	if( ! akWorkshopRef)
		return
	endif
	
	; Search for scrappable objects
	int iWorkshopID = akWorkshopRef.GetWorkshopID()
	
	if( ! InitialPositionsRecorded[iWorkshopID] || bRecordInitialPositionsBlock[iWorkshopID])
		return
	endif
	
	bRecordInitialPositionsBlock[iWorkshopID] = true
	
	if(FindObjectsEventKeyword.SendStoryEventAndWait(akLoc = akWorkshopRef.myLocation, akRef1 = akWorkshopRef))
		int i = 0
		while(i < ScrappableCollection.GetCount())
			RecordLastPosition(ScrappableCollection.GetAt(i))
			
			i += 1
		endWhile
		
		ObjectFinderQuest.Stop()
		
		InitialPositionsRecorded[iWorkshopID] = true
		UndoSupportReady.Show()
	else
		ModTrace("Failed to start ObjectFinder Quest.")
	endif
	
	bRecordInitialPositionsBlock[iWorkshopID] = false
EndFunction


Function RecordLastPosition(ObjectReference akObjectRef)
	; Use threading as querying for position/angle data can be slow when done at large scale
	WorkshopPlus:Threading:Thread_Record3dData kThreadRef = ThreadManager.CreateThread(Thread_RecordPosition) as WorkshopPlus:Threading:Thread_Record3dData
	
	if(kThreadRef)
		kThreadRef.kRecordFromRef = akObjectRef
		
		ThreadManager.QueueThread(kThreadRef)
	endif
EndFunction



Function ClearHistory()
	History01 = new BuildAction[128]
	History02 = new BuildAction[128]
	History03 = new BuildAction[128]
	History04 = new BuildAction[128]
	History05 = new BuildAction[128]
	History06 = new BuildAction[128]
	History07 = new BuildAction[128]
	History08 = new BuildAction[128]
	History09 = new BuildAction[128]
	History10 = new BuildAction[128]
	
	LastUsed = new ArraySlot
	Pointer = new ArraySlot
EndFunction


Function CreateHistory(ObjectReference akObjectRef, Int aiWorkshopID, Int aiActionType)
	Form formBase = akObjectRef.GetBaseObject()
	
	if(SkipForms.Find(formBase) >= 0)
		; Things like workshops, we don't want to mess with
		return
	endif

	ArraySlot WhichSlot = new ArraySlot
	
	if(History01[0].iAction <= 0)
		;Debug.MessageBox("Initializing LastUsed and Pointer")
		LastUsed.iArrayNum = 1
		LastUsed.iIndex = 0
		
		Pointer.iArrayNum = 1
		Pointer.iIndex = 0
		;Debug.MessageBox("LastUsed: " + LastUsed.iArrayNum + ", " + LastUsed.iIndex)
		WhichSlot = LastUsed
		;Debug.MessageBox("WhichSlot: " + WhichSlot.iArrayNum + ", " + WhichSlot.iIndex)
	else
		;Debug.MessageBox("LastUsed: " + LastUsed.iArrayNum + ", " + LastUsed.iIndex)
		
		WhichSlot = FindHistorySlot(LastUsed.iArrayNum, LastUsed.iIndex)
		
		;Debug.MessageBox("After WhichSlot - WhichSlot: " + WhichSlot.iArrayNum + ", " + WhichSlot.iIndex)
	endif
	
	
	BuildAction ThisAction = new BuildAction
	
	ThisAction.ObjectRef = akObjectRef
	ThisAction.BaseObject = formBase
	
	int iWaitCount = 0
	while(akObjectRef.HasKeyword(TemporarilyMoved) && iWaitCount < 10)
		; Give the acting script a moment to restore the original position
		Utility.Wait(0.01)
		iWaitCount += 1
	endWhile
	
	ThisAction.posX = akObjectRef.X
	ThisAction.posY = akObjectRef.Y
	ThisAction.posZ = akObjectRef.Z
	ThisAction.angX = akObjectRef.GetAngleX()
	ThisAction.angY = akObjectRef.GetAngleY()
	ThisAction.angZ = akObjectRef.GetAngleZ()
	ThisAction.fScale = akObjectRef.GetScale()
	
	
	if(aiActionType == Action_Move)	
		;Debug.MessageBox("Move Action - recording previous data")
		ThisAction.lastPosX = akObjectRef.GetValue(avLastPosX)
		ThisAction.lastPosY = akObjectRef.GetValue(avLastPosY)
		ThisAction.lastPosZ = akObjectRef.GetValue(avLastPosZ)
		ThisAction.lastAngX = akObjectRef.GetValue(avLastAngX)
		ThisAction.lastAngY = akObjectRef.GetValue(avLastAngY)
		ThisAction.lastAngZ = akObjectRef.GetValue(avLastAngZ)
		ThisAction.lastfScale = akObjectRef.GetValue(avLastScale)
	else
		ThisAction.lastPosX = ThisAction.posX
		ThisAction.lastPosY = ThisAction.posY
		ThisAction.lastPosZ = ThisAction.posZ
		ThisAction.lastAngX = ThisAction.angX
		ThisAction.lastAngY = ThisAction.angY
		ThisAction.lastAngZ = ThisAction.angZ
		ThisAction.lastfScale = ThisAction.fScale
	endif
	
	if(aiActionType == Action_Create || aiActionType == Action_Move)
		RecordLastPosition(akObjectRef)
	endif
	
	ThisAction.iAction = aiActionType
	ThisAction.iWorkshopID = aiWorkshopID
	
	if(WhichSlot.iArrayNum == 1)
		History01[WhichSlot.iIndex] = ThisAction
	elseif(WhichSlot.iArrayNum == 2)
		History02[WhichSlot.iIndex] = ThisAction
	elseif(WhichSlot.iArrayNum == 3)
		History03[WhichSlot.iIndex] = ThisAction
	elseif(WhichSlot.iArrayNum == 4)
		History04[WhichSlot.iIndex] = ThisAction
	elseif(WhichSlot.iArrayNum == 5)
		History05[WhichSlot.iIndex] = ThisAction
	elseif(WhichSlot.iArrayNum == 6)
		History06[WhichSlot.iIndex] = ThisAction
	elseif(WhichSlot.iArrayNum == 7)
		History07[WhichSlot.iIndex] = ThisAction
	elseif(WhichSlot.iArrayNum == 8)
		History08[WhichSlot.iIndex] = ThisAction
	elseif(WhichSlot.iArrayNum == 9)
		History09[WhichSlot.iIndex] = ThisAction
	elseif(WhichSlot.iArrayNum == 10)
		History10[WhichSlot.iIndex] = ThisAction
	else
		Debug.Trace("Failed to store history. Slot: " + WhichSlot + ", Action: " + ThisAction)
	endif
	
	LastUsed = WhichSlot
	Pointer = LastUsed
EndFunction


ArraySlot Function FindHistorySlot(Int aiArrayNum, Int aiIndex, Bool bNext = true, Int aiWorkshopID = -1)
	ArraySlot UseSlot = new ArraySlot
	
	if(aiWorkshopID >= 0)
		if(LastUsed.iIndex < 0)
			return new ArraySlot
		endif
		
		; Loop through actions searching for first one in that direction with a matching workshopID
		int i = 0
		
		while(UseSlot.iIndex < 0)			
			BuildAction CheckAction = GetAction(aiArrayNum, aiIndex)
			if(CheckAction.iAction <= 0)
				; We haven't advanced this far
				return new ArraySlot
			endif
			
			if(CheckAction.iWorkshopID == aiWorkshopID)
				UseSlot.iArrayNum = aiArrayNum
				UseSlot.iIndex = aiIndex
			else
				; Increment StartSlot
				ArraySlot StartSlot = IncrementSlot(aiArrayNum, aiIndex, bNext)
				
				if(StartSlot.iArrayNum == LastUsed.iArrayNum && StartSlot.iIndex == LastUsed.iIndex)
					; Already back at current history slot
					return new ArraySlot
				else
					aiArrayNum = StartSlot.iArrayNum
					aiIndex = StartSlot.iIndex
				endif				
			endif
		endWhile
	else
		;Debug.MessageBox("Incrementing slot: " + aiArrayNum + ", " + aiIndex)
		UseSlot = IncrementSlot(aiArrayNum, aiIndex, bNext)
	endif
	
	return UseSlot
EndFunction


ArraySlot Function IncrementSlot(Int aiArrayNum, Int aiIndex, Bool bNext = true)
	ArraySlot UseSlot = new ArraySlot
	
	if(aiIndex == -1)
		UseSlot.iArrayNum = 1
		UseSlot.iIndex = 0
		return UseSlot
	endif
			
	if(bNext)
		if(aiIndex < 127)
			UseSlot.iArrayNum = aiArrayNum
			UseSlot.iIndex = aiIndex + 1
		else
			if(aiArrayNum >= iMaxArrays)
				UseSlot.iArrayNum = 1
				UseSlot.iIndex = 0
			else
				UseSlot.iArrayNum = aiArrayNum + 1
				UseSlot.iIndex = 0
			endif
		endif
	else
		if(aiIndex > 0)
			UseSlot.iArrayNum = aiArrayNum
			UseSlot.iIndex = aiIndex - 1
		else
			if(aiArrayNum <= 0)
				UseSlot.iArrayNum = iMaxArrays
				UseSlot.iIndex = 127
			else
				UseSlot.iArrayNum = aiArrayNum - 1
				UseSlot.iIndex = 127
			endif
		endif
	endif
	
	;Debug.MessageBox("Returning " + UseSlot.iArrayNum + ", " + UseSlot.iIndex)
	
	return UseSlot
EndFunction


BuildAction Function GetAction(Int aiArrayNum, Int aiIndex)
	;Debug.MessageBox("Getting Action in slot " + aiArrayNum + ", " + aiIndex)
	if(aiArrayNum == 1)
		return History01[aiIndex]
	elseif(aiArrayNum == 2)
		return History02[aiIndex]
	elseif(aiArrayNum == 3)
		return History03[aiIndex]
	elseif(aiArrayNum == 4)
		return History04[aiIndex]
	elseif(aiArrayNum == 5)
		return History05[aiIndex]
	elseif(aiArrayNum == 6)
		return History06[aiIndex]
	elseif(aiArrayNum == 7)
		return History07[aiIndex]
	elseif(aiArrayNum == 8)
		return History08[aiIndex]
	elseif(aiArrayNum == 9)
		return History09[aiIndex]
	elseif(aiArrayNum == 10)
		return History10[aiIndex]
	endif
EndFunction


Function Undo()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		Debug.MessageBox("Player is not in workshop mode.")
		return
	endif
	
	WorkshopScript thisWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
	
	if( ! thisWorkshop)
		Debug.MessageBox("Could not find settlement.")
		return
	endif
	
	Int iWorkshopID = thisWorkshop.GetWorkshopID()
	
	;Debug.MessageBox("Pointer: " + Pointer.iArrayNum + ", " + Pointer.iIndex + " - LastUsed: " + LastUsed.iArrayNum + ", " + LastUsed.iIndex)
	ArraySlot HoldPointer = Pointer
	Pointer = FindHistorySlot(Pointer.iArrayNum, Pointer.iIndex, false, iWorkshopID)
	
	if(Pointer.iIndex >= 0)
		Debug.Notification("Undoing action " + Pointer.iArrayNum + "." + Pointer.iIndex)
		ApplyAction(GetAction(Pointer.iArrayNum, Pointer.iIndex), true)
		Pointer = IncrementSlot(Pointer.iArrayNum, Pointer.iIndex, false)
		
		return
	else
		Pointer = HoldPointer
	endif
	
	Debug.MessageBox("Nothing to Undo.")
EndFunction


Function Redo()
	WorkshopScript thisWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
	
	if( ! thisWorkshop)
		Debug.MessageBox("Could not find settlement.")
		return
	endif
	
	Int iWorkshopID = thisWorkshop.GetWorkshopID()
	
	ArraySlot HoldPointer = Pointer
	Pointer = IncrementSlot(Pointer.iArrayNum, Pointer.iIndex, true)
	;Debug.MessageBox("Checking Pointer " + Pointer.iArrayNum + "." + Pointer.iIndex)
	Pointer = FindHistorySlot(Pointer.iArrayNum, Pointer.iIndex, true, iWorkshopID)
		
	if(Pointer.iIndex >= 0)
		Debug.Notification("Redoing action " + Pointer.iArrayNum + "." + Pointer.iIndex)
		ApplyAction(GetAction(Pointer.iArrayNum, Pointer.iIndex))
		
		return
	else
		Pointer = HoldPointer
	endif
	
	Debug.MessageBox("Nothing to Redo.")
EndFunction


Function ApplyAction(BuildAction aAction, Bool bReverse = false)
	WorkshopScript thisWorkshop = WorkshopParent.GetWorkshop(aAction.iWorkshopID)
	
	String sActionMessage = " Action Manager - "
	if(bReverse)
		sActionMessage += "Reversing "
	else
		sActionMessage += "Applying "
	endif
	
	if(aAction.iAction == Action_Create)
		sActionMessage += "Create action."
	elseif(aAction.iAction == Action_Move)
		sActionMessage += "Move action."
	elseif(aAction.iAction == Action_Destroy)
		sActionMessage += "Destroy action."
	endif
	
	ModTrace("[WS Plus]" + sActionMessage)


		; Before starting, clear power
	Float fPowerRequired = 0.0
	Bool bCanBePowered = false
	Bool bHasPowerConnection = false
	if(aAction.ObjectRef && ! aAction.ObjectRef.IsDeleted() && aAction.ObjectRef.HasKeyword(WorkshopCanBePowered))
		bCanBePowered = true
		fPowerRequired = aAction.ObjectRef.GetValue(PowerRequired)
		aAction.ObjectRef.SetValue(PowerRequired, 0)
		aAction.ObjectRef.RemoveKeyword(WorkshopCanBePowered)
		
		if(aAction.ObjectRef.HasKeyword(PowerConnection))
			bHasPowerConnection = true
			aAction.ObjectRef.RemoveKeyword(PowerConnection)
		endif
	endif
	

	if(( ! bReverse && aAction.iAction == Action_Destroy) || (bReverse && aAction.iAction == Action_Create))
		; Scrap this ref
		int iLayerID = aAction.ObjectRef.GetValue(LayerManager.LayerID) as Int
		
		WorkshopParent.RemoveObjectPUBLIC(aAction.ObjectRef, thisWorkshop)
		aAction.ObjectRef.Disable()		
		aAction.ObjectRef.SetLinkedRef(None, WorkshopItemKeyword)
		
		WorkshopPlus:WorkshopLayer thisLayer = LayerManager.GetLayerFromID(iLayerID, thisWorkshop)
		if(thisLayer)
			LayerManager.RemoveItemFromLayer_Lock(aAction.ObjectRef, thisLayer)
		endif
	elseif(( ! bReverse && aAction.iAction == Action_Create) || (bReverse && aAction.iAction == Action_Destroy) || aAction.iAction == Action_Move)
		Float[] f3dData = new Float[7]
		int iLayerID = -1
		
		if(bReverse && aAction.iAction == Action_Move)
			;Debug.MessageBox("Using previous data - " + aAction.lastPosZ + " rather than " + aAction.posZ)
			; Grab previous coordinates from object AVs
			f3dData[0] = aAction.lastPosX
			f3dData[1] = aAction.lastPosY
			f3dData[2] = aAction.lastPosZ
			f3dData[3] = aAction.lastAngX
			f3dData[4] = aAction.lastAngY
			f3dData[5] = aAction.lastAngZ
			f3dData[6] = aAction.lastfScale
		else
			f3dData[0] = aAction.posX
			f3dData[1] = aAction.posY
			f3dData[2] = aAction.posZ
			f3dData[3] = aAction.angX
			f3dData[4] = aAction.angY
			f3dData[5] = aAction.angZ
			f3dData[6] = aAction.fScale
		endif
	
		if(aAction.ObjectRef && ! aAction.ObjectRef.IsDisabled())
			;Debug.MessageBox("Not disabled - Current position: " + aAction.ObjectRef.GetPositionX() + ", " + aAction.ObjectRef.Y + ", " + aAction.ObjectRef.Z + "; Moving to " + f3dData[0] + ", " + f3dData[1] + ", " + f3dData[2])
			; Restore 3d settings
			if(aAction.ObjectRef.IsCreated())
				aAction.ObjectRef.SetPosition(f3dData[0], f3dData[1], f3dData[2])
				aAction.ObjectRef.SetAngle(f3dData[3], f3dData[4], f3dData[5])
			else
				;Debug.MessageBox("Can't move this item, replacing it")
				; Non-created items can't be moved, so instead we'll replace them
				ObjectReference kTempMarker = aAction.ObjectRef.PlaceAtMe(XMarker)
				ObjectReference kReplacement
				kTempMarker.SetPosition(f3dData[0], f3dData[1], f3dData[2])
				kTempMarker.SetAngle(f3dData[3], f3dData[4], f3dData[5])
				
				kReplacement = kTempMarker.PlaceAtMe(aAction.BaseObject, 1, false, false, false)
				RecordLastPosition(kReplacement)
				
				; Grab layer ID of previous object before finishing swap
				aAction.ObjectRef.GetValue(LayerManager.LayerID)
				
				aAction.ObjectRef.Disable()
				aAction.ObjectRef = kReplacement
				aAction.ObjectRef.SetLinkedRef(thisWorkshop, WorkshopItemKeyword)
				
				thisWorkshop.OnWorkshopObjectPlaced(aAction.ObjectRef)
				
				kTempMarker.DisableNoWait()
				kTempMarker.Delete()
				kTempMarker = None
			endif
			
			aAction.ObjectRef.SetScale(f3dData[6])
				
			; Toggle display to fix fuzziness
			aAction.ObjectRef.Disable(false)
			aAction.ObjectRef.Enable(false)
		else
			;Debug.MessageBox("Disabled - creating new.")	
			Bool bNewCopy = false
			if( ! aAction.ObjectRef || aAction.ObjectRef.IsDeleted())
				; Create new copy
				bNewCopy = true
				aAction.ObjectRef = thisWorkshop.PlaceAtMe(aAction.BaseObject, 1, false, true, false)
			endif
			
			ModTrace("[WATCHING FOR] Repositioning " + aAction.ObjectRef + ", Using position data: " + f3dData)
			
			aAction.ObjectRef.SetLinkedRef(thisWorkshop, WorkshopItemKeyword)
			aAction.ObjectRef.SetPosition(f3dData[0], f3dData[1], f3dData[2])
			
			if(aAction.ObjectRef as Actor)
				; Actors must be enabled before setting angle or scale
				aAction.ObjectRef.Enable(false)
			endif
			
			aAction.ObjectRef.SetAngle(f3dData[3], f3dData[4], f3dData[5])
			aAction.ObjectRef.SetScale(f3dData[6])
			aAction.ObjectRef.Enable(false)
			
			if( ! bNewCopy) ; This object should still have its previous layer id
				iLayerID = aAction.ObjectRef.GetValue(LayerManager.LayerID) as Int
			endif
			
			thisWorkshop.OnWorkshopObjectPlaced(aAction.ObjectRef)
		endif
		
		if(aAction.iAction != Action_Move)
			; Update object on layer
			WorkshopPlus:WorkshopLayer kLayerRef = None
			if(iLayerID >= 1)
				kLayerRef = LayerManager.GetLayerFromID(iLayerID, thisWorkshop)
			endif
			
			if(kLayerRef)
				LayerManager.AddItemToLayer_Lock(aAction.ObjectRef, kLayerRef)	
			else
				LayerManager.AddItemToLayer_Lock(aAction.ObjectRef)				
			endif
		endif
	endif
	
	if(aAction.ObjectRef && ! aAction.ObjectRef.IsDeleted() && bCanBePowered)
		; Restore power as best we can - will require F4SE to fully restore
		aAction.ObjectRef.SetValue(PowerRequired, fPowerRequired)
		aAction.ObjectRef.AddKeyword(WorkshopCanBePowered)
		
		if(bHasPowerConnection)
			aAction.ObjectRef.AddKeyword(PowerConnection)
		endif
		
		if( ! aAction.ObjectRef.IsDisabled())
			aAction.ObjectRef.Disable(false)
			aAction.ObjectRef.Enable(false)
			aAction.ObjectRef.OnPowerOn(aAction.ObjectRef)
		endif
	endif
EndFunction


Bool Function SafeToClone(ObjectReference akObjectRef)
	Form formBase = akObjectRef.GetBaseObject()
	if(SkipForms.Find(formBase) >= 0)
		return false
	endif
	
	if(akObjectRef as WorkshopScript)
		return false
	endif
	
	if(akObjectRef as Actor && ! ( akObjectRef as WorkshopObjectActorScript))
		return false
	endif
	
	return true
EndFunction


Function CloneGrabbed()
	if( ! kGrabbedRef)
		return
	endif
	
	WorkshopScript thisWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
	
	if( ! thisWorkshop)		
		Debug.MessageBox("Unable to clone object, no workshop found.")
		return
	endif
	
	if( ! SafeToClone(kGrabbedRef))
		Debug.Notification("[WS Plus] You can't clone that.")
	endif
	
	ObjectReference kClonedRef = kGrabbedRef.PlaceAtMe(kGrabbedRef.GetBaseObject(), abDeleteWhenAble = false)
	kClonedRef.SetScale(kGrabbedRef.GetScale())
	
	kClonedRef.SetLinkedRef(thisWorkshop, WorkshopItemKeyword)
	thisWorkshop.OnWorkshopObjectPlaced(kClonedRef)	
	
	LayerManager.AddItemToLayer_Lock(kClonedRef)
	
	CreateHistory(kClonedRef, thisWorkshop.GetWorkshopID(), Action_Create)
EndFunction



; ---------------------------------------------
; MCM Functions - Easiest to avoid parameters for use with MCM's CallFunction, also we only want these hotkeys to work in WS mode
; ---------------------------------------------

Function Hotkey_Redo()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	Redo()
EndFunction


Function Hotkey_Undo()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	Undo()
EndFunction


Function Hotkey_CloneGrabbed()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	CloneGrabbed()
EndFunction