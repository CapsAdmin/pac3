local PART = {}

PART.ClassName = "info"
PART.NonPhysical = true
PART.Group = ''
PART.Icon = 'icon16/help.png'

pac.StartStorableVars()
	pac.GetSet(PART, "SpawnEntity", "")
	pac.GetSet(PART, "UserData", "")
pac.EndStorableVars()