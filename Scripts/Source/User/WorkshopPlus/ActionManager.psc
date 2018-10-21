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


int iTimerID_DoubleCheckDuplicationHolders = 101 Const

String sThreadID_ObjectCopied = "WSPlus_ObjectCopied"

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
	Form Property Thread_CopyObject Auto Const Mandatory
	{ 1.0.2 - Setting up object copy thread to make cloning handled layers faster }
	Form Property UndoHelperForm Auto Const Mandatory
	{ 1.0.2 - Scripted object used to handle undo tasks on large groups of items }
	EffectShader Property ShaderFlashComplete Auto Const Mandatory
	{ 1.0.2 - Want to make sure player knows when cloning is complete }
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
	ActorValue Property LayerIDAV Auto Const
	{ 1.0.2 - Used to check the layer ID for bulk undo/redo operations }
	ActorValue Property RecordLayerIDAV Auto Const
	{ 1.0.2 - Used to remember the layer ID for bulk undo/redo operations }
EndGroup

Group Keywords
	Keyword Property WorkshopCanBePowered Auto Const
	Keyword Property PowerConnection Auto Const
	Keyword Property WorkshopItemKeyword Auto Const
	Keyword Property TemporarilyMoved Auto Const Mandatory
	Keyword Property WorkshopStackedItemParentKEYWORD Auto Const Mandatory
	Keyword Property LayerHolderLinkKeyword Auto Const Mandatory
	{ 1.0.2 - Same as LayerManager }
	Keyword Property UndoHelperKeyword Auto Const Mandatory
	{ 1.0.2 - Keyword to identify an object as an Undo Helper }
	Keyword Property UndoHelperLinkKeyword Auto Const Mandatory
	{ 1.0.2 - Keyword to attach items to undo helpers }
	Keyword Property LayerHandleKeyword Auto Const Mandatory
	{ 1.0.2 - Keyword to identify an object as a layer handle }
EndGroup

Group Aliases
	RefCollectionAlias Property ScrappableCollection Auto Const
	{ Scrappable objects found by our ObjectFinder quest so we can record the location for the sake of Undo records }
	RefCollectionAlias Property UndoHelperCollection Auto Const
	{ 1.0.2 - Holds references to UndoHelpers - when clearing undo history, we'll release these }
	ReferenceAlias Property SafeSpawnPoint Auto Const
	{ 1.0.2 - Needed for spawning undo helpers }
	RefCollectionAlias[] Property LayerItemDuplicationHolders Auto Const Mandatory
	{ 1.0.2 - We'll store layer items here temporarily during duplication so we don't overwhelm the quest with a ton of threaded calls to lock functions }
EndGroup


Group Messages
	Message Property UndoSupportReady Auto Const
	Message Property MustBeInWorkshopModeToUseHotkeys Auto Const Mandatory
	Message Property CloneLayerHandleOptions Auto Const Mandatory
	Message Property MustBeInSettlement Auto Const Mandatory
	Message Property UndoBusy Auto Const Mandatory
	Message Property UndoMessage Auto Const Mandatory
	Message Property NothingToUndoMessage Auto Const Mandatory
	Message Property RedoBusy Auto Const Mandatory
	Message Property RedoMessage Auto Const Mandatory
	Message Property NothingToRedoMessage Auto Const Mandatory
EndGroup


Group Settings
	GlobalVariable Property Setting_CloneLayerHandleMethod Auto Const Mandatory
	{ 1.0.2 - Gives the player control for how cloning layer handles works. 0 = Just create on current layer, 1 = Create new layer if possible, 2 = ask me each time }
EndGroup



; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool[] bRecordInitialPositionsBlock
Bool bRegisterWorkshopsBlock = false
Bool bAddingDuplicatesToLayersBlock = false
Bool bUndoRedoBlock = false ; 1.0.2 - Prevent spamming which will cause unexpected behavior

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

ObjectReference Property kGrabbedRef Auto Hidden ; 1.0.2 Converted to property as we're going to need access this from some other functions


; 1.0.2 - UndoHelpers will allow undoing large duplication actions
ObjectReference[] Property UndoHelperHolder Auto Hidden

; ---------------------------------------------
; Events
; --------------------------------------------- 

Event ObjectReference.OnWorkshopObjectGrabbed(ObjectReference akWorkshopRef, ObjectReference akReference)
	kGrabbedRef = akReference
EndEvent



Event ObjectReference.OnWorkshopObjectPlaced(ObjectReference akWorkshopRef, ObjectReference akReference)
	if(kGrabbedRef == akReference) ; 1.0.2 - Ensure we clear the grabbed ref once it's no longer grabbed
		kGrabbedRef = None
	endif
	
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	if(akReference.GetLinkedRef(WorkshopStackedItemParentKEYWORD) == None && akReference.GetLinkedRef(UndoHelperLinkKeyword) == None)
		CreateHistory(akReference, asWorkshop.GetWorkshopID(), Action_Create)
	endif
EndEvent

Event ObjectReference.OnWorkshopObjectMoved(ObjectReference akWorkshopRef, ObjectReference akReference)
	if(kGrabbedRef == akReference) ; 1.0.2 - Ensure we clear the grabbed ref once it's no longer grabbed
		kGrabbedRef = None
	endif
	
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	if(akReference.GetLinkedRef(UndoHelperLinkKeyword) != None)
		; Disconnect from the UndoHelperKeyword
		akReference.SetLinkedRef(None, UndoHelperLinkKeyword)
	endif
	
	; 1.0.2 - Recording movement of all stacked items is spotty at best and the goal going forward is to record batch actions with UndoHelpers
	if(akReference.GetLinkedRef(WorkshopStackedItemParentKEYWORD) == None)
		CreateHistory(akReference, asWorkshop.GetWorkshopID(), Action_Move)
	endif
EndEvent

Event ObjectReference.OnWorkshopObjectDestroyed(ObjectReference akWorkshopRef, ObjectReference akReference)
	if(kGrabbedRef == akReference) ; 1.0.2 - Ensure we clear the grabbed ref once it's no longer grabbed
		kGrabbedRef = None
	endif
	
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	if(akReference.GetLinkedRef(UndoHelperLinkKeyword) != None)
		; Disconnect from the UndoHelperKeyword
		akReference.SetLinkedRef(None, UndoHelperLinkKeyword)
	endif
	
	if( ! akReference.HasKeyword(LayerHandleKeyword))
		CreateHistory(akReference, asWorkshop.GetWorkshopID(), Action_Destroy)
	endif
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



; 1.0.2 - Monitoring for our threads so we can add duplicated items to the appropriate layers
Event WorkshopFramework:Library:ThreadRunner.OnThreadCompleted(WorkshopFramework:Library:ThreadRunner akThreadRunner, Var[] akargs)
	; akargs[0] = sCustomCallCallbackID, akargs[1] = iCallbackID, akargs[2] = ThreadRef
	String sCustomCallCallbackID = akargs[0] as String
	
	;ModTrace("Received event with callback ID: " + sCustomCallCallbackID)
	if(sCustomCallCallbackID == sThreadID_ObjectCopied)
		AddDuplicatesToLayers()
	endif
EndEvent


Event OnTimer(Int aiTimerID)
	if(aiTimerID == iTimerID_DoubleCheckDuplicationHolders)
		AddDuplicatesToLayers()
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
	ThreadManager.RegisterForCallbackThreads(Self)
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


Function HandleInstallModChanges()
	if(iInstalledVersion < 3) ; 1.0.2 - We're going to use the thread manager for handling batch duplication of items
		ThreadManager.RegisterForCallbackThreads(Self)
	endif
	
	Parent.HandleInstallModChanges()
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
	
	; 1.0.2 - Clear Undo Helpers
	UndoHelperHolder = new ObjectReference[0]
	
	int i = UndoHelperCollection.GetCount()
	
	while(i > 0)
		ObjectReference kUndoHelperRef = UndoHelperCollection.GetAt(0)
		
		if(kUndoHelperRef)
			ObjectReference[] kLinkedRefs = kUndoHelperRef.GetLinkedRefChildren(UndoHelperLinkKeyword)
			if(kLinkedRefs.Length > 0)
				int j = 0
				while(j < kLinkedRefs.Length)
					kLinkedRefs[i].SetLinkedRef(None, UndoHelperLinkKeyword)
					
					j += 1
				endWhile
			endif
			
			UndoHelperCollection.RemoveRef(kUndoHelperRef)
			kUndoHelperRef.Disable(false)
			kUndoHelperRef.Delete()
		endif
		
		i -= 1
	endWhile
EndFunction


Function CreateHistory(ObjectReference akObjectRef, Int aiWorkshopID, Int aiActionType)
	if( ! akObjectRef.HasKeyword(UndoHelperKeyword) && akObjectRef.GetLinkedRef(UndoHelperLinkKeyword) != None)
		return ; This object is part of an undo helper group - we want them handled by the undo helper
	endif
	
	if(akObjectRef.HasKeyword(LayerHandleKeyword))
		; TODO: Add support for undo/redo of LinkHandle movement
		return
	endif
	
	Form formBase = akObjectRef.GetBaseObject()
	
	if(SkipForms.Find(formBase) >= 0)
		; Things like workshops, we don't want to mess with
		return
	endif

	ArraySlot WhichSlot = new ArraySlot
	
	if( ! History01 || History01.Length < 128)
		; Not initialized yet
		ClearHistory()
	endif
	
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


Function PrepareUndoHelper(Int aiWorkshopID, Int aiLayerIndex)
	if( ! UndoHelperHolder || UndoHelperHolder.Length == 0)
		UndoHelperHolder = new ObjectReference[LayerManager.iMaxLayers + 1]
	endif
	
	ObjectReference kSpawnAt = SafeSpawnPoint.GetRef()
	
	if(kSpawnAt)
		ObjectReference kTemp = kSpawnAt.PlaceAtMe(UndoHelperForm, abDeleteWhenAble = false)
		UndoHelperCollection.AddRef(kTemp)
		UndoHelperHolder[aiLayerIndex] = kTemp
		
		CreateHistory(kTemp, aiWorkshopID, Action_Create)
	endif
EndFunction


Function Undo()
	WorkshopScript thisWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
	
	if( ! thisWorkshop)
		MustBeInSettlement.Show()
		
		return
	endif
	
	if(bUndoRedoBlock)
		UndoBusy.Show()
		
		return
	endif
	
	bUndoRedoBlock = true
	
	Int iWorkshopID = thisWorkshop.GetWorkshopID()
	
	;Debug.MessageBox("Pointer: " + Pointer.iArrayNum + ", " + Pointer.iIndex + " - LastUsed: " + LastUsed.iArrayNum + ", " + LastUsed.iIndex)
	ArraySlot HoldPointer = Pointer
	Pointer = FindHistorySlot(Pointer.iArrayNum, Pointer.iIndex, false, iWorkshopID)
	
	if(Pointer.iIndex >= 0)
		UndoMessage.Show()
		ApplyAction(GetAction(Pointer.iArrayNum, Pointer.iIndex), true)
		Pointer = IncrementSlot(Pointer.iArrayNum, Pointer.iIndex, false)
	else
		Pointer = HoldPointer
		
		NothingToUndoMessage.Show()
	endif
	
	bUndoRedoBlock = false
EndFunction


Function Redo()
	WorkshopScript thisWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
	
	if( ! thisWorkshop)
		MustBeInSettlement.Show()
		
		return
	endif
	
	if(bUndoRedoBlock)
		RedoBusy.Show()
		
		return
	endif
	
	bUndoRedoBlock = true
	
	Int iWorkshopID = thisWorkshop.GetWorkshopID()
	
	ArraySlot HoldPointer = Pointer
	Pointer = IncrementSlot(Pointer.iArrayNum, Pointer.iIndex, true)
	;Debug.MessageBox("Checking Pointer " + Pointer.iArrayNum + "." + Pointer.iIndex)
	Pointer = FindHistorySlot(Pointer.iArrayNum, Pointer.iIndex, true, iWorkshopID)
		
	if(Pointer.iIndex >= 0)
		;Debug.Notification("Redoing action " + Pointer.iArrayNum + "." + Pointer.iIndex)
		ApplyAction(GetAction(Pointer.iArrayNum, Pointer.iIndex))
		
		RedoMessage.Show()
	else
		Pointer = HoldPointer
		
		NothingToRedoMessage.Show()
	endif
	
	bUndoRedoBlock = false
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
	
	ModTrace("[WS Plus]" + sActionMessage + " on object " + aAction.ObjectRef)


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
	
	; 1.0.2 - Offering undo/redo of bulk operations
	if(aAction.ObjectRef.HasKeyword(UndoHelperKeyword))
		ObjectReference[] kLinkedRefs = aAction.ObjectRef.GetLinkedRefChildren(UndoHelperLinkKeyword)
		ModTrace("[WSPlus] Attempting undo helper action: " + aAction)
		if(kLinkedRefs.Length > 0)
			Int iTargetLayerID
			if(kLinkedRefs[0].IsDisabled())
				kLinkedRefs[0].Enable(false)
				iTargetLayerID = kLinkedRefs[0].GetValue(RecordLayerIDAV) as Int
				kLinkedRefs[0].Disable(false) 
			else
				iTargetLayerID = kLinkedRefs[0].GetValue(LayerIDAV) as Int
				
				if(iTargetLayerID <= 0)
					; Check RecordLayerIDAV
					iTargetLayerID = kLinkedRefs[0].GetValue(RecordLayerIDAV) as Int
				endif
			endif
						
			WorkshopPlus:WorkshopLayer thisLayer = LayerManager.GetLayerFromID(iTargetLayerID, thisWorkshop)
			
			int i = 0
			while(i < kLinkedRefs.Length)
				if(( ! bReverse && aAction.iAction == Action_Destroy) || (bReverse && aAction.iAction == Action_Create))
					kLinkedRefs[i].Disable(false)
					kLinkedRefs[i].SetLinkedRef(None, WorkshopItemKeyword)
					if(thisLayer)						
						LayerManager.RemoveItemFromLayer_Lock(kLinkedRefs[i], thisLayer)
					endif
				elseif(( ! bReverse && aAction.iAction == Action_Create) || (bReverse && aAction.iAction == Action_Destroy))
					kLinkedRefs[i].Enable(false)
					kLinkedRefs[i].SetLinkedRef(thisWorkshop, WorkshopItemKeyword)
					if(thisLayer)						
						LayerManager.AddItemToLayer_Lock(kLinkedRefs[i], thisLayer)
					endif
				elseif(aAction.iAction == Action_Move)
					; TODO - Handle undoing LayerHandle moves
				endif
				
				i += 1
			endWhile
		endif
	else
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
		MustBeInSettlement.Show()
		
		return
	endif
	
	if( ! SafeToClone(kGrabbedRef))
		Debug.Notification("[WS Plus] You can't clone that.")
	endif
	
	if(kGrabbedRef.HasKeyword(LayerHandleKeyword))
		; The actual object is going to be the invisible marker only - but it's linked on that same keyword to the actual handle object
		WorkshopPlus:ObjectReferences:LayerHandle thisLayerHandle = kGrabbedRef.GetLinkedRef(LayerHandleKeyword) as WorkshopPlus:ObjectReferences:LayerHandle
		ObjectReference[] HandledObjectRefs = thisLayerHandle.GetLinkedRefChildren(WorkshopStackedItemParentKEYWORD)
		
		if(HandledObjectRefs.Length == 0)
			; Tell player there is nothing to clone
		elseif(HandledObjectRefs.Length == 1)
			CloneWorkshopObject(HandledObjectRefs[0], thisWorkshop)
		else
			; Check settings to see if player wants the option to put this on a new layer
			float iHandleMethod = Setting_CloneLayerHandleMethod.GetValue()
			int iLayerIndex = 0
			WorkshopPlus:SettlementLayers thisSettlementLayers = LayerManager.GetCurrentSettlementLayers()
			
			if(iHandleMethod == 0)				
				if(thisSettlementLayers.ActiveLayer == thisSettlementLayers.DefaultLayer)
					iLayerIndex = 0
				else
					iLayerIndex = thisSettlementLayers.Layers.Find(thisSettlementLayers.ActiveLayer) + 1
				endif
			elseif(iHandleMethod == 1)
				if(thisLayerHandle.LayerRef == thisSettlementLayers.DefaultLayer)
					iLayerIndex = 0
				else
					iLayerIndex = thisSettlementLayers.Layers.Find(thisLayerHandle.LayerRef) + 1
				endif
			elseif(iHandleMethod == 2)
				LayerManager.CreateNewLayer()
				thisSettlementLayers = LayerManager.GetCurrentSettlementLayers() ; Update our copy
				iLayerIndex = thisSettlementLayers.Layers.Find(thisSettlementLayers.ActiveLayer) + 1
			else
				int iOption = CloneLayerHandleOptions.Show()
				
				if(iOption == 0)
					return
				elseif(iOption == 1)
					LayerManager.CreateNewLayer()
					thisSettlementLayers = LayerManager.GetCurrentSettlementLayers() ; Update our copy
					iLayerIndex = thisSettlementLayers.Layers.Find(thisSettlementLayers.ActiveLayer) + 1
				else
					iLayerIndex = iOption - 2
				endif
			endif
			
			if(iLayerIndex == -2) ; Canceled
				return
			else
				PrepareUndoHelper(thisWorkshop.GetWorkshopID(), iLayerIndex)
			
				thisLayerHandle.PlayBusyShader()
				
				int i = 0
				while(i < HandledObjectRefs.Length)
					; Copy all items
					CloneWorkshopObject_Threaded(HandledObjectRefs[i], thisWorkshop, iLayerIndex)
					
					i += 1
				endWhile
				
				thisLayerHandle.PlayReadyShader()
			endif
		endif
	else
		; 1.0.2 - Changing actual cloning action to separate function so we can call it in bulk
		CloneWorkshopObject(kGrabbedRef, thisWorkshop)
	endif
EndFunction



; 1.0.2 - Seperating this part out so we can use it for bulk cloning
Function CloneWorkshopObject_Threaded(ObjectReference akCloneMe, WorkshopScript akWorkshopRef, Int aiLayerIndex)
	WorkshopPlus:Threading:Thread_CopyObject kThreadRef = ThreadManager.CreateThread(Thread_CopyObject) as WorkshopPlus:Threading:Thread_CopyObject
			
	kThreadRef.bFadeIn = false 
	kThreadRef.bStartEnabled = true
	kThreadRef.kWorkshopRef = akWorkshopRef
	kThreadRef.kSpawnAt = akCloneMe
	kThreadRef.kCopyRef = akCloneMe
	kThreadRef.LayerCollection = LayerItemDuplicationHolders[aiLayerIndex]
	
	if(kThreadRef)
		ThreadManager.QueueThread(kThreadRef, sThreadID_ObjectCopied)
	endif
EndFunction


; 1.0.2 - Changing actual cloning action to separate function so we can call it in bulk
ObjectReference Function CloneWorkshopObject(ObjectReference akCopyRef, WorkshopScript akWorkshopRef = None, Bool abCreateHistory = true)
	if( ! akCopyRef)
		return None
	endif
	
	if( ! akWorkshopRef)
		akWorkshopRef = akCopyRef.GetLinkedRef(WorkshopItemKeyword) as WorkshopScript
		
		if( ! akWorkshopRef)
			return None
		endif
	endif
	
	ObjectReference kClonedRef = akCopyRef.PlaceAtMe(akCopyRef.GetBaseObject(), abInitiallyDisabled = true, abDeleteWhenAble = false)
	kClonedRef.SetScale(akCopyRef.GetScale())
	kClonedRef.Enable(false)
	kClonedRef.SetLinkedRef(akWorkshopRef, WorkshopItemKeyword)
	akWorkshopRef.OnWorkshopObjectPlaced(kClonedRef)			
	LayerManager.AddItemToLayer_Lock(kClonedRef)
	RecordLastPosition(kClonedRef)
	
	if(abCreateHistory)
		CreateHistory(kClonedRef, akWorkshopRef.GetWorkshopID(), Action_Create)
	endif
	
	return kClonedRef
EndFunction




Function AddDuplicatesToLayers()
	; Using a block function to avoid overloading the locking mechanism
	if(bAddingDuplicatesToLayersBlock)
		return
	endif
	
	bAddingDuplicatesToLayersBlock = true
	
	WorkshopPlus:SettlementLayers thisSettlementLayers = LayerManager.GetCurrentSettlementLayers()
	
	int i = 0
	while(i < LayerItemDuplicationHolders.Length)
		int iCount = LayerItemDuplicationHolders[i].GetCount()
		
		if(iCount > 0)
			if(thisSettlementLayers)
				WorkshopPlus:WorkshopLayer kLayerRef = thisSettlementLayers.DefaultLayer
				if(i > 0 && thisSettlementLayers.Layers.Length > (i - 1))
					kLayerRef = thisSettlementLayers.Layers[(i - 1)] ; Our Duplication refcollections are indexed so that 0 = Default layer, so we need to account for that
				endif
				
				int j = iCount
				while(j > 0)
					ObjectReference kTemp = LayerItemDuplicationHolders[i].GetAt(0)
					
					LayerManager.AddItemToLayer_Lock(kTemp, kLayerRef)
					
					RecordLastPosition(kTemp)
					if(UndoHelperHolder[i] != None)
						kTemp.SetLinkedRef(UndoHelperHolder[i], UndoHelperLinkKeyword)
					endif
					
					ShaderFlashComplete.Play(kTemp, 2.0)
					LayerItemDuplicationHolders[i].RemoveRef(kTemp)
					
					j -= 1
				endWhile
			endif
		endif
		
		i += 1
	endWhile
	
	bAddingDuplicatesToLayersBlock = false
	
	; Since we're using a block, there could be times when the function is running, and has already passed the added layer in the initial loops, this could result in straggler items getting left behind, so let's double check for items and if any found, schedule another check shortly in case follow-up events to trigger it never come.
	i = 0
	while(i < LayerItemDuplicationHolders.Length)
		if(LayerItemDuplicationHolders[i].GetCount() > 0)
			StartTimer(3.0, iTimerID_DoubleCheckDuplicationHolders)
			
			return
		endif
		
		i += 1
	endWhile
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