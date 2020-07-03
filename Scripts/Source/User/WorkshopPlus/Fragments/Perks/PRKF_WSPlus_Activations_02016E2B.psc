;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname WorkshopPlus:Fragments:Perks:PRKF_WSPlus_Activations_02016E2B Extends Perk Hidden Const

;BEGIN FRAGMENT Fragment_Entry_00
Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
;BEGIN CODE
MainQuest.TrackItems(akTargetRef as Actor)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Entry_01
Function Fragment_Entry_01(ObjectReference akTargetRef, Actor akActor)
;BEGIN CODE
MainQuest.TrackOwner(akTargetRef)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

WorkshopPlus:MainQuest Property MainQuest Auto Const Mandatory
