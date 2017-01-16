pace.example_outfits = {}
--pace.example_outfits[""] = {}
pace.example_outfits["projectile gun advanced"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["ClassName"] = "model",
				["Position"] = Vector(21.794189453125, -0.0023193359375, 31.116744995117),
				["Model"] = "models/props_combine/combine_barricade_short01a.mdl",
				["Bone"] = "None",
				["Name"] = "Stand",
				["UniqueID"] = "3327276730",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "501117373",
								["Delay"] = 0.3,
								["Physical"] = true,
								["Name"] = "Multiple projectiles can be shot at once",
								["Sticky"] = true,
								["ClassName"] = "projectile",
								["Spread"] = 0.05,
								["OutfitPartUID"] = "2361506147",
								["OutfitPartName"] = "Fire",
								["EditorExpand"] = true,
								["Gravity"] = false,
							},
						},
						[2] = {
							["children"] = {
								[1] = {
									["children"] = {
									},
									["self"] = {
										["Effect"] = "muzzle_minigun",
										["ClassName"] = "effect",
										["UniqueID"] = "643206501",
										["Rate"] = 0.1,
									},
								},
							},
							["self"] = {
								["Alpha"] = 0,
								["ClassName"] = "model",
								["Position"] = Vector(35.404052734375, -0.00048828125, 0),
								["Model"] = "models/pac/default.mdl",
								["EditorExpand"] = true,
								["Name"] = "Muzzle effects",
								["UniqueID"] = "2824542135",
							},
						},
						[3] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "event",
								["UniqueID"] = "68147785",
								["Event"] = "animation_event",
								["Arguments"] = "attack primary",
								["Name"] = "Projectiles are tirggered by events",
								["Invert"] = true,
							},
						},
						[4] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "2520114528",
								["Delay"] = 0.2,
								["Physical"] = true,
								["Name"] = "Mass and speed controls damage",
								["Sticky"] = true,
								["ClassName"] = "projectile",
								["Spread"] = 0.05,
								["OutfitPartUID"] = "2361506147",
								["OutfitPartName"] = "Fire",
								["EditorExpand"] = true,
								["Gravity"] = false,
							},
						},
						[5] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "1069681707",
								["Physical"] = true,
								["Name"] = "Delay adds a delay to the shot.",
								["Sticky"] = true,
								["ClassName"] = "projectile",
								["OutfitPartUID"] = "2361506147",
								["OutfitPartName"] = "Fire",
								["EditorExpand"] = true,
								["Gravity"] = false,
							},
						},
					},
					["self"] = {
						["Alpha"] = 0,
						["ClassName"] = "model",
						["UniqueID"] = "2557787785",
						["Model"] = "models/pac/default.mdl",
						["Name"] = "Physical tickbox makes them kill",
						["EditorExpand"] = true,
					},
				},
			},
			["self"] = {
				["Model"] = "models/airboatgun.mdl",
				["ClassName"] = "model",
				["Position"] = Vector(18.18505859375, 31.786865234375, 45.897933959961),
				["EditorExpand"] = true,
				["UniqueID"] = "2818191603",
				["Bone"] = "None",
				["Name"] = "This gun aims with eye angles",
				["EyeAngles"] = true,
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "2370197831",
		["ClassName"] = "group",
		["Name"] = "The gun",
		["Description"] = "add parts to me!",
	},
},
[2] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "sound",
								["UniqueID"] = "162303831",
								["SoundLevel"] = 70,
								["Sound"] = "weapons/diamond_back_01.wav",
								["MaxPitch"] = 110,
								["Name"] = "They can include sounds",
								["MinPitch"] = 90,
							},
						},
						[2] = {
							["children"] = {
								[1] = {
									["children"] = {
										[1] = {
											["children"] = {
											},
											["self"] = {
												["EditorExpand"] = true,
												["UniqueID"] = "1837104160",
												["Rate"] = 0.5,
												["Effect"] = "taunt_pyro_balloon_explosion",
												["ClassName"] = "effect",
											},
										},
										[2] = {
											["children"] = {
											},
											["self"] = {
												["ClassName"] = "sound",
												["UniqueID"] = "1017367923",
												["SoundLevel"] = 70,
												["Pitch"] = 0.5,
												["Sound"] = "weapons/air_burster_explode2.wav",
											},
										},
									},
									["self"] = {
										["AffectChildrenOnly"] = true,
										["Invert"] = true,
										["Name"] = "is ranger below 5?",
										["ClassName"] = "event",
										["UniqueID"] = "3181550699",
										["RootOwner"] = false,
										["EditorExpand"] = true,
										["Operator"] = "below",
										["Arguments"] = "5@@10",
										["Event"] = "ranger",
									},
								},
							},
							["self"] = {
								["Alpha"] = 0,
								["ClassName"] = "model",
								["UniqueID"] = "1704152275",
								["Model"] = "models/pac/default.mdl",
								["Name"] = "Projectiles can have events too",
								["EditorExpand"] = true,
							},
						},
					},
					["self"] = {
						["EditorExpand"] = true,
						["UniqueID"] = "1874802794",
						["Model"] = "models/Items/AR2_Grenade.mdl",
						["Name"] = "Projectile models can be anything you want.",
						["ClassName"] = "model",
					},
				},
			},
			["self"] = {
				["Name"] = "Fire",
				["ClassName"] = "group",
				["UniqueID"] = "2361506147",
				["EditorExpand"] = true,
			},
		},
	},
	["self"] = {
		["ClassName"] = "group",
		["UniqueID"] = "448539766",
		["Hide"] = true,
		["Name"] = "The projectile itself. Must be in a group within a group",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["projectile gun"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["StartColor"] = Vector(255, 93, 0),
								["ClassName"] = "trail",
								["UniqueID"] = "883293869",
								["Name"] = "Trails and effects can bug, but are mostly stable.",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "sound",
								["UniqueID"] = "162303831",
								["SoundLevel"] = 70,
								["Name"] = "They can include sounds",
								["Sound"] = "weapons/diamond_back_01.wav",
							},
						},
					},
					["self"] = {
						["EditorExpand"] = true,
						["UniqueID"] = "1874802794",
						["Model"] = "models/Items/AR2_Grenade.mdl",
						["Name"] = "Projectile models can be anything you want.",
						["ClassName"] = "model",
					},
				},
			},
			["self"] = {
				["Name"] = "Fire",
				["ClassName"] = "group",
				["UniqueID"] = "2361506147",
				["EditorExpand"] = true,
			},
		},
	},
	["self"] = {
		["ClassName"] = "group",
		["UniqueID"] = "448539766",
		["Hide"] = true,
		["Name"] = "The projectile itself. Must be in a group within a group",
		["EditorExpand"] = true,
	},
},
[2] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Arguments"] = "attack primary",
								["UniqueID"] = "68147785",
								["Event"] = "animation_event",
								["Name"] = "Projectiles are tirggered by events",
								["ClassName"] = "event",
							},
						},
					},
					["self"] = {
						["EditorExpand"] = true,
						["ClassName"] = "projectile",
						["UniqueID"] = "501117373",
						["Sticky"] = true,
						["OutfitPartUID"] = "2361506147",
						["OutfitPartName"] = "Fire",
						["Name"] = "In outfit name, put fire.",
						["Gravity"] = false,
					},
				},
			},
			["self"] = {
				["Model"] = "models/airboatgun.mdl",
				["ClassName"] = "model",
				["Position"] = Vector(-0.000732421875, 31.787841796875, 50.024978637695),
				["EditorExpand"] = true,
				["UniqueID"] = "2818191603",
				["Bone"] = "None",
				["Name"] = "This gun aims with eye angles",
				["EyeAngles"] = true,
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "2370197831",
		["ClassName"] = "group",
		["Name"] = "The gun",
		["Description"] = "add parts to me!",
	},
},
}

pace.example_outfits["custom death animations"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["DrawPlayerOnDeath"] = true,
				["ClassName"] = "entity",
				["UniqueID"] = "672119311",
				["HideRagdollOnDeath"] = true,
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "animation",
						["UniqueID"] = "1613280023",
						["SequenceName"] = "death_01;death_02;death_03;death_04",
						["ResetOnHide"] = false,
						["OwnerCycle"] = true,
					},
				},
			},
			["self"] = {
				["AffectChildrenOnly"] = true,
				["ClassName"] = "event",
				["UniqueID"] = "3013021887",
				["Event"] = "owner_alive",
				["EditorExpand"] = true,
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "1026455901",
		["ClassName"] = "group",
		["Name"] = "custom death animation",
		["Description"] = "add parts to me!",
	},
},
}

pace.example_outfits["hitpos and second head"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
								[1] = {
									["children"] = {
										[1] = {
											["children"] = {
											},
											["self"] = {
												["EndPointName"] = "Rope for effect",
												["ClassName"] = "beam",
												["Frequency"] = 4.1,
												["UniqueID"] = "1053510544",
												["WidthBend"] = 0.1,
												["Bend"] = -1.1,
												["EndPointUID"] = "2358293445",
												["Position"] = Vector(0.00634765625, -0.000732421875, -20.6767578125),
											},
										},
									},
									["self"] = {
										["Alpha"] = 0,
										["ClassName"] = "model",
										["Position"] = Vector(0.00048828125, -0.0013427734375, 0.46875),
										["Model"] = "models/pac/default.mdl",
										["EditorExpand"] = true,
										["Name"] = "Rope for effect",
										["UniqueID"] = "2358293445",
									},
								},
							},
							["self"] = {
								["ClassName"] = "model",
								["UniqueID"] = "3252937828",
								["AimPartUID"] = "24880209",
								["Model"] = "models/maxofs2d/balloon_gman.mdl",
								["EditorExpand"] = true,
								["Name"] = "This aims at the hitpos model.",
								["AimPartName"] = "The model. The head aims at this.",
							},
						},
					},
					["self"] = {
						["ClassName"] = "jiggle",
						["UniqueID"] = "2245707605",
						["EditorExpand"] = true,
						["Bone"] = "invalidbone",
						["Name"] = "Makes the head float behind.",
						["Position"] = Vector(-0.001953125, -25.370361328125, 56.828125),
					},
				},
			},
			["self"] = {
				["Name"] = "The Head",
				["ClassName"] = "group",
				["UniqueID"] = "2053457589",
				["EditorExpand"] = true,
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
								[1] = {
									["children"] = {
									},
									["self"] = {
										["ClassName"] = "event",
										["UniqueID"] = "3899494357",
										["Event"] = "animation_event",
										["Arguments"] = "attack primary",
										["Invert"] = true,
									},
								},
								[2] = {
									["children"] = {
									},
									["self"] = {
										["Effect"] = "manmelter_impact_flare",
										["ClassName"] = "effect",
										["UniqueID"] = "3223733502",
										["Rate"] = 0.1,
									},
								},
							},
							["self"] = {
								["Alpha"] = 0,
								["ClassName"] = "model",
								["UniqueID"] = "1169353982",
								["Model"] = "models/pac/default.mdl",
								["Name"] = "The effects",
								["EditorExpand"] = true,
							},
						},
					},
					["self"] = {
						["UniqueID"] = "24880209",
						["Name"] = "The model. The head aims at this.",
						["Alpha"] = 0.725,
						["ClassName"] = "model",
						["Size"] = 0.2,
						["Color"] = Vector(255, 0, 0),
						["Bone"] = "hitpos",
						["Model"] = "models/pac/default.mdl",
						["EditorExpand"] = true,
					},
				},
			},
			["self"] = {
				["Name"] = "The hitpos. This is always where you aim.",
				["ClassName"] = "group",
				["UniqueID"] = "3768347404",
				["EditorExpand"] = true,
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "860513635",
		["ClassName"] = "group",
		["Name"] = "Second Head & Hitpos effects",
		["Description"] = "add parts to me!",
	},
},
}

pace.example_outfits["chell engineer"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["Size"] = 19,
						["Bone"] = "neck",
						["UniqueID"] = "2923654610",
						["ClassName"] = "bone",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["Size"] = 16,
						["EditorExpand"] = true,
						["UniqueID"] = "339941070",
						["ClassName"] = "bone",
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["Size"] = 11,
						["Bone"] = "hair 2",
						["UniqueID"] = "991205961",
						["ClassName"] = "bone",
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "849112520",
						["Bone"] = "right upperarm",
						["Size"] = 14,
						["ScaleChildren"] = true,
					},
				},
				[5] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "3892714567",
						["Bone"] = "left upperarm",
						["Size"] = 14,
						["ScaleChildren"] = true,
					},
				},
				[6] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(0, -180, 0),
						["UniqueID"] = "974942078",
						["Bone"] = "hair 1",
						["Size"] = 18,
						["ClassName"] = "bone",
					},
				},
			},
			["self"] = {
				["BoneMerge"] = true,
				["ClassName"] = "model",
				["Size"] = 0.065,
				["UniqueID"] = "75544955",
				["Model"] = "models/player/p2_chell.mdl",
				["EditorExpand"] = true,
			},
		},
		[2] = {
			["children"] = {
			},
			["self"] = {
				["Alpha"] = 0,
				["ClassName"] = "entity",
				["UniqueID"] = "1800887009",
				["Model"] = "mossman",
			},
		},
		[3] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(6, 0, 4),
						["UniqueID"] = "2495951518",
						["Size"] = 0,
						["Bone"] = "pelvis",
						["Name"] = "pouch",
						["Angles"] = Angle(125, 181, -180),
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(-90, 90, 0),
						["Size"] = 0,
						["UniqueID"] = "3325314793",
						["Bone"] = "spine 2",
						["Name"] = "spine 2",
						["ClassName"] = "model",
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(0, 0, 90),
						["Size"] = 0,
						["UniqueID"] = "1743724022",
						["Bone"] = "left forearm",
						["Name"] = "left forearm",
						["ClassName"] = "model",
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Size"] = 0,
						["Bone"] = "right toe",
						["Name"] = "right toe",
						["UniqueID"] = "1558353985",
					},
				},
				[5] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(-5.8302612304688, -3.0517578125e-005, 0.0001220703125),
						["UniqueID"] = "2641027949",
						["Bone"] = "pelvis",
						["Name"] = "cable",
						["Size"] = 0,
					},
				},
				[6] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(0, 0, -1),
						["UniqueID"] = "1178597367",
						["Size"] = 0,
						["Bone"] = "left thigh",
						["Name"] = "left thigh",
						["Angles"] = Angle(0, 0, 90),
					},
				},
				[7] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(-1, -1, 0),
						["UniqueID"] = "2345204986",
						["Size"] = 0,
						["Bone"] = "right foot",
						["Name"] = "right foot",
						["Angles"] = Angle(-89.96875, -74.78125, 0),
					},
				},
				[8] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(90, 90, 0),
						["Position"] = Vector(-1, 0, 0),
						["UniqueID"] = "307376686",
						["Size"] = 0,
						["Name"] = "eng head",
						["ClassName"] = "model",
					},
				},
				[9] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(1, 0, 0),
						["UniqueID"] = "1768170218",
						["Size"] = 0,
						["Bone"] = "neck",
						["Name"] = "eng neck",
						["Angles"] = Angle(45, 135, 45),
					},
				},
				[10] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Size"] = 0,
						["Bone"] = "spine",
						["Name"] = "spine",
						["UniqueID"] = "3323129991",
					},
				},
				[11] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(0, 0, 1),
						["UniqueID"] = "4007183121",
						["Size"] = 0,
						["Bone"] = "right thigh",
						["Name"] = "right thigh",
						["Angles"] = Angle(0, 0, 90),
					},
				},
				[12] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(-2, -1, 1),
						["UniqueID"] = "1836681915",
						["Bone"] = "right forearm",
						["Name"] = "right forearm 2",
						["Size"] = 0,
					},
				},
				[13] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Size"] = 0,
						["Bone"] = "right forearm",
						["Name"] = "right forearm",
						["UniqueID"] = "3027505941",
					},
				},
				[14] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(0, 0, 90),
						["Size"] = 0,
						["UniqueID"] = "2304756006",
						["Bone"] = "left calf",
						["Name"] = "left calf",
						["ClassName"] = "model",
					},
				},
				[15] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(-4.2017974853516, 0.26244354248047, 4.8128662109375),
						["UniqueID"] = "2679756814",
						["Size"] = 0,
						["Bone"] = "pelvis",
						["Name"] = "case",
						["Angles"] = Angle(-50.6875, 0, 0),
					},
				},
				[16] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(0, 90, 0),
						["Size"] = 0,
						["UniqueID"] = "2960033445",
						["Bone"] = "left clavicle",
						["Name"] = "left clavicle",
						["ClassName"] = "model",
					},
				},
				[17] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(0, 90, 0),
						["Size"] = 0,
						["UniqueID"] = "4103624534",
						["Bone"] = "left hand",
						["Name"] = "left hand",
						["ClassName"] = "model",
					},
				},
				[18] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(0, 0, -1),
						["UniqueID"] = "1678182360",
						["Size"] = 0,
						["Bone"] = "pelvis",
						["Name"] = "pelvis aaa",
						["Angles"] = Angle(0, 0, 180),
					},
				},
				[19] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(0, -0.5, 1),
						["UniqueID"] = "4070004939",
						["Size"] = 0,
						["Bone"] = "right upperarm",
						["Name"] = "right upperarm",
						["Angles"] = Angle(0, 0, -45),
					},
				},
				[20] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(0, 0, 90),
						["Size"] = 0,
						["UniqueID"] = "2929592770",
						["Bone"] = "right calf",
						["Name"] = "right calf",
						["ClassName"] = "model",
					},
				},
				[21] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(-2, -1, 1),
						["UniqueID"] = "2884787364",
						["Bone"] = "left forearm",
						["Name"] = "left forearm 2",
						["Size"] = 0,
					},
				},
				[22] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Size"] = 0,
						["Bone"] = "left toe",
						["Name"] = "left toe",
						["UniqueID"] = "1681786408",
					},
				},
				[23] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(0, -90, 0),
						["Size"] = 0,
						["UniqueID"] = "1731261432",
						["Bone"] = "right hand",
						["Name"] = "right hand",
						["ClassName"] = "model",
					},
				},
				[24] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(-90, 90, 0),
						["Size"] = 0,
						["UniqueID"] = "822048986",
						["Bone"] = "spine 4",
						["Name"] = "spine 4",
						["ClassName"] = "model",
					},
				},
				[25] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(-1, -1, 0),
						["UniqueID"] = "2984162826",
						["Size"] = 0,
						["Bone"] = "left foot",
						["Name"] = "left foot",
						["Angles"] = Angle(-89.96875, 105.0625, 0),
					},
				},
				[26] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(-90, 90, 0),
						["Size"] = 0,
						["UniqueID"] = "328058315",
						["Bone"] = "spine 1",
						["Name"] = "spine 1",
						["ClassName"] = "model",
					},
				},
				[27] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(0, -90, 0),
						["Size"] = 0,
						["UniqueID"] = "2740657678",
						["Bone"] = "right clavicle",
						["Name"] = "right clavicle",
						["ClassName"] = "model",
					},
				},
				[28] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["Position"] = Vector(0, -0.5, -1),
						["UniqueID"] = "1017765576",
						["Size"] = 0,
						["Bone"] = "left upperarm",
						["Name"] = "left upperarm",
						["Angles"] = Angle(0, 0, -135),
					},
				},
				[29] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["UniqueID"] = "3287122655",
								["Size"] = 0.6,
								["FollowPartUID"] = "3323129991",
								["Hide"] = true,
								["Name"] = "bip spine",
								["Bone"] = "bip spine",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["AlternativeBones"] = true,
								["FollowPartName"] = "left forearm 2",
								["MoveChildrenToOrigin"] = true,
								["Size"] = 0,
								["ClassName"] = "bone",
								["FollowPartUID"] = "2884787364",
								["Bone"] = "bip lowerarm left",
								["UniqueID"] = "446153236",
								["ScaleChildren"] = true,
							},
						},
						[3] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["UniqueID"] = "743934821",
								["Angles"] = Angle(0, 90, -90),
								["FollowPartName"] = "right toe",
								["Bone"] = "bip toe right",
								["Name"] = "bip toe right",
								["FollowPartUID"] = "1558353985",
							},
						},
						[4] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["UniqueID"] = "2722274794",
								["Size"] = 0.8,
								["FollowPartName"] = "spine 4",
								["Bone"] = "bip spine  3",
								["Name"] = "bip spine  3",
								["FollowPartUID"] = "822048986",
							},
						},
						[5] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["UniqueID"] = "2340277211",
								["Size"] = 0.6,
								["FollowPartName"] = "left clavicle",
								["Bone"] = "bip collar left",
								["Name"] = "bip collar left",
								["FollowPartUID"] = "2960033445",
							},
						},
						[6] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "1526595101",
								["FollowPartName"] = "spine 4",
								["Name"] = "bip spine  2",
								["Scale"] = Vector(0.62000000476837, 1, 1),
								["ClassName"] = "bone",
								["Size"] = 0.75,
								["FollowPartUID"] = "822048986",
								["Bone"] = "bip spine  2",
								["Translucent"] = true,
								["Position"] = Vector(0, 0, -2),
							},
						},
						[7] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "1739212823",
								["FollowPartName"] = "left calf",
								["Name"] = "bip knee left",
								["Scale"] = Vector(1.3999999761581, 1, 1),
								["ClassName"] = "bone",
								["Size"] = 0.8,
								["FollowPartUID"] = "2304756006",
								["Bone"] = "bip knee left",
								["Translucent"] = true,
							},
						},
						[8] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "bone",
								["UniqueID"] = "644745846",
								["Translucent"] = true,
								["FollowPartName"] = "eng head",
								["Bone"] = "bip head",
								["Name"] = "bip head 2",
								["FollowPartUID"] = "307376686",
							},
						},
						[9] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["UniqueID"] = "3817450885",
								["Angles"] = Angle(0, 90, 90),
								["FollowPartName"] = "left toe",
								["Bone"] = "bip toe left",
								["Name"] = "bip toe left",
								["FollowPartUID"] = "1681786408",
							},
						},
						[10] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["Position"] = Vector(0, 0, 2),
								["Size"] = 0,
								["FollowPartUID"] = "3646956450",
								["Bone"] = "bip head",
								["Name"] = "bip head",
								["UniqueID"] = "2792730236",
							},
						},
						[11] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "bone",
								["UniqueID"] = "1011541059",
								["Translucent"] = true,
								["FollowPartName"] = "left thigh",
								["Bone"] = "bip hip left",
								["Name"] = "bip hip left",
								["FollowPartUID"] = "1178597367",
							},
						},
						[12] = {
							["children"] = {
							},
							["self"] = {
								["AlternativeBones"] = true,
								["FollowPartName"] = "right forearm 2",
								["MoveChildrenToOrigin"] = true,
								["Size"] = 0,
								["ClassName"] = "bone",
								["FollowPartUID"] = "1836681915",
								["Bone"] = "bip lowerarm right",
								["UniqueID"] = "2919943281",
								["ScaleChildren"] = true,
							},
						},
						[13] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["UniqueID"] = "2531499474",
								["Size"] = 0.525,
								["FollowPartName"] = "eng neck",
								["Bone"] = "bip neck",
								["Name"] = "bip neck",
								["FollowPartUID"] = "1768170218",
							},
						},
						[14] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "3601652359",
								["FollowPartName"] = "right calf",
								["Name"] = "bip knee right",
								["Scale"] = Vector(1.5, 1, 1),
								["ClassName"] = "bone",
								["Size"] = 0.7,
								["FollowPartUID"] = "2929592770",
								["Bone"] = "bip knee right",
								["Translucent"] = true,
							},
						},
						[15] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["UniqueID"] = "716401665",
								["Size"] = 0.8,
								["FollowPartName"] = "pelvis aaa",
								["Bone"] = "bip pelvis",
								["Name"] = "bip pelvis",
								["FollowPartUID"] = "1678182360",
							},
						},
						[16] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "bone",
								["UniqueID"] = "1339471438",
								["Translucent"] = true,
								["FollowPartName"] = "left foot",
								["Bone"] = "bip foot left",
								["Name"] = "bip foot left",
								["FollowPartUID"] = "2984162826",
							},
						},
						[17] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "bone",
								["UniqueID"] = "1716292165",
								["Translucent"] = true,
								["FollowPartName"] = "right thigh",
								["Bone"] = "bip hip right",
								["Name"] = "bip hip right",
								["FollowPartUID"] = "4007183121",
							},
						},
						[18] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["UniqueID"] = "2974320077",
								["Size"] = 0.6,
								["FollowPartName"] = "spine 2",
								["Bone"] = "bip spine  1",
								["Name"] = "bip spine  1",
								["FollowPartUID"] = "3325314793",
							},
						},
						[19] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "bone",
								["UniqueID"] = "2345144303",
								["Translucent"] = true,
								["FollowPartName"] = "right foot",
								["Bone"] = "bip foot right",
								["Name"] = "bip foot right",
								["FollowPartUID"] = "2345204986",
							},
						},
						[20] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "bone",
								["UniqueID"] = "3582762322",
								["Translucent"] = true,
								["FollowPartName"] = "left upperarm",
								["Bone"] = "bip upperarm left",
								["Name"] = "bip upperarm left",
								["FollowPartUID"] = "1017765576",
							},
						},
						[21] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["UniqueID"] = "1956028592",
								["Size"] = 0.6,
								["FollowPartName"] = "right clavicle",
								["Bone"] = "bip collar right",
								["Name"] = "bip collar right",
								["FollowPartUID"] = "2740657678",
							},
						},
						[22] = {
							["children"] = {
							},
							["self"] = {
								["Translucent"] = true,
								["ClassName"] = "bone",
								["UniqueID"] = "3895044508",
								["Size"] = 0.6,
								["FollowPartName"] = "spine 1",
								["Bone"] = "bip spine  0",
								["Name"] = "bip spine  0",
								["FollowPartUID"] = "328058315",
							},
						},
						[23] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "bone",
								["UniqueID"] = "1461978598",
								["Translucent"] = true,
								["FollowPartName"] = "right upperarm",
								["Bone"] = "bip upperarm right",
								["Name"] = "bip upperarm right",
								["FollowPartUID"] = "4070004939",
							},
						},
						[24] = {
							["children"] = {
								[1] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "1822660892",
										["FollowPartName"] = "cable",
										["Name"] = "prp cord",
										["EditorExpand"] = true,
										["Angles"] = Angle(0, 90, 0),
										["FollowPartUID"] = "2641027949",
										["Bone"] = "prp cord",
										["Translucent"] = true,
										["ClassName"] = "bone",
									},
								},
								[2] = {
									["children"] = {
									},
									["self"] = {
										["Translucent"] = true,
										["ClassName"] = "bone",
										["UniqueID"] = "3235248178",
										["EditorExpand"] = true,
										["FollowPartName"] = "case",
										["Bone"] = "prp pouch",
										["Name"] = "prp pouch",
										["FollowPartUID"] = "2679756814",
									},
								},
								[3] = {
									["children"] = {
									},
									["self"] = {
										["ClassName"] = "bone",
										["UniqueID"] = "2931251135",
										["Translucent"] = true,
										["FollowPartUID"] = "876700782",
										["Bone"] = "prp helmet",
										["Name"] = "prp helmet",
										["Size"] = 0,
									},
								},
								[4] = {
									["children"] = {
									},
									["self"] = {
										["ClassName"] = "bone",
										["UniqueID"] = "1825103941",
										["Translucent"] = true,
										["FollowPartName"] = "pouch",
										["Bone"] = "prp legpouch",
										["Name"] = "prp legpouch",
										["FollowPartUID"] = "2495951518",
									},
								},
							},
							["self"] = {
								["ClassName"] = "group",
								["UniqueID"] = "59992070",
								["EditorExpand"] = true,
							},
						},
					},
					["self"] = {
						["UniqueID"] = "3522381108",
						["ClassName"] = "model",
						["Size"] = 0.88,
						["Model"] = "models/player/engineer.mdl",
						["EditorExpand"] = true,
						["Bone"] = "NONE",
						["Name"] = "tf2",
						["DrawOrder"] = 2,
					},
				},
			},
			["self"] = {
				["EditorExpand"] = true,
				["UniqueID"] = "2495494298",
				["ClassName"] = "group",
				["Name"] = "tf2 bones",
				["DrawOrder"] = 9,
			},
		},
	},
	["self"] = {
		["Name"] = "chell engineer",
		["ClassName"] = "group",
		["UniqueID"] = "3325156525",
		["EditorExpand"] = true,
	},
},
}

pace.example_outfits["skis"] = {
["children"] = {
	[1] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["Event"] = "speed",
					["Invert"] = true,
					["Operator"] = "above",
					["UniqueID"] = "3385628781",
					["ClassName"] = "event",
				},
			},
		},
		["self"] = {
			["ClassName"] = "sound",
			["UniqueID"] = "757087059",
			["Pitch"] = 0.988,
			["Volume"] = 0.075,
			["Sound"] = "physics/cardboard/cardboard_box_scrape_smooth_loop1.wav",
		},
	},
	[2] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["ClassName"] = "holdtype",
					["UniqueID"] = "3691453799",
					["Fallback"] = "idle_dual",
				},
			},
		},
		["self"] = {
			["Angles"] = Angle(89.53125, 90, 90),
			["Position"] = Vector(3.0205078125, -0.3251953125, -34.953125),
			["UniqueID"] = "2643199443",
			["Size"] = 0.75,
			["Bone"] = "left hand",
			["Model"] = "models/props_junk/harpoon002a.mdl",
			["ClassName"] = "model",
		},
	},
	[3] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["ClassName"] = "model",
					["Size"] = 0,
					["UniqueID"] = "4216593801",
					["Model"] = "models/pac/default.mdl",
					["Name"] = "ski ang",
					["EditorExpand"] = true,
				},
			},
		},
		["self"] = {
			["StopRadius"] = 12.7,
			["ClassName"] = "jiggle",
			["UniqueID"] = "1412949239",
			["Bone"] = "none",
		},
	},
	[4] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["Expression"] = "200 + abs(sin(time()*4)*200)",
					["ClassName"] = "proxy",
					["UniqueID"] = "2683052730",
					["VariableName"] = "SprintSpeed",
				},
			},
		},
		["self"] = {
			["ClassName"] = "entity",
			["UniqueID"] = "833317075",
			["SprintSpeed"] = 348.99995660026,
			["WalkSpeed"] = 311.34908096117,
			["MuteFootsteps"] = true,
		},
	},
	[5] = {
		["children"] = {
			[1] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["ZeroEyePitch"] = true,
							["UniqueID"] = "1787959610",
							["Expression"] = "0,0,owner_velocity_right()*-5",
							["RootOwner"] = true,
							["ClassName"] = "proxy",
							["VariableName"] = "Angles",
						},
					},
				},
				["self"] = {
					["Position"] = Vector(0, -4, 0),
					["Scale"] = Vector(4.5999999046326, 0.52999997138977, 1),
					["Angles"] = Angle(0, 0, 9.8090892502737e-045),
					["UniqueID"] = "4169370848",
					["EditorExpand"] = true,
					["ClassName"] = "model",
					["Bone"] = "",
					["Model"] = "models/props_c17/playground_swingset_seat01a.mdl",
					["Material"] = "models/props_medieval/fort_wall",
				},
			},
			[2] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["ClassName"] = "proxy",
							["UniqueID"] = "2100202144",
							["Expression"] = "0,0,owner_velocity_right()*-5",
							["ZeroEyePitch"] = true,
							["RootOwner"] = true,
							["EditorExpand"] = true,
							["VariableName"] = "Angles",
						},
					},
				},
				["self"] = {
					["Position"] = Vector(0, 8, 0),
					["Scale"] = Vector(4.5999999046326, -0.52999997138977, 1),
					["UniqueID"] = "3989406105",
					["EditorExpand"] = true,
					["DoubleFace"] = true,
					["Material"] = "models/props_medieval/fort_wall",
					["Angles"] = Angle(0, 0, 9.8090892502737e-045),
					["Bone"] = "",
					["Model"] = "models/props_c17/playground_swingset_seat01a.mdl",
					["ClassName"] = "model",
				},
			},
		},
		["self"] = {
			["ClassName"] = "model",
			["Size"] = 0,
			["AimPartUID"] = "4216593801",
			["UniqueID"] = "4083807794",
			["Bone"] = "none",
			["Model"] = "models/pac/default.mdl",
			["AimPartName"] = "ski ang",
		},
	},
	[6] = {
		["children"] = {
		},
		["self"] = {
			["ClassName"] = "poseparameter",
			["PoseParameter"] = "aim_pitch",
			["UniqueID"] = "3215839163",
			["EditorExpand"] = true,
			["Range"] = 0.02,
		},
	},
	[7] = {
		["children"] = {
			[1] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["ClassName"] = "proxy",
							["UniqueID"] = "2660013532",
							["Expression"] = "0,abs(sin(owner_velocity_length_increase()/2)^5*10)",
							["RootOwner"] = true,
							["VariableName"] = "Angles",
						},
					},
				},
				["self"] = {
					["Angles"] = Angle(0, 0.66187018156052, 0),
					["UniqueID"] = "1917341326",
					["Bone"] = "spine",
					["ClassName"] = "bone",
					["EditorExpand"] = true,
				},
			},
			[2] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["Expression"] = "nil,nil,abs(owner_velocity_right())*-0.25",
							["ClassName"] = "proxy",
							["UniqueID"] = "2407280773",
							["VariableName"] = "Position",
						},
					},
					[2] = {
						["children"] = {
						},
						["self"] = {
							["VelocityRoughness"] = 20,
							["UniqueID"] = "1628568469",
							["Expression"] = "nil, owner_velocity_right()*3",
							["ClassName"] = "proxy",
							["VariableName"] = "Angles",
						},
					},
				},
				["self"] = {
					["EditorExpand"] = true,
					["Position"] = Vector(0, 0, -9.4978594233908e-007),
					["UniqueID"] = "2159076784",
					["Bone"] = "pelvis",
					["Angles"] = Angle(0.65625, -5.5293148761848e-006, 0),
					["ClassName"] = "bone",
				},
			},
			[3] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["ZeroEyePitch"] = true,
							["UniqueID"] = "913256970",
							["Expression"] = "owner_velocity_right()*5",
							["RootOwner"] = true,
							["ClassName"] = "proxy",
							["VariableName"] = "Angles",
						},
					},
				},
				["self"] = {
					["Angles"] = Angle(1.8995719074155e-005, 0, 0),
					["UniqueID"] = "3944894964",
					["Bone"] = "pelvis",
					["ClassName"] = "bone",
					["EditorExpand"] = true,
				},
			},
			[4] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["ClassName"] = "proxy",
							["UniqueID"] = "1794378940",
							["Expression"] = "0,abs(sin(owner_velocity_length_increase()/2)^5*10)",
							["RootOwner"] = true,
							["VariableName"] = "Angles",
						},
					},
				},
				["self"] = {
					["Angles"] = Angle(0, 1.4108070135117, 0),
					["UniqueID"] = "2757067662",
					["Bone"] = "spine 1",
					["ClassName"] = "bone",
					["EditorExpand"] = true,
				},
			},
			[5] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["ClassName"] = "proxy",
							["UniqueID"] = "3536679756",
							["Expression"] = "0,abs(sin(owner_velocity_length_increase()/2)^5*100)",
							["RootOwner"] = true,
							["VariableName"] = "Angles",
						},
					},
				},
				["self"] = {
					["Angles"] = Angle(0, 13.703516960144, 0),
					["UniqueID"] = "375750313",
					["Bone"] = "right upperarm",
					["ClassName"] = "bone",
					["EditorExpand"] = true,
				},
			},
			[6] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["ClassName"] = "proxy",
							["UniqueID"] = "665328600",
							["Expression"] = "0,abs(sin(owner_velocity_length_increase()/2)^5*10)",
							["RootOwner"] = true,
							["EditorExpand"] = true,
							["VariableName"] = "Angles",
						},
					},
				},
				["self"] = {
					["Angles"] = Angle(0, 1.4360531568527, 0),
					["UniqueID"] = "3396535210",
					["Bone"] = "spine 2",
					["ClassName"] = "bone",
					["EditorExpand"] = true,
				},
			},
			[7] = {
				["children"] = {
				},
				["self"] = {
					["ClassName"] = "event",
					["UniqueID"] = "1918845321",
					["Event"] = "speed",
					["Operator"] = "above",
					["EditorExpand"] = true,
					["Invert"] = true,
				},
			},
			[8] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["ClassName"] = "proxy",
							["UniqueID"] = "1350385686",
							["Expression"] = "0,abs(sin(owner_velocity_length_increase()/2)^5*100)",
							["RootOwner"] = true,
							["VariableName"] = "Angles",
						},
					},
				},
				["self"] = {
					["Angles"] = Angle(0, 7.8078889846802, 0),
					["UniqueID"] = "3851295836",
					["Bone"] = "left upperarm",
					["ClassName"] = "bone",
					["EditorExpand"] = true,
				},
			},
		},
		["self"] = {
			["UniqueID"] = "448031741",
			["ClassName"] = "group",
		},
	},
	[8] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["ClassName"] = "model",
					["Size"] = 0.076,
					["UniqueID"] = "4253746561",
					["Angles"] = Angle(-72.28125, -101.375, 0),
					["Model"] = "models/props_foliage/shrub_01a.mdl",
					["Position"] = Vector(-19.3798828125, 0.8603515625, 64.4970703125),
				},
			},
			[2] = {
				["children"] = {
				},
				["self"] = {
					["ClassName"] = "model",
					["Position"] = Vector(-19.3798828125, 0.8603515625, 64.4970703125),
					["UniqueID"] = "569061154",
					["Model"] = "models/props_foliage/shrub_01a.mdl",
					["Size"] = 0.108,
				},
			},
			[3] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["RimlightBoost"] = 0.8,
							["UniqueID"] = "1566253071",
							["PhongExponent"] = 1.5,
							["PhongTint"] = Vector(0.30000001192093, 0.30000001192093, 0.30000001192093),
							["RimlightExponent"] = 0.5,
							["BaseTexture"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/objects/norwegian_flag.png",
							["ClassName"] = "material",
							["PhongBoost"] = 0.21,
							["BumpMap"] = "models/player/items/soldier/dappertopper",
							["Rimlight"] = true,
							["PhongFresnelRanges"] = Vector(0, 0.5, 1),
							["Phong"] = true,
						},
					},
				},
				["self"] = {
					["Position"] = Vector(-16.120849609375, -4.77880859375, 49.9658203125),
					["AlternativeScaling"] = true,
					["EditorExpand"] = true,
					["DoubleFace"] = true,
					["PositionOffset"] = Vector(12, -9, -57),
					["UniqueID"] = "527092226",
					["Bone"] = "spine 1",
					["Model"] = "models/weapons/c_models/c_buffbanner/c_buffbanner.mdl",
					["ClassName"] = "model",
				},
			},
			[4] = {
				["children"] = {
				},
				["self"] = {
					["ClassName"] = "model",
					["Size"] = 0.076,
					["UniqueID"] = "1340769713",
					["Model"] = "models/pac/default.mdl",
					["Brightness"] = -2,
					["Position"] = Vector(-20.099000930786, -0.05799999833107, 64.651000976563),
				},
			},
			[5] = {
				["children"] = {
				},
				["self"] = {
					["Position"] = Vector(-20.885999679565, 0.58600002527237, 64.440002441406),
					["Scale"] = Vector(2.0199999809265, 1, 1),
					["Angles"] = Angle(0, -180, 0),
					["Size"] = 0.064,
					["UniqueID"] = "1861275626",
					["Color"] = Vector(69, 69, 69),
					["Material"] = "models/debug/debugwhite",
					["Model"] = "models/pac/default.mdl",
					["ClassName"] = "model",
				},
			},
			[6] = {
				["children"] = {
				},
				["self"] = {
					["ClassName"] = "model",
					["Size"] = 0.078,
					["UniqueID"] = "3949930207",
					["Angles"] = Angle(0, -179.96875, -52.875),
					["Model"] = "models/props_foliage/shrub_01a.mdl",
					["Position"] = Vector(-19.3798828125, 0.8603515625, 64.4970703125),
				},
			},
			[7] = {
				["children"] = {
				},
				["self"] = {
					["BaseTexture"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/objects/backpack_norwegian.png",
					["ClassName"] = "material",
					["UniqueID"] = "2356710271",
					["BumpMap"] = "models\\player\\items\\sniper\\xms_sniper_commandobackpack_phongmask",
					["DetailScale"] = 1.1,
					["Phong"] = true,
				},
			},
			[8] = {
				["children"] = {
				},
				["self"] = {
					["ClassName"] = "model",
					["Size"] = 0.076,
					["UniqueID"] = "390040388",
					["Model"] = "models/pac/default.mdl",
					["Brightness"] = -2,
					["Position"] = Vector(-20.099000930786, 1.4579999446869, 64.651000976563),
				},
			},
			[9] = {
				["children"] = {
				},
				["self"] = {
					["Angles"] = Angle(0, 56.65625, 0),
					["Position"] = Vector(-19.142578125, 1.22119140625, 64.498046875),
					["UniqueID"] = "355640945",
					["ClassName"] = "model",
					["Size"] = 0.108,
					["Model"] = "models/props_foliage/shrub_01a.mdl",
					["Scale"] = Vector(1, 1, 0.76999998092651),
				},
			},
			[10] = {
				["children"] = {
				},
				["self"] = {
					["UniqueID"] = "995829773",
					["ClassName"] = "model",
					["Position"] = Vector(-18.736000061035, 0.58999997377396, 66.169998168945),
					["Angles"] = Angle(0, -180, 0),
					["Color"] = Vector(0, 0, 0),
					["Size"] = 0.252,
					["Model"] = "models/pac/default.mdl",
					["Material"] = "models/debug/debugwhite",
				},
			},
		},
		["self"] = {
			["ClassName"] = "model",
			["Position"] = Vector(-4, 12, 0),
			["PositionOffset"] = Vector(0, 0, -55.5),
			["UniqueID"] = "622162126",
			["Bone"] = "spine 2",
			["Model"] = "models/player/items/sniper/xms_sniper_commandobackpack.mdl",
			["Angles"] = Angle(0, 62.53125, 90),
		},
	},
	[9] = {
		["children"] = {
		},
		["self"] = {
			["UniqueID"] = "3626082813",
			["Angles"] = Angle(-87.46875, -90, -89.96875),
			["Position"] = Vector(3.65478515625, -1.7568359375, 32.96875),
			["EditorExpand"] = true,
			["Size"] = 0.75,
			["Bone"] = "right hand",
			["Model"] = "models/props_junk/harpoon002a.mdl",
			["ClassName"] = "model",
		},
	},
	[10] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["Angles"] = Angle(-1.2806604900106e-005, -9.6446151733398, 6.8835506681353e-005),
					["Bone"] = "right foot",
					["UniqueID"] = "3273273727",
					["ClassName"] = "bone",
				},
			},
			[2] = {
				["children"] = {
				},
				["self"] = {
					["Angles"] = Angle(-2.5186322091031e-005, -26.92621421814, -8.7938693468459e-005),
					["Bone"] = "left foot",
					["UniqueID"] = "3476253006",
					["ClassName"] = "bone",
				},
			},
		},
		["self"] = {
			["Angles"] = Angle(0, 16, 0),
			["Bone"] = "left thigh",
			["UniqueID"] = "3655999250",
			["ClassName"] = "bone",
		},
	},
},
["self"] = {
	["Name"] = "ski",
	["ClassName"] = "group",
	["UniqueID"] = "415902456",
	["EditorExpand"] = true,
},
}

pace.example_outfits["southpark"] = {
[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "3513732839",
						["Size"] = 0,
					},
				},
			},
			["self"] = {
				["Alpha"] = 0,
				["EditorExpand"] = true,
				["UniqueID"] = "2782871480",
				["Fullbright"] = true,
				["Size"] = 0.44,
				["ClassName"] = "entity",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["RootOwner"] = true,
								["UniqueID"] = "3210564156",
								["Expression"] = "90 + (owner_velocity_length() > 2 and (sin(owner_velocity_length_increase()*10 + random()) > 0 and 2 or -2) or 0),90,90",
								["ClassName"] = "proxy",
								["Input"] = "owner_velocity_length_increase",
								["VariableName"] = "AngleOffset",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["Arguments"] = "-0.7",
								["UniqueID"] = "1222338801",
								["Event"] = "dot_right",
								["Operator"] = "above",
								["ClassName"] = "event",
								["EditorExpand"] = true,
							},
						},
					},
					["self"] = {
						["Invert"] = true,
						["UniqueID"] = "537182332",
						["Model"] = "models/hunter/plates/plate1x1.mdl",
						["EditorExpand"] = true,
						["Name"] = "left",
						["Scale"] = Vector(1, 1, -0.0099999997764826),
						["Alpha"] = 0.999,
						["ClassName"] = "model",
						["AngleOffset"] = Angle(90, 90, 90),
						["AimPartName"] = "LOCALEYES_YAW",
						["Bone"] = "none",
						["Fullbright"] = true,
						["Translucent"] = true,
						["Material"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/male/kyle/side.png",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["EditorExpand"] = true,
						["UniqueID"] = "2385081529",
						["Expression"] = "0,0,owner_velocity_length() > 2 and (sin(owner_velocity_length_increase()*10 + random()) > 0 and 2 or 0) or 0",
						["ClassName"] = "proxy",
						["Input"] = "owner_velocity_length_increase",
						["VariableName"] = "PositionOffset",
					},
				},
				[3] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["EditorExpand"] = true,
								["UniqueID"] = "75353876",
								["Expression"] = "90 + (owner_velocity_length() > 2 and (sin(owner_velocity_length_increase()*10 + random()) > 0 and 2 or -2) or 0),90,90",
								["ClassName"] = "proxy",
								["RootOwner"] = true,
								["Input"] = "owner_velocity_length_increase",
								["VariableName"] = "AngleOffset",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["Arguments"] = "0.7",
								["UniqueID"] = "3855963026",
								["Event"] = "dot_forward",
								["Operator"] = "below",
								["ClassName"] = "event",
								["EditorExpand"] = true,
							},
						},
					},
					["self"] = {
						["UniqueID"] = "2325223398",
						["Model"] = "models/hunter/plates/plate1x1.mdl",
						["EditorExpand"] = true,
						["Name"] = "back",
						["Scale"] = Vector(1, 1, 0.0099999997764826),
						["Alpha"] = 0.99,
						["AngleOffset"] = Angle(90, 90, 90),
						["Fullbright"] = true,
						["AimPartName"] = "LOCALEYES_YAW",
						["ClassName"] = "model",
						["Bone"] = "none",
						["Translucent"] = true,
						["Material"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/male/kyle/back.png",
					},
				},
				[4] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Arguments"] = "0.7",
								["UniqueID"] = "2514734784",
								["Event"] = "dot_right",
								["Operator"] = "below",
								["ClassName"] = "event",
								["EditorExpand"] = true,
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["RootOwner"] = true,
								["UniqueID"] = "2809374115",
								["Expression"] = "90 + (owner_velocity_length() > 2 and (sin(owner_velocity_length_increase()*10 + random()) > 0 and 2 or -2) or 0),90,90",
								["ClassName"] = "proxy",
								["Input"] = "owner_velocity_length_increase",
								["VariableName"] = "AngleOffset",
							},
						},
					},
					["self"] = {
						["UniqueID"] = "1916911126",
						["Model"] = "models/hunter/plates/plate1x1.mdl",
						["EditorExpand"] = true,
						["Name"] = "right",
						["Scale"] = Vector(1, 1, 0.0099999997764826),
						["Alpha"] = 0.999,
						["AngleOffset"] = Angle(90, 90, 90),
						["Fullbright"] = true,
						["AimPartName"] = "LOCALEYES_YAW",
						["ClassName"] = "model",
						["Bone"] = "none",
						["Translucent"] = true,
						["Material"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/male/kyle/side.png",
					},
				},
				[5] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Arguments"] = "-0.7",
								["UniqueID"] = "2334772782",
								["Event"] = "dot_forward",
								["Operator"] = "above",
								["ClassName"] = "event",
								["EditorExpand"] = true,
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["EditorExpand"] = true,
								["UniqueID"] = "4261893074",
								["Expression"] = "90 + (owner_velocity_length() > 2 and (sin(owner_velocity_length_increase()*10 + random()) > 0 and 2 or -2) or 0),90,90",
								["ClassName"] = "proxy",
								["Input"] = "owner_velocity_length_increase",
								["VariableName"] = "AngleOffset",
							},
						},
					},
					["self"] = {
						["UniqueID"] = "2579545900",
						["Model"] = "models/hunter/plates/plate1x1.mdl",
						["EditorExpand"] = true,
						["Name"] = "front",
						["Scale"] = Vector(1, 1, 0.0099999997764826),
						["Alpha"] = 0.999,
						["AngleOffset"] = Angle(90, 90, 90),
						["Fullbright"] = true,
						["AimPartName"] = "LOCALEYES_YAW",
						["ClassName"] = "model",
						["Bone"] = "none",
						["Translucent"] = true,
						["Material"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/male/kyle/front.png",
					},
				},
			},
			["self"] = {
				["UniqueID"] = "49506760",
				["ClassName"] = "model",
				["Position"] = Vector(0, 0, 24),
				["Model"] = "models/pac/default.mdl",
				["Size"] = 0,
				["Bone"] = "none",
				["Name"] = "body",
				["EditorExpand"] = true,
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "743553614",
		["ClassName"] = "group",
		["Name"] = "my outfit",
		["Description"] = "add parts to me!",
	},
},

}

pace.example_outfits["custom sprite"] = {["children"] = {
	[1] = {
		["children"] = {
		},
		["self"] = {
			["Position"] = Vector(0, 0, 85),
			["Model"] = "models/hunter/plates/plate1x1.mdl",
			["UniqueID"] = "1351937832",
			["Angles"] = Angle(90, 0, 0),
			["Name"] = "plate",
			["Scale"] = Vector(0.60000002384186, 1, 0.0099999997764826),
			["Alpha"] = 0.998,
			["Bone"] = "none",
			["AimPartName"] = "LOCALEYES",
			["ClassName"] = "model",
			["Fullbright"] = true,
			["Translucent"] = true,
			["Material"] = "http://th06.deviantart.net/fs71/200H/f/2012/271/e/0/you_belong_with_me_text_png_by_rachael1505-d5g4ish.png",
		},
	},
},
["self"] = {
	["ClassName"] = "group",
	["UniqueID"] = "2642178115",
	["EditorExpand"] = true,
	["Name"] = "sprite",
	["Description"] = "add parts to me!",
},
}

pace.example_outfits["custom face"] = {["children"] = {
	[1] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["Position"] = Vector(0, 0.70999997854233, 0.36000001430511),
					["TintColor"] = Vector(255, 255, 255),
					["Name"] = "eye socket flesh",
					["Scale"] = Vector(1, 0.8299999833107, -0.49000000953674),
					["ClassName"] = "model",
					["Size"] = 0.46,
					["UniqueID"] = "1481102509",
					["GlobalID"] = "3650892708",
					["Brightness"] = 0.6,
					["Material"] = "models/weapons/v_crowbar/crowbar_cyl",
				},
			},
			[2] = {
				["children"] = {
				},
				["self"] = {
					["UniqueID"] = "1866261967",
					["Name"] = "left eye",
					["Model"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/eye.obj",
					["EditorExpand"] = true,
					["GlobalID"] = "2673971993",
					["Size"] = 0.19945035257042,
					["AimPartName"] = "PLAYEREYES",
					["ClassName"] = "model",
					["Material"] = "mat eye",
					["EyeAngles"] = true,
					["Position"] = Vector(1.3710000514984, 1.2359999418259, 1.2239999771118),
				},
			},
			[3] = {
				["children"] = {
				},
				["self"] = {
					["UniqueID"] = "884148990",
					["Name"] = "right eye",
					["Model"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/eye.obj",
					["EditorExpand"] = true,
					["GlobalID"] = "2673971993",
					["Size"] = 0.19945035257042,
					["AimPartName"] = "PLAYEREYES",
					["ClassName"] = "model",
					["Material"] = "mat eye",
					["EyeAngles"] = true,
					["Position"] = Vector(-1.3710000514984, 1.2359999418259, 1.2239999771118),
				},
			},
			[4] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["DrawOrder"] = 2,
							["Position"] = Vector(0.061999998986721, 1.4270000457764, 1.7189999818802),
							["Model"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/lashes.obj",
							["EditorExpand"] = true,
							["Passes"] = 0,
							["Name"] = "lash left top",
							["Scale"] = Vector(1, 1.0499999523163, 1.3400000333786),
							["Alpha"] = 0.998,
							["GlobalID"] = "332840017",
							["Size"] = 0.59296051285207,
							["UniqueID"] = "1558416082",
							["Angles"] = Angle(-90, 90, 180),
							["ClassName"] = "model",
							["Translucent"] = true,
							["Material"] = "models/alyx/hairbits",
						},
					},
					[2] = {
						["children"] = {
						},
						["self"] = {
							["DrawOrder"] = 2,
							["Position"] = Vector(-0.061999998986721, 1.1770000457764, 1.9190000295639),
							["Model"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/lashes.obj",
							["EditorExpand"] = true,
							["Passes"] = 0,
							["Name"] = "lash right bottom",
							["Scale"] = Vector(1, -1.0499999523163, -0.20999999344349),
							["Alpha"] = 0.998,
							["GlobalID"] = "332840017",
							["Size"] = 0.59296051285207,
							["UniqueID"] = "160045824",
							["Angles"] = Angle(-90, 90, 180),
							["ClassName"] = "model",
							["Translucent"] = true,
							["Material"] = "models/alyx/hairbits",
						},
					},
					[3] = {
						["children"] = {
						},
						["self"] = {
							["DrawOrder"] = 2,
							["Position"] = Vector(-0.061999998986721, 1.4270000457764, 1.7189999818802),
							["Model"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/lashes.obj",
							["EditorExpand"] = true,
							["Passes"] = 0,
							["Name"] = "lash right top",
							["Scale"] = Vector(1, -1.0499999523163, 1.3400000333786),
							["Alpha"] = 0.998,
							["GlobalID"] = "332840017",
							["Size"] = 0.59296051285207,
							["UniqueID"] = "3007135820",
							["Angles"] = Angle(-90, 90, 180),
							["ClassName"] = "model",
							["Translucent"] = true,
							["Material"] = "models/alyx/hairbits",
						},
					},
					[4] = {
						["children"] = {
						},
						["self"] = {
							["DrawOrder"] = 2,
							["Position"] = Vector(0.061999998986721, 1.2569999694824, 1.9190000295639),
							["Model"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/lashes.obj",
							["EditorExpand"] = true,
							["Passes"] = 0,
							["Name"] = "lash left bottom",
							["Scale"] = Vector(1, 1.0499999523163, -0.20999999344349),
							["Alpha"] = 0.998,
							["GlobalID"] = "332840017",
							["Size"] = 0.59296051285207,
							["UniqueID"] = "306380809",
							["Angles"] = Angle(-90, 85.375, 180),
							["ClassName"] = "model",
							["Translucent"] = true,
							["Material"] = "models/alyx/hairbits",
						},
					},
				},
				["self"] = {
					["GlobalID"] = "256013495",
					["UniqueID"] = "684272044",
					["EditorExpand"] = true,
					["Name"] = "lashes",
					["ClassName"] = "group",
				},
			},
			[5] = {
				["children"] = {
				},
				["self"] = {
					["EditorExpand"] = true,
					["UniqueID"] = "3295496192",
					["Angles"] = Angle(-68.28125, 89.9375, 0),
					["GlobalID"] = "2096308948",
					["Position"] = Vector(-0.265625, -0.1351318359375, -1.2769775390625),
					["Name"] = "head clip",
					["ClassName"] = "clip",
				},
			},
			[6] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["Size"] = 0.2,
							["ClassName"] = "model",
							["Position"] = Vector(-4, 0, 4),
							["UniqueID"] = "3838093491",
							["Color"] = Vector(104, 147, 255),
							["Material"] = "models/debug/debugwhite",
							["Name"] = "ornament",
							["GlobalID"] = "1401210613",
						},
					},
					[2] = {
						["children"] = {
						},
						["self"] = {
							["DrawOrder"] = 2,
							["UniqueID"] = "2776830986",
							["Alpha"] = 0.99,
							["Material"] = "mat hair",
							["Position"] = Vector(-3.9423828125, 0.05322265625, 4.2568359375),
							["Model"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/hair/hair1.obj",
							["DoubleFace"] = true,
							["ClassName"] = "model",
							["Name"] = "tail",
							["Scale"] = Vector(0.94999998807907, 1, 1),
							["Angles"] = Angle(0, 0, -24.75),
							["EditorExpand"] = true,
							["Size"] = 0.578,
							["PositionOffset"] = Vector(3.7999999523163, 0, -4.6100001335144),
							["Color"] = Vector(91, 69, 69),
							["TextureFilter"] = 5,
							["Translucent"] = true,
							["GlobalID"] = "2731912434",
						},
					},
				},
				["self"] = {
					["DrawOrder"] = 6,
					["UniqueID"] = "3755909938",
					["Alpha"] = 0.99,
					["Material"] = "mat hair",
					["Position"] = Vector(0, -2.2530000209808, -1.0089999437332),
					["Model"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/hair/hair2.obj",
					["Angles"] = Angle(0, -180, 127.59375),
					["Name"] = "hair",
					["Scale"] = Vector(0.94999998807907, 1, 1),
					["DoubleFace"] = true,
					["EditorExpand"] = true,
					["Size"] = 0.601,
					["GlobalID"] = "2731912434",
					["Color"] = Vector(91, 69, 69),
					["TextureFilter"] = 5,
					["Translucent"] = true,
					["ClassName"] = "model",
				},
			},
		},
		["self"] = {
			["DrawOrder"] = -1,
			["Invert"] = true,
			["ClassName"] = "model",
			["Name"] = "facegen head",
			["EditorExpand"] = true,
			["UniqueID"] = "1117824224",
			["Angles"] = Angle(90, -99.375, 0),
			["DoubleFace"] = true,
			["Position"] = Vector(1.539999961853, -2.3099999427795, 0.050000000745058),
			["Color"] = Vector(220, 198, 184),
			["Material"] = "mat face",
			["Model"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/face1.obj",
			["GlobalID"] = "3070286632",
		},
	},
	[2] = {
		["children"] = {
		},
		["self"] = {
			["RimlightBoost"] = 20,
			["DetailBlendFactor"] = 1,
			["UniqueID"] = "3222908452",
			["GlobalID"] = "2449305501",
			["RimlightExponent"] = 1.5,
			["PhongTint"] = Vector(27, 27, 27),
			["Name"] = "mat eye",
			["ClassName"] = "material",
			["BaseTexture"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/eye1.png",
			["DetailBlendMode"] = 1,
			["OwnerName"] = "",
			["PhongBoost"] = 4,
			["BumpMap"] = "dev/bump_normal",
			["EditorExpand"] = true,
			["PhongFresnelRanges"] = Vector(0.78125, 0.78125, 0.78125),
			["Phong"] = true,
		},
	},
	[3] = {
		["children"] = {
		},
		["self"] = {
			["UniqueID"] = "525837810",
			["PhongExponent"] = 4,
			["EditorExpand"] = true,
			["Rimlight"] = true,
			["Name"] = "mat face",
			["RimlightExponent"] = 34.700000762939,
			["BaseTexture"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/hair/face1.jpg",
			["ClassName"] = "material",
			["OwnerName"] = "",
			["PhongBoost"] = 0.05,
			["BumpMap"] = "dev/bump_normal",
			["GlobalID"] = "847843936",
			["PhongFresnelRanges"] = Vector(1.09375, 1.09375, 1.09375),
			["Phong"] = true,
		},
	},
	[4] = {
		["children"] = {
		},
		["self"] = {
			["Detail"] = "models/props_halloween/halloween_blk",
			["DetailBlendFactor"] = 88.6,
			["UniqueID"] = "2481252630",
			["DetailTint"] = Vector(29, 29, 29),
			["PhongTint"] = Vector(1, 1, 1),
			["BaseTexture"] = "https://raw.githubusercontent.com/CapsAdmin/pac3_assets/master/organic/human/female/head/hair/hair1.png",
			["BumpMap"] = "models/player/items/soldier/dappertopper",
			["Phong"] = true,
			["RimlightBoost"] = 0.21,
			["DetailScale"] = 0.99,
			["PhongExponent"] = 2.1,
			["Name"] = "mat hair",
			["DetailBlendMode"] = 1,
			["PhongBoost"] = 0.2,
			["GlobalID"] = "3865516471",
			["PhongFresnelRanges"] = Vector(0.10000000149012, 0.30000001192093, 1),
			["ClassName"] = "material",
		},
	},
	[5] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["Alpha"] = 0,
					["ClassName"] = "entity",
					["UniqueID"] = "1253362386",
					["Model"] = "alyx",
					["EditorExpand"] = true,
					["GlobalID"] = "2076204873",
					["Name"] = "hide player",
					["Material"] = "models/weapons/v_crowbar/head_uvw",
				},
			},
			[2] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["ClassName"] = "bone",
							["GlobalID"] = "1629676574",
							["UniqueID"] = "4177958607",
							["Scale"] = Vector(1, 0.89999997615814, 1),
						},
					},
				},
				["self"] = {
					["BoneMerge"] = true,
					["GlobalID"] = "1556503194",
					["UniqueID"] = "355786210",
					["EditorExpand"] = true,
					["Size"] = 0.906,
					["Model"] = "models/Humans/Group01/Female_01.mdl",
					["ClassName"] = "model",
				},
			},
		},
		["self"] = {
			["GlobalID"] = "1107806585",
			["UniqueID"] = "2729351200",
			["EditorExpand"] = true,
			["Name"] = "body",
			["ClassName"] = "group",
		},
	},
},
["self"] = {
	["DrawOrder"] = 2,
	["UniqueID"] = "3974461974",
	["EditorExpand"] = true,
	["GlobalID"] = "4003629331",
	["Name"] = "custom face",
	["ClassName"] = "group",
},
}

pace.example_outfits["manual bonemerge"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "856336120",
						["FollowPartName"] = "left toe",
						["Bone"] = "bip toe left",
						["Name"] = "bip toe left",
						["FollowPartUID"] = "955774632",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "3728373108",
						["FollowPartUID"] = "1994207982",
						["FollowPartName"] = "left knee",
						["Bone"] = "bip knee left",
						["Name"] = "bip knee left",
						["Scale"] = Vector(2, 1, 1),
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "2336138590",
						["FollowPartUID"] = "1948671510",
						["FollowPartName"] = "right knee",
						["Bone"] = "bip knee right",
						["Name"] = "bip knee right",
						["Scale"] = Vector(2, 1, 1),
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "2889420274",
						["FollowPartName"] = "right foot",
						["Bone"] = "bip foot right",
						["Name"] = "bip foot right",
						["FollowPartUID"] = "672240445",
					},
				},
				[5] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "3691159707",
						["FollowPartName"] = "right hand",
						["Bone"] = "bip lowerarm right",
						["Name"] = "bip lowerarm right",
						["FollowPartUID"] = "4259035567",
					},
				},
				[6] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "2224813423",
						["FollowPartName"] = "left foot",
						["Bone"] = "bip foot left",
						["Name"] = "bip foot left",
						["FollowPartUID"] = "2995259331",
					},
				},
				[7] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "3978245216",
						["FollowPartName"] = "right toe",
						["Bone"] = "bip toe right",
						["Name"] = "bip toe right",
						["FollowPartUID"] = "3543216241",
					},
				},
				[8] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["UniqueID"] = "2062752203",
						["FollowPartName"] = "left hand",
						["Bone"] = "bip lowerarm left",
						["Name"] = "bip lowerarm left",
						["FollowPartUID"] = "2558472022",
					},
				},
			},
			["self"] = {
				["Model"] = "models/workshop/player/items/scout/xms_scout_elf_sneakers/xms_scout_elf_sneakers.mdl",
				["ClassName"] = "model",
				["UniqueID"] = "2394819278",
				["EditorExpand"] = true,
				["Translucent"] = true,
				["Bone"] = "none",
				["Name"] = "xms scout elf sneakers",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(-90, -90, 0),
						["UniqueID"] = "3543216241",
						["Size"] = 0,
						["Bone"] = "right toe",
						["Name"] = "right toe",
						["ClassName"] = "model",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(-90, 90, 0),
						["UniqueID"] = "2995259331",
						["Size"] = 0,
						["Bone"] = "left foot",
						["Name"] = "left foot",
						["ClassName"] = "model",
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(-90, 180, -90),
						["UniqueID"] = "955774632",
						["Size"] = 0,
						["Bone"] = "left toe",
						["Name"] = "left toe",
						["ClassName"] = "model",
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["Size"] = 0,
						["Angles"] = Angle(3, 4, 90),
						["Position"] = Vector(-22, -3, 2),
						["UniqueID"] = "1948671510",
						["Bone"] = "right calf",
						["Name"] = "right knee",
						["ClassName"] = "model",
					},
				},
				[5] = {
					["children"] = {
					},
					["self"] = {
						["Size"] = 0,
						["Angles"] = Angle(-3, 4, 90),
						["Position"] = Vector(-22, -3, -2),
						["UniqueID"] = "1994207982",
						["Bone"] = "left calf",
						["Name"] = "left knee",
						["ClassName"] = "model",
					},
				},
				[6] = {
					["children"] = {
					},
					["self"] = {
						["Angles"] = Angle(-90, -90, 0),
						["UniqueID"] = "672240445",
						["Size"] = 0,
						["Bone"] = "right foot",
						["Name"] = "right foot",
						["ClassName"] = "model",
					},
				},
				[7] = {
					["children"] = {
					},
					["self"] = {
						["Size"] = 0,
						["Angles"] = Angle(0, 0, 90),
						["Position"] = Vector(-8, 0, 0),
						["UniqueID"] = "2558472022",
						["Bone"] = "left hand",
						["Name"] = "left hand",
						["ClassName"] = "model",
					},
				},
				[8] = {
					["children"] = {
					},
					["self"] = {
						["Size"] = 0,
						["Angles"] = Angle(0, 0, 90),
						["Position"] = Vector(-8, 0, 0),
						["UniqueID"] = "4259035567",
						["Bone"] = "right hand",
						["Name"] = "right hand",
						["ClassName"] = "model",
					},
				},
			},
			["self"] = {
				["UniqueID"] = "495335707",
				["EditorExpand"] = true,
				["Name"] = "dummy skeleton",
				["ClassName"] = "group",
			},
		},
		[3] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["Size"] = 0.05,
						["UniqueID"] = "3767891771",
						["Bone"] = "left calf",
						["Name"] = "left calf",
						["ScaleChildren"] = true,
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["Size"] = 0.05,
						["UniqueID"] = "3080702787",
						["Bone"] = "right calf",
						["Name"] = "right calf",
						["ScaleChildren"] = true,
					},
				},
			},
			["self"] = {
				["UniqueID"] = "677173573",
				["EditorExpand"] = true,
				["Name"] = "player bones",
				["ClassName"] = "group",
			},
		},
	},
	["self"] = {
		["ClassName"] = "group",
		["UniqueID"] = "36651421",
		["EditorExpand"] = true,
		["Name"] = "elf sneakers",
		["Description"] = "add parts to me!",
	},
},
}

pace.example_outfits["realistic footsteps"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "is in world",
								["UniqueID"] = "905788888",
								["Name"] = "dog footstep[1,4]",
								["Sound"] = "npc/dog/dog_footstep[1,4].wav",
								["ClassName"] = "sound",
								["Pitch"] = 0.625,
								["ParentUID"] = "213354147",
								["EditorExpand"] = true,
							},
						},
					},
					["self"] = {
						["AffectChildrenOnly"] = true,
						["Invert"] = true,
						["ParentName"] = "hoverball",
						["Name"] = "is ranger below 5?",
						["EditorExpand"] = true,
						["UniqueID"] = "213354147",
						["ClassName"] = "event",
						["Event"] = "ranger",
						["Arguments"] = "5@@10",
						["Operator"] = "below",
						["ParentUID"] = "103201093",
						["RootOwner"] = false,
					},
				},
			},
			["self"] = {
				["ParentName"] = "my outfit",
				["Position"] = Vector(-30, 0, 0),
				["TintColor"] = Vector(0.63942295312881, 0.63942295312881, 0.63942295312881),
				["Name"] = "right foot",
				["ClassName"] = "model",
				["EditorExpand"] = true,
				["UniqueID"] = "103201093",
				["Bone"] = "right toe",
				["Angles"] = Angle(0, 90, 0),
				["ParentUID"] = "2980027574",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "is in world",
								["UniqueID"] = "1659234766",
								["Name"] = "dog footstep[1,4]",
								["Sound"] = "npc/dog/dog_footstep[1,4].wav",
								["ClassName"] = "sound",
								["Pitch"] = 0.625,
								["ParentUID"] = "3181550699",
								["EditorExpand"] = true,
							},
						},
					},
					["self"] = {
						["AffectChildrenOnly"] = true,
						["Invert"] = true,
						["ParentName"] = "hoverball",
						["Name"] = "is ranger below 5?",
						["EditorExpand"] = true,
						["UniqueID"] = "3181550699",
						["ClassName"] = "event",
						["Event"] = "ranger",
						["Arguments"] = "5@@10",
						["Operator"] = "below",
						["ParentUID"] = "3681250577",
						["RootOwner"] = false,
					},
				},
			},
			["self"] = {
				["ParentName"] = "my outfit",
				["Position"] = Vector(-30, 0, 0),
				["TintColor"] = Vector(0.63942295312881, 0.63942295312881, 0.63942295312881),
				["Name"] = "left foot",
				["ClassName"] = "model",
				["EditorExpand"] = true,
				["UniqueID"] = "3681250577",
				["Bone"] = "left toe",
				["Angles"] = Angle(0, 90, 0),
				["ParentUID"] = "2980027574",
			},
		},
	},
	["self"] = {
		["ClassName"] = "group",
		["UniqueID"] = "2980027574",
		["EditorExpand"] = true,
		["Name"] = "realistic footsteps",
		["Description"] = "add parts to me!",
	},
},
}
pace.example_outfits["custom spray"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "2898900871",
				["UniqueID"] = "3375894473",
				["Name"] = "bind i \"pac_event spray\"",
				["Arguments"] = "spray@@0.1",
				["ParentName"] = "group",
				["ClassName"] = "event",
				["RootOwner"] = false,
				["Operator"] = "equal",
				["Event"] = "command",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "platex",
								["ClassName"] = "model",
								["UniqueID"] = "2265985564",
								["Model"] = "models\\props/CS_militia/tree_large_militia.mdl",
								["Size"] = -0.15,
								["ParentUID"] = "347482952",
								["Name"] = "some tree",
							},
						},
					},
					["self"] = {
						["ParentName"] = "jiggle",
						["UniqueID"] = "347482952",
						["Angles"] = Angle(0, 90, -90),
						["ParentUID"] = "3014689230",
						["EditorExpand"] = true,
						["Name"] = "image",
						["Scale"] = Vector(2.0299999713898, 2.3699998855591, 0.10000000149012),
						["Alpha"] = 0.995,
						["ClassName"] = "model",
						["Size"] = 1.603,
						["Bone"] = "",
						["Fullbright"] = true,
						["Model"] = "models/hunter/plates/plate1x1.mdl",
						["Material"] = "http://1.bp.blogspot.com/-BtiTcfMnbBk/UIUdRNNgfFI/AAAAAAAAJ9M/ikUHkS7c98M/s1600/flowerframepinkwhite.png",
					},
				},
			},
			["self"] = {
				["ParentName"] = "group",
				["UniqueID"] = "3014689230",
				["Speed"] = 0,
				["Name"] = "jiggle",
				["ClassName"] = "jiggle",
				["ParentUID"] = "2898900871",
				["EditorExpand"] = true,
				["Bone"] = "hitpos",
				["ResetOnHide"] = true,
				["Description"] = "The reason it stays still is because speed is set to 0. When it's unhidden it resets back to  where it's supposed to be, the hitpos of the player",
			},
		},
		[3] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group",
				["ClassName"] = "sound",
				["UniqueID"] = "3516081266",
				["ParentUID"] = "2898900871",
				["Name"] = "spray sound",
				["Sound"] = "player/sprayer.wav",
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "2898900871",
		["Name"] = "custom spray",
		["ClassName"] = "group",
	},
}
}
pace.example_outfits["spinning parts"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["ClassName"] = "sunbeams",
						["UniqueID"] = "3874516580",
						["Size"] = -0.15,
						["Multiplier"] = 0.05,
						["Name"] = "",
						["ParentUID"] = "4092294027",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["ClassName"] = "proxy",
						["UniqueID"] = "4150349410",
						["Expression"] = "nil, time()*50",
						["ParentUID"] = "4092294027",
						["Name"] = "",
						["VariableName"] = "Angles",
					},
				},
				[3] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "hoverball",
								["ClassName"] = "model",
								["Position"] = Vector(11.699999809265, 0, 0),
								["UniqueID"] = "3278812056",
								["Size"] = 0.3,
								["ParentUID"] = "2145645982",
								["Name"] = "",
								["Material"] = "models/shadertest/envball_6",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "hoverball",
								["ClassName"] = "proxy",
								["UniqueID"] = "4006368583",
								["Expression"] = "time()*50, time()*50",
								["ParentUID"] = "2145645982",
								["Name"] = "",
								["VariableName"] = "Angles",
							},
						},
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["Position"] = Vector(0, -51, 0),
						["Name"] = "",
						["ClassName"] = "model",
						["UniqueID"] = "2145645982",
						["Material"] = "models/lilchewchew/embers",
						["ParentUID"] = "4092294027",
						["Angles"] = Angle(1642751, 1642751, 0),
						["EditorExpand"] = true,
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["Invert"] = true,
						["Name"] = "",
						["ClassName"] = "model",
						["Size"] = 15,
						["UniqueID"] = "1872614930",
						["ParentUID"] = "4092294027",
						["Material"] = "models/screenspace",
						["Brightness"] = 0,
						["EditorExpand"] = true,
					},
				},
			},
			["self"] = {
				["ParentName"] = "group",
				["Position"] = Vector(0, 0, 98),
				["Name"] = "",
				["UniqueID"] = "4092294027",
				["ClassName"] = "model",
				["Size"] = 2,
				["EditorExpand"] = true,
				["Material"] = "models/effects/goldenwrench",
				["Bone"] = "none",
				["ParentUID"] = "883707760",
				["Angles"] = Angle(0, 1642751, 0),
			},
		},
	},
	["self"] = {
		["Name"] = "",
		["ClassName"] = "group",
		["UniqueID"] = "883707760",
		["EditorExpand"] = true,
	},
}
}
pace.example_outfits["boombox"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "head",
						["ClassName"] = "proxy",
						["UniqueID"] = "1375860677",
						["Expression"] = "nil, -abs(sin(0.25-time()*2.67))^10 * 2",
						["ParentUID"] = "2962520020",
						["Name"] = "",
						["VariableName"] = "Position",
					},
				},
			},
			["self"] = {
				["ParentUID"] = "3979673445",
				["ClassName"] = "bone",
				["UniqueID"] = "2962520020",
				["ParentName"] = "group",
				["Position"] = Vector(0, -0.5782373547554, 0),
				["Name"] = "",
				["EditorExpand"] = true,
			},
		},
		[2] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3979673445",
				["ClassName"] = "bone",
				["UniqueID"] = "2112230287",
				["ParentName"] = "group",
				["Bone"] = "left forearm",
				["Name"] = "",
				["Angles"] = Angle(54.375, 179.96875, 179.96875),
			},
		},
		[3] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "scout boombox 03",
								["ClassName"] = "proxy",
								["UniqueID"] = "2809877038",
								["Expression"] = "0.25+rand()/100",
								["ParentUID"] = "1282464796",
								["Name"] = "",
								["VariableName"] = "Pitch",
							},
						},
					},
					["self"] = {
						["ParentName"] = "citizenradio",
						["ClassName"] = "sound",
						["UniqueID"] = "1282464796",
						["ParentUID"] = "2608531680",
						["Pitch"] = 0.25955017247606,
						["EditorExpand"] = true,
						["Name"] = "",
						["Sound"] = "items/scout_boombox_03.wav",
					},
				},
			},
			["self"] = {
				["ParentName"] = "group",
				["Position"] = Vector(4.58447265625, -0.5157470703125, 2.2789611816406),
				["Name"] = "",
				["Angles"] = Angle(0.1875, -7.0625, -90),
				["ClassName"] = "model",
				["Size"] = 0.45,
				["UniqueID"] = "2608531680",
				["ParentUID"] = "3979673445",
				["Bone"] = "left clavicle",
				["Model"] = "models/props_lab/citizenradio.mdl",
				["EditorExpand"] = true,
			},
		},
		[4] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3979673445",
				["ClassName"] = "bone",
				["UniqueID"] = "3011199636",
				["ParentName"] = "group",
				["Bone"] = "left upperarm",
				["Name"] = "",
				["Angles"] = Angle(-45.21875, -12.9375, 175.53125),
			},
		},
		[5] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3979673445",
				["ClassName"] = "bone",
				["UniqueID"] = "4237647066",
				["ParentName"] = "group",
				["Bone"] = "left hand",
				["Name"] = "",
				["Angles"] = Angle(-19.125, -52.625, -2.03125),
			},
		},
		[6] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group",
				["ClassName"] = "animation",
				["UniqueID"] = "2938406291",
				["WeaponHoldType"] = "normal",
				["Name"] = "",
				["ParentUID"] = "3979673445",
			},
		},
	},
	["self"] = {
		["Name"] = "",
		["ClassName"] = "group",
		["UniqueID"] = "3979673445",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["broom"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3097251620",
				["ClassName"] = "bone",
				["UniqueID"] = "2450199460",
				["ParentName"] = "group 4",
				["Bone"] = "right upperarm",
				["Name"] = "",
				["Angles"] = Angle(-35.826240539551, 33.586395263672, -93.891380310059),
			},
		},
		[2] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3097251620",
				["ClassName"] = "bone",
				["UniqueID"] = "2786303479",
				["ParentName"] = "group 4",
				["Bone"] = "right forearm",
				["Name"] = "",
				["Angles"] = Angle(-24.864221572876, -30.300058364868, -73.212387084961),
			},
		},
		[3] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
								[1] = {
									["children"] = {
									},
									["self"] = {
										["ParentName"] = "signpole",
										["ClassName"] = "model",
										["Size"] = 3,
										["UniqueID"] = "2089200739",
										["Name"] = "",
										["ParentUID"] = "3089574101",
									},
								},
							},
							["self"] = {
								["ParentName"] = "model 28",
								["UniqueID"] = "3089574101",
								["Name"] = "",
								["Scale"] = Vector(1, 1, 0.89999997615814),
								["ClassName"] = "model",
								["ParentUID"] = "3559883105",
								["Angles"] = Angle(90, 0, 0),
								["Model"] = "models/props_c17/signpole001.mdl",
								["EditorExpand"] = true,
							},
						},
						[2] = {
							["children"] = {
								[1] = {
									["children"] = {
									},
									["self"] = {
										["ParentName"] = "trail 1",
										["ClassName"] = "event",
										["UniqueID"] = "3132388009",
										["Arguments"] = "0",
										["Event"] = "speed",
										["Operator"] = "equal",
										["Name"] = "",
										["ParentUID"] = "2082072250",
									},
								},
							},
							["self"] = {
								["ParentUID"] = "3559883105",
								["UniqueID"] = "2082072250",
								["Length"] = 1000,
								["Name"] = "",
								["EndSize"] = 25,
								["ClassName"] = "trail",
								["StartSize"] = 25,
								["Stretch"] = true,
								["ParentName"] = "model 28",
								["EndAlpha"] = 0,
								["StartAlpha"] = 0.4,
								["TrailPath"] = "particle/smokesprites_0006",
							},
						},
					},
					["self"] = {
						["ParentName"] = "model 27",
						["UniqueID"] = "3559883105",
						["AimPartUID"] = "917658153",
						["Name"] = "",
						["ClassName"] = "model",
						["Size"] = 0,
						["AimPartName"] = "model 27",
						["Bone"] = "hitpos",
						["ParentUID"] = "917658153",
						["EditorExpand"] = true,
					},
				},
			},
			["self"] = {
				["ParentName"] = "group 4",
				["Position"] = Vector(3.0804443359375, -1.2985992431641, -0.92620849609375),
				["Name"] = "",
				["ClassName"] = "model",
				["Size"] = 0,
				["UniqueID"] = "917658153",
				["ParentUID"] = "3097251620",
				["Bone"] = "right hand",
				["Angles"] = Angle(-78.240921020508, -126.14680480957, -46.212745666504),
				["EditorExpand"] = true,
			},
		},
		[4] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group 4",
				["Invert"] = true,
				["Name"] = "",
				["ClassName"] = "event",
				["UniqueID"] = "3101905678",
				["ParentUID"] = "3097251620",
				["Operator"] = "equal",
				["Event"] = "weapon_class",
				["Arguments"] = "weapon_crowbar@@1",
			},
		},
		[5] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3097251620",
				["ClassName"] = "bone",
				["UniqueID"] = "1807477957",
				["ParentName"] = "group",
				["Bone"] = "right hand",
				["Name"] = "",
				["Angles"] = Angle(11.853768348694, 16.613912582397, 55.454776763916),
			},
		},
	},
	["self"] = {
		["Name"] = "broom",
		["ClassName"] = "group",
		["UniqueID"] = "3097251620",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["staff"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["Position"] = Vector(3.4189453125, -1.826171875, 0.180908203125),
				["AimPartUID"] = "1736154830",
				["AngleOffset"] = Angle(90, 0, 0),
				["AimPartName"] = "aimpoint",
				["PositionOffset"] = Vector(-38.599998474121, 0, 0),
				["ClassName"] = "model",
				["Bone"] = "right hand",
				["Model"] = "models/props_c17/signpole001.mdl",
				["UniqueID"] = "1959830642",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "event",
						["UniqueID"] = "4152703468",
						["Event"] = "is_voice_chatting",
					},
				},
			},
			["self"] = {
				["Arguments"] = "weapon_crowbar@@1",
				["Invert"] = true,
				["UniqueID"] = "3915329507",
				["Event"] = "weapon_class",
				["Operator"] = "equal",
				["EditorExpand"] = true,
				["ClassName"] = "event",
			},
		},
		[3] = {
			["children"] = {
			},
			["self"] = {
				["ClassName"] = "model",
				["UniqueID"] = "1736154830",
				["Size"] = 0,
				["Bone"] = "left hand",
				["Name"] = "aimpoint",
				["Position"] = Vector(1.7999999523163, -1.5, 0),
			},
		},
	},
	["self"] = {
		["Name"] = "staff",
		["ClassName"] = "group",
		["UniqueID"] = "3166345426",
		["EditorExpand"] = true,
	},
},
[2] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "event",
						["UniqueID"] = "577637106",
						["Event"] = "is_in_noclip",
					},
				},
			},
			["self"] = {
				["Arguments"] = "weapon_crowbar;wowozela@@1",
				["Invert"] = true,
				["UniqueID"] = "3792909328",
				["Event"] = "weapon_class",
				["Operator"] = "equal",
				["EditorExpand"] = true,
				["ClassName"] = "event",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Angles"] = Angle(36.59375, -34.375, 41.375),
								["Bone"] = "right upperarm",
								["UniqueID"] = "3973710705",
								["ClassName"] = "bone",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["Angles"] = Angle(74.75, -35.09375, 87.78125),
								["UniqueID"] = "3137964571",
								["Bone"] = "right hand",
								["ClassName"] = "bone",
								["EditorExpand"] = true,
							},
						},
						[3] = {
							["children"] = {
							},
							["self"] = {
								["Angles"] = Angle(-15.78125, -21.6875, 7.28125),
								["Bone"] = "left upperarm",
								["UniqueID"] = "484853236",
								["ClassName"] = "bone",
							},
						},
						[4] = {
							["children"] = {
							},
							["self"] = {
								["Angles"] = Angle(-38.09375, -24.1875, 73.5),
								["UniqueID"] = "1673164210",
								["Bone"] = "left hand",
								["ClassName"] = "bone",
								["EditorExpand"] = true,
							},
						},
						[5] = {
							["children"] = {
							},
							["self"] = {
								["Angles"] = Angle(0, 11.59375, 0),
								["UniqueID"] = "1677482011",
								["Bone"] = "right forearm",
								["ClassName"] = "bone",
								["EditorExpand"] = true,
							},
						},
						[6] = {
							["children"] = {
							},
							["self"] = {
								["Angles"] = Angle(25, 55.375, 0),
								["Bone"] = "left forearm",
								["UniqueID"] = "1444995674",
								["ClassName"] = "bone",
							},
						},
						[7] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "event",
								["UniqueID"] = "1674777836",
								["Event"] = "speed",
								["Operator"] = "below",
								["Arguments"] = "30",
								["Invert"] = true,
							},
						},
					},
					["self"] = {
						["ClassName"] = "group",
						["UniqueID"] = "2548552443",
						["EditorExpand"] = true,
					},
				},
			},
			["self"] = {
				["Walk"] = "walk_dual",
				["ClassName"] = "holdtype",
				["UniqueID"] = "3980234911",
				["EditorExpand"] = true,
				["ActLand"] = "jump_land",
				["AttackStandPrimaryfire"] = "zombie_attack_01",
				["StandIdle"] = "walk_dual",
				["CrouchIdle"] = "cidle_melee2",
			},
		},
	},
	["self"] = {
		["Name"] = "bones",
		["ClassName"] = "group",
		["UniqueID"] = "1744634544",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["robotic arm with aimpart"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["StartColor"] = Vector(29, 0, 255),
						["UniqueID"] = "428214384",
						["Length"] = 1000,
						["Name"] = "IDK",
						["EndSize"] = 1,
						["ClassName"] = "trail",
						["EndColor"] = Vector(255, 0, 0),
						["ParentName"] = "point 1",
						["ParentUID"] = "2384404661",
						["Bone"] = "hitpos",
						["StartSize"] = 1,
						["TrailPath"] = "sprites/strider_blackball",
					},
				},
				[2] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "beam 1",
								["ClassName"] = "clip",
								["UniqueID"] = "3914029148",
								["ParentUID"] = "3474379373",
								["Name"] = "",
								["Position"] = Vector(-1.0465393066406, -0.000732421875, 0.000244140625),
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "beam 1",
								["ClassName"] = "model",
								["Position"] = Vector(71, 0, 0),
								["UniqueID"] = "2613673133",
								["Size"] = 0.25,
								["Name"] = "point 2",
								["ParentUID"] = "3474379373",
							},
						},
					},
					["self"] = {
						["ParentName"] = "point 1",
						["UniqueID"] = "3474379373",
						["AimPartUID"] = "88457808",
						["Name"] = "beam 1",
						["Scale"] = Vector(4, 1, 1),
						["ClassName"] = "model",
						["Size"] = 0.25,
						["AimPartName"] = "point 3",
						["ParentUID"] = "2384404661",
						["EditorExpand"] = true,
						["Model"] = "models/Mechanics/robotics/a4.mdl",
						["Angles"] = Angle(-1, 0, 0),
					},
				},
			},
			["self"] = {
				["ParentName"] = "pencil",
				["UniqueID"] = "2384404661",
				["Name"] = "point 1",
				["ClassName"] = "model",
				["Size"] = 0.25,
				["ParentUID"] = "2657213663",
				["Bone"] = "right hand",
				["EyeAngles"] = true,
				["EditorExpand"] = true,
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
								[1] = {
									["children"] = {
										[1] = {
											["children"] = {
											},
											["self"] = {
												["ParentName"] = "beam 2",
												["ClassName"] = "clip",
												["UniqueID"] = "4026204007",
												["Name"] = "",
												["ParentUID"] = "1330312944",
											},
										},
										[2] = {
											["children"] = {
											},
											["self"] = {
												["ParentName"] = "beam 2",
												["ClassName"] = "model",
												["Position"] = Vector(61, 0, 0),
												["UniqueID"] = "88457808",
												["Size"] = 0.25,
												["Name"] = "point 3",
												["ParentUID"] = "1330312944",
											},
										},
									},
									["self"] = {
										["ParentName"] = "point 4",
										["UniqueID"] = "1330312944",
										["AimPartUID"] = "2613673133",
										["Name"] = "beam 2",
										["Scale"] = Vector(3.4000000953674, 1, 1),
										["ClassName"] = "model",
										["Size"] = 0.25,
										["AimPartName"] = "point 2",
										["ParentUID"] = "3329593912",
										["Model"] = "models/Mechanics/robotics/a4.mdl",
										["EditorExpand"] = true,
									},
								},
							},
							["self"] = {
								["ParentName"] = "beam 3",
								["ClassName"] = "model",
								["Position"] = Vector(18, 0, 0),
								["UniqueID"] = "3329593912",
								["Size"] = 0.25,
								["EditorExpand"] = true,
								["Name"] = "point 4",
								["ParentUID"] = "1523060539",
							},
						},
					},
					["self"] = {
						["ParentName"] = "point 5",
						["Position"] = Vector(18, 0, 0),
						["Name"] = "beam 3",
						["ClassName"] = "model",
						["Size"] = 0.25,
						["EditorExpand"] = true,
						["ParentUID"] = "1280732317",
						["Model"] = "models/Mechanics/robotics/a4.mdl",
						["UniqueID"] = "1523060539",
					},
				},
			},
			["self"] = {
				["ParentName"] = "pencil",
				["ClassName"] = "model",
				["Size"] = 0.25,
				["UniqueID"] = "1280732317",
				["EditorExpand"] = true,
				["Bone"] = "hitpos",
				["Name"] = "point 5",
				["ParentUID"] = "2657213663",
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "2657213663",
		["ClassName"] = "group",
		["Name"] = "pencil",
		["Description"] = "add parts to me!",
	},
},
}
pace.example_outfits["cloaking"] = {["children"] = {
	[1] = {
		["children"] = {
			[1] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["Arguments"] = "p",
							["UniqueID"] = "3408215400",
							["Event"] = "button",
							["Operator"] = "equal",
							["ClassName"] = "event",
							["EditorExpand"] = true,
						},
					},
				},
				["self"] = {
					["ClassName"] = "proxy",
					["UniqueID"] = "2836747662",
					["Expression"] = "max((-timeex()+1) ^ 5, 0)",
					["EditorExpand"] = true,
					["VariableName"] = "CloakFactor",
				},
			},
			[2] = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["Arguments"] = "p",
							["Invert"] = true,
							["UniqueID"] = "3680420824",
							["Event"] = "button",
							["Operator"] = "equal",
							["EditorExpand"] = true,
							["ClassName"] = "event",
						},
					},
				},
				["self"] = {
					["ClassName"] = "proxy",
					["UniqueID"] = "3171310209",
					["Expression"] = "min((timeex()+0.1) ^ 5, 1)",
					["EditorExpand"] = true,
					["VariableName"] = "CloakFactor",
				},
			},
		},
		["self"] = {
			["EditorExpand"] = true,
			["UniqueID"] = "3721614203",
			["CloakPassEnabled"] = true,
			["Name"] = "testmat",
			["ClassName"] = "material",
		},
	},
	[2] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["ClassName"] = "model",
					["UniqueID"] = "263578771",
					["Position"] = Vector(-0.00048828125, 0.001953125, -30.1435546875),
					["Translucent"] = true,
					["Material"] = "testmat",
				},
			},
		},
		["self"] = {
			["ClassName"] = "model",
			["UniqueID"] = "1778920631",
			["EditorExpand"] = true,
			["Translucent"] = true,
			["Material"] = "testmat",
		},
	},
},
["self"] = {
	["Name"] = "press p",
	["ClassName"] = "group",
	["UniqueID"] = "512753821",
	["EditorExpand"] = true,
},
}
pace.example_outfits["direction aim"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group",
				["UniqueID"] = "3828184438",
				["AimPartUID"] = "411152218",
				["Name"] = "",
				["ClassName"] = "model",
				["AimPartName"] = "hoverball",
				["ParentUID"] = "298616389",
				["Model"] = "models/Combine_Scanner.mdl",
				["Angles"] = Angle(0, 180, 0),
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "jiggle",
						["ClassName"] = "model",
						["UniqueID"] = "411152218",
						["Name"] = "",
						["ParentUID"] = "1707667187",
					},
				},
			},
			["self"] = {
				["ParentName"] = "group",
				["ClassName"] = "jiggle",
				["UniqueID"] = "1707667187",
				["StopRadius"] = 20,
				["EditorExpand"] = true,
				["Name"] = "",
				["ParentUID"] = "298616389",
			},
		},
	},
	["self"] = {
		["Name"] = "aiming",
		["ClassName"] = "group",
		["UniqueID"] = "298616389",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["beams and physics"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["ClassName"] = "model",
						["UniqueID"] = "115212208",
						["Name"] = "beam end",
						["ParentUID"] = "295021755",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["SecondsToArrive"] = 0,
						["Follow"] = true,
						["UniqueID"] = "2106190365",
						["MaxSpeed"] = 4,
						["MaxSpeedDamp"] = 0,
						["Gravity"] = false,
						["Box"] = false,
						["Name"] = "",
						["SelfCollision"] = true,
						["MaxAngular"] = 0,
						["EditorExpand"] = true,
						["ParentName"] = "hoverball",
						["Radius"] = 25,
						["ParentUID"] = "295021755",
						["MaxAngularDamp"] = 0,
						["DampFactor"] = 0,
						["ClassName"] = "physics",
					},
				},
			},
			["self"] = {
				["ParentName"] = "hoverball pet",
				["ClassName"] = "model",
				["Size"] = 4,
				["UniqueID"] = "295021755",
				["EditorExpand"] = true,
				["Name"] = "",
				["ParentUID"] = "4035355741",
			},
		},
		[2] = {
			["children"] = {
			},
			["self"] = {
				["EndPointName"] = "beam end",
				["WidthBend"] = 11.8,
				["Bend"] = 69,
				["Name"] = "",
				["ClassName"] = "beam",
				["Width"] = 0.1,
				["UniqueID"] = "4060552917",
				["ParentName"] = "hoverball pet",
				["ParentUID"] = "4035355741",
				["EndPointUID"] = "115212208",
			},
		},
	},
	["self"] = {
		["Name"] = "hoverball pet",
		["ClassName"] = "group",
		["UniqueID"] = "4035355741",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["projectiles"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentUID"] = "4290163041",
						["ClassName"] = "trail",
						["UniqueID"] = "134836612",
						["StartSize"] = 79,
						["Name"] = "",
						["ParentName"] = "hoverball",
					},
				},
			},
			["self"] = {
				["ParentName"] = "projectile outfit",
				["ClassName"] = "model",
				["UniqueID"] = "4290163041",
				["EditorExpand"] = true,
				["Name"] = "",
				["ParentUID"] = "2945112489",
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "2945112489",
		["Hide"] = true,
		["Name"] = "projectile outfit",
		["ClassName"] = "group",
	},
},
[2] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "projectile",
						["ClassName"] = "event",
						["UniqueID"] = "4104894345",
						["Arguments"] = "attack primary",
						["Event"] = "animation_event",
						["Operator"] = "equal",
						["Name"] = "",
						["ParentUID"] = "4109349808",
					},
				},
			},
			["self"] = {
				["ParentUID"] = "2369892362",
				["UniqueID"] = "4109349808",
				["Name"] = "",
				["ClassName"] = "projectile",
				["EditorExpand"] = true,
				["OutfitPartUID"] = "2945112489",
				["OutfitPartName"] = "projectile outfit",
				["EyeAngles"] = true,
				["ParentName"] = "projectile test",
			},
		},
	},
	["self"] = {
		["Name"] = "projectile test (attack to activate)",
		["ClassName"] = "group",
		["UniqueID"] = "2369892362",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["acrobatics"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3223648273",
				["ClassName"] = "bone",
				["UniqueID"] = "2768596880",
				["ParentName"] = "group 6",
				["Bone"] = "left calf",
				["Name"] = "",
				["Angles"] = Angle(0, 22.5, 0),
			},
		},
		[2] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3223648273",
				["ClassName"] = "bone",
				["UniqueID"] = "3791464752",
				["ParentName"] = "group 6",
				["Bone"] = "right calf",
				["Name"] = "",
				["Angles"] = Angle(0, 123.3125, 0),
			},
		},
		[3] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3223648273",
				["ClassName"] = "bone",
				["UniqueID"] = "2661382123",
				["ParentName"] = "group 6",
				["Bone"] = "left thigh",
				["Name"] = "",
				["Angles"] = Angle(10.183678627014, -106.71871948242, 1.9083663573838e-005),
			},
		},
		[4] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3223648273",
				["ClassName"] = "bone",
				["UniqueID"] = "348837590",
				["ParentName"] = "group 6",
				["Bone"] = "right thigh",
				["Name"] = "",
				["Angles"] = Angle(-7.7517943382263, -135.00001525879, -4.3082385673188e-005),
			},
		},
		[5] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3223648273",
				["ClassName"] = "bone",
				["UniqueID"] = "2126583953",
				["ParentName"] = "group 6",
				["Angles"] = Angle(0, 9.6875, 0),
				["Bone"] = "spine 4",
				["Name"] = "",
				["EditorExpand"] = true,
			},
		},
		[6] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group 6",
				["UniqueID"] = "2164632886",
				["SequenceName"] = "jump_dual",
				["Name"] = "",
				["ClassName"] = "animation",
				["Rate"] = 0,
				["ParentUID"] = "3223648273",
				["Offset"] = 1,
				["EditorExpand"] = true,
			},
		},
		[7] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3223648273",
				["ClassName"] = "bone",
				["UniqueID"] = "560353957",
				["ParentName"] = "group 6",
				["Name"] = "",
				["Angles"] = Angle(0, -27.78125, 0),
			},
		},
		[8] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3223648273",
				["ClassName"] = "bone",
				["UniqueID"] = "2683329050",
				["ParentName"] = "group 6",
				["Bone"] = "spine 2",
				["Name"] = "",
				["Angles"] = Angle(0, 15.9375, 0),
			},
		},
		[9] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3223648273",
				["ClassName"] = "bone",
				["UniqueID"] = "154039705",
				["ParentName"] = "group 6",
				["Bone"] = "spine 1",
				["Name"] = "",
				["Angles"] = Angle(0, 11.28125, 0),
			},
		},
		[10] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "pelvis",
						["UniqueID"] = "1547969926",
						["Name"] = "",
						["VariableName"] = "Angles",
						["ClassName"] = "proxy",
						["Additive"] = true,
						["ZeroEyePitch"] = true,
						["ParentUID"] = "1278359509",
						["EditorExpand"] = true,
						["Expression"] = "nil,owner_velocity_right()*-2",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "pelvis",
						["UniqueID"] = "216986434",
						["Name"] = "",
						["VariableName"] = "Angles",
						["ClassName"] = "proxy",
						["Additive"] = true,
						["ZeroEyePitch"] = true,
						["ParentUID"] = "1278359509",
						["Expression"] = "nil,nil,owner_velocity_forward()*-2",
					},
				},
			},
			["self"] = {
				["ParentUID"] = "3223648273",
				["UniqueID"] = "1278359509",
				["Name"] = "",
				["ClassName"] = "bone",
				["ParentName"] = "group 6",
				["EditorExpand"] = true,
				["Bone"] = "pelvis",
				["Position"] = Vector(10.199999809265, 0, 5.5999999046326),
				["Angles"] = Angle(0, 2.5128486156464, 1100.025390625),
			},
		},
		[11] = {
			["children"] = {
			},
			["self"] = {
				["ParentUID"] = "3223648273",
				["ClassName"] = "bone",
				["UniqueID"] = "931655091",
				["ParentName"] = "group 6",
				["Bone"] = "left calf",
				["Name"] = "",
				["Angles"] = Angle(0, 105.625, 0),
			},
		},
		[12] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group 6",
				["ClassName"] = "event",
				["UniqueID"] = "93830991",
				["EditorExpand"] = true,
				["Event"] = "is_on_ground",
				["Arguments"] = "1",
				["Name"] = "",
				["ParentUID"] = "3223648273",
			},
		},
	},
	["self"] = {
		["ParentName"] = "group 5",
		["ClassName"] = "group",
		["UniqueID"] = "3223648273",
		["Name"] = "acrobatic",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["run leaning"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "bone 50",
						["ClassName"] = "proxy",
						["UniqueID"] = "209517437",
						["Expression"] = "nil, owner_velocity_right()*3, owner_velocity_forward()*-1",
						["VelocityRoughness"] = 20,
						["ParentUID"] = "3891402856",
						["Name"] = "",
						["VariableName"] = "Angles",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "bone 50",
						["ClassName"] = "proxy",
						["UniqueID"] = "1699907531",
						["Expression"] = "nil,nil,abs(owner_velocity_right())*-0.25",
						["ParentUID"] = "3891402856",
						["Name"] = "",
						["VariableName"] = "Position",
					},
				},
			},
			["self"] = {
				["ParentUID"] = "2288060575",
				["UniqueID"] = "3891402856",
				["Name"] = "",
				["ClassName"] = "bone",
				["ParentName"] = "run lean",
				["EditorExpand"] = true,
				["Bone"] = "pelvis",
				["Position"] = Vector(0, 0, -1.5248252971103e-026),
				["Angles"] = Angle(0.65625, -3.0828566215146e-044, 4.2038953929745e-045),
			},
		},
	},
	["self"] = {
		["Name"] = "run lean",
		["ClassName"] = "group",
		["UniqueID"] = "2288060575",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["pet"] = {
[1] = {
	["children"] = {
	[1] = {
		["children"] = {
			[1] = {
				["children"] = {
				},
				["self"] = {
					["UniqueID"] = "2841372084",
					["Event"] = "sequence_name",
					["ClassName"] = "event",
					["Name"] = "Is not sitting",
					["Arguments"] = "sit",
				},
			},
			[2] = {
				["children"] = {
					[1] = {
						["children"] = {
							[1] = {
								["children"] = {
									[1] = {
										["children"] = {
										},
										["self"] = {
											["ClassName"] = "proxy",
											["UniqueID"] = "414998607",
											["Function"] = "none",
											["Pow"] = 1.1,
											["Name"] = "Speed",
											["VariableName"] = "Offset",
										},
									},
									[2] = {
										["children"] = {
										},
										["self"] = {
											["ClassName"] = "event",
											["Invert"] = true,
											["UniqueID"] = "3806373689",
											["Event"] = "parent_velocity_length",
											["Operator"] = "equal or below",
											["Name"] = "Idleing",
											["Arguments"] = "0.1",
										},
									},
								},
								["self"] = {
									["EditorExpand"] = true,
									["Offset"] = 3576.2130471265,
									["UniqueID"] = "2878575396",
									["Rate"] = 2.07,
									["SequenceName"] = "zombie_run_fast",
									["Name"] = "Idle-Animation",
									["ClassName"] = "animation",
								},
							},
							[2] = {
								["children"] = {
								},
								["self"] = {
									["Outline"] = 1,
									["UniqueID"] = "1103917759",
									["Angles"] = Angle(0, 90, 90),
									["ClassName"] = "text",
									["Name"] = "Pet-Name",
									["Font"] = "DermaDefault",
									["Bone"] = "",
									["Size"] = 0.1,
									["AimPartName"] = "LOCALEYES",
									["Color"] = Vector(98, 212, 202),
									["OutlineColor"] = Vector(0, 0, 0),
									["Position"] = Vector(0, 0, 38.876953125),
									["Text"] = "Name",
								},
							},
							[3] = {
								["children"] = {
									[1] = {
										["children"] = {
										},
										["self"] = {
											["ClassName"] = "proxy",
											["UniqueID"] = "1982702090",
											["Expression"] = "-owner_velocity_right()",
											["Name"] = "Pose-Range Y",
											["VariableName"] = "Range",
										},
									},
								},
								["self"] = {
									["ClassName"] = "poseparameter",
									["UniqueID"] = "823754137",
									["EditorExpand"] = true,
									["Name"] = "Move_Y",
									["PoseParameter"] = "move_y",
								},
							},
							[4] = {
								["children"] = {
									[1] = {
										["children"] = {
										},
										["self"] = {
											["ClassName"] = "event",
											["Invert"] = true,
											["UniqueID"] = "2039768100",
											["Event"] = "parent_velocity_length",
											["Operator"] = "above",
											["Name"] = "Running",
											["Arguments"] = "0.1",
										},
									},
									[2] = {
										["children"] = {
										},
										["self"] = {
											["ClassName"] = "proxy",
											["UniqueID"] = "2163461662",
											["Function"] = "none",
											["Pow"] = 1.1,
											["Name"] = "Running speed",
											["VariableName"] = "Offset",
										},
									},
								},
								["self"] = {
									["EditorExpand"] = true,
									["Offset"] = 3468.769872777,
									["UniqueID"] = "1941589296",
									["Rate"] = 2,
									["SequenceName"] = "zombie_run_fast",
									["Name"] = "Run-Animation",
									["ClassName"] = "animation",
								},
							},
							[5] = {
								["children"] = {
									[1] = {
										["children"] = {
										},
										["self"] = {
											["ClassName"] = "proxy",
											["UniqueID"] = "1585907437",
											["Expression"] = "-owner_velocity_forward()",
											["Name"] = "Pose-Range X",
											["VariableName"] = "Range",
										},
									},
								},
								["self"] = {
									["ClassName"] = "poseparameter",
									["UniqueID"] = "695260429",
									["EditorExpand"] = true,
									["Name"] = "Move_X",
									["PoseParameter"] = "move_x",
								},
							},
							[6] = {
								["children"] = {
									[1] = {
										["children"] = {
										},
										["self"] = {
											["ClassName"] = "event",
											["Invert"] = true,
											["UniqueID"] = "3866365879",
											["Event"] = "sequence_name",
											["Name"] = "Owner Is Jumping",
											["Arguments"] = "jump",
										},
									},
								},
								["self"] = {
									["Offset"] = 1,
									["UniqueID"] = "1591214338",
									["EditorExpand"] = true,
									["SequenceName"] = "swimming_all",
									["Name"] = "Jump-Animation",
									["ClassName"] = "animation",
								},
							},
						},
						["self"] = {
							["Position"] = Vector(-35.3525390625, -0.20556640625, 0),
							["AimPartUID"] = "2249661024",
							["AlternativeScaling"] = true,
							["Name"] = "Pet-Model",
							["Size"] = 0.525,
							["AimPartName"] = "Minin",
							["UniqueID"] = "2120397005",
							["Bone"] = "",
							["Model"] = "models/player/mossman_arctic.mdl",
							["ClassName"] = "model",
						},
					},
				},
				["self"] = {
					["Position"] = Vector(-2.8173828125, -0.01153564453125, 0),
					["Speed"] = 0.3,
					["Name"] = "Ease",
					["ClassName"] = "jiggle",
					["ConstrainZ"] = true,
					["StopRadius"] = 1,
					["Bone"] = "",
					["UniqueID"] = "2249661024",
				},
			},
		},
		["self"] = {
			["ClassName"] = "model",
			["UniqueID"] = "2629496463",
			["Size"] = 0,
			["EditorExpand"] = true,
			["Bone"] = "",
			["Name"] = "Base",
		},
	},
},
["self"] = {
	["ClassName"] = "group",
	["UniqueID"] = "3638855604",
	["Name"] = "Pet",
},
}
}
pace.example_outfits["scout"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["EditorExpand"] = true,
				["UniqueID"] = "3794698230",
				["ClassName"] = "entity",
				["Bone"] = "none",
				["Model"] = "models/player/hwm/scout.mdl",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "3916476839",
								["Expression"] = "nil, nil, owner_eye_angle_pitch()*-50 + 25",
								["ClassName"] = "proxy",
								["Input"] = "owner_eye_angle_pitch",
								["VariableName"] = "Angles",
							},
						},
					},
					["self"] = {
						["EditorExpand"] = true,
						["UniqueID"] = "3706039830",
						["Bone"] = "bip spine  0",
						["ClassName"] = "bone",
						["Angles"] = Angle(0, 0, 2.3859710693359),
					},
				},
				[2] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "2768103191",
								["Expression"] = "nil, nil, owner_eye_angle_pitch()*-50 + 25",
								["EditorExpand"] = true,
								["ClassName"] = "proxy",
								["Input"] = "owner_eye_angle_pitch",
								["VariableName"] = "Angles",
							},
						},
					},
					["self"] = {
						["EditorExpand"] = true,
						["UniqueID"] = "3883955167",
						["Bone"] = "bip spine  1",
						["ClassName"] = "bone",
						["Angles"] = Angle(0, 0, 2.3859710693359),
					},
				},
			},
			["self"] = {
				["UniqueID"] = "3391528412",
				["EditorExpand"] = true,
				["Name"] = "body pitch",
				["ClassName"] = "group",
			},
		},
		[3] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "event",
								["UniqueID"] = "4167178939",
								["Event"] = "holdtype",
								["EditorExpand"] = true,
								["Operator"] = "equal",
								["Arguments"] = "melee;melee2;grenade;slam",
								["Invert"] = true,
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["CrouchWalk"] = "Crouch_Walk_MELEE",
								["Fallback"] = "Run_MELEE",
								["UniqueID"] = "126820848",
								["Noclip"] = "Airwalk_MELEE",
								["Jump"] = "Jump_Start_melee",
								["AttackStandPrimaryfire"] = "MELEE_swing",
								["Swim"] = "Swim_MELEE",
								["EditorExpand"] = true,
								["Run"] = "Run_MELEE",
								["ClassName"] = "holdtype",
								["Air"] = "Jump_Float_melee",
								["ActLand"] = "jumpLand_melee",
								["CrouchIdle"] = "Crouch_MELEE",
								["StandIdle"] = "Stand_MELEE",
								["AttackCrouchPrimaryfire"] = "MELEE_crouch_swing",
							},
						},
					},
					["self"] = {
						["Position"] = Vector(0, 6, -2),
						["Name"] = "melee",
						["EditorExpand"] = true,
						["UniqueID"] = "1454655852",
						["Angles"] = Angle(0, -90, -90),
						["Bone"] = "weapon_bone_ 2",
						["ClassName"] = "entity",
						["Weapon"] = true,
					},
				},
				[2] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "1142180148",
								["ActLand"] = "jumpLand_LOSER",
								["AttackStandPrimaryfire"] = "LOSER_swing",
								["Run"] = "Run_LOSER",
								["CrouchIdle"] = "Crouch_LOSER",
								["StandIdle"] = "Stand_LOSER",
								["Fallback"] = "Run_LOSER",
								["ReloadStand"] = "ReloadStand_LOSER",
								["Noclip"] = "Airwalk_LOSER",
								["SwimIdle"] = "Swim_LOSER",
								["ReloadCrouch"] = "ReloadCrouch_LOSER",
								["AttackCrouchPrimaryfire"] = "LOSER_crouch_swing",
								["EditorExpand"] = true,
								["Swim"] = "Swim_LOSER",
								["Jump"] = "Jump_Start_LOSER",
								["CrouchWalk"] = "Crouch_Walk_LOSER",
								["Air"] = "Jump_Float_LOSER",
								["ClassName"] = "holdtype",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "event",
								["UniqueID"] = "44235598",
								["Event"] = "holdtype",
								["EditorExpand"] = true,
								["Operator"] = "equal",
								["Arguments"] = "normal",
								["Invert"] = true,
							},
						},
					},
					["self"] = {
						["Position"] = Vector(1.79345703125, 2.2670288085938, -3.9368896484375),
						["Name"] = "loser",
						["EditorExpand"] = true,
						["UniqueID"] = "1299149497",
						["Angles"] = Angle(-90, 0, -90),
						["Bone"] = "weapon_bone_ 2",
						["ClassName"] = "entity",
						["Weapon"] = true,
					},
				},
				[3] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "event",
								["UniqueID"] = "478977194",
								["Event"] = "holdtype",
								["EditorExpand"] = true,
								["Operator"] = "equal",
								["Arguments"] = "pistol",
								["Invert"] = true,
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "4021620632",
								["ActLand"] = "jumpLand_SECONDARY",
								["AttackStandPrimaryfire"] = "AttackStand_SECONDARY",
								["Run"] = "Run_SECONDARY",
								["CrouchIdle"] = "Crouch_SECONDARY",
								["StandIdle"] = "Stand_SECONDARY",
								["Fallback"] = "Run_SECONDARY",
								["ReloadStand"] = "ReloadStand_SECONDARY",
								["Noclip"] = "Airwalk_SECONDARY",
								["SwimIdle"] = "Swim_SECONDARY",
								["ReloadCrouch"] = "ReloadCrouch_SECONDARY",
								["AttackCrouchPrimaryfire"] = "SECONDARY_crouch_swing",
								["EditorExpand"] = true,
								["Swim"] = "Swim_SECONDARY",
								["Jump"] = "Jump_Start_SECONDARY",
								["CrouchWalk"] = "Crouch_Walk_SECONDARY",
								["Air"] = "Jump_Float_SECONDARY",
								["ClassName"] = "holdtype",
							},
						},
					},
					["self"] = {
						["Position"] = Vector(-0.40000000596046, 4, 0.5),
						["Name"] = "secondary",
						["EditorExpand"] = true,
						["UniqueID"] = "4107862047",
						["Angles"] = Angle(90, 180, 90),
						["Bone"] = "weapon_bone_ 2",
						["ClassName"] = "entity",
						["Weapon"] = true,
					},
				},
				[4] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "event",
								["UniqueID"] = "4046565299",
								["Event"] = "holdtype",
								["EditorExpand"] = true,
								["Operator"] = "equal",
								["Arguments"] = "physgun;smg;shotgun;crossbow;rpg",
								["Invert"] = true,
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["UniqueID"] = "1633433427",
								["ActLand"] = "jumpLand_PRIMARY",
								["AttackStandPrimaryfire"] = "AttackStand_PRIMARY",
								["Run"] = "Run_PRIMARY",
								["CrouchIdle"] = "Crouch_PRIMARY",
								["StandIdle"] = "Stand_PRIMARY",
								["Fallback"] = "Run_PRIMARY",
								["ActRangeAttack1"] = "AttackStand_PRIMARY",
								["Noclip"] = "Airwalk_PRIMARY",
								["ReloadStand"] = "ReloadStand_PRIMARY",
								["SwimIdle"] = "Swim_PRIMARY",
								["ReloadCrouch"] = "ReloadCrouch_PRIMARY",
								["AttackCrouchPrimaryfire"] = "AttackCrouch_PRIMARY",
								["EditorExpand"] = true,
								["Swim"] = "Swim_PRIMARY",
								["Jump"] = "Jump_Start_primary",
								["CrouchWalk"] = "Crouch_Walk_PRIMARY",
								["Air"] = "Jump_Float_PRIMARY",
								["ClassName"] = "holdtype",
							},
						},
					},
					["self"] = {
						["Position"] = Vector(1.79345703125, 2.2670288085938, -3.9368896484375),
						["Name"] = "primary",
						["EditorExpand"] = true,
						["UniqueID"] = "1885440714",
						["Angles"] = Angle(-90, 0, -90),
						["Bone"] = "weapon_bone_ 2",
						["ClassName"] = "entity",
						["Weapon"] = true,
					},
				},
			},
			["self"] = {
				["UniqueID"] = "2404083068",
				["EditorExpand"] = true,
				["Name"] = "holdtypes",
				["ClassName"] = "group",
			},
		},
		[4] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Position"] = Vector(38, 0, 0),
								["Name"] = "aimpoint offset",
								["ClassName"] = "model",
								["Size"] = 0,
								["UniqueID"] = "1010921696",
								["Bone"] = "",
								["Model"] = "models/pac/default.mdl",
								["EditorExpand"] = true,
							},
						},
					},
					["self"] = {
						["Model"] = "models/pac/default.mdl",
						["ClassName"] = "model",
						["UniqueID"] = "2554496253",
						["Size"] = 0,
						["EditorExpand"] = true,
						["Bone"] = "hitpos_ent_ang_zero_pitch",
						["Name"] = "aim point",
					},
				},
				[2] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Angles"] = Angle(0, 90, -90),
								["UniqueID"] = "351823559",
								["Model"] = "models/pac/default.mdl",
								["Size"] = 0,
								["Name"] = "head follow",
								["ClassName"] = "model",
							},
						},
					},
					["self"] = {
						["Position"] = Vector(0, -4, 0),
						["AimPartUID"] = "1010921696",
						["Material"] = "models/weapons/v_crowbar/head_uvw",
						["Name"] = "head origin",
						["Scale"] = Vector(1.7000000476837, 1, 1),
						["EditorExpand"] = true,
						["Size"] = 0,
						["AimPartName"] = "aimpoint offset",
						["UniqueID"] = "3330122862",
						["Bone"] = "bip neck",
						["Model"] = "models/pac/default.mdl",
						["ClassName"] = "model",
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["FollowAnglesOnly"] = true,
						["ClassName"] = "bone",
						["UniqueID"] = "68316071",
						["FollowPartName"] = "w",
						["Bone"] = "bip head",
						["FollowPartUID"] = "351823559",
					},
				},
			},
			["self"] = {
				["UniqueID"] = "3248913488",
				["EditorExpand"] = true,
				["Name"] = "head aim",
				["ClassName"] = "group",
			},
		},
	},
	["self"] = {
		["UniqueID"] = "1008348447",
		["EditorExpand"] = true,
		["Name"] = "scout",
		["ClassName"] = "group",
	},
},
}
pace.example_outfits["alternative noclip"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group",
				["ClassName"] = "animation",
				["UniqueID"] = "2927189943",
				["Rate"] = 0,
				["Offset"] = 0.35,
				["SequenceName"] = "swimming_all",
				["Name"] = "",
				["ParentUID"] = "2962288236",
			},
		},
		[2] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group",
				["ClassName"] = "event",
				["Invert"] = true,
				["UniqueID"] = "3792369850",
				["Event"] = "is_in_noclip",
				["Operator"] = "",
				["Name"] = "",
				["ParentUID"] = "2962288236",
			},
		},
	},
	["self"] = {
		["Name"] = "alternative noclip",
		["ClassName"] = "group",
		["UniqueID"] = "2962288236",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["thrown grenade skin"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "grenade hand",
				["ClassName"] = "model",
				["Position"] = Vector(3, 0, 0),
				["UniqueID"] = "774008521",
				["Bone"] = "right hand",
				["Name"] = "",
				["ParentUID"] = "1583647680",
			},
		},
		[2] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "grenade hand",
				["Invert"] = true,
				["Name"] = "",
				["ClassName"] = "event",
				["UniqueID"] = "4040202386",
				["ParentUID"] = "1583647680",
				["Operator"] = "equal",
				["Event"] = "weapon_class",
				["Arguments"] = "weapon_frag@@1",
			},
		},
	},
	["self"] = {
		["Name"] = "grenade hand",
		["ClassName"] = "group",
		["UniqueID"] = "1583647680",
		["EditorExpand"] = true,
	},
},
[2] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group",
				["ClassName"] = "model",
				["UniqueID"] = "124624470",
				["Name"] = "",
				["ParentUID"] = "3816187223",
			},
		},
	},
	["self"] = {
		["ClassName"] = "group",
		["UniqueID"] = "3816187223",
		["Name"] = "thrown grenade skin",
		["EditorExpand"] = true,
		["Duplicate"] = true,
		["OwnerName"] = "frag",
	},
},
}
pace.example_outfits["aimpart eyes"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group",
				["ClassName"] = "model",
				["Position"] = Vector(13, 0, 0),
				["AimPartName"] = "LOCALEYES",
				["UniqueID"] = "2375757640",
				["Name"] = "I always look at you!",
				["ParentUID"] = "2728547329",
			},
		},
		[2] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group",
				["ClassName"] = "model",
				["Position"] = Vector(13.317047119141, 1.9924926757813, -13.223754882813),
				["AimPartName"] = "PLAYEREYES",
				["UniqueID"] = "4254836979",
				["EyeAngles"] = true,
				["Name"] = "I look at the person you're aiming at!",
				["ParentUID"] = "2728547329",
			},
		},
		[3] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "group",
				["ClassName"] = "model",
				["Position"] = Vector(13.778839111328, 0.87811279296875, 12.80078125),
				["AimPartName"] = "LOCALEYES",
				["UniqueID"] = "4254836979",
				["Name"] = "I will follow at your eye angles!",
				["ParentUID"] = "2728547329",
			},
		},
	},
	["self"] = {
		["Name"] = "eye test",
		["ClassName"] = "group",
		["UniqueID"] = "2728547329",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["custom texture"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "tv monitor",
						["Position"] = Vector(5.6459999084473, -1.9769999980927, 0.68999999761581),
						["Name"] = "webcam image",
						["Scale"] = Vector(0.69999998807907, 1, 1.3700000047684),
						["ParentUID"] = "846923788",
						["ClassName"] = "model",
						["Size"] = 0.308,
						["UniqueID"] = "463513559",
						["Material"] = "http://www.marikollen.no/axis2b.jpg",
						["Fullbright"] = true,
						["Model"] = "models/hunter/plates/plate1x1.mdl",
						["Angles"] = Angle(90, 0, 0),
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "tv monitor",
						["Position"] = Vector(5.6459999084473, -1.9769999980927, 0.68999999761581),
						["Model"] = "models/hunter/plates/plate1x1.mdl",
						["UniqueID"] = "2979959881",
						["Name"] = "tv noise",
						["Scale"] = Vector(0.69999998807907, 1, 1.3700000047684),
						["Angles"] = Angle(90, 0, 0),
						["ClassName"] = "model",
						["Size"] = 0.308,
						["Material"] = "Effects/tvscreen_noise002a",
						["Color"] = Vector(255, 255, 171),
						["Fullbright"] = true,
						["Brightness"] = 3.8,
						["ParentUID"] = "846923788",
					},
				},
			},
			["self"] = {
				["ParentName"] = "group",
				["Position"] = Vector(2, 0, -2),
				["Name"] = "",
				["ClassName"] = "model",
				["EditorExpand"] = true,
				["ParentUID"] = "1754034265",
				["Angles"] = Angle(0, -90, -90),
				["Model"] = "models/props_c17/tv_monitor01.mdl",
				["UniqueID"] = "846923788",
			},
		},
	},
	["self"] = {
		["Name"] = "url texture test",
		["ClassName"] = "group",
		["UniqueID"] = "1754034265",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["white material"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["Position"] = Vector(-1, 0, 11),
						["Name"] = "",
						["ClassName"] = "model",
						["UniqueID"] = "288937067",
						["Color"] = Vector(33, 255, 0),
						["Material"] = "white_material",
						["ParentUID"] = "3918691596",
						["EditorExpand"] = true,
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ParentUID"] = "3918691596",
						["UniqueID"] = "1024988007",
						["Name"] = "white_material",
						["ParentName"] = "hoverball",
						["RimlightExponent"] = 34.700000762939,
						["EditorExpand"] = true,
						["BaseTexture"] = "models/debug/debugwhite",
						["ClassName"] = "material",
						["OwnerName"] = "",
						["PhongBoost"] = 0.10000000149012,
						["BumpMap"] = "dev/bump_normal",
						["Rimlight"] = true,
						["PhongFresnelRanges"] = Vector(1.09375, 1.09375, 1.09375),
						["Phong"] = true,
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["Position"] = Vector(-1, 0, -9),
						["AlternativeScaling"] = true,
						["Name"] = "",
						["ParentUID"] = "3918691596",
						["ClassName"] = "model",
						["Size"] = 0.35,
						["UniqueID"] = "452643146",
						["Color"] = Vector(127, 255, 255),
						["Material"] = "white_material",
						["Model"] = "models/Combine_Scanner.mdl",
						["Angles"] = Angle(0, -90, -90),
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["UniqueID"] = "163925285",
						["Name"] = "",
						["ClassName"] = "model",
						["Size"] = 0.7,
						["Color"] = Vector(255, 191, 0),
						["Material"] = "white_material",
						["Model"] = "models/hunter/blocks/cube025x025x025.mdl",
						["ParentUID"] = "3918691596",
					},
				},
				[5] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["Outline"] = 1.1,
						["UniqueID"] = "315091138",
						["Name"] = "",
						["ClassName"] = "text",
						["Size"] = 0.25,
						["Position"] = Vector(8, 0, 0),
						["ParentUID"] = "3918691596",
						["OutlineColor"] = Vector(0, 0, 0),
						["Angles"] = Angle(90, -90, 0),
						["Text"] = "custom white material",
					},
				},
			},
			["self"] = {
				["ParentName"] = "material test",
				["ClassName"] = "model",
				["Position"] = Vector(13, 0, 0),
				["UniqueID"] = "3918691596",
				["Size"] = 0,
				["EditorExpand"] = true,
				["Name"] = "",
				["ParentUID"] = "4055337243",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["Position"] = Vector(-1, 0, 11),
						["Name"] = "",
						["ClassName"] = "model",
						["UniqueID"] = "1976803975",
						["Color"] = Vector(0, 255, 63),
						["Material"] = "models/debug/debugwhite",
						["ParentUID"] = "2310852168",
						["EditorExpand"] = true,
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["Position"] = Vector(-1, 0, -9),
						["AlternativeScaling"] = true,
						["Name"] = "",
						["ParentUID"] = "2310852168",
						["ClassName"] = "model",
						["Size"] = 0.35,
						["UniqueID"] = "2229102787",
						["Color"] = Vector(127, 255, 255),
						["Material"] = "models/debug/debugwhite",
						["Model"] = "models/Combine_Scanner.mdl",
						["Angles"] = Angle(0, -90, -90),
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["UniqueID"] = "153198253",
						["Name"] = "",
						["ClassName"] = "model",
						["Size"] = 0.7,
						["Color"] = Vector(255, 191, 0),
						["Material"] = "models/debug/debugwhite",
						["Model"] = "models/hunter/blocks/cube025x025x025.mdl",
						["ParentUID"] = "2310852168",
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["Outline"] = 1.1,
						["UniqueID"] = "2512445182",
						["Name"] = "",
						["ClassName"] = "text",
						["Size"] = 0.25,
						["Position"] = Vector(8, 0, 0),
						["ParentUID"] = "2310852168",
						["OutlineColor"] = Vector(0, 0, 0),
						["Angles"] = Angle(90, -90, 0),
						["Text"] = "models/debug/debugwhite",
					},
				},
			},
			["self"] = {
				["ParentName"] = "material test",
				["ClassName"] = "model",
				["Position"] = Vector(30, 0, 0),
				["UniqueID"] = "2310852168",
				["Size"] = 0,
				["EditorExpand"] = true,
				["Name"] = "",
				["ParentUID"] = "4055337243",
			},
		},
	},
	["self"] = {
		["Name"] = "material test",
		["ClassName"] = "group",
		["UniqueID"] = "4055337243",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["meathook crowbar"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "meathooka",
						["Invert"] = true,
						["Name"] = "",
						["ClassName"] = "event",
						["UniqueID"] = "2936785357",
						["ParentUID"] = "1275424410",
						["Operator"] = "equal",
						["Event"] = "weapon_class",
						["Arguments"] = "weapon_crowbar@@1",
					},
				},
			},
			["self"] = {
				["ParentName"] = "group",
				["Position"] = Vector(3.2984008789063, -3.8543701171875, -3.4800720214844),
				["Name"] = "",
				["ClassName"] = "model",
				["EditorExpand"] = true,
				["ParentUID"] = "1051241830",
				["Bone"] = "right hand",
				["Model"] = "models/props_junk/meathook001a.mdl",
				["UniqueID"] = "1275424410",
			},
		},
	},
	["self"] = {
		["Name"] = "",
		["ClassName"] = "group",
		["UniqueID"] = "1051241830",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["weapons on back"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "has weapon equal \"weapon pistol\"",
								["UniqueID"] = "1106157978",
								["Name"] = "",
								["ClassName"] = "event",
								["ParentUID"] = "3886076484",
								["Event"] = "weapon_class",
								["Operator"] = "equal",
								["EditorExpand"] = true,
								["Arguments"] = "weapon_pistol",
							},
						},
					},
					["self"] = {
						["ParentName"] = "w pistol",
						["Invert"] = true,
						["Name"] = "",
						["ClassName"] = "event",
						["UniqueID"] = "3886076484",
						["Arguments"] = "weapon_pistol",
						["ParentUID"] = "314111413",
						["Operator"] = "equal",
						["Event"] = "has_weapon",
						["EditorExpand"] = true,
					},
				},
			},
			["self"] = {
				["ParentName"] = "group",
				["Skin"] = 1,
				["Position"] = Vector(-6.560302734375, 1.0362396240234, 1.2730102539063),
				["Name"] = "",
				["Angles"] = Angle(14.65625, 81.9375, 13.28125),
				["ClassName"] = "model",
				["UniqueID"] = "314111413",
				["EditorExpand"] = true,
				["Bone"] = "pelvis",
				["Model"] = "models/weapons/w_pistol.mdl",
				["ParentUID"] = "3227451436",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "has weapon equal \"weapon physgun\"",
								["UniqueID"] = "1106157978",
								["Name"] = "",
								["ClassName"] = "event",
								["ParentUID"] = "1223387592",
								["Event"] = "weapon_class",
								["Operator"] = "equal",
								["EditorExpand"] = true,
								["Arguments"] = "weapon_physgun",
							},
						},
					},
					["self"] = {
						["ParentName"] = "w physics",
						["Invert"] = true,
						["Name"] = "",
						["ClassName"] = "event",
						["UniqueID"] = "1223387592",
						["Arguments"] = "weapon_physgun",
						["ParentUID"] = "3263695821",
						["Operator"] = "equal",
						["Event"] = "has_weapon",
						["EditorExpand"] = true,
					},
				},
			},
			["self"] = {
				["ParentName"] = "group",
				["Skin"] = 1,
				["Position"] = Vector(-3.3938903808594, -4.792236328125, -2.058349609375),
				["Name"] = "",
				["Angles"] = Angle(8.03125, 4.3125, 134.9375),
				["ClassName"] = "model",
				["UniqueID"] = "3263695821",
				["EditorExpand"] = true,
				["Bone"] = "spine",
				["Model"] = "models/Weapons/w_physics.mdl",
				["ParentUID"] = "3227451436",
			},
		},
		[3] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "has weapon equal \"weapon physcannon\"",
								["ClassName"] = "event",
								["UniqueID"] = "1106157978",
								["Arguments"] = "weapon_physcannon",
								["Event"] = "weapon_class",
								["Operator"] = "equal",
								["Name"] = "",
								["ParentUID"] = "1428301906",
							},
						},
					},
					["self"] = {
						["ParentName"] = "w physics",
						["Invert"] = true,
						["Name"] = "",
						["ClassName"] = "event",
						["UniqueID"] = "1428301906",
						["Arguments"] = "weapon_physcannon",
						["ParentUID"] = "3263695821",
						["Operator"] = "equal",
						["Event"] = "has_weapon",
						["EditorExpand"] = true,
					},
				},
			},
			["self"] = {
				["ParentName"] = "group",
				["Position"] = Vector(-3.3938903808594, -4.792236328125, -2.058349609375),
				["Name"] = "",
				["ClassName"] = "model",
				["Angles"] = Angle(-24.9375, -9.875, 97.34375),
				["UniqueID"] = "3263695821",
				["ParentUID"] = "3227451436",
				["Bone"] = "spine",
				["Model"] = "models/Weapons/w_physics.mdl",
				["EditorExpand"] = true,
			},
		},
		[4] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "has weapon equal \"weapon crowbar\"",
								["UniqueID"] = "2261979630",
								["Name"] = "",
								["ClassName"] = "event",
								["ParentUID"] = "566028478",
								["Event"] = "weapon_class",
								["Operator"] = "equal",
								["EditorExpand"] = true,
								["Arguments"] = "weapon_crowbar",
							},
						},
					},
					["self"] = {
						["ParentName"] = "w crowbar",
						["Invert"] = true,
						["Name"] = "",
						["ClassName"] = "event",
						["UniqueID"] = "566028478",
						["Arguments"] = "weapon_crowbar",
						["ParentUID"] = "24878752",
						["Operator"] = "equal",
						["Event"] = "has_weapon",
						["EditorExpand"] = true,
					},
				},
			},
			["self"] = {
				["ParentName"] = "group",
				["Position"] = Vector(-2.3724746704102, -4.6481323242188, 0.36083984375),
				["Name"] = "",
				["ClassName"] = "model",
				["Angles"] = Angle(-33.875, -11.25, 98.03125),
				["UniqueID"] = "24878752",
				["ParentUID"] = "3227451436",
				["Bone"] = "spine",
				["Model"] = "models/Weapons/w_crowbar.mdl",
				["EditorExpand"] = true,
			},
		},
	},
	["self"] = {
		["Name"] = "weapons on back",
		["ClassName"] = "group",
		["UniqueID"] = "3227451436",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["rolling ball"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "trackball ",
								["UniqueID"] = "3346301612",
								["Name"] = "",
								["VariableName"] = "Angles",
								["ClassName"] = "proxy",
								["Additive"] = true,
								["RootOwner"] = true,
								["ParentUID"] = "3440646591",
								["Expression"] = "-owner_velocity_forward() * 2",
							},
						},
					},
					["self"] = {
						["ParentName"] = "hoverball",
						["Position"] = Vector(0, 0, -0.10000000149012),
						["Name"] = "",
						["ParentUID"] = "2375944239",
						["UniqueID"] = "3440646591",
						["ClassName"] = "model",
						["Size"] = 1.65,
						["EditorExpand"] = true,
						["Angles"] = Angle(8582.53125, 0, 90),
						["Bone"] = "none",
						["Model"] = "models/XQM/Rails/trackball_1.mdl",
						["Description"] = "the actual forward roll ball",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "base",
						["UniqueID"] = "459998550",
						["Name"] = "",
						["VariableName"] = "Angles",
						["ClassName"] = "proxy",
						["Expression"] = "nil, nil, owner_velocity_right() * 5",
						["ParentUID"] = "2375944239",
						["RootOwner"] = true,
						["Description"] = "this is for side lean",
					},
				},
			},
			["self"] = {
				["ParentName"] = "my outfit",
				["Position"] = Vector(0, 0, 24),
				["Name"] = "base",
				["Angles"] = Angle(0, 0, 7.0064923216241e-045),
				["ClassName"] = "model",
				["Size"] = 1.075,
				["UniqueID"] = "2375944239",
				["ParentUID"] = "2375944239",
				["Bone"] = "none",
				["Model"] = "models/XQM/Rails/trackball_1.mdl",
				["EditorExpand"] = true,
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "2683560774",
		["ClassName"] = "group",
		["Name"] = "rolling ball",
		["Description"] = "add parts to me!",
	},
},
}
pace.example_outfits["console command event"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "zone",
						["Invert"] = true,
						["Name"] = "",
						["ClassName"] = "event",
						["UniqueID"] = "899328776",
						["ParentUID"] = "2227000698",
						["Arguments"] = "speak@@0.5",
						["Event"] = "command",
						["EditorExpand"] = true,
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "zone",
						["ClassName"] = "proxy",
						["UniqueID"] = "2871073228",
						["Expression"] = "randx(0.2, 0.3)",
						["EditorExpand"] = true,
						["ParentUID"] = "2227000698",
						["Name"] = "",
						["VariableName"] = "Pitch",
					},
				},
			},
			["self"] = {
				["ParentName"] = "sounds",
				["ClassName"] = "sound",
				["UniqueID"] = "2227000698",
				["ParentUID"] = "572820835",
				["Pitch"] = 0.28428220437401,
				["EditorExpand"] = true,
				["Name"] = "",
				["Sound"] = "npc/overwatch/radiovoice/404zone.wav;npc/overwatch/radiovoice/_comma.wav;npc/overwatch/radiovoice/accomplicesoperating.wav;npc/overwatch/radiovoice/administer.wav;npc/overwatch/radiovoice/airwatchcopiesnoactivity.wav;npc/overwatch/radiovoice/airwatchreportspossiblemiscount.wav;npc/overwatch/radiovoice/alarms62.wav;npc/overwatch/radiovoice/allteamsrespondcode3.wav;npc/overwatch/radiovoice/allunitsapplyforwardpressure.wav;npc/overwatch/radiovoice/allunitsat.wav;npc/overwatch/radiovoice/allunitsbeginwhitnesssterilization.wav;npc/overwatch/radiovoice/allunitsbolfor243suspect.wav;npc/overwatch/radiovoice/allunitsdeliverterminalverdict.wav;npc/overwatch/radiovoice/allunitsreturntocode12.wav;npc/overwatch/radiovoice/allunitsverdictcodeis.wav;npc/overwatch/radiovoice/allunitsverdictcodeonsuspect.wav;npc/overwatch/radiovoice/amputate.wav;npc/overwatch/radiovoice/anticitizen.wav;npc/overwatch/radiovoice/antifatigueration3mg.wav;npc/overwatch/radiovoice/apply.wav;npc/overwatch/radiovoice/assault243.wav;npc/overwatch/radiovoice/attemptedcrime27.wav;npc/overwatch/radiovoice/attention.wav;npc/overwatch/radiovoice/attentionyouhavebeenchargedwith.wav;npc/overwatch/radiovoice/beginscanning10-0.wav;npc/overwatch/radiovoice/block.wav;npc/overwatch/radiovoice/canalblock.wav;npc/overwatch/radiovoice/capitalmalcompliance.wav;npc/overwatch/radiovoice/cauterize.wav;npc/overwatch/radiovoice/citizen.wav;npc/overwatch/radiovoice/completesentencingatwill.wav;npc/overwatch/radiovoice/condemnedzone.wav;npc/overwatch/radiovoice/confirmupialert.wav;npc/overwatch/radiovoice/controlsection.wav;npc/overwatch/radiovoice/criminaltrespass63.wav;npc/overwatch/radiovoice/defender.wav;npc/overwatch/radiovoice/deservicedarea.wav;npc/overwatch/radiovoice/destrutionofcpt.wav;npc/overwatch/radiovoice/devisivesociocidal.wav;npc/overwatch/radiovoice/die1.wav;npc/overwatch/radiovoice/die2.wav;npc/overwatch/radiovoice/die3.wav;npc/overwatch/radiovoice/disassociationfromcivic.wav;npc/overwatch/radiovoice/disengaged647e.wav;npc/overwatch/radiovoice/distributionblock.wav;npc/overwatch/radiovoice/disturbancemental10-103m.wav;npc/overwatch/radiovoice/disturbingunity415.wav;npc/overwatch/radiovoice/document.wav;npc/overwatch/radiovoice/eight.wav;npc/overwatch/radiovoice/engagingteamisnoncohesive.wav;npc/overwatch/radiovoice/examine.wav;npc/overwatch/radiovoice/externaljurisdiction.wav;npc/overwatch/radiovoice/failuretocomply.wav;npc/overwatch/radiovoice/failuretotreatoutbreak.wav;npc/overwatch/radiovoice/finalverdictadministered.wav;npc/overwatch/radiovoice/five.wav;npc/overwatch/radiovoice/fmil_Region 073.wav;npc/overwatch/radiovoice/four.wav;npc/overwatch/radiovoice/freeman.wav;npc/overwatch/radiovoice/fugitive17f.wav;npc/overwatch/radiovoice/halfrankpoints.wav;npc/overwatch/radiovoice/halfreproductioncredits.wav;npc/overwatch/radiovoice/hero.wav;npc/overwatch/radiovoice/highpriorityregion.wav;npc/overwatch/radiovoice/illegalcarrying95.wav;npc/overwatch/radiovoice/illegalinoperation63s.wav;npc/overwatch/radiovoice/immediateamputation.wav;npc/overwatch/radiovoice/incitingpopucide.wav;npc/overwatch/radiovoice/industrialzone.wav;npc/overwatch/radiovoice/infection.wav;npc/overwatch/radiovoice/infestedzone.wav;npc/overwatch/radiovoice/inject.wav;npc/overwatch/radiovoice/innoculate.wav;npc/overwatch/radiovoice/inprogress.wav;npc/overwatch/radiovoice/intercede.wav;npc/overwatch/radiovoice/interlock.wav;npc/overwatch/radiovoice/investigate.wav;npc/overwatch/radiovoice/investigateandreport.wav;npc/overwatch/radiovoice/isnow.wav;npc/overwatch/radiovoice/isolate.wav;npc/overwatch/radiovoice/jury.wav;npc/overwatch/radiovoice/king.wav;npc/overwatch/radiovoice/leadersreportratios.wav;npc/overwatch/radiovoice/level5anticivilactivity.wav;npc/overwatch/radiovoice/line.wav;npc/overwatch/radiovoice/lock.wav;npc/overwatch/radiovoice/lockdownlocationsacrificecode.wav;npc/overwatch/radiovoice/lostbiosignalforunit.wav;npc/overwatch/radiovoice/nine.wav;npc/overwatch/radiovoice/noncitizen.wav;npc/overwatch/radiovoice/nonpatrolregion.wav;npc/overwatch/radiovoice/nonsanctionedarson51.wav;npc/overwatch/radiovoice/off2.wav;npc/overwatch/radiovoice/off4.wav;npc/overwatch/radiovoice/officerat.wav;npc/overwatch/radiovoice/officerclosingonsuspect.wav;npc/overwatch/radiovoice/on1.wav;npc/overwatch/radiovoice/on3.wav;npc/overwatch/radiovoice/one.wav;npc/overwatch/radiovoice/outlandzone.wav;npc/overwatch/radiovoice/patrol.wav;npc/overwatch/radiovoice/permanentoffworld.wav;npc/overwatch/radiovoice/politistablizationmarginal.wav;npc/overwatch/radiovoice/posession69.wav;npc/overwatch/radiovoice/prematuremissiontermination.wav;npc/overwatch/radiovoice/prepareforfinalsentencing.wav;npc/overwatch/radiovoice/preparetoinnoculate.wav;npc/overwatch/radiovoice/preparetoreceiveverdict.wav;npc/overwatch/radiovoice/preparevisualdownload.wav;npc/overwatch/radiovoice/preserve.wav;npc/overwatch/radiovoice/pressure.wav;npc/overwatch/radiovoice/productionblock.wav;npc/overwatch/radiovoice/promotingcommunalunrest.wav;npc/overwatch/radiovoice/prosecute.wav;npc/overwatch/radiovoice/publicnoncompliance507.wav;npc/overwatch/radiovoice/quick.wav;npc/overwatch/radiovoice/recalibratesocioscan.wav;npc/overwatch/radiovoice/recievingconflictingdata.wav;npc/overwatch/radiovoice/recklessoperation99.wav;npc/overwatch/radiovoice/reinforcementteamscode3.wav;npc/overwatch/radiovoice/remainingunitscontain.wav;npc/overwatch/radiovoice/reminder100credits.wav;npc/overwatch/radiovoice/remindermemoryreplacement.wav;npc/overwatch/radiovoice/reporton.wav;npc/overwatch/radiovoice/reportplease.wav;npc/overwatch/radiovoice/repurposedarea.wav;npc/overwatch/radiovoice/residentialblock.wav;npc/overwatch/radiovoice/resistingpacification148.wav;npc/overwatch/radiovoice/respond.wav;npc/overwatch/radiovoice/restrict.wav;npc/overwatch/radiovoice/restrictedblock.wav;npc/overwatch/radiovoice/restrictedincursioninprogress.wav;npc/overwatch/radiovoice/rewardnotice.wav;npc/overwatch/radiovoice/riot404.wav;npc/overwatch/radiovoice/roller.wav;npc/overwatch/radiovoice/search.wav;npc/overwatch/radiovoice/sector.wav;npc/overwatch/radiovoice/serve.wav;npc/overwatch/radiovoice/seven.wav;npc/overwatch/radiovoice/six.wav;npc/overwatch/radiovoice/socialfractureinprogress.wav;npc/overwatch/radiovoice/sociocide.wav;npc/overwatch/radiovoice/sociostabilizationrestored.wav;npc/overwatch/radiovoice/stabilizationjurisdiction.wav;npc/overwatch/radiovoice/stationblock.wav;npc/overwatch/radiovoice/statuson243suspect.wav;npc/overwatch/radiovoice/sterilize.wav;npc/overwatch/radiovoice/stick.wav;npc/overwatch/radiovoice/stormsystem.wav;npc/overwatch/radiovoice/subject.wav;npc/overwatch/radiovoice/suspectisnow187.wav;npc/overwatch/radiovoice/suspectmalignantverdictcodeis.wav;npc/overwatch/radiovoice/suspend.wav;npc/overwatch/radiovoice/suspendnegotiations.wav;npc/overwatch/radiovoice/switchcomtotac3.wav;npc/overwatch/radiovoice/switchtotac5reporttocp.wav;npc/overwatch/radiovoice/tap.wav;npc/overwatch/radiovoice/teamsreportstatus.wav;npc/overwatch/radiovoice/terminalprosecution.wav;npc/overwatch/radiovoice/terminalrestrictionzone.wav;npc/overwatch/radiovoice/threattoproperty51b.wav;npc/overwatch/radiovoice/three.wav;npc/overwatch/radiovoice/transitblock.wav;npc/overwatch/radiovoice/two.wav;npc/overwatch/radiovoice/union.wav;npc/overwatch/radiovoice/unitdeserviced.wav;npc/overwatch/radiovoice/unitdownat.wav;npc/overwatch/radiovoice/unlawfulentry603.wav;npc/overwatch/radiovoice/upi.wav;npc/overwatch/radiovoice/vice.wav;npc/overwatch/radiovoice/victor.wav;npc/overwatch/radiovoice/violationofcivictrust.wav;npc/overwatch/radiovoice/wasteriver.wav;npc/overwatch/radiovoice/weapon94.wav;npc/overwatch/radiovoice/workforceintake.wav;npc/overwatch/radiovoice/xray.wav;npc/overwatch/radiovoice/yellow.wav;npc/overwatch/radiovoice/youarechargedwithterminal.wav;npc/overwatch/radiovoice/youarejudgedguilty.wav;npc/overwatch/radiovoice/zero.wav;npc/overwatch/radiovoice/zone.wav",
			},
		},
	},
	["self"] = {
		["Name"] = "run \"pac_event speak\" in console!",
		["ClassName"] = "group",
		["UniqueID"] = "2684545507",
		["EditorExpand"] = true,
	},
},
}
pace.example_outfits["crowbar sound"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ParentName"] = "attack stop2",
						["ClassName"] = "event",
						["UniqueID"] = "3759671898",
						["Arguments"] = "attack primary",
						["Event"] = "animation_event",
						["Operator"] = "equal",
						["Name"] = "animation event equal \"attack primary\"",
						["ParentUID"] = "4118723227",
					},
				},
			},
			["self"] = {
				["ParentName"] = "my outfit",
				["ClassName"] = "sound",
				["UniqueID"] = "4118723227",
				["ParentUID"] = "195077844",
				["EditorExpand"] = true,
				["Overlapping"] = true,
				["Name"] = "",
				["Sound"] = "npc/combine_gunship/attack_start2.wav",
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "195077844",
		["ClassName"] = "group",
		["Name"] = "crowbar sound",
		["Description"] = "add parts to me!",
	},
},
}
pace.example_outfits["engineer wrench viewmodel"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "swing a",
								["Invert"] = true,
								["Name"] = "",
								["ClassName"] = "event",
								["UniqueID"] = "2065992220",
								["ParentUID"] = "4012617537",
								["Operator"] = "find",
								["Event"] = "sequence_name",
								["Arguments"] = "miss;hit",
							},
						},
					},
					["self"] = {
						["ParentName"] = "v wrench engineer",
						["UniqueID"] = "4012617537",
						["SequenceName"] = "swing_a;swing_b;swing_c",
						["Name"] = "",
						["ClassName"] = "animation",
						["OwnerCycle"] = true,
						["Rate"] = 27.16,
						["ParentUID"] = "985706371",
						["EditorExpand"] = true,
					},
				},
				[2] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "draw",
								["Invert"] = true,
								["Name"] = "",
								["ClassName"] = "event",
								["UniqueID"] = "329197997",
								["ParentUID"] = "3935937698",
								["Operator"] = "find",
								["Event"] = "sequence_name",
								["Arguments"] = "draw",
							},
						},
					},
					["self"] = {
						["ParentName"] = "v wrench engineer",
						["UniqueID"] = "3935937698",
						["SequenceName"] = "draw",
						["Name"] = "",
						["ClassName"] = "animation",
						["OwnerCycle"] = true,
						["Rate"] = 27.16,
						["ParentUID"] = "985706371",
						["EditorExpand"] = true,
					},
				},
				[3] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ParentName"] = "idle tap",
								["Invert"] = true,
								["Name"] = "",
								["ClassName"] = "event",
								["UniqueID"] = "329197997",
								["ParentUID"] = "3935937698",
								["Operator"] = "find",
								["Event"] = "sequence_name",
								["Arguments"] = "idle",
							},
						},
					},
					["self"] = {
						["ParentName"] = "v wrench engineer",
						["UniqueID"] = "3935937698",
						["SequenceName"] = "idle_tap",
						["Name"] = "",
						["ClassName"] = "animation",
						["OwnerCycle"] = true,
						["Rate"] = 27.16,
						["ParentUID"] = "985706371",
						["EditorExpand"] = true,
					},
				},
			},
			["self"] = {
				["ParentName"] = "my outfit",
				["Position"] = Vector(4, 0, 0),
				["Name"] = "",
				["ClassName"] = "model",
				["EditorExpand"] = true,
				["ParentUID"] = "3452433632",
				["Bone"] = "none",
				["Model"] = "models/weapons/v_models/v_wrench_engineer.mdl",
				["UniqueID"] = "985706371",
			},
		},
		[2] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "my outfit",
				["ClassName"] = "entity",
				["HideEntity"] = true,
				["UniqueID"] = "1488372497",
				["Name"] = "",
				["ParentUID"] = "3452433632",
			},
		},
		[3] = {
			["children"] = {
			},
			["self"] = {
				["ParentName"] = "my outfit",
				["Invert"] = true,
				["Name"] = "",
				["ClassName"] = "event",
				["UniqueID"] = "2066236890",
				["ParentUID"] = "3452433632",
				["Operator"] = "equal",
				["Event"] = "weapon_class",
				["Arguments"] = "weapon_crowbar@@0",
			},
		},
	},
	["self"] = {
		["ClassName"] = "group",
		["OwnerName"] = "viewmodel",
		["UniqueID"] = "3452433632",
		["EditorExpand"] = true,
		["Name"] = "engineer wrench",
		["Description"] = "add parts to me!",
	},
},
}

pace.example_outfits["toggle visor"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "event",
								["UniqueID"] = "322686765",
								["Event"] = "is_flashlight_on",
							},
						},
					},
					["self"] = {
						["ClassName"] = "proxy",
						["UniqueID"] = "3911060605",
						["Expression"] = "1.5-clamp(timeex()*0.75,0,1.5),nil,nil",
						["EditorExpand"] = true,
						["VariableName"] = "PositionOffset",
					},
				},
				[2] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Event"] = "is_flashlight_on",
								["ClassName"] = "event",
								["Invert"] = true,
								["UniqueID"] = "2946404636",
							},
						},
					},
					["self"] = {
						["ClassName"] = "proxy",
						["UniqueID"] = "1059528532",
						["Expression"] = "clamp(timeex()*0.75,0,1.5),nil,nil",
						["EditorExpand"] = true,
						["VariableName"] = "PositionOffset",
					},
				},
				[3] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "event",
								["UniqueID"] = "989968329",
								["Event"] = "is_flashlight_on",
							},
						},
					},
					["self"] = {
						["ClassName"] = "proxy",
						["UniqueID"] = "11378563",
						["Expression"] = "-20+clamp(timeex()*10,0,20),nil,nil",
						["EditorExpand"] = true,
						["VariableName"] = "AngleOffset",
					},
				},
				[4] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Event"] = "is_flashlight_on",
								["ClassName"] = "event",
								["Invert"] = true,
								["UniqueID"] = "1761752820",
							},
						},
					},
					["self"] = {
						["ClassName"] = "proxy",
						["UniqueID"] = "2769038604",
						["Expression"] = "-clamp(timeex()*10,0,20),nil,nil",
						["EditorExpand"] = true,
						["VariableName"] = "AngleOffset",
					},
				},
			},
			["self"] = {
				["EditorExpand"] = true,
				["Position"] = Vector(0, 0.66455078125, 0.0146484375),
				["UniqueID"] = "3708941127",
				["ClassName"] = "model",
				["Model"] = "models/player/items/engineer/drg_brainiac_goggles.mdl",
				["Angles"] = Angle(0, -79.03125, -90),
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "599543498",
		["ClassName"] = "group",
		["Name"] = "my outfit",
		["Description"] = "add parts to me!",
	},
},

}
pace.example_outfits["manual bonemerge base"] = {[1] = { --thanks KombatWaffle!
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "bone",
						["Name"] = "1 head",
						["UniqueID"] = "3219022890",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["UniqueID"] = "3834639759",
						["Bone"] = "neck",
						["Name"] = "2 neck",
						["ClassName"] = "bone",
					},
				},
				[3] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "right hand",
								["UniqueID"] = "1049847703",
								["ClassName"] = "bone",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "left upperarm",
								["UniqueID"] = "1851454191",
								["ClassName"] = "bone",
							},
						},
						[3] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "left forearm",
								["UniqueID"] = "1774020936",
								["ClassName"] = "bone",
							},
						},
						[4] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "right forearm",
								["UniqueID"] = "1994599723",
								["ClassName"] = "bone",
							},
						},
						[5] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "left hand",
								["UniqueID"] = "1059739036",
								["ClassName"] = "bone",
							},
						},
						[6] = {
							["children"] = {
								[1] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "597052393",
										["Bone"] = "left finger 12",
										["Name"] = "left index 2",
										["ClassName"] = "bone",
									},
								},
								[2] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "2935430560",
										["Bone"] = "left finger 11",
										["Name"] = "left index 1",
										["ClassName"] = "bone",
									},
								},
								[3] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "83394505",
										["Bone"] = "right finger 0",
										["Name"] = "right thumb 0",
										["ClassName"] = "bone",
									},
								},
								[4] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "3595368042",
										["Bone"] = "right finger 22",
										["Name"] = "right middle 2",
										["ClassName"] = "bone",
									},
								},
								[5] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "902475965",
										["Bone"] = "right finger 21",
										["Name"] = "right middle 1",
										["ClassName"] = "bone",
									},
								},
								[6] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "4171407717",
										["Bone"] = "left finger 22",
										["Name"] = "left middle 2",
										["ClassName"] = "bone",
									},
								},
								[7] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "2319424445",
										["Bone"] = "left finger 0",
										["Name"] = "left thumb 0",
										["ClassName"] = "bone",
									},
								},
								[8] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "2886256528",
										["Bone"] = "left finger 21",
										["Name"] = "left middle 1",
										["ClassName"] = "bone",
									},
								},
								[9] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "99336175",
										["Bone"] = "right finger 12",
										["Name"] = "right index 2",
										["ClassName"] = "bone",
									},
								},
								[10] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "4157044864",
										["Bone"] = "left finger 02",
										["Name"] = "left thumb 2",
										["ClassName"] = "bone",
									},
								},
								[11] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "3922306884",
										["Bone"] = "right finger 11",
										["Name"] = "right index 1",
										["ClassName"] = "bone",
									},
								},
								[12] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "4180624527",
										["Bone"] = "left finger 1",
										["Name"] = "left index 0",
										["ClassName"] = "bone",
									},
								},
								[13] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "4200506327",
										["Bone"] = "left finger 01",
										["Name"] = "left thumb 1",
										["ClassName"] = "bone",
									},
								},
								[14] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "3204358535",
										["Bone"] = "right finger 01",
										["Name"] = "right thumb 1",
										["ClassName"] = "bone",
									},
								},
								[15] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "234131325",
										["Bone"] = "right finger 02",
										["Name"] = "right thumb 2",
										["ClassName"] = "bone",
									},
								},
								[16] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "3601158958",
										["Bone"] = "right finger 1",
										["Name"] = "right index 0",
										["ClassName"] = "bone",
									},
								},
								[17] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "1461030461",
										["Bone"] = "right finger 2",
										["Name"] = "right middle 0",
										["ClassName"] = "bone",
									},
								},
								[18] = {
									["children"] = {
									},
									["self"] = {
										["UniqueID"] = "2174844583",
										["Bone"] = "left finger 2",
										["Name"] = "left middle 0",
										["ClassName"] = "bone",
									},
								},
							},
							["self"] = {
								["ClassName"] = "group",
								["UniqueID"] = "3038270339",
								["Name"] = "z fingers",
							},
						},
						[7] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "right upperarm",
								["UniqueID"] = "1578938478",
								["ClassName"] = "bone",
							},
						},
					},
					["self"] = {
						["ClassName"] = "group",
						["UniqueID"] = "3213516171",
						["Name"] = "3 arms",
					},
				},
				[4] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "right toe",
								["UniqueID"] = "3309911680",
								["ClassName"] = "bone",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "left thigh",
								["UniqueID"] = "1195866600",
								["ClassName"] = "bone",
							},
						},
						[3] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "left toe",
								["UniqueID"] = "2134680716",
								["ClassName"] = "bone",
							},
						},
						[4] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "left foot",
								["UniqueID"] = "3251207148",
								["ClassName"] = "bone",
							},
						},
						[5] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "left calf",
								["UniqueID"] = "3623282163",
								["ClassName"] = "bone",
							},
						},
						[6] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "right foot",
								["UniqueID"] = "2400195426",
								["ClassName"] = "bone",
							},
						},
						[7] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "right calf",
								["UniqueID"] = "2611066688",
								["ClassName"] = "bone",
							},
						},
						[8] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "right thigh",
								["UniqueID"] = "548750273",
								["ClassName"] = "bone",
							},
						},
					},
					["self"] = {
						["ClassName"] = "group",
						["UniqueID"] = "2074611772",
						["Name"] = "5 legs",
					},
				},
				[5] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "left clavicle",
								["UniqueID"] = "118747060",
								["ClassName"] = "bone",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "pelvis",
								["UniqueID"] = "633433534",
								["ClassName"] = "bone",
							},
						},
						[3] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "spine 1",
								["UniqueID"] = "1604551711",
								["ClassName"] = "bone",
							},
						},
						[4] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "right clavicle",
								["UniqueID"] = "1505793257",
								["ClassName"] = "bone",
							},
						},
						[5] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "spine 4",
								["UniqueID"] = "922760510",
								["ClassName"] = "bone",
							},
						},
						[6] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "spine",
								["UniqueID"] = "3715306285",
								["ClassName"] = "bone",
							},
						},
						[7] = {
							["children"] = {
							},
							["self"] = {
								["Bone"] = "spine 2",
								["UniqueID"] = "2223632612",
								["ClassName"] = "bone",
							},
						},
					},
					["self"] = {
						["ClassName"] = "group",
						["UniqueID"] = "504239125",
						["Name"] = "4 torso",
					},
				},
			},
			["self"] = {
				["ClassName"] = "model",
				["UniqueID"] = "150419338",
				["EditorExpand"] = true,
				["Bone"] = "none",
				["Model"] = "models/Humans/Group01/male_03.mdl",
				["Position"] = Vector(0, 41.72021484375, 0),
			},
		},
	},
	["self"] = {
		["EditorExpand"] = true,
		["UniqueID"] = "1536298646",
		["ClassName"] = "group",
		["Name"] = "ragdoll (click on \"follow part name\" on bones)",
		["Description"] = "add parts to me!",
	},
},
[2] = {
	["children"] = {
		[1] = {
			["children"] = {
			},
			["self"] = {
				["ClassName"] = "entity",
				["Name"] = "1 tick \"hide entity\" to test",
				["UniqueID"] = "1430581518",
			},
		},
		[2] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "3470289025",
						["Bone"] = "spine",
						["Name"] = "spine",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "1547175201",
						["Bone"] = "spine 2",
						["Name"] = "spine 2",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "2760363415",
						["Bone"] = "right clavicle",
						["Name"] = "right clavicle",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "3417724297",
						["Bone"] = "left clavicle",
						["Name"] = "left clavicle",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[5] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "4059783409",
						["Bone"] = "spine 1",
						["Name"] = "spine 1",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[6] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "2832511831",
						["Bone"] = "pelvis",
						["Name"] = "pelvis",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[7] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "929053462",
						["Bone"] = "spine 4",
						["Name"] = "spine 4",
						["Model"] = "models/pac/default.mdl",
					},
				},
			},
			["self"] = {
				["ClassName"] = "group",
				["UniqueID"] = "3173205400",
				["Name"] = "5 torso",
			},
		},
		[3] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "3023738861",
						["Bone"] = "right upperarm",
						["Name"] = "right upperarm",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["Model"] = "models/pac/default.mdl",
						["ClassName"] = "model",
						["Name"] = "head",
						["UniqueID"] = "1106589889",
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "2992973832",
						["Bone"] = "left upperarm",
						["Name"] = "left upperarm",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "3874292941",
						["Bone"] = "right forearm",
						["Name"] = "right forearm",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[5] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "1922247035",
						["Bone"] = "right hand",
						["Name"] = "right hand",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[6] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "364163665",
						["Bone"] = "left hand",
						["Name"] = "left hand",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[7] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "410492983",
						["Bone"] = "left forearm",
						["Name"] = "left forearm",
						["Model"] = "models/pac/default.mdl",
					},
				},
			},
			["self"] = {
				["ClassName"] = "group",
				["UniqueID"] = "47211331",
				["Name"] = "4 arms",
			},
		},
		[4] = {
			["children"] = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "1786732817",
						["Bone"] = "left toe",
						["Name"] = "left toe",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "1007419184",
						["Bone"] = "right thigh",
						["Name"] = "right thigh",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "1155349686",
						["Bone"] = "left foot",
						["Name"] = "left foot",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "3294245957",
						["Bone"] = "right calf",
						["Name"] = "right calf",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[5] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "2190040123",
						["Bone"] = "left thigh",
						["Name"] = "left thigh",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[6] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "3101514897",
						["Bone"] = "right toe",
						["Name"] = "right toe",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[7] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "4079545963",
						["Bone"] = "left calf",
						["Name"] = "left calf",
						["Model"] = "models/pac/default.mdl",
					},
				},
				[8] = {
					["children"] = {
					},
					["self"] = {
						["ClassName"] = "model",
						["UniqueID"] = "2289620193",
						["Bone"] = "right foot",
						["Name"] = "right foot",
						["Model"] = "models/pac/default.mdl",
					},
				},
			},
			["self"] = {
				["ClassName"] = "group",
				["UniqueID"] = "1972673486",
				["Name"] = "6 legs",
			},
		},
		[5] = {
			["children"] = {
			},
			["self"] = {
				["Model"] = "models/pac/default.mdl",
				["ClassName"] = "model",
				["Name"] = "2 head",
				["UniqueID"] = "2915462787",
			},
		},
		[6] = {
			["children"] = {
			},
			["self"] = {
				["ClassName"] = "model",
				["UniqueID"] = "236075491",
				["Bone"] = "neck",
				["Name"] = "3 neck",
				["Model"] = "models/pac/default.mdl",
			},
		},
	},
	["self"] = {
		["Name"] = "self (tick hide optional)",
		["ClassName"] = "group",
		["UniqueID"] = "2400740861",
		["EditorExpand"] = true,
	},
},}
pace.example_outfits["weapon sound replacement"] = {[1] = {
	["children"] = {
		[1] = {
			["children"] = {
				[1] = {
					["children"] = {
						[1] = {
							["children"] = {
							},
							["self"] = {
								["Name"] = "Sound being used",
								["ClassName"] = "sound",
								["UniqueID"] = "508902514",
								["Sound"] = "weapons/alyx_gun/alyx_gun_fire[3,6].wav",
							},
						},
						[2] = {
							["children"] = {
							},
							["self"] = {
								["ClassName"] = "sound",
								["UniqueID"] = "598369995",
								["Volume"] = 0.05,
								["Name"] = "Sound being replaced (Usually Weapon_Name.Single), Volume at 0.05",
								["Sound"] = "Weapon_Crowbar.Single",
							},
						},
					},
					["self"] = {
						["AffectChildrenOnly"] = true,
						["ClassName"] = "event",
						["UniqueID"] = "1328612190",
						["Event"] = "animation_event",
						["EditorExpand"] = true,
						["Name"] = "Animation Event to get if we're attacking (use reload instead of attack primary for crossbow)",
						["Arguments"] = "attack primary@@0.01",
					},
				},
			},
			["self"] = {
				["Arguments"] = "crowbar",
				["Invert"] = true,
				["Event"] = "weapon_class",
				["EditorExpand"] = true,
				["UniqueID"] = "1301957784",
				["Name"] = "Weapon (crowbar)",
				["ClassName"] = "event",
			},
		},
	},
	["self"] = {
		["Name"] = "Sound Replacement",
		["ClassName"] = "group",
		["UniqueID"] = "2836933954",
		["EditorExpand"] = true,
	},
},
}
