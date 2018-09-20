Scriptname WorkshopPlus:DataStructures Hidden Const

Struct BuildAction
	Int iAction
	
	ObjectReference ObjectRef
	Form BaseObject
	Int iWorkshopID
	
	Float posX
	Float posY
	Float posZ
	Float angX
	Float angY
	Float angZ
	Float fScale
		
	Float lastPosX
	Float lastPosY
	Float lastPosZ
	Float lastAngX
	Float lastAngY
	Float lastAngZ
	Float lastfScale
EndStruct


Struct ArraySlot
	Int iArrayNum = -1
	Int iIndex = -1
EndStruct