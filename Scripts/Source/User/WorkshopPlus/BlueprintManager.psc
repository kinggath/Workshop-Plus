; ---------------------------------------------
; WorkshopPlus:BlueprintManager.psc - by kinggath
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

Scriptname WorkshopPlus:BlueprintManager extends WorkshopFramework:Library:SlaveQuest
{ Handles layer blueprints }


import WorkshopPlus:DataStructures
import WorkshopFramework:Library:DataStructures
import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:WorkshopFunctions

; ---------------------------------------------
; Consts 
; ---------------------------------------------


; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopPlus:LayerManager Property LayerManager Auto Const Mandatory
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
	WorkshopFramework:HUDFrameworkManager Property HUDFrameworkManager Auto Const Mandatory
	WorkshopFramework:PlaceObjectManager Property PlaceObjectManager Auto Const Mandatory	
EndGroup


Group Aliases
	ReferenceAlias Property SafeSpawnPoint Auto Const Mandatory
	ReferenceAlias Property LastCreatedBlueprint Auto Const Mandatory
	ReferenceAlias Property BlueprintCentralStorage Auto Const Mandatory
	ReferenceAlias Property SelectedBlueprint Auto Const Mandatory
	ReferenceAlias Property BlueprintBuildVendor Auto Const Mandatory
	ReferenceAlias Property BlueprintBuildVendorContainer Auto Const Mandatory
	RefCollectionAlias Property BlueprintObjects Auto Const Mandatory
	{ 1.0.4 - If we fail to persist these, the formlist doesn't correctly hold them }
EndGroup

Group Assets
	Form[] Property BlankBlueprintForm Auto Const Mandatory
	Form Property PlaceableBlueprintControllerForm Auto Const Mandatory
EndGroup


Group Formlists
	Formlist Property BlueprintReferencesList Auto Const Mandatory
EndGroup

Group Globals
	GlobalVariable Property gCurrentWorkshop Auto Const Mandatory
	GlobalVariable Property CurrentActiveLayerIndex Auto Const Mandatory
	GlobalVariable Property CurrentLayerCount Auto Const Mandatory	  
	GlobalVariable Property Setting_BlueprintBuildDelay Auto Const Mandatory
	GlobalVariable Property Settings_ShowHotkeyWarnings Auto Const Mandatory
	{ 1.0.4 }
EndGroup

Group Keywords
	Keyword Property LayerItemLinkChainKeyword Auto Const Mandatory
	Keyword Property WorkshopStackedItemParentKEYWORD Auto Const Mandatory
	Keyword Property BlueprintControllerKeyword Auto Const Mandatory
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property BlueprintObjectKeyword Auto Const Mandatory
	{ 1.0.4 - Tagging blueprint objects so we can pull them from containers easily }
EndGroup

Group Messages
	Message Property LayerMissing_UnableToCreateBlueprint Auto Const Mandatory
	Message Property LayerEmpty_UnableToCreateBlueprint Auto Const Mandatory
	Message Property Confirm_BlueprintReuseNameSlot Auto Const Mandatory
	Message Property NoBlueprintsFound Auto Const Mandatory
	Message Property NoBlueprintSelected Auto Const Mandatory
	Message Property BlueprintControlMenu Auto Const Mandatory
	Message[] Property BlueprintStorageExplanationMessages Auto Const Mandatory
	Message Property BlueprintBuildInProgress Auto Const Mandatory
	Message Property BlueprintCreationInProgress Auto Const Mandatory
	Message Property ProblemAccessingBlueprintStorage Auto Const Mandatory
	Message Property ExistingLayerSelectMenu Auto Const Mandatory
	Message Property LayerSelectMenu Auto Const Mandatory
	Message Property BlueprintControllerNotFound Auto Const Mandatory
	Message Property BlueprintConstructionComplete Auto Const Mandatory
	Message Property MustBeInWorkshopModeToUseHotkeys Auto Const Mandatory
EndGroup


Group Threading
	Form Property Thread_CopyToBlueprint Auto Const Mandatory
EndGroup


; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool bFirstUseOfBlueprintSlots = true
Int Property iNextBlueprintNameIndex = -1 Auto Hidden 
Int Property NextBlueprintNameIndex
	Int Function Get()
		iNextBlueprintNameIndex += 1
		
		if(iNextBlueprintNameIndex > BlankBlueprintForm.Length - 1)
			iNextBlueprintNameIndex = 0
			bFirstUseOfBlueprintSlots = false
		endif
		
		return iNextBlueprintNameIndex
	EndFunction
EndProperty

WorkshopPlus:ObjectReferences:BlueprintController Property ActiveBlueprintControllerRef Auto Hidden
WorkshopPlus:WorkshopLayer Property BuildingBlueprintOnLayerRef Auto Hidden

Bool Property bBlueprintCreationBlock = false Auto Hidden
Bool Property bBlueprintBuildBlock = false Auto Hidden
Bool Property bBlueprintRenamePromptBlock = false Auto Hidden

Bool Property bBlueprintStorageTutorialComplete = false Auto Hidden

; ---------------------------------------------
; Vars
; ---------------------------------------------

int iLastShownBlueprintIndex = 0
int[] ExpectingBatchIDs

; ---------------------------------------------
; Events
; ---------------------------------------------

Event OnMenuOpenCloseEvent(String asMenuName, Bool abOpening)
	if(asMenuName == "BarterMenu" && ! abOpening)
		UnregisterForMenuOpenCloseEvent("BarterMenu")
		
		; Test vendor container for blueprints (use first one found)
		ObjectReference kVendorContainerRef = BlueprintBuildVendorContainer.GetRef()
		
		int i = 0
		int iCount = BlueprintObjects.GetCount() ; Switching from the formlist to the RefCollectionAlias
		WorkshopPlus:ObjectReferences:Blueprint BuildMe = None
		
		while(i < iCount && ! BuildMe)
			ObjectReference thisRef = BlueprintObjects.GetAt(i)
			
			if(kVendorContainerRef.GetItemCount(thisRef) > 0)
				BuildMe = thisRef as WorkshopPlus:ObjectReferences:Blueprint
			endif
			
			i += 1
		endWhile
		
		; Move all blueprints to storage container from vendor and player
		ObjectReference kStorageRef = BlueprintCentralStorage.GetRef()
		kVendorContainerRef.RemoveAllItems(kStorageRef)
		; 1.0.4 - Using keyword instead ; PlayerRef.RemoveItem(BlueprintReferencesList, -1, true, kStorageRef)
		PlayerRef.RemoveItem(BlueprintObjectKeyword, -1, true, kStorageRef)
		
		if(BuildMe)			
			SelectedBlueprint.ForceRefTo(BuildMe)
			BuildSelectedBlueprint()
		else
			Debug.MessageBox("No blueprint found in the storage container.")
			NoBlueprintSelected.Show()
		endif
	elseif(asMenuName == "ContainerMenu" && ! abOpening)
		UnregisterForMenuOpenCloseEvent("ContainerMenu")
		UnregisterForRemoteEvent(PlayerRef, "OnItemAdded")
	endif
EndEvent


; 1.0.4 - Fixing the older blueprint objects by persisting them in an alias
Event ObjectReference.OnItemAdded(ObjectReference akAddedTo, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	ObjectReference kCentralStorageRef = BlueprintCentralStorage.GetRef()
	
	if(kCentralStorageRef && akAddedTo == kCentralStorageRef && akItemReference != None && akBaseItem.HasKeyword(BlueprintObjectKeyword))
		BlueprintObjects.AddRef(akItemReference)
	endif
EndEvent


Event WorkshopFramework:PlaceObjectManager.SimpleObjectBatchCreated(WorkshopFramework:PlaceObjectManager akPlaceObjectManagerQuest, Var[] akArgs)
	Int iBatchID = akArgs[0] as Int
	Bool bAdditionalEvents = akArgs[1] as Bool
	
	int iBatchIndex = ExpectingBatchIDs.Find(iBatchID)
	
	if(iBatchIndex >= 0)
		; This event is for us!
		int iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
		
		; Attach the items to the blueprint controller so the player can place them easily - also add them to the active layer, but don't connect to the layer handle if it exists
		if(ActiveBlueprintControllerRef)
			int i = 2
			while(i < akArgs.Length)
				ObjectReference kTemp = akArgs[i] as ObjectReference
				
				if(kTemp)
					kTemp.SetLinkedRef(ActiveBlueprintControllerRef, WorkshopStackedItemParentKeyword)
					
					if(BuildingBlueprintOnLayerRef)
						LayerManager.AddItemToLayer_Lock(kTemp, BuildingBlueprintOnLayerRef)
					else
						LayerManager.AddItemToLayer_Lock(kTemp, None) ; Just add to the active layer
					endif
				endif
				
				i += 1
			endWhile
		endif
		
		if( ! bAdditionalEvents)
			if(ExpectingBatchIDs.Length > 1)
				ExpectingBatchIDs.Remove(iBatchIndex)
			elseif(ExpectingBatchIDs.Length == 1)
				; Finished processing a blueprint build event
				ExpectingBatchIDs = new Int[0]
				
				; Update the BP Controller object's shader
				ActiveBlueprintControllerRef.PlayReadyShader()
				
				BlueprintConstructionComplete.Show()
				
				; Clear the previously used layer, this locks out new items on the layer from being attached to the layer handle
				BuildingBlueprintOnLayerRef = None 
			endif
			
			if(ExpectingBatchIDs == None || ExpectingBatchIDs.Length == 0)
				bBlueprintBuildBlock = false
			endif
		endif
		
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndEvent


;
; Event Handlers
;

Function HandleInstallModChanges()
	Parent.HandleInstallModChanges()
	
	if(iInstalledVersion < 6)
		; 1.0.4 - Starting resource shortage loop
		PersistBlueprints()
	endif	
EndFunction


; ---------------------------------------------
; Functions
; ---------------------------------------------

Function ShowBlueprintCentralStorage()
	ObjectReference CentralStorage = BlueprintCentralStorage.GetRef()
	
	if( ! CentralStorage)
		ProblemAccessingBlueprintStorage.Show()
		return
	endif
	
	; Show central storage container
	CentralStorage.Activate(PlayerRef)
	
	if( ! bBlueprintStorageTutorialComplete)
		int i = 0 
		while(i < BlueprintStorageExplanationMessages.Length)
			int iDelay = BlueprintStorageExplanationMessages[i].Show()
			
			i += 1
		endWhile
		
		bBlueprintStorageTutorialComplete = true
	endif
EndFunction


Function ShowBlueprintControlMenu(WorkshopPlus:ObjectReferences:BlueprintController akControlRef = None)
	int iConfirm = BlueprintControlMenu.Show()
		
	WorkshopPlus:SettlementLayers TheseSettlementLayers = LayerManager.GetCurrentSettlementLayers()
			
	if(iConfirm == 0)
		ShowBlueprintCentralStorage()				
	elseif(iConfirm == 1)
		if(bBlueprintCreationBlock)
			BlueprintCreationInProgress.Show()
			return
		endif
		
		; Popup layer select menu so player can decide which layer to blueprint
		CurrentActiveLayerIndex.SetValue(-2.0) ; We want all layers to show up in the select
		CurrentLayerCount.SetValue(TheseSettlementLayers.Layers.Length)
		
		Int iSelect = ExistingLayerSelectMenu.Show()
		Int iTargetLayerIndex
		if(iSelect == 0)
			return
		elseif(iSelect == 1)
			iTargetLayerIndex = 0
		else
			iTargetLayerIndex = iSelect - 1
		endif
			
		CreateBlueprintFromLayer(iTargetLayerIndex)
	elseif(iConfirm == 2)
		if(bBlueprintBuildBlock)
			BlueprintBuildInProgress.Show()
			return
		endif
		
		if( ! akControlRef)
			; Attempt to find a control ref
			WorkshopScript thisWorkshop = GetNearestWorkshop(PlayerRef)
			ObjectReference[] kFound = thisWorkshop.FindAllReferencesWithKeyword(BlueprintControllerKeyword, 20000.0)
			
			if(kFound.Length)
				int i = 0
				while(i < kFound.Length)
					if(kFound[i].GetLinkedRef(WorkshopItemKeyword) == thisWorkshop)
						akControlRef = kFound[i] as WorkshopPlus:ObjectReferences:BlueprintController
					endif
					
					i += 1
				endWhile
			endif
		endif
		
		if( ! akControlRef)
			BlueprintControllerNotFound.Show()
			
			return
		else
			ActiveBlueprintControllerRef = akControlRef
		endif
		
		; Popup layer select menu so player can decide which layer to build on - make it the active layer
		CurrentActiveLayerIndex.SetValue(-2.0) ; We want all layers to show up in the select
		CurrentLayerCount.SetValue(TheseSettlementLayers.Layers.Length)
		
		Int iSelect = LayerSelectMenu.Show()
		
		if(iSelect == 0)
			return
		elseif(iSelect == 1)
			LayerManager.CreateNewLayer()
		else
			int iTargetLayerIndex = iSelect - 3
			if(iTargetLayerIndex == -1)
				LayerManager.MakeActiveLayer(TheseSettlementLayers.DefaultLayer)
			else
				LayerManager.MakeActiveLayer(TheseSettlementLayers.Layers[iTargetLayerIndex])
			endif
		endif
		
		TheseSettlementLayers = LayerManager.GetCurrentSettlementLayers() ; Update our copy	
		
		; Set the target layer for the items
		BuildingBlueprintOnLayerRef = TheseSettlementLayers.ActiveLayer
		
		; Popup build vendor so player can select the blueprint
		ShowBuildBlueprintVendor()
	elseif(iConfirm == 3)
		akControlRef.Hide()
	else
		return
	endif
EndFunction


Function CreateBlueprintFromLayer(Int aiLayerIndex)
	if(bBlueprintCreationBlock)
		return
	endif
	
	WorkshopPlus:WorkshopLayer sourceLayer
	WorkshopPlus:SettlementLayers TheseLayers = LayerManager.GetCurrentSettlementLayers()
	
	if( ! TheseLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[gCurrentWorkshop.GetValueInt()] + ".", 2)
		
		return
	endif
	
	if(aiLayerIndex == 0)
		sourceLayer = TheseLayers.DefaultLayer
	elseif(TheseLayers.Layers.Length >= aiLayerIndex)
		sourceLayer = TheseLayers.Layers[aiLayerIndex - 1]
	else
		LayerMissing_UnableToCreateBlueprint.Show()
		
		return
	endif
	
	ObjectReference kNextRef = sourceLayer.kLastCreatedItem
	if( ! kNextRef)
		LayerEmpty_UnableToCreateBlueprint.Show()
		return
	endif
	
	; Warn player if they are re-using a slot that they need to manually rename the blueprint
	int iNameIndex = NextBlueprintNameIndex
	
	if(iNameIndex == 0 && ! bFirstUseOfBlueprintSlots)
		int iConfirm = Confirm_BlueprintReuseNameSlot.Show()
		
		if(iConfirm == 0)
			return
		endif
	endif
		
	bBlueprintCreationBlock = true
	
	; Spawn blueprint object
	ObjectReference kSpawnAt = SafeSpawnPoint.GetRef()
	WorkshopPlus:ObjectReferences:Blueprint kBlueprintRef = kSpawnAt.PlaceAtMe(BlankBlueprintForm[iNameIndex], abDeleteWhenAble = false) as WorkshopPlus:ObjectReferences:Blueprint
	
	; 1.0.4 - The formlist ended up not working as expected and using a RefCollectionAlias makes more sense
	; BlueprintReferencesList.AddForm(kBlueprintRef)
	BlueprintObjects.AddRef(kBlueprintRef)
	LastCreatedBlueprint.ForceRefTo(kBlueprintRef)
	
	; Copy items to blueprint via threads
	ObjectReference[] kObjectBatch = new ObjectReference[0]
	WorkshopPlus:Threading:Thread_CopyToBlueprint kThreadRef
	int iExpectedCount = sourceLayer.iItemCount
	int iMaxBatches = kBlueprintRef.iMaxBatches
	Int iMaxWaitCount = 10
	Int iWaitCount = 0
	while(kNextRef)
		kObjectBatch.Add(kNextRef)
		
		if(kObjectBatch.Length > 0 && (kObjectBatch.Length == 128 || (iExpectedCount > iMaxBatches && kObjectBatch.Length >= Math.Ceiling(iExpectedCount as Float/iMaxBatches as Float))))
			kThreadRef = ThreadManager.CreateThread(Thread_CopyToBlueprint) as WorkshopPlus:Threading:Thread_CopyToBlueprint
			
			if(kThreadRef)
				kBlueprintRef.iExpectedItems += kObjectBatch.Length
				kThreadRef.kBlueprintRef = kBlueprintRef
				kThreadRef.kObjectsToCopy = kObjectBatch
				; Grab a batch index immediately, this primes the blueprint to accept a large number of items before it self-compresses the arrays
				kThreadRef.iBatchIndex = kBlueprintRef.RequestBatchIndex()
					
				ThreadManager.QueueThread(kThreadRef)
			endif
			
			kObjectBatch = new ObjectReference[0]
		endif
	
		kNextRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)
	endWhile
	
	if(kObjectBatch.Length > 0)
		kThreadRef = ThreadManager.CreateThread(Thread_CopyToBlueprint) as WorkshopPlus:Threading:Thread_CopyToBlueprint
		kBlueprintRef.iExpectedItems += kObjectBatch.Length
		kThreadRef.kBlueprintRef = kBlueprintRef
		kThreadRef.kObjectsToCopy = kObjectBatch
		
		ThreadManager.QueueThread(kThreadRef)
	endif
	
	; We don't need to do anything else, the blueprint will take care of itself
	; NOTE: We are not clearing the block flag here - that will be done by the blueprint itself during finalization
EndFunction


; 1.0.4 - Fixing existing blueprints so they don't lose their data
Function PersistBlueprints()
	ObjectReference kCentralStorageRef = BlueprintCentralStorage.GetRef()
	
	if(kCentralStorageRef)
		kCentralStorageRef.RemoveAllItems(PlayerRef)
	
		AddInventoryEventFilter(BlueprintObjectKeyword)
		RegisterForRemoteEvent(kCentralStorageRef, "OnItemAdded")
		
		; Drop the blueprints to restore the references
		while(PlayerRef.GetItemCount(BlueprintObjectKeyword) > 0)
			int i = 0
			while(i < BlankBlueprintForm.Length)
				PlayerRef.DropObject(BlankBlueprintForm[i], 1)
				
				i += 1
			endWhile
		endWhile
	endif
	
	Utility.Wait(2.0)
	UnregisterForRemoteEvent(kCentralStorageRef, "OnItemAdded")
EndFunction


Function ShowBuildBlueprintVendor()
	; Add all blueprints to player's inventory
	ObjectReference kCentralStorageRef = BlueprintCentralStorage.GetRef()
	Actor kVendorRef = BlueprintBuildVendor.GetRef() as Actor
	if(kCentralStorageRef && kVendorRef)
		kCentralStorageRef.RemoveAllItems(PlayerRef)
		
		; Show vendor
		kVendorRef.ShowBarterMenu()
		
		RegisterForMenuOpenCloseEvent("BarterMenu")
	endif
EndFunction


Function BuildSelectedBlueprint()
	WorkshopPlus:ObjectReferences:Blueprint akBlueprintRef = SelectedBlueprint.GetRef() as WorkshopPlus:ObjectReferences:Blueprint
	
	if( ! akBlueprintRef)
		Debug.MessageBox("Could not find the ref to a blueprint object.")
		NoBlueprintSelected.Show()
		return
	endif
	
	if( ! ActiveBlueprintControllerRef)
		BlueprintControllerNotFound.Show()
		return
	endif
	
	; 1.0.4 Clear all stacked refs from bp controller in case player creates multiple in a row
	ObjectReference[] kStacked = ActiveBlueprintControllerRef.GetLinkedRefChildren(WorkshopStackedItemParentKEYWORD)
	
	int i = 0
	while(i < kStacked.Length)
		kStacked[i].SetLinkedRef(None, WorkshopStackedItemParentKEYWORD)
		
		i += 1
	endWhile
	
	ActiveBlueprintControllerRef.PlayBusyShader()
	BuildBlueprint(akBlueprintRef, ActiveBlueprintControllerRef)	
EndFunction


Function BuildBlueprint(WorkshopPlus:ObjectReferences:Blueprint akBlueprintRef, WorkshopPlus:ObjectReferences:BlueprintController akBlueprintController)
	if( ! akBlueprintRef || ! akBlueprintController)
		return
	endif

	if(bBlueprintBuildBlock)
		; Notify player they need to wait for the current to complete
		BlueprintBuildInProgress.Show()
		return
	endif
	
	;Add a short delay so the player can get out of the way
	Utility.Wait(Setting_BlueprintBuildDelay.GetValue())
	
	; Monitor for the return events so we know when the build is complete
	RegisterForCustomEvent(PlaceObjectManager, "SimpleObjectBatchCreated")
	
	bBlueprintBuildBlock = true
	ActiveBlueprintControllerRef = akBlueprintController
	
	WorkshopPlus:SettlementLayers TheseLayers = LayerManager.GetCurrentSettlementLayers()
	if(TheseLayers)
		BuildingBlueprintOnLayerRef = TheseLayers.ActiveLayer
	else
		BuildingBlueprintOnLayerRef = None
	endif
	
	ExpectingBatchIDs = new Int[0]
	
	WorkshopScript thisWorkshop = ResourceManager.Workshops[gCurrentWorkshop.GetValueInt()]
	
	if(akBlueprintRef.ObjectBatch01.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch01, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch02.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch02, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch03.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch03, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif	
	
	if(akBlueprintRef.ObjectBatch04.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch04, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif	
	
	if(akBlueprintRef.ObjectBatch05.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch05, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch06.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch06, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch07.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch07, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch08.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch08, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch09.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch09, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch10.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch10, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch11.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch11, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch12.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch12, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch13.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch13, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch14.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch14, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch15.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch15, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	
	if(akBlueprintRef.ObjectBatch16.Length > 0)
		int iBatchID = PlaceObjectManager.CreateBatchObjectsV2(akBlueprintRef.ObjectBatch16, thisWorkshop, akBlueprintController)
		
		ExpectingBatchIDs.Add(iBatchID)
	endif
	; Note - we're leaving bBlueprintBuildBlock, it will get flipped back when the batch events return
EndFunction


Function PlaceBlueprintController(ObjectReference akPlaceAtRef = None)
	if( ! akPlaceAtRef)
		akPlaceAtRef = PlayerRef
	endif
	
	WorldObject thisWorldObject = new WorldObject
	
	thisWorldObject.ObjectForm = PlaceableBlueprintControllerForm
	
	if(akPlaceAtRef == PlayerRef)
		; Place in front of the player
		Float fDistanceInFrontOfPlayer = 256.0
		Float fPlayerAngle = PlayerRef.GetAngleZ()
		
		Float fPlayerPosX = PlayerRef.X
		Float fPlayerPosY = PlayerRef.Y
		Float fPlayerPosZ = PlayerRef.Z
		
		thisWorldObject.fPosX = fPlayerPosX + fDistanceInFrontOfPlayer*Math.Sin(fPlayerAngle)
		thisWorldObject.fPosY = fPlayerPosY + fDistanceInFrontOfPlayer*Math.Cos(fPlayerAngle)
		thisWorldObject.fPosZ = fPlayerPosZ
	else
		thisWorldObject.fPosX = akPlaceAtRef.X
		thisWorldObject.fPosY = akPlaceAtRef.Y
		thisWorldObject.fPosZ = akPlaceAtRef.Z
	endif
	
	PlaceObjectManager.CreateObjectImmediately(thisWorldObject, GetNearestWorkshop(PlayerRef))
EndFunction



Function Hotkey_PlaceBlueprintController()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	PlaceBlueprintController()
EndFunction


; Added 1.0.4
Function ShowHotkeyWarning()
	if(Settings_ShowHotkeyWarnings.GetValue() == 1.0)
		ShowHotkeyWarning()
	endif
EndFunction