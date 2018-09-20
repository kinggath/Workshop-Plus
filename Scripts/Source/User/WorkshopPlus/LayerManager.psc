; ---------------------------------------------
; WorkshopPlus:LayerManager.psc - by kinggath
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

Scriptname WorkshopPlus:LayerManager extends WorkshopFramework:Library:SlaveQuest
{ Handles layers }

import WorkshopFramework:Library:UtilityFunctions


; ---------------------------------------------
; Consts 
; ---------------------------------------------

int iMaxLayers = 16 ; We can expand this, but we'll need to edit the LayerSelect message in XEdit as we're at the max the CK will allow atm

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
	WorkshopFramework:MainQuest Property WSFW_Main Auto Const Mandatory
	Form Property Thread_ScrapObject Auto Const Mandatory
	GlobalVariable Property gCurrentWorkshop Auto Const Mandatory
	{ Point to currentWorkshopId global controlled by WorkshopParent }
EndGroup


Group Aliases
	ReferenceAlias Property SafeSpawnPoint Auto Const Mandatory
	ReferenceAlias Property ActiveLayerRef Auto Const Mandatory
	{ Used for displaying the layer name in messages - not currently useful since we can't display ref names in Message Box selection, but perhaps F4SE can allow that in the future and we can introduce layer naming }
EndGroup


Group Assets
	Form Property SettlementLayersHolderForm Auto Const Mandatory
	Form Property WorkshopLayerForm Auto Const Mandatory
	EffectShader Property ShaderActiveLayer Auto Const Mandatory
	EffectShader Property ShaderHighlightLayer Auto Const Mandatory
	EffectShader Property ShaderFlashLayer Auto Const Mandatory
EndGroup


Group ActorValues
	ActorValue Property LayerID Auto Const Mandatory
EndGroup


Group Globals
	GlobalVariable Property AllowLayerHandlingCancellation Auto Const Mandatory
	GlobalVariable Property CurrentActiveLayerIndex Auto Const Mandatory
	GlobalVariable Property CurrentLayerCount Auto Const Mandatory
EndGroup

Group Keyword
	Keyword Property WorkshopKeyword Auto Const Mandatory
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property LayerHolderLinkKeyword Auto Const Mandatory
	Keyword Property LayerItemLinkChainKeyword Auto Const Mandatory
	Keyword Property LayerItemLinkKeyword Auto Const Mandatory
EndGroup

Group Messages
	Message Property CannotDeleteDefaultLayer Auto Const Mandatory
	Message Property MustBeInWorkshopModeToUseHotkeys Auto Const Mandatory
	Message Property NewLayerActivated Auto Const Mandatory
	Message Property DefaultLayerActivated Auto Const Mandatory
	Message Property NoOtherLayersToSwitchTo Auto Const Mandatory
	Message Property NoMoreLayersAllowed Auto Const Mandatory
	Message Property LayerSelect Auto Const Mandatory
	Message Property ScrapOrMoveItemsConfirmation Auto Const Mandatory
EndGroup


Group Settings
	GlobalVariable Property Setting_AutoChangeLayerOnMovedObjects Auto Const Mandatory
	GlobalVariable Property Setting_AutoUnhideLayersOnExitWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_AutoUnhideLayersDelay Auto Const Mandatory
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

Int Property iNextLayerID = 0 Auto Hidden ; Starting at 0 so first call to NextLayerID = 1, we don't want to use 0 as a layer ID, because that's the default value of the AV.
Int Property NextLayerID
	Int Function Get()
		iNextLayerID += 1
		
		return iNextLayerID
	EndFunction
EndProperty

; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bRegisterWorkshopsBlock = false
WorkshopPlus:SettlementLayers CurrentSettlementLayers
WorkshopPlus:WorkshopLayer LastHiddenLayer

; ---------------------------------------------
; Events
; --------------------------------------------- 

; TODO Sim Settlements: If WorkshopPlus detected, have City Plan code automatically create a CityPlan layer and stick all items on it. Plus maybe add an option to auto create layers for plots, and other item classifications.

Event ObjectReference.OnWorkshopObjectPlaced(ObjectReference akWorkshopRef, ObjectReference akReference)
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	WorkshopPlus:WorkshopLayer kLayerRef = CurrentSettlementLayers.ActiveLayer
	if(asWorkshop.GetWorkshopID() != gCurrentWorkshop.GetValueInt())
		WorkshopPlus:SettlementLayers kLayerHolder = asWorkshop.GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if(kLayerHolder)
			kLayerRef = kLayerHolder.ActiveLayer
		endif
	endif
	
	if(kLayerRef)
		AddItemToLayer_Lock(akReference, kLayerRef)
	endif
EndEvent

Event ObjectReference.OnWorkshopObjectMoved(ObjectReference akWorkshopRef, ObjectReference akReference)
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	; If option to auto shift moved object to active layer, then do so
	if(Setting_AutoChangeLayerOnMovedObjects.GetValue() == 1)
		WorkshopPlus:WorkshopLayer kLayerRef = CurrentSettlementLayers.ActiveLayer
		if(asWorkshop.GetWorkshopID() != gCurrentWorkshop.GetValueInt())
			WorkshopPlus:SettlementLayers kLayerHolder = asWorkshop.GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
			
			if(kLayerHolder)
				kLayerRef = kLayerHolder.ActiveLayer
			endif
		endif
		
		if(kLayerRef)
			int iPreviousLayerID = akReference.GetValue(LayerID) as Int
			WorkshopPlus:WorkshopLayer PreviousLayer = GetLayerFromID(iPreviousLayerID, asWorkshop)
			if(PreviousLayer)
				RemoveItemFromLayer_Lock(akReference, PreviousLayer, kLayerRef)
			else
				AddItemToLayer_Lock(akReference, kLayerRef)
			endif
		endif
	endif
EndEvent

Event ObjectReference.OnWorkshopObjectDestroyed(ObjectReference akWorkshopRef, ObjectReference akReference)
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	; Move and enable temporarily so we can test AV (Always setposition while disabled, it's cheaper)
	akReference.SetPosition(akReference.X, akReference.Y, akReference.Z - 10000)
	akReference.Enable(false)
	Int iLayerID = akReference.GetValue(LayerID) as Int
	akReference.Disable(false)
	akReference.SetPosition(akReference.X, akReference.Y, akReference.Z + 10000)
	
	if(iLayerID > 0)
		WorkshopPlus:SettlementLayers kLayerHolderRef = CurrentSettlementLayers
		if(asWorkshop.GetWorkshopID() != gCurrentWorkshop.GetValueInt())
			kLayerHolderRef = asWorkshop.GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
			
			if( ! kLayerHolderRef)
				return
			endif
		endif
		
		if(kLayerHolderRef.DefaultLayer.iLayerID == iLayerID)
			RemoveItemFromLayer_Lock(akReference, kLayerHolderRef.DefaultLayer)
		else
			int i = 0 
			bool bLayerFound = false
			while(i < kLayerHolderRef.Layers.Length && ! bLayerFound)
				if(kLayerHolderRef.Layers[i].iLayerID == iLayerID)
					RemoveItemFromLayer_Lock(akReference, kLayerHolderRef.Layers[i])
					bLayerFound = true
				endif
				
				i += 1
			endWhile
		endif
	endif
EndEvent

Event WorkshopFramework:MainQuest.PlayerEnteredSettlement(WorkshopFramework:MainQuest akQuestRef, Var[] akArgs)
	WorkshopScript kWorkshopRef = akArgs[0] as WorkshopScript
	Bool bPreviouslyUnloaded = akArgs[1] as Bool
	
	CurrentSettlementLayers = kWorkshopRef.GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
	
	if(CurrentSettlementLayers == None)
		Debug.MessageBox("Creating settlement layer holder.")
		CurrentSettlementLayers = SetupSettlementLayers_Lock(kWorkshopRef)
	else
		Debug.MessageBox("CurrentSettlementLayers detected.")
	endif
EndEvent

Event WorkshopFramework:MainQuest.PlayerExitedSettlement(WorkshopFramework:MainQuest akQuestRef, Var[] akArgs)
	WorkshopScript kWorkshopRef = akArgs[0] as WorkshopScript
	Bool bStillLoaded = akArgs[1] as Bool
	
EndEvent



; ---------------------------------------------
; Functions
; --------------------------------------------- 

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; Init arrays
	
	; Register for events
	RegisterForCustomEvent(WSFW_Main, "PlayerEnteredSettlement")
	RegisterForCustomEvent(WSFW_Main, "PlayerExitedSettlement")
EndFunction


Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	; New workshops might have been added, so we need to register for those events
	RegisterForAllWorkshopEvents()
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
			RegisterForRemoteEvent(kWorkshops[i], "OnWorkshopObjectPlaced")
			RegisterForRemoteEvent(kWorkshops[i], "OnWorkshopObjectMoved")
			RegisterForRemoteEvent(kWorkshops[i], "OnWorkshopObjectDestroyed")
		endif
		
		i += 1
	endWhile
	
	bRegisterWorkshopsBlock = false
	
	;Debug.Notification("[Workshop Plus] Finished registering for workshop events.")
EndFunction


WorkshopPlus:WorkshopLayer Function GetLayerFromID(Int aiLayerID, WorkshopScript akWorkshopRef)
	WorkshopPlus:SettlementLayers kLayerHolder = akWorkshopRef.GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
	
	if(kLayerHolder)
		if(kLayerHolder.DefaultLayer.iLayerID == aiLayerID)
			return kLayerHolder.DefaultLayer
		elseif(kLayerHolder.Layers.Length > 0)
			int i = 0
			while(i < kLayerHolder.Layers.Length)
				if(kLayerHolder.Layers[i].iLayerID == aiLayerID)
					return kLayerHolder.Layers[i]
				endif
				
				i += 1
			endWhile
		endif
	else
		return None
	endif
EndFunction


WorkshopPlus:SettlementLayers Function SetupSettlementLayers_Lock(WorkshopScript akWorkshopRef)
	ObjectReference kSpawnAt = SafeSpawnPoint.GetRef()
	
	if(kSpawnAt)
		int iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return None
		endif
		
		WorkshopPlus:SettlementLayers kLayerHolderRef = kSpawnAt.PlaceAtMe(SettlementLayersHolderForm, abDeleteWhenAble = false) as WorkshopPlus:SettlementLayers
		
		if(kLayerHolderRef)
			; New layer set, prepare it
			kLayerHolderRef.iWorkshopID = akWorkshopRef.GetWorkshopID()
			kLayerHolderRef.DefaultLayer = CreateLayer_Lock(false)
			kLayerHolderRef.ActiveLayer = kLayerHolderRef.DefaultLayer
			
			; We only want one layer holder per settlement, so we'll link workshop to holder
			akWorkshopRef.SetLinkedRef(kLayerHolderRef, LayerHolderLinkKeyword)
			
			; Copy existing items onto the default layer
			ObjectReference[] kExistingObjects = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
			
			int i = 0
			while(i < kExistingObjects.Length)
				AddItemToLayer_Lock(kExistingObjects[i], kLayerHolderRef.DefaultLayer, abGetLock = false)
				
				i += 1
			endWhile
			
			
			; TODO Sim Settlements: Any items with the CitySpawned keyword should be moved to a separate layer
			
			ModTrace("[WSPlus] Successfully configured layer holder for " + akWorkshopRef + ".")
		else
			ModTrace("[WSPlus] Failed to setup layers for settlement " + akWorkshopRef + ".", 2)
		endif
		
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
		
		return kLayerHolderRef
	else
		ModTrace("[WSPlus] Unable to find spawn point to set up layers for settlement " + akWorkshopRef + ".", 2)
	endif
	
	return None
EndFunction


WorkshopPlus:WorkshopLayer Function CreateLayer_Lock(Bool abGetLock = true)
	ModTrace("[WS Plus] Creating layer   -     START")
	int iLockKey 
	
	if(abGetLock)
		iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return None
		endif
	endif
			
	int iLayerID = NextLayerID
	
	ObjectReference kSpawnAt = SafeSpawnPoint.GetRef()
	WorkshopPlus:WorkshopLayer kLayerRef = None
	if(kSpawnAt)
		kLayerRef = kSpawnAt.PlaceAtMe(WorkshopLayerForm, abDeleteWhenAble = false) as WorkshopPlus:WorkshopLayer
		kLayerRef.iLayerID = iLayerID
		
		ModTrace("[WS Plus] Creating layer   -     SUCCESS")
	else
		ModTrace("[WSPlus] Unable to find spawn point to create layer " + iLayerID + " for settlement " + ResourceManager.Workshops[gCurrentWorkshop.GetValueInt()] + ".", 2)
	endif
	
	if(abGetLock)
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
	
	return kLayerRef
EndFunction


Function AddLayer()
	ModTrace("[WS Plus] AddLayer   -     START")
	
	int iCurrentWorkshopID = gCurrentWorkshop.GetValueInt()
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
		return
	endif
	
	if(CurrentSettlementLayers.iWorkshopID != iCurrentWorkshopID)
		CurrentSettlementLayers = ResourceManager.Workshops[iCurrentWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if( ! CurrentSettlementLayers)
			ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
			return
		endif
	endif
	
	if(CurrentSettlementLayers.Layers == None)
		CurrentSettlementLayers.Layers = new WorkshopPlus:WorkshopLayer[0]
	endif
	
	WorkshopPlus:WorkshopLayer kNewLayerRef = CreateLayer_Lock()
	
	if(kNewLayerRef)
		CurrentSettlementLayers.Layers.Add(kNewLayerRef)
		MakeActiveLayer(kNewLayerRef)		
	endif
	
	ModTrace("[WS Plus] Adding layer   -     SUCCESS")
EndFunction


Function MakeActiveLayer(WorkshopPlus:WorkshopLayer akLayerRef)
	ModTrace("[WS Plus] Setting active layer " + akLayerRef)
	if( ! akLayerRef)
		ModTrace("[WSPlus] Could not make layer " + akLayerRef + " active, the ref is missing or is not the correct type.")
		
		return
	endif
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[gCurrentWorkshop.GetValueInt()] + ".", 2)
		
		return
	endif
	
	; Make all other layers inactive
	int i = 0
	while(i < CurrentSettlementLayers.Layers.Length)
		CurrentSettlementLayers.Layers[i].bActive = false
		
		i += 1
	endWhile
	
	WorkshopPlus:WorkshopLayer kPreviousActiveLayer = CurrentSettlementLayers.ActiveLayer
	ModTrace("[WS Plus]: Previous layer shader: " + kPreviousActiveLayer.CurrentHighlightShader  + " vs ActiveShader: " + ShaderActiveLayer)
	if(kPreviousActiveLayer.CurrentHighlightShader == ShaderActiveLayer)
		Debug.MessageBox("ActiveShader detected")
		HighlightLayerItems(kPreviousActiveLayer, None, true)
		HighlightLayerItems(akLayerRef, ShaderActiveLayer)
	endif
	
	CurrentSettlementLayers.ActiveLayer = akLayerRef
	akLayerRef.bActive = true
	
	ActiveLayerRef.ForceRefTo(akLayerRef)
	
	if(akLayerRef == CurrentSettlementLayers.DefaultLayer)
		DefaultLayerActivated.Show()
	else
		NewLayerActivated.Show(CurrentSettlementLayers.Layers.Find(akLayerRef))
	endif
EndFunction 


Function ToggleActiveLayer()
	if(LastHiddenLayer)
		ShowLayer_Lock(LastHiddenLayer)
	else
		HideLayer_Lock(CurrentSettlementLayers.ActiveLayer)
	endif
EndFunction


Function ShowLayer_Lock(WorkshopPlus:WorkshopLayer akLayerRef = None, Bool abGetLock = true)
	ModTrace("[WS Plus] Showing layer " + akLayerRef)
	if( ! akLayerRef)
		akLayerRef = LastHiddenLayer
		
		if( ! akLayerRef)
			ModTrace("[WSPlus] Could not show layer " + akLayerRef + ", the ref is missing or is not the correct type.")
		endif
		
		return
	endif
	
	if( ! akLayerRef.kLastCreatedItem)
		return ; Nothing to show
	else
		; Get Edit Lock 
		int iLockKey
		if(abGetLock)
			iLockKey = GetLock()
			if(iLockKey <= GENERICLOCK_KEY_NONE)
				ModTrace("Unable to get lock!", 2)
				
				return
			endif
		endif
		
		
		akLayerRef.kLastCreatedItem.Enable(false)
		akLayerRef.kLastCreatedItem.EnableLinkChain(LayerItemLinkChainKeyword, false)
		akLayerRef.bShown = true
		
		if(akLayerRef == LastHiddenLayer)
			LastHiddenLayer = None
		endif
		
		
		if(abGetLock)
			; Release Edit Lock
			if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
				ModTrace("Failed to release lock " + iLockKey + "!", 2)
			endif
		endif			
	endif
EndFunction


Function HideLayer_Lock(WorkshopPlus:WorkshopLayer akLayerRef = None, Bool abGetLock = true)
	ModTrace("[WS Plus] Hiding layer " + akLayerRef)
	if( ! akLayerRef)
		akLayerRef = CurrentSettlementLayers.ActiveLayer
		
		if( ! akLayerRef)
			ModTrace("[WSPlus] Could not hide layer " + akLayerRef + ", the ref is missing or is not the correct type.")
		
			return
		endif
	endif
	
	if( ! akLayerRef.kLastCreatedItem)
		return ; Nothing to hide
	else
		; Get Edit Lock 
		int iLockKey
		if(abGetLock)
			iLockKey = GetLock()
			if(iLockKey <= GENERICLOCK_KEY_NONE)
				ModTrace("Unable to get lock!", 2)
				
				return
			endif
		endif
		
		akLayerRef.kLastCreatedItem.Disable(false)
		akLayerRef.kLastCreatedItem.DisableLinkChain(LayerItemLinkChainKeyword, false)
		akLayerRef.bShown = false
		
		LastHiddenLayer = akLayerRef		
		
		if(abGetLock)
			; Release Edit Lock
			if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
				ModTrace("Failed to release lock " + iLockKey + "!", 2)
			endif
		endif
	endif
EndFunction


Bool Function CanBeAddedToLayer(ObjectReference akNewItem)
	if(akNewItem.HasKeyword(WorkshopKeyword) || (akNewItem as WorkshopNPCScript && ! (akNewItem as WorkshopObjectActorScript)))
		return false
	endif
	
	return true
EndFunction


Function AddItemToLayer_Lock(ObjectReference akNewItem, WorkshopPlus:WorkshopLayer akLayerRef = None, Bool abGetLock = true)
	if( ! CanBeAddedToLayer(akNewItem))
		return
	endif
	
	
	if( ! akLayerRef)
		akLayerRef = CurrentSettlementLayers.ActiveLayer
	endif
	
	ModTrace("[WS Plus] Adding item " + akNewItem + " to layer " + akLayerRef)
	
	; Get Edit Lock 
	int iLockKey
	if(abGetLock)
		iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
	endif
	
	
	; Move finished turn off layer flash
	ShaderFlashLayer.Stop(akNewItem)
		
	; Add item to end of linked ref chain
	ObjectReference kPreviousItem = akLayerRef.kLastCreatedItem
	akLayerRef.kLastCreatedItem = akNewItem
	
	if(kPreviousItem && akNewItem != kPreviousItem) ; Make sure items don't link to themselves
		akNewItem.SetLinkedRef(kPreviousItem, LayerItemLinkChainKeyword)
	endif
	
	; Set AV to mark item with layer ID in case we need to rebuild the linked ref chain, or in the future, we might need to allow certain items to be pulled from the ref chain so they aren't disabled/enabled
	akNewItem.SetValue(LayerID, akLayerRef.iLayerID)
	
	if( ! akLayerRef.bShown)
		akNewItem.Disable(false)
	elseif(akLayerRef.CurrentHighlightShader != None)
		akLayerRef.CurrentHighlightShader.Play(akNewItem, -1.0)
	endif
	
	; Release Edit Lock
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction


Function RemoveItemFromLayer_Lock(ObjectReference akRemoveItemRef, WorkshopPlus:WorkshopLayer akRemoveFromLayerRef = None, WorkshopPlus:WorkshopLayer akNewLayerRef = None, Bool abGetLock = true)
	if( ! akRemoveFromLayerRef)
		akRemoveFromLayerRef = CurrentSettlementLayers.ActiveLayer
	endif
	
	ModTrace("[WS Plus] Removing item " + akRemoveItemRef + " to layer " + akRemoveFromLayerRef + ", moving to " + akNewLayerRef)
	
	; Get Edit Lock 
	int iLockKey 
	if(abGetLock)
		iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
	endif
	
	
	; Find item this is linked to in chain
	ObjectReference kChainParentRef = akRemoveItemRef.GetLinkedRef(LayerItemLinkChainKeyword)
	; Find child linked refs (should only be one)
	ObjectReference kChainChildRef = None
	ObjectReference[] kChainChildrenRefs = akRemoveItemRef.GetLinkedRefChildren(LayerItemLinkChainKeyword)
	if(kChainChildrenRefs.Length > 0)
		kChainChildRef = kChainChildrenRefs[0]
	endif
	
	; Clear link to parent
	akRemoveItemRef.SetLinkedRef(None, LayerItemLinkChainKeyword)
	
	; Attach parent to child so there is no gap in the chain
	if(kChainChildRef)
		; Link child to parent 
		kChainChildRef.SetLinkedRef(kChainParentRef, LayerItemLinkChainKeyword)
	endif
	
	; If this was the last created item, pass that throne on to the next item up the chain
	if(akRemoveItemRef == akRemoveFromLayerRef.kLastCreatedItem)
		akRemoveFromLayerRef.kLastCreatedItem = kChainParentRef
	endif
	
	if(akRemoveFromLayerRef.CurrentHighlightShader != None)
		akRemoveFromLayerRef.CurrentHighlightShader.Stop(akRemoveItemRef)
	endif
	
	if(akNewLayerRef)
		AddItemToLayer_Lock(akRemoveItemRef, akNewLayerRef, abGetLock = false)
	else
		akRemoveItemRef.SetValue(LayerID, 0.0)
	endif
	
	
	if(abGetLock)
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction


Function HideMultipleLayers_Lock(Bool bInactiveOnly = false)
	ModTrace("[WS Plus] HideMultipleLayers called... ")
	int iCurrentWorkshopID = gCurrentWorkshop.GetValueInt()
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
		return
	endif
	
	if(CurrentSettlementLayers.iWorkshopID != iCurrentWorkshopID)
		CurrentSettlementLayers = ResourceManager.Workshops[iCurrentWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if( ! CurrentSettlementLayers)
			ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
			return
		endif
	endif
	
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("Unable to get lock!", 2)
		
		return
	endif
	
	; Default Layer
	if( ! bInactiveOnly || ! CurrentSettlementLayers.DefaultLayer.bActive)
		HideLayer_Lock(CurrentSettlementLayers.DefaultLayer, false)
	endif
	
	; Other Layers
	int i = 0
	while(i < CurrentSettlementLayers.Layers.Length)
		if( ! bInactiveOnly || ! CurrentSettlementLayers.Layers[i].bActive)
			HideLayer_Lock(CurrentSettlementLayers.Layers[i], false)
		endif
	
		i += 1
	endWhile	
	
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("Failed to release lock " + iLockKey + "!", 2)
	endif
EndFunction


Function ShowMultipleLayers_Lock()
	ModTrace("[WS Plus] ShowMultipleLayers called...")
	int iCurrentWorkshopID = gCurrentWorkshop.GetValueInt()
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
		return
	endif
	
	if(CurrentSettlementLayers.iWorkshopID != iCurrentWorkshopID)
		CurrentSettlementLayers = ResourceManager.Workshops[iCurrentWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if( ! CurrentSettlementLayers)
			ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
			return
		endif
	endif
	
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("Unable to get lock!", 2)
		
		return
	endif
	
	; Default Layer
	ShowLayer_Lock(CurrentSettlementLayers.DefaultLayer, false)
	
	; Other Layers
	int i = 0
	while(i < CurrentSettlementLayers.Layers.Length)
		ShowLayer_Lock(CurrentSettlementLayers.Layers[i], false)
	
		i += 1
	endWhile	
	
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("Failed to release lock " + iLockKey + "!", 2)
	endif
EndFunction


Function HighlightActiveLayer(Bool abActiveShader = false)
	ModTrace("[WS Plus] HighlightActiveLayer called...")
	EffectShader ShaderToApply = ShaderHighlightLayer
	if(abActiveShader)
		ShaderToApply = ShaderActiveLayer
	endif
	
	HighlightLayerItems(CurrentSettlementLayers.ActiveLayer, ShaderToApply)
EndFunction

Function ClearActiveLayerHighlight()
	ModTrace("[WS Plus] ClearActiveLayerHighlight called...")
	HighlightLayerItems(CurrentSettlementLayers.ActiveLayer, None, true)
EndFunction

Function ClearAllHighlighting()
	ModTrace("[WS Plus] ClearAllHighlighting called...")
	int i = 0
	while(i < CurrentSettlementLayers.Layers.Length)
		HighlightLayerItems(CurrentSettlementLayers.Layers[i], None, true)
	
		i += 1
	endWhile
EndFunction

Function HighlightLayerItems(WorkshopPlus:WorkshopLayer akLayerRef = None, EffectShader aShader = None, Bool abClearHighlights = false)
	ModTrace("[WS Plus] HighlightLayerItems called..." + akLayerRef + ", Shader: " + aShader + "; abClearHighlights: " + abClearHighlights)
	if( ! akLayerRef)
		akLayerRef = CurrentSettlementLayers.ActiveLayer
	endif
	
	if(abClearHighlights)
		ObjectReference kNextRef = akLayerRef.kLastCreatedItem
		while(kNextRef)
			if( ! aShader)
				akLayerRef.CurrentHighlightShader.Stop(kNextRef)
			else
				aShader.Stop(kNextRef)
			endif
			
			kNextRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)
		endWhile
		
		akLayerRef.CurrentHighlightShader = None
	else
		if( ! aShader)
			aShader = ShaderHighlightLayer
		endif
			
		if(akLayerRef.CurrentHighlightShader != aShader)
			if(akLayerRef.CurrentHighlightShader != None)
				; First clear previous
				HighlightLayerItems(akLayerRef, None, true)
			endif
			
			ObjectReference kNextRef = akLayerRef.kLastCreatedItem
			while(kNextRef)
				aShader.Play(kNextRef, -1.0)
				
				kNextRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)
			endWhile
			
			akLayerRef.CurrentHighlightShader = aShader
		endif
	endif
EndFunction


Function SwitchToNextLayer()
	ModTrace("[WS Plus] SwitchToNextLayer called...")
	int iCurrentWorkshopID = gCurrentWorkshop.GetValueInt()
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
		return
	endif
	
	if(CurrentSettlementLayers.iWorkshopID != iCurrentWorkshopID)
		CurrentSettlementLayers = ResourceManager.Workshops[iCurrentWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if( ! CurrentSettlementLayers)
			ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
			return
		endif
	endif
	
	
	; If default, switch to first layer in Layers array
	if(CurrentSettlementLayers.ActiveLayer == CurrentSettlementLayers.DefaultLayer)
		if(CurrentSettlementLayers.Layers.Length > 0)
			MakeActiveLayer(CurrentSettlementLayers.Layers[0])
		else
			NoOtherLayersToSwitchTo.Show()
		endif
	else
		if(CurrentSettlementLayers.Layers.Length > 0)
			int iIndex = CurrentSettlementLayers.Layers.Find(CurrentSettlementLayers.ActiveLayer)
			
			if(iIndex == CurrentSettlementLayers.Layers.Length - 1)
				; Last layer, switch to default
				MakeActiveLayer(CurrentSettlementLayers.DefaultLayer)
			else
				MakeActiveLayer(CurrentSettlementLayers.Layers[iIndex + 1])
			endif
		else
			NoOtherLayersToSwitchTo.Show()
		endif
	endif
EndFunction

Function CreateNewLayer()
	ModTrace("[WS Plus] CreateNewLayer called...")
	int iCurrentWorkshopID = gCurrentWorkshop.GetValueInt()
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
		return
	endif
	
	if(CurrentSettlementLayers.iWorkshopID != iCurrentWorkshopID)
		CurrentSettlementLayers = ResourceManager.Workshops[iCurrentWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if( ! CurrentSettlementLayers)
			ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
			return
		endif
	endif
	
	
	; Confirm there are less than iMaxLayers layers in array
	if(CurrentSettlementLayers.Layers.Length >= iMaxLayers)
		NoMoreLayersAllowed.Show(iMaxLayers as Float)
		
		return
	else
		AddLayer()
	endif
EndFunction


Int Function DisplayLayerSelect(Bool abAllowCancel = true, Bool abExcludeCurrentLayer = true)
	int iActiveLayerIndex = -2
	
	if(abExcludeCurrentLayer)
		if(CurrentSettlementLayers.ActiveLayer == CurrentSettlementLayers.DefaultLayer)
			iActiveLayerIndex = -1
		else
			iActiveLayerIndex = CurrentSettlementLayers.Layers.Find(CurrentSettlementLayers.ActiveLayer)
		endif
	endif
	
	if(abAllowCancel)
		AllowLayerHandlingCancellation.SetValue(1)
	else
		; When the layer ref is deleted externally, we have no choice but to move or scrap the items
		AllowLayerHandlingCancellation.SetValue(0)
	endif
	
	CurrentActiveLayerIndex.SetValue(iActiveLayerIndex)
	CurrentLayerCount.SetValue(CurrentSettlementLayers.Layers.Length)
	
	return LayerSelect.Show()
EndFunction


Function DeleteActiveLayer()
	ModTrace("[WS Plus] DeleteActiveLayer called...")
	DeleteLayer_Lock(CurrentSettlementLayers.ActiveLayer)
EndFunction


Function DeleteLayer_Lock(WorkshopPlus:WorkshopLayer akLayerRef)
	ModTrace("[WS Plus] DeleteLayer called..." + akLayerRef)
	if(akLayerRef == CurrentSettlementLayers.DefaultLayer)
		CannotDeleteDefaultLayer.Show()
		
		LayerDeleted(akLayerRef, true)
	else
		Bool bPromptPlayer = true
		if(akLayerRef.kLastCreatedItem == None) ; No items to worry about, just remove the layer
			bPromptPlayer = false
		endif
		
		LayerDeleted(akLayerRef, abPromptPlayer = bPromptPlayer)
		
		akLayerRef.bDeletedByManager = true ; Prevent infinite loop of LayerDeleted being called
		akLayerRef.Disable()
		akLayerRef.Delete()
		
		; Remove this layer from the layers array
		int iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
		
		int iLayerIndex = CurrentSettlementLayers.Layers.Find(akLayerRef)
		CurrentSettlementLayers.Layers.Remove(iLayerIndex)
		
		SwitchToNextLayer()
		
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction


Function LayerDeleted(WorkshopPlus:WorkshopLayer akLayerRef, Bool abPromptPlayer = false, Bool abPlayerInitiatedDeletion = true)
	; Handle clearing out layer - separating this function from DeleteLayer and ClearLayer so that we can call it if the WorkshopLayer ref is disabled from an outside source
	WorkshopPlus:WorkshopLayer kMoveItemsToLayerRef = None
	if(abPromptPlayer)
		; Prompt player and ask them to choose a layer or scrap all of the items
		if(abPlayerInitiatedDeletion)
			AllowLayerHandlingCancellation.SetValue(1.0)
		else
			AllowLayerHandlingCancellation.SetValue(0.0)
		endif
		
		int iConfirm = ScrapOrMoveItemsConfirmation.Show()
		
		; iConfirm == 0 ; Cancel 
		if(iConfirm == 1) ; Move Items
			iConfirm = DisplayLayerSelect(abAllowCancel = abPlayerInitiatedDeletion)
			
			; Message Entries 0 = Cancel; 1 = Default Layer
			
			if(iConfirm == 0)
				return ; Canceled
			elseif(iConfirm == 1)
				kMoveItemsToLayerRef = CurrentSettlementLayers.DefaultLayer
			else
				kMoveItemsToLayerRef = CurrentSettlementLayers.Layers[(iConfirm - 2)]
				
				if( ! kMoveItemsToLayerRef)
					; We couldn't find the layer, so just move to default layer
					kMoveItemsToLayerRef = CurrentSettlementLayers.DefaultLayer
				endif
			endif
		else ; Scrap items
			kMoveItemsToLayerRef = None
		endif		
	endif
	
	ClearLayer_Lock(akLayerRef, kMoveItemsToLayerRef)
EndFunction


Function LayerHolderDeleted(WorkshopPlus:SettlementLayers akLayerHolderRef, Bool abIntentionalDeletion = true)
	if( ! abIntentionalDeletion)
		Debug.MessageBox("An important object required by Workshop Plus was destroyed by a third party mod. Workshop Plus will attempt to recover the data. If you see this message repeatedly, you likely have a conflicting mod.")
		; Try and create a new one and pass all the data over
		if(akLayerHolderRef.iWorkshopID > -1)
			WorkshopScript thisWorkshop = ResourceManager.Workshops[akLayerHolderRef.iWorkshopID]
			
			ObjectReference kSpawnAt = SafeSpawnPoint.GetRef()
	
			if(thisWorkshop && kSpawnAt)
				WorkshopPlus:SettlementLayers kNewLayerHolder = kSpawnAt.PlaceAtMe(SettlementLayersHolderForm, abDeleteWhenAble = false) as WorkshopPlus:SettlementLayers
				
				kNewLayerHolder.DefaultLayer = akLayerHolderRef.DefaultLayer
				kNewLayerHolder.ActiveLayer = akLayerHolderRef.ActiveLayer
				kNewLayerHolder.iWorkshopID = akLayerHolderRef.iWorkshopID
				kNewLayerHolder.Layers = new WorkshopPlus:WorkshopLayer[0]
				
				int i = 0
				while(i < akLayerHolderRef.Layers.Length)
					kNewLayerHolder.Layers.Add(akLayerHolderRef.Layers[i])
					
					i += 1
				endWhile
				
				thisWorkshop.SetLinkedRef(kNewLayerHolder, LayerHolderLinkKeyword)
			endif
		endif
	endif
EndFunction


Function ClearActiveLayer()
	ModTrace("[WS Plus] ClearActiveLayer called...")
	WorkshopPlus:WorkshopLayer kMoveItemsToLayerRef = None
	
	; Prompt player and ask them to choose a layer or scrap all of the items
	AllowLayerHandlingCancellation.SetValue(1.0)
	
	int iConfirm = ScrapOrMoveItemsConfirmation.Show()
	
	; iConfirm == 0 ; Cancel 
	if(iConfirm == 1) ; Move Items
		iConfirm = DisplayLayerSelect(true)
		
		; Message Entries 0 = Cancel; 1 = Default Layer
		
		if(iConfirm == 0)
			return ; Canceled
		elseif(iConfirm == 1)
			kMoveItemsToLayerRef = CurrentSettlementLayers.DefaultLayer
		else
			kMoveItemsToLayerRef = CurrentSettlementLayers.Layers[(iConfirm - 2)]
			
			if( ! kMoveItemsToLayerRef)
				; We couldn't find the layer, so just move to default layer
				kMoveItemsToLayerRef = CurrentSettlementLayers.DefaultLayer
			endif
		endif
	else ; Scrap items
		kMoveItemsToLayerRef = None
	endif
	
	ClearLayer_Lock(CurrentSettlementLayers.ActiveLayer, kMoveItemsToLayerRef)
EndFunction


Function ClearLayer_Lock(WorkshopPlus:WorkshopLayer akLayerRef, WorkshopPlus:WorkshopLayer akMoveItemsToLayerRef = None)
	ModTrace("[WS Plus] ClearLayer: " + akLayerRef + ", Moving To: " + akMoveItemsToLayerRef)
	
	if(akLayerRef)
		int iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
	
	
		ObjectReference kNextRef = akLayerRef.kLastCreatedItem
		while(kNextRef)
			ObjectReference kThisRef = kNextRef
			kNextRef = kThisRef.GetLinkedRef(LayerItemLinkChainKeyword)
			
			kThisRef.SetLinkedRef(None, LayerItemLinkChainKeyword)
			ShaderFlashLayer.Play(kThisRef, -1.0)
			
			if(akMoveItemsToLayerRef)
				AddItemToLayer_Lock(kThisRef, akMoveItemsToLayerRef, abGetLock = false)
			else
				WorkshopPlus:Threading:Thread_ScrapWorkshopObject kThreadRef = ThreadManager.CreateThread(Thread_ScrapObject) as WorkshopPlus:Threading:Thread_ScrapWorkshopObject
				
				if(kThreadRef)
					kThreadRef.kScrapMe = kThisRef
					
					ThreadManager.QueueThread(kThreadRef)
				endif				
			endif			
		endWhile
		
		; All items removed from layer
		akLayerRef.kLastCreatedItem = None
		
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif	
EndFunction


; ---------------------------------------------
; MCM Functions - Easiest to avoid parameters for use with MCM's CallFunction, also we only want these hotkeys to work in WS mode
; ---------------------------------------------

Function Hotkey_ToggleActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	ToggleActiveLayer()
EndFunction


Function Hotkey_HideInactiveLayers()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	HideMultipleLayers_Lock(bInactiveOnly = true)
EndFunction


Function Hotkey_HideAllLayers()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	HideMultipleLayers_Lock(bInactiveOnly = false)
EndFunction

Function Hotkey_ShowAllLayers()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	ShowMultipleLayers_Lock() ; Interfacing this in case we think up more use cases
EndFunction


Function Hotkey_ToggleActiveLayerHighlighting()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	if(CurrentSettlementLayers.ActiveLayer.CurrentHighlightShader == ShaderActiveLayer)
		ClearActiveLayerHighlight()
	else
		HighlightActiveLayer(true)
	endif
EndFunction


Function Hotkey_HighlightActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	HighlightActiveLayer(false)
EndFunction


Function Hotkey_ClearActiveLayerHighlight()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	ClearActiveLayerHighlight()
EndFunction

Function Hotkey_ClearAllHighlighting()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	ClearAllHighlighting()
EndFunction

Function Hotkey_SwitchToNextLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	SwitchToNextLayer()
EndFunction

Function Hotkey_CreateNewLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	CreateNewLayer()
EndFunction


Function Hotkey_DeleteActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	DeleteActiveLayer()
EndFunction


Function Hotkey_ClearActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	ClearActiveLayer()
EndFunction