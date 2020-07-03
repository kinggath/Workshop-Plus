;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopPlus:Fragments:Terminals:TERM_WSPlus_ActivationOption_02016E30 Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
WSPlus_AlternateActivation_TrackItems.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
WSPlus_AlternateActivation_TrackItems.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
WSPlus_AlternateActivation_TrackOwner.SetValueInt(0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
WSPlus_AlternateActivation_TrackOwner.SetValueInt(1)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
GlobalVariable Property WSPlus_AlternateActivation_TrackItems Auto Const Mandatory
GlobalVariable Property WSPlus_AlternateActivation_TrackOwner Auto Const Mandatory
