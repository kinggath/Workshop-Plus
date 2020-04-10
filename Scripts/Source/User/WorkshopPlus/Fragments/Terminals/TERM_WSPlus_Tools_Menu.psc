;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopPlus:Fragments:Terminals:TERM_WSPlus_Tools_Menu Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
LayerManager.RemoveAllLayers()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
WorkshopScript kThisWorkshop = WorkshopFramework:WSFW_API.GetNearestWorkshop(Game.GetPlayer())

if(kThisWorkshop != None)
WSPlusMain.ToggleFreeBuildMode(kThisWorkshop, abEnableFreeBuild = true)
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
WorkshopScript kThisWorkshop = WorkshopFramework:WSFW_API.GetNearestWorkshop(Game.GetPlayer())

if(kThisWorkshop != None)
WSPlusMain.ToggleFreeBuildMode(kThisWorkshop, abEnableFreeBuild = false)
endif
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
Utility.Wait(0.1)
LayerManager.BreakInfiniteLinkedLayers(abTriggeredManually = true)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

WorkshopPlus:LayerManager Property LayerManager Auto Const Mandatory
WorkshopPlus:MainQuest Property WSPlusMain Auto Const Mandatory
