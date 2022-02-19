local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "info"

PART.Group = ''
PART.Icon = 'icon16/help.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("SpawnEntity", "")
	BUILDER:GetSet("UserData", "")
BUILDER:EndStorableVars()