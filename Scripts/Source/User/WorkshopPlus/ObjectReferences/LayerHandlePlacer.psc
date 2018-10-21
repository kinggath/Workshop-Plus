; ---------------------------------------------
; WorkshopPlus:ObjectReferences:LayerHandlePlacer.psc - by kinggath
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

Scriptname WorkshopPlus:ObjectReferences:LayerHandlePlacer extends ObjectReference Const
{ Places the layer handle corresponding to the current layer, and then self-destructs }


import WorkshopFramework:WorkshopFunctions

Form[] Property LayerHandlerForms Auto Const Mandatory
WorkshopPlus:LayerManager Property LayerManager Auto Const Mandatory
Keyword Property WorkshopItemKeyword Auto Const Mandatory
Message Property DefaultLayerWarningConfirm Auto Const Mandatory

Event OnInit()
	WorkshopPlus:SettlementLayers thisSettlementLayers = LayerManager.GetCurrentSettlementLayers()	
	
	int iIndex = thisSettlementLayers.Layers.Find(thisSettlementLayers.ActiveLayer)
	ObjectReference kHandle
	
	if(iIndex < 0)
		iIndex = 0
		
		kHandle = thisSettlementLayers.DefaultLayer.LayerHandle
	else
		kHandle = thisSettlementLayers.Layers[iIndex].LayerHandle
		
		iIndex += 1
	endif
	
	if( ! kHandle)
		bool bCreateHandle = true
		if(iIndex == 0)
			Int iConfirm = DefaultLayerWarningConfirm.Show()
			
			if(iConfirm == 0)
				bCreateHandle = false
			endif
		endif
		
		if(bCreateHandle)
			kHandle = PlaceAtMe(LayerHandlerForms[iIndex], abInitiallyDisabled = true, abDeleteWhenAble = false)
			kHandle.SetLinkedRef(GetNearestWorkshop(Self), WorkshopItemKeyword)
			kHandle.Enable(false)
		endif
	else ; Bring the existing handle over to the player
		kHandle.MoveTo(Self)
		WorkshopPlus:ObjectReferences:LayerHandle asHandle = kHandle as WorkshopPlus:ObjectReferences:LayerHandle
		
		if(asHandle)
			asHandle.kControlledRef.MoveTo(kHandle)
			if(asHandle.fLinkRadius <= 0)
				asHandle.AttachObjects() ; Attach any new objects on the layer
			endif
		endif
	endif
	
	Disable(false)
	Delete()
EndEvent