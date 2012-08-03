pace.Fonts = 
{
	VERSION >= 150 and "DermaDefault" or "DefaultSmall",
	"Default",
	"BudgetLabel",
	"DefaultsmallDropShadow",
	"DefaultBold",
	"TabLarge",
	"DefaultFixedOutline",
	"ChatFont",
	"DefaultFixedDropShadow",
	"Trebuchet18",
	"Trebuchet19",
	"UiBold",
}

pace.ShadowedFonts = 
{
	["BudgetLabel"] = true,
	["DefaultsmallDropShadow"] = true,
	["TabLarge"] = true,
	["DefaultFixedOutline"] = true,
	["ChatFont"] = true,
	["DefaultFixedDropShadow"] = true,
}


if VERSION >= 150 then
	pace.PartIcons =
	{
		text = "icon16/text_align_center.png",
		bone = "widgets/bone_small.png",
		clip = "icon16/cut.png",
		light = "icon16/lightbulb.png",
		sprite = "icon16/layers.png",
		bone = "icon16/connect.png",
		effect = "icon16/wand.png",
		model = "icon16/shape_square.png",
		animation = "icon16/eye.png",
		entity = "icon16/brick.png",
		group = "icon16/world.png",
		trail = "icon16/arrow_undo.png",
		event = "icon16/clock.png",
		sunbeams = "icon16/sun.png",
		sound = "icon16/sound.png",
		command = "icon16/application_xp_terminal.png",
	}
else
	pace.PartIcons =
	{
		text = "gui/silkicons/page",
		bone = "gui/silkicons/anchor",
		light = "gui/silkicons/star",
	}
end

pace.PropertyOrder =
{
	"Name",
	"Description",
	"Hide",
	"ParentName",
	"WeaponClass",
	"HideWeaponClass",
	"Bone",
	"BoneMerge",
	"BoneMergeAlternative",
	"OriginFix",
	"Position",
	"Angles",
	"AngleVelocity",
	"ModifyAngles",
	"Size",
	"Scale",
	"Material",
	"TrailPath",
	"Color",
	"StartColor",
	"EndColor",
	"Brightness",
	"Alpha",
	"StartAlpha",
	"EndAlpha",
	"Min",
	"Max",
	"Loop",
	"PingPongLoop",
}