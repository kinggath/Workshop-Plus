Scriptname WorkshopPlus:LayerControlModule_Open extends activemagiceffect

WorkshopPlus:LayerManager Property LayerManager Auto Const Mandatory
Potion Property ControlModule Auto Const Mandatory

Event OnEffectStart(Actor akTarget, Actor akCaster)
	Game.GetPlayer().AddItem(ControlModule, abSilent = true)
	
	LayerManager.ShowControlMenu()
EndEvent