return {
	shaders = {
		eyerefract = {
			generic = {
				lightwarptexture = {
					type = "texture",
					friendly = "LightWarpTexture",
					description = "1D ramp texture for tinting scalar diffuse term",
				},
				warpparam = {
					type = "float",
					default = 0,
					friendly = "WarpParam",
					description = "animation param between 0 and 1",
				},
				entityorigin = {
					type = "vec3",
					default = Vector(0,0,0),
					friendly = "EntityOrigin",
					description = "center if the model in world space",
				},
				corneatexture = {
					type = "texture",
					description = "cornea texture",
					default = "Engine/eye-cornea",
				},
				ambientoccltexture = {
					type = "texture",
					description = "reflection texture",
					default = "Engine/eye-extra",
				},
				ambientocclcolor = {
					type = "vec3",
					description = "Ambient occlusion color",
					default = Vector(0.33,0.33,0.33),
				},
			},
			eye = {
				intro = {
					friendly = "Episode1Intro",
					description = "center if the model in world space",
					type = "bool",
					default = false,
				},
				eyeballradius = {
					type = "float",
					description = "Requires $raytracesphere 1. Radius of the eyeball. Should be the diameter of the eyeball divided by 2.",
					default = 0.5,
					friendly = "EyeballRadius",
				},
				raytracesphere = {
					type = "bool",
					description = "Enables sphere raytracing. Each pixel is raytraced to allow sharper angles to look more accurate.",
					default = true,
					friendly = "RayTraceSphere",
				},
				spheretexkillcombo = {
					type = "bool",
					description = "Requires $raytracesphere 1. Causes pixels which don't hit the raytraced sphere to be transparent",
					default = false,
					friendly = "SphereTexkillCombo",
				},
				eyeorigin = {
					type = "vec3",
					description = "origin for the eyes",
					default = Vector(0,0,0),
					friendly = "EyeOrigin",
				},
				iris = {
					type = "texture",
					description = "iris texture",
					default = "engine/eye-iris-green",
					friendly = "Iris",
				},
				irisframe = {
					type = "integer",
					description = "frame for the iris texture",
					default = 0,
					friendly = "IrisFrame",
					linked = "iris"
				},
				dilation = {
					type = "float",
					description = "Pupil dilation (0 is none, 1 is maximal)",
					default = 0.5,
					friendly = "Dilation",
				},
				irisu = {
					type = "vec4",
					description = "U projection vector for the iris",
					default = "[0 1 0 0 ]",
					friendly = "IrisU",
				},
				irisv = {
					type = "vec4",
					description = "V projection vector for the iris",
					default = "[0 0 1 0]",
					friendly = "IrisV",
				},
				parallaxstrength = {
					type = "float",
					description = "Parallax strength",
					default = 0.25,
					friendly = "ParallaxStrength",
				},
				corneabumpstrength = {
					type = "float",
					description = "Cornea strength",
					default = 1,
					friendly = "CorneaBumpStrength",
				},
				halflambert = {
					type = "bool",
					description = "Enables half-lambertian lighting.",
					default = 1,
					friendly = "HalfLambert",
				},
				glossiness = {
					type = "float",
					description = "The opacity of the cubemap reflection.",
					default = 0.5,
					friendly = "Glossiness",
				},
			},
			cloak = {
				cloakpassenabled = {
					friendly = "Enable",
					type = "bool",
					description = "Enables cloak render in a second pass",
					default = false,
				},
				cloakfactor = {
					friendly = "Factor",
					type = "float",
					description = "",
					default = 0,
				},
				cloakcolortint = {
					friendly = "ColorTint",
					type = "color",
					description = "Cloak color tint",
					default = Vector(1, 1, 1),
				},
				refractamount = {
					type = "float",
					friendly = "RefractAmount",
					default = 0.5,
					description = "How strong the refraction effect should be when the material is partially cloaked (default = 2).",
				},
			},
			["environment map"] = {
				envmap = {
					type = "texture",
					friendly = "Envmap",
					description = "Enables cubemap reflections.",
					default = "Engine/eye-reflection-cubemap-",
					partial_hdr = true
				},
			}
		},
		vertexlitgeneric = {
			wrinkle = {
				compress = {
					type = "texture",
					friendly = "Compress",
					description = "compression wrinklemap",
				},
				bumpcompress = {
					type = "texture",
					friendly = "BumpCompress",
					description = "compression bump map",
				},
				bumpstretch = {
					type = "texture",
					friendly = "BumpStretch",
					description = "expansion bump map",
				},
				stretch = {
					type = "texture",
					friendly = "Stretch",
					description = "expansion wrinklemap",
				},
			},
			["sheen map"] = {
				sheenmapmaskoffsetx = {
					type = "float",
					description = "X Offset of the mask relative to model space coords of target",
					default = 0,
					friendly = "MaskOffsetX",
				},
				sheenindex = {
					type = "integer",
					description = "Index of the Effect Type (Color Additive, Override etc...)",
					default = 0,
					friendly = "Index",
				},
				sheenmaptint = {
					type = "color",
					description = "sheenmap tint",
					friendly = "Tint",
				},
				sheenmapmaskoffsety = {
					type = "float",
					description = "Y Offset of the mask relative to model space coords of target",
					default = 0,
					friendly = "MaskOffsetY",
				},
				sheenpassenabled = {
					type = "bool",
					description = "Enables weapon sheen render in a second pass",
					default = false,
					friendly = "Enable",
				},
				sheenmapmask = {
					type = "texture",
					description = "sheenmap mask",
					friendly = "Mask",
				},
				sheenmapmaskscalex = {
					type = "float",
					description = "X Scale the size of the map mask to the size of the target",
					default = 1,
					friendly = "MaskScaleX",
				},
				sheenmapmaskscaley = {
					type = "float",
					description = "Y Scale the size of the map mask to the size of the target",
					default = 1,
					friendly = "MaskScaleY",
				},
				sheenmap = {
					type = "texture",
					description = "sheenmap",
				},
				sheenmapmaskframe = {
					type = "integer",
					description = "",
					default = 0,
					friendly = "MaskFrame",
					linked = "sheenmap"
				},
				sheenmapmaskdirection = {
					type = "integer",
					description = "The direction the sheen should move (length direction of weapon) XYZ, 0,1,2",
					default = 0,
					friendly = "Direction",
				},
			},
			["rim lighting"] = {
				rimlightboost = {
					type = "float",
					friendly = "Boost",
					default = 0,
					description = "Boost for rim lights",
				},
				rimmask = {
					type = "bool",
					friendly = "ExponentAlphaMask",
					default = false,
					description = "Indicates whether or not to use alpha channel of exponent texture to mask the rim term",
				},
				rimlight = {
					type = "bool",
					default = false,
					description = "enables rim lighting",
					friendly = "Enable",
				},
				rimlightexponent = {
					type = "float",
					friendly = "Exponent",
					default = 0,
					description = "Exponent for rim lights",
				},
			},
			phong = {
				albedo = {
					type = "texture",
					friendly = "Albedo",
					description = "albedo (Base texture with no baked lighting)",
				},
				basemapalphaphongmask = {
					type = "bool",
					friendly = "BaseMapAlphaPhongMask",
					default = false,
					description = "indicates that there is no normal map and that the phong mask is in base alpha",
				},
				invertphongmask = {
					type = "bool",
					friendly = "InvertPhongMask",
					default = false,
					description = "invert the phong mask (0=full phong, 1=no phong)",
				},
				phongexponenttexture = {
					type = "texture",
					friendly = "Exponent",
					description = "Phong Exponent map",
				},
				phongwarptexture = {
					type = "texture",
					friendly = "Warp",
					description = "warp the specular term",
				},
			},
			flesh = {
				fleshcubetexture = {
					type = "texture",
					friendly = "CubeTexture",
					description = "Flesh cubemap texture",
				},
				flesheffectcenterradius3 = {
					type = "vec4",
					friendly = "EffectCenterRadius3",
					default = "[ 0 0 0 0 ]",
					description = "Flesh effect center and radius",
				},
				fleshglossbrightness = {
					type = "float",
					friendly = "GlossBrightness",
					default = 0,
					description = "Flesh gloss brightness",
				},
				fleshsubsurfacetint = {
					type = "color",
					friendly = "SubsurfaceTint",
					default = Vector(1, 1, 1),
					description = "Subsurface Color",
				},
				fleshbordersoftness = {
					type = "float",
					friendly = "BorderSoftness",
					default = 0,
					description = "Flesh border softness (> 0.0 && <= 0.5)",
				},
				fleshdebugforcefleshon = {
					type = "bool",
					friendly = "DebugForceFleshOn",
					default = false,
					description = "Flesh Debug full flesh",
				},
				fleshbordertexture1d = {
					type = "texture",
					friendly = "BorderTexture1D",
					description = "Flesh border 1D texture",
				},
				flesheffectcenterradius1 = {
					type = "vec4",
					friendly = "EffectCenterRadius1",
					default = "[ 0 0 0 0 ]",
					description = "Flesh effect center and radius",
				},
				flesheffectcenterradius4 = {
					type = "vec4",
					friendly = "EffectCenterRadius4",
					default = "[ 0 0 0 0 ]",
					description = "Flesh effect center and radius",
				},
				fleshinteriorenabled = {
					friendly = "InteriorEnabled",
					type = "bool",
					description = "Enable Flesh interior blend pass",
					default = false,
				},
				fleshbordernoisescale = {
					type = "float",
					friendly = "BorderNoiseScale",
					default = 0,
					description = "Flesh Noise UV scalar for border",
				},
				fleshsubsurfacetexture = {
					type = "texture",
					friendly = "SubsurfaceTexture",
					description = "Flesh subsurface texture",
				},
				fleshglobalopacity = {
					type = "float",
					friendly = "GlobalOpacity",
					default = 0,
					description = "Flesh global opacity",
				},
				fleshinteriortexture = {
					type = "texture",
					friendly = "Texture",
					description = "Flesh color texture",
				},
				fleshborderwidth = {
					type = "float",
					friendly = "BorderWidth",
					default = 0,
					description = "Flesh border",
				},
				fleshbordertint = {
					type = "color",
					friendly = "BorderTint",
					default = Vector(1, 1, 1),
					description = "Flesh border Color",
				},
				fleshscrollspeed = {
					type = "float",
					friendly = "ScrollSpeed",
					default = 0,
					description = "Flesh scroll speed",
				},
				flesheffectcenterradius2 = {
					type = "vec4",
					friendly = "EffectCenterRadius2",
					default = "[ 0 0 0 0 ]",
					description = "Flesh effect center and radius",
				},
				fleshinteriornoisetexture = {
					type = "texture",
					friendly = "NoiseTexture",
					description = "Flesh noise texture",
				},
				fleshnormaltexture = {
					type = "texture",
					friendly = "NormalTexture",
					description = "Flesh normal texture",
				},
			},
			["self illumination"] = {
				selfillumfresnel = {
					type = "bool",
					friendly = "Fresnel",
					default = false,
					description = "Self illum fresnel",
				},
				selfillum_envmapmask_alpha = {
					type = "float",
					friendly = "EnvMapMaskAlpha",
					default = 0,
					description = "defines that self illum value comes from env map mask alpha",
				},
				selfillumfresnelminmaxexp = {
					type = "vec4",
					friendly = "FresnelMinMaxExp",
					default = "[ 0 0 0 0 ]",
					description = "Self illum fresnel min, max, exp",
				},
				selfillum = {
					is_flag = true,
					type = "integer",
					default = false,
					description = "flag",
				},
				selfillummask = {
					type = "texture",
					friendly = "Mask",
					description = "If we bind a texture here, it overrides base alpha (if any) for self illum",
				},
				selfillumtint = {
					type = "color",
					friendly = "Tint",
					default = Vector(1, 1, 1),
					description = "Self-illumination tint",
				},
			},
			generic = {
				color2 = {
					type = "color",
					friendly = "Color2",
					default = Vector(1, 1, 1),
					description = "color2",
				},
				opaquetexture = {
					is_flag = true,
					type = "integer",
					friendly = "OpaqueTexture",
					default = false,
					description = "flag",
				},
				noalphamod = {
					is_flag = true,
					type = "integer",
					friendly = "NoAlphaMod",
					default = false,
					description = "flag",
				},
				znearer = {
					is_flag = true,
					type = "integer",
					friendly = "Znearer",
					default = false,
					description = "flag",
				},
				additive = {
					is_flag = true,
					type = "integer",
					friendly = "Additive",
					default = false,
					description = "flag",
				},
				nocull = {
					is_flag = true,
					type = "integer",
					friendly = "NoCull",
					default = false,
					description = "flag",
				},
				ignore_alpha_modulation = {
					is_flag = true,
					type = "integer",
					friendly = "IgnoreAlphaModulation",
					default = false,
					description = "flag",
				},
				color = {
					type = "color",
					friendly = "Color",
					default = Vector(1, 1, 1),
					description = "color",
				},
				no_draw = {
					is_flag = true,
					type = "integer",
					friendly = "NoDraw",
					default = false,
					description = "flag",
				},
				suppress_decals = {
					is_flag = true,
					type = "integer",
					friendly = "SuppressDecals",
					default = false,
					description = "flag",
				},
				lightwarptexture = {
					type = "texture",
					friendly = "LightWarpTexture",
					description = "1D ramp texture for tinting scalar diffuse term",
				},
				use_in_fillrate_mode = {
					is_flag = true,
					type = "integer",
					friendly = "UseInFillrateMode",
					default = false,
					description = "flag",
				},
				halflambert = {
					is_flag = true,
					type = "bool",
					friendly = "HalfLambert",
					default = false,
					description = "flag",
				},
				ambientonly = {
					type = "bool",
					friendly = "AmbientOnly",
					default = false,
					description = "Control drawing of non-ambient light ()",
				},
				ignorez = {
					is_flag = true,
					type = "integer",
					friendly = "Ignorez",
					default = false,
					description = "flag",
				},
				nofog = {
					is_flag = true,
					type = "integer",
					friendly = "Nofog",
					default = false,
					description = "flag",
				},
				nolod = {
					type = "bool",
					default = false,
					description = "flag",
					friendly = "NoLod",
				},
				decal = {
					is_flag = true,
					type = "integer",
					friendly = "Decal",
					default = false,
					description = "flag",
				},
				allowalphatocoverage = {
					is_flag = true,
					type = "integer",
					friendly = "AllowAlphaToCoverage",
					default = false,
					description = "flag",
				},
				model = {
					is_flag = true,
					type = "integer",
					friendly = "Model",
					default = false,
					description = "flag",
				},
				multipass = {
					is_flag = true,
					type = "integer",
					friendly = "Multipass",
					default = false,
					description = "flag",
				},
				debug = {
					is_flag = true,
					type = "integer",
					friendly = "Debug",
					default = false,
					description = "flag",
				},
				wireframe = {
					is_flag = true,
					type = "integer",
					friendly = "Wireframe",
					default = false,
					description = "flag",
				},
				translucent = {
					is_flag = true,
					type = "integer",
					friendly = "Translucent",
					default = false,
					description = "flag",
				},
				flat = {
					is_flag = true,
					type = "integer",
					friendly = "Flat",
					default = false,
					description = "flag",
				},
			},
			["bump map"] = {
				bumpmap = {
					type = "texture",
					friendly = "BumpMap",
					description = "bump map",
					default = "null-bumpmap",
				},
				bumpframe = {
					type = "integer",
					friendly = "Frame",
					default = 0,
					description = "The frame to start an animated bump map on.",
					linked = "bumpmap"
				},
				bumptransform = {
					type = "matrix",
					friendly = "Transform",
					description = "Transforms the bump map texture.",
				},
				nodiffusebumplighting = {
					type = "bool",
					friendly = "NoDiffuseLighting",
					default = false,
					description = "Stops the bump map affecting the lighting of the material's albedo, which help combat overdraw. Does not affect the specular map.",
				},
			},
			seamless = {
				seamless_scale = {
					type = "float",
					friendly = "Scale",
					default = 0,
					description = "the scale for the seamless mapping. # of repetions of texture per inch.",
				},
				seamless_detail = {
					type = "bool",
					friendly = "Detail",
					default = false,
					description = "where to apply seamless mapping to the detail texture.",
				},
				seamless_base = {
					type = "bool",
					friendly = "Base",
					default = false,
					description = "whether to apply seamless mapping to the base texture. requires a smooth model.",
				},
			},
			cloak = {
				cloakpassenabled = {
					friendly = "Enable",
					type = "bool",
					description = "Enables cloak render in a second pass",
					default = false,
				},
				cloakfactor = {
					friendly = "Factor",
					type = "float",
					description = "",
					default = 0,
				},
				cloakcolortint = {
					friendly = "ColorTint",
					type = "color",
					description = "Cloak color tint",
					default = Vector(1, 1, 1),
				},
				refractamount = {
					type = "float",
					friendly = "RefractAmount",
					default = 0.5,
					description = "How strong the refraction effect should be when the material is partially cloaked (default = 2).",
				},
			},
			blend = {
				blendtintbybasealpha = {
					type = "bool",
					friendly = "TintByBaseAlpha",
					default = false,
					description = "Use the base alpha to blend in the $color modulation",
				},
				blendtintcoloroverbase = {
					friendly = "TintColorOverBase",
					type = "float",
					description = "blend between tint acting as a multiplication versus a replace",
					default = 0,
				},
			},
			detail = {
				detail = {
					type = "texture",
					description = "detail texture",
				},
				detailtint = {
					type = "color",
					friendly = "Tint",
					default = Vector(1, 1, 1),
					description = "detail texture tint",
				},
			},
			["emissive blend"] = {
				emissiveblendstrength = {
					type = "float",
					friendly = "Strength",
					default = 0,
					description = "Emissive blend strength",
				},
				emissiveblendbasetexture = {
					type = "texture",
					friendly = "BaseTexture",
					description = "self-illumination map",
				},
				emissiveblendenabled = {
					friendly = "Enabled",
					type = "bool",
					description = "Enable emissive blend pass",
					default = false,
				},
				emissiveblendtexture = {
					type = "texture",
					friendly = "Texture",
					description = "self-illumination map",
				},
				emissiveblendflowtexture = {
					type = "texture",
					friendly = "FlowTexture",
					description = "flow map",
				},
				emissiveblendtint = {
					type = "color",
					friendly = "Tint",
					default = Vector(1, 1, 1),
					description = "Self-illumination tint",
				},
				emissiveblendscrollvector = {
					type = "vec2",
					friendly = "ScrollVector",
					description = "Emissive scroll vec",
					default = Vector(0, 0),
				},
			},
		},
		unlitgeneric = {
			outline = {
				outlineend1 = {
					type = "float",
					friendly = "End1",
					default = 0,
					description = "outer end value for outline",
				},
				outline = {
					type = "bool",
					default = false,
					description = "Enable outline for distance coded textures.",
				},
				outlineend0 = {
					type = "float",
					friendly = "End0",
					default = 0,
					description = "inner end value for outline",
				},
				outlinestart1 = {
					type = "float",
					friendly = "Start1",
					default = 0,
					description = "inner start value for outline",
				},
				outlinecolor = {
					type = "color",
					friendly = "Color",
					default = Vector(1, 1, 1),
					description = "color of outline for distance coded images.",
				},
				outlinestart0 = {
					type = "float",
					friendly = "Start0",
					default = 0,
					description = "outer start value for outline",
				},
				outlinealpha = {
					type = "float",
					friendly = "Alpha",
					default = 1,
					description = "alpha value for outline",
				},
			},
			glow = {
				glowstart = {
					type = "float",
					friendly = "Start",
					default = 0,
					description = "start value for glow/shadow",
				},
				glow = {
					type = "bool",
					default = false,
					description = "Enable glow/shadow for distance coded textures.",
				},
				glowcolor = {
					type = "color",
					friendly = "Color",
					default = Vector(1, 1, 1),
					description = "color of outter glow for distance coded line art.",
				},
				glowalpha = {
					type = "float",
					friendly = "Alpha",
					default = 1,
					description = "Base glow alpha amount for glows/shadows with distance alpha.",
				},
				glowx = {
					type = "float",
					friendly = "X",
					default = 0,
					description = "texture offset x for glow mask.",
				},
				glowend = {
					type = "float",
					friendly = "End",
					default = 0,
					description = "end value for glow/shadow",
				},
				glowy = {
					type = "float",
					friendly = "Y",
					default = 0,
					description = "texture offset y for glow mask.",
				},
			},
			generic = {
				nofog = {
					is_flag = true,
					type = "integer",
					friendly = "NoFog",
					default = false,
					description = "flag",
				},
				opaquetexture = {
					is_flag = true,
					type = "integer",
					friendly = "OpaqueTexture",
					default = false,
					description = "flag",
				},
				nolod = {
					type = "bool",
					default = false,
					description = "flag",
					friendly = "nolod",
				},
				ignorez = {
					is_flag = true,
					type = "integer",
					friendly = "Ignorez",
					default = false,
					description = "flag",
				},
				texture = {
					type = "texture",
					description = "base texture",
					friendly = "texture",
				},
				noalphamod = {
					is_flag = true,
					type = "integer",
					friendly = "NoAlphaMod",
					default = false,
					description = "flag",
				},
				znearer = {
					is_flag = true,
					type = "integer",
					friendly = "Znearer",
					default = false,
					description = "flag",
				},
				additive = {
					is_flag = true,
					type = "integer",
					friendly = "Additive",
					default = false,
					description = "flag",
				},
				nocull = {
					is_flag = true,
					type = "integer",
					friendly = "NoCull",
					default = false,
					description = "flag",
				},
				hdrcolorscale = {
					type = "float",
					friendly = "HDRColorScale",
					default = 1,
					description = "hdr color scale",
				},
				softedges = {
					type = "bool",
					friendly = "SoftEdges",
					default = false,
					description = "Enable soft edges to distance coded textures.",
				},
				ignore_alpha_modulation = {
					is_flag = true,
					type = "integer",
					friendly = "IgnoreAlphaModulation",
					default = false,
					description = "flag",
				},
				color = {
					type = "color",
					friendly = "Color",
					default = Vector(1, 1, 1),
					description = "color",
				},
				no_draw = {
					is_flag = true,
					type = "integer",
					friendly = "NoDraw",
					default = false,
					description = "flag",
				},
				suppress_decals = {
					is_flag = true,
					type = "integer",
					friendly = "SuppressDecals",
					default = false,
					description = "flag",
				},
				alpha = {
					type = "float",
					friendly = "Alpha",
					default = 1,
					description = "alpha",
				},
				use_in_fillrate_mode = {
					is_flag = true,
					type = "integer",
					friendly = "UseInFillrateMode",
					default = false,
					description = "flag",
				},
				halflambert = {
					is_flag = true,
					type = "bool",
					friendly = "HalfLambert",
					default = false,
					description = "flag",
				},
				no_debug_override = {
					is_flag = true,
					type = "integer",
					friendly = "NoDebugOverride",
					default = false,
					description = "flag",
				},
				decal = {
					is_flag = true,
					type = "integer",
					friendly = "Decal",
					default = false,
					description = "flag",
				},
				allowalphatocoverage = {
					is_flag = true,
					type = "integer",
					friendly = "AllowAlphaToCoverage",
					default = false,
					description = "flag",
				},
				color2 = {
					type = "color",
					friendly = "Color2",
					default = Vector(1, 1, 1),
					description = "color2",
				},
				multipass = {
					is_flag = true,
					type = "integer",
					friendly = "Multipass",
					default = false,
					description = "flag",
				},
				lightwarptexture = {
					type = "texture",
					friendly = "DiffuseWarpTexture",
					description = "1D ramp texture for tinting scalar diffuse term",
				},
				model = {
					is_flag = true,
					type = "integer",
					friendly = "Model",
					default = false,
					description = "flag",
				},
				wireframe = {
					is_flag = true,
					type = "integer",
					friendly = "Wireframe",
					default = false,
					description = "flag",
				},
				translucent = {
					is_flag = true,
					type = "integer",
					friendly = "Translucent",
					default = false,
					description = "flag",
				},
				flat = {
					is_flag = true,
					type = "integer",
					friendly = "Flat",
					default = false,
					description = "flag",
				},
			},
			["base texture"] = {
				basetexturetransform = {
					type = "matrix",
					friendly = "Transform",
					description = "Base Texture Texcoord Transform",
				},
				basetexture = {
					type = "texture",
					description = "Base Texture with lighting built in",
					default = "models/debug/debugwhite",
				},
				frame = {
					type = "integer",
					friendly = "Frame",
					default = 0,
					description = "Animation Frame",
					linked = "basetexture"
				},
			},
			["self illumination"] = {
				selfillum = {
					is_flag = true,
					type = "integer",
					default = false,
					description = "flag",
				},
				selfillummask = {
					type = "texture",
					friendly = "Mask",
					description = "If we bind a texture here, it overrides base alpha (if any) for self illum",
				},
			},
			srgb = {
				gammacolorread = {
					type = "integer",
					friendly = "GammaColorRead",
					default = 0,
					description = "Disables SRGB conversion of color texture read.",
				},
				srgbtint = {
					type = "color",
					friendly = "Tint",
					default = Vector(1, 1, 1),
					description = "tint value to be applied when running on new-style srgb parts",
				},
			},
			edge = {
				edgesoftnessend = {
					type = "float",
					friendly = "SoftnessEnd",
					default = 0,
					description = "End value for soft edges for distancealpha.",
				},
				edgesoftnessstart = {
					type = "float",
					friendly = "SoftnessStart",
					default = 0,
					description = "Start value for soft edges for distancealpha.",
				},
			},
			vertex = {
				vertexcolor = {
					is_flag = true,
					type = "bool",
					friendly = "Color",
					default = false,
					description = "flag",
				},
				vertexalphatest = {
					type = "bool",
					friendly = "AlphaTest",
					default = false,
					description = "",
				},
				vertexalpha = {
					is_flag = true,
					type = "bool",
					friendly = "Alpha",
					default = false,
					description = "flag",
				},
			},
			distance = {
				distancealpha = {
					type = "bool",
					friendly = "Alpha",
					default = false,
					description = "Use distance-coded alpha generated from hi-res texture by vtex.",
				},
				distancealphafromdetail = {
					type = "bool",
					friendly = "AlphaFromDetail",
					default = false,
					description = "Take the distance-coded alpha mask from the detail texture.",
				},
			},
			scale = {
				scaleoutlinesoftnessbasedonscreenres = {
					type = "bool",
					friendly = "OutlineSoftnessBasedOnScreenRes",
					default = false,
					description = "Scale the size of the soft part of the outline based upon resolution. 1024x768 = nominal.",
				},
				scaleedgesoftnessbasedonscreenres = {
					type = "bool",
					friendly = "EdgeSoftnessBasedOnScreenRes",
					default = false,
					description = "Scale the size of the soft edges based upon resolution. 1024x768 = nominal.",
				},
			},
			phong = {
				phongwarptexture = {
					type = "texture",
					friendly = "WarpTexture",
					description = "2D map for warping specular",
				},
				phongexponenttexture = {
					type = "texture",
					friendly = "ExponentTexture",
					description = "Phong Exponent map",
				},
				albedo = {
					type = "texture",
					friendly = "Albedo",
					description = "albedo (Base texture with no baked lighting)",
				},
			},
		},
		refract = {
			["base texture"] = {
				basetexture = {
					type = "texture",
					description = "Use a texture instead of rendering the view for the source of the distorted pixels.",
					default = "",
				},
			},
			["local"] = {
				localrefract = {
					type = "bool",
					default = false,
					description = "Uses alpha channel of base texture to create a parallax effect.",
					friendly = "Refract",
				},
				localrefractdepth = {
					type = "float",
					default = 0,
					description = "Depth of the parallax effect in units.",
					friendly = "RefractDepth",
				},
			},
			force = {
				forcealphawrite = {
					type = "bool",
					friendly = "AlphaWrite",
					default = false,
				},
				forcerefract = {
					type = "bool",
					default = false,
					friendly = "Refract",
					description = "Forces the shader to be used for cards with poor fill rate (DX8 only).",
				},
			},
			refract = {
				refracttinttexture = {
					type = "texture",
					friendly = "TintTexture",
					description = "Tints the colour of the refraction either uniformly or per-texel.",
				},
				refracttinttextureframe = {
					type = "integer",
					friendly = "TintTextureFrame",
					description = "Frame to start an animated tint texture on.",
					default = 0,
					linked = "refracttinttexture"
				},
				refracttint = {
					type = "color",
					friendly = "Tint",
					default = Vector(1, 1, 1),
					description = "Tint color of the refraction.",
				},
				refractamount = {
					type = "float",
					friendly = "RefractAmount",
					default = 0.5,
					description = "How strong the refraction effect should be when the material is partially cloaked (default = 2).",
				},
			},
			generic = {
				vertexcolormodulate = {
					type = "bool",
					default = false,
					friendly = "VertexColorModulate",
					recompute = true,
				},
				bluramount = {
					type = "integer",
					friendly = "BlurAmount",
					default = 0,
					description = "Adds a blur effect. Valid values are 0, 1 and 2 (0 and 1 for DX8-).",
					recompute = true,
				},
				masked = {
					type = "bool",
					default = false,
					friendly = "Masked",
					description = "To do: mask using dest alpha",
				},
				fresnelreflection = {
					type = "float",
					default = 1,
					friendly = "FresnelReflection",
					description = "Broken - Not implemented despite the parameter existing.",
				},
				opaquetexture = {
					is_flag = true,
					type = "integer",
					friendly = "OpaqueTexture",
					default = false,
					description = "flag",
				},
				fadeoutonsilhouette = {
					type = "bool",
					friendly = "FadeOutOnSilhouette",
					description = "0 for no fade out on silhouette, 1 for fade out on sillhouette",
					default = false,
				},
				nocull = {
					is_flag = true,
					type = "integer",
					friendly = "NoCull",
					default = false,
					description = "flag",
				},
				translucent = {
					is_flag = true,
					type = "integer",
					friendly = "Translucent",
					default = false,
					description = "flag",
				},
				model = {
					is_flag = true,
					type = "integer",
					friendly = "Model",
					default = true,
					description = "flag",
				},
			},
			normal = {
				dudvmap = {
					type = "texture",
					friendly = "DudvMap",
					description = "The pattern of refraction is defined by a normal map (DX9+) or DUDV map (DX8-). May be animated.",
					default = "dev/water_dudv",
				},
				normalmap = {
					type = "texture",
					friendly = "NormalMap",
					description = "The pattern of refraction is defined by a normal map (DX9+) or DUDV map (DX8-). May be animated.",
					default = "dev/water_normal",
				},
				normalmap2 = {
					type = "texture",
					friendly = "SecondNormalMap",
					description = "If a second normal map is specified, it will be blended with the first one.",
				},
				bumpframe = {
					type = "int",
					default = 0,
					friendly = "BumpFrame",
					description = "The frame to start the first animated bump map on.",
					linked = "normalmap"
				},
				bumpframe2 = {
					type = "int",
					default = 0,
					friendly = "SecondBumpFrame",
					description = "The frame to start the second animated bump map on.",
					linked = "normalmap2"
				},
				bumptransform = {
					type = "matrix",
					friendly = "Transform",
					description = "Transform of the first bump map.",
				},
				bumptransform2 = {
					type = "matrix",
					friendly = "Second Transform",
					description = "Transform of the second bump map.",
				},
			},
		},
	},
	base = {
		["base texture"] = {
			basetexture = {
				type = "texture",
				description = "Base Texture with lighting built in",
				default = "models/debug/debugwhite",
			},
			basetexturetransform = {
				type = "matrix",
				friendly = "Transform",
				description = "Base Texture Texcoord Transform",
			},
			frame = {
				type = "integer",
				friendly = "Frame",
				default = 0,
				description = "Base Texture Animation Frame",
				linked = "basetexture"
			},
		},
		detail = {
			detail = {
				type = "texture",
				friendly = "Texture",
				description = "detail texture",
			},
			detailblendfactor = {
				type = "float",
				friendly = "BlendFactor",
				default = 1,
				description = "blend amount for detail texture.",
			},
			detailframe = {
				type = "integer",
				friendly = "Frame",
				default = 0,
				description = "frame number for $detail",
				linked = "detail"
			},
			detailblendmode = {
				recompute = true,
				type = "integer",
				friendly = "BlendMode",
				default = 0,
				description = "mode for combining detail texture with base."..
[[
0 = original mode
1 = ADDITIVE base.rgb+detail.rgb*fblend
2 = alpha blend detail over base
3 = straight fade between base and detail.
4 = use base alpha for blend over detail
5 = add detail color post lighting
6 = TCOMBINE_RGB_ADDITIVE_SELFILLUM_THRESHOLD_FADE 6
7 = use alpha channel of base to select between mod2x channels in r+a of detail
8 = multiply
9 = use alpha channel of detail to mask base
10 = use detail to modulate lighting as an ssbump
11 = detail is an ssbump but use it as an albedo. shader does the magic here - no user needs to specify mode 11
12 = there is no detail texture
]],
			},
			detailscale = {
				type = "float",
				friendly = "SimpleScale",
				default = 1,
				description = "scale of the detail texture",
			},
			detailtexturetransform = {
				type = "matrix",
				friendly = "Transform",
				description = "$detail texcoord transform",
			},
		},
		["depth blend"] = {
			depthblendscale = {
				friendly = "Scale",
				type = "float",
				description = "Amplify or reduce DEPTHBLEND fading. Lower values make harder edges.",
				default = 50,
			},
			depthblend = {
				type = "float",
				description = "fade at intersection boundaries",
				default = 0,
				friendly = "Blend",
			},
		},
		generic = {
			separatedetailuvs = {
				type = "bool",
				friendly = "SeparateDetailUv",
				default = false,
				description = "Use texcoord1 for detail texture",
			},
			alpha = {
				type = "float",
				friendly = "Alpha",
				default = 1,
				description = "alpha",
			},
		},
		srgb = {
			linearwrite = {
				type = "bool",
				friendly = "LinearWrite",
				default = false,
				description = "Disables SRGB conversion of shader results.",
			},
			srgbtint = {
				type = "color",
				friendly = "Tint",
				default = Vector(1, 1, 1),
				description = "tint value to be applied when running on new-style srgb parts",
			},
		},
		phong = {
			phongtint = {
				type = "color",
				friendly = "Tint",
				description = "Phong tint for local specular lights",
			},
			phongfresnelranges = {
				type = "vec3",
				friendly = "FresnelRanges",
				description = "Parameters for remapping fresnel output",
				default = Vector(0.05, 0.5, 1),
			},
			phongalbedotint = {
				type = "bool",
				friendly = "AlbedoTint",
				default = false,
				description = "Apply tint by albedo (controlled by spec exponent texture",
			},
			phongexponent = {
				type = "float",
				friendly = "Exponent",
				default = 5,
				description = "Phong exponent for local specular lights",
			},
			phong = {
				type = "bool",
				default = false,
				friendly = "Enable",
				description = "enables phong lighting",
			},
			phongboost = {
				type = "float",
				friendly = "Boost",
				default = 1,
				description = "Phong overbrightening factor (specular mask channel should be authored to account for this)",
			},
		},
		flashlight = {
			flashlighttexture = {
				type = "texture",
				friendly = "Texture",
				description = "flashlight spotlight shape texture",
			},
			flashlightnolambert = {
				type = "bool",
				friendly = "NoLambert",
				default = false,
				description = "Flashlight pass sets N.L=1.0",
			},
			flashlighttextureframe = {
				type = "integer",
				friendly = "Frame",
				default = 0,
				description = "Animation Frame for $flashlight",
				linked = "flashlighttexture"
			},
			receiveflashlight = {
				type = "bool",
				friendly = "ReceiveFlashlight",
				default = false,
				description = "Forces this material to receive flashlights.",
			},
		},
		["alpha test"] = {
			alphatest = {
				is_flag = true,
				type = "integer",
				friendly = "AlphaTest",
				default = false,
				description = "flag",
			},
			alphatestreference = {
				recompute = true,
				type = "float",
				friendly = "Reference",
				default = 0.7,
				description = "",
			},
		},
		["environment map"] = {
			envmapmasktransform = {
				type = "matrix",
				friendly = "MaskTransform",
				description = "$envmapmask texcoord transform",
			},
			envmapsaturation = {
				type = "float",
				friendly = "Saturation",
				default = 1,
				description = "saturation 0 == greyscale 1 == normal",
			},
			envmapcontrast = {
				type = "float",
				friendly = "Contrast",
				default = 0,
				description = "contrast 0 == normal 1 == color*color",
			},
			envmapmask = {
				type = "texture",
				friendly = "Mask",
				description = "envmap mask",
			},
			envmapmaskframe = {
				type = "integer",
				friendly = "MaskFrame",
				default = 0,
				description = "Frame of the animated mask.",
				linked = "envmapmask"
			},
			envmapcameraspace = {
				is_flag = true,
				type = "integer",
				friendly = "CameraSpace",
				default = false,
				description = "flag",
			},
			envmap = {
				type = "texture",
				friendly = "Envmap",
				description = "envmap. won't work if hdr is enabled",
				default = "",
				partial_hdr = true
			},
			envmapframe = {
				type = "integer",
				friendly = "Frame",
				default = 0,
				description = "envmap frame number",
				linked = "envmap"
			},
			envmapmode = {
				is_flag = true,
				type = "integer",
				friendly = "Mode",
				default = false,
				description = "flag",
			},
			envmaptint = {
				type = "color",
				friendly = "Tint",
				default = Vector(1, 1, 1),
				description = "envmap tint",
			},
			envmapsphere = {
				is_flag = true,
				type = "integer",
				friendly = "Sphere",
				default = false,
				description = "flag",
			},
			normalmapalphaenvmapmask = {
				is_flag = true,
				type = "integer",
				friendly = "NormalmapAlphaMask",
				default = false,
				description = "flag",
			},
			basealphaenvmapmask = {
				is_flag = true,
				type = "integer",
				friendly = "BaseAlphaMask",
				default = false,
				description = "flag",
			},
		},
		vertex = {
				vertexalpha = {
					is_flag = true,
					type = "bool",
					friendly = "Alpha",
					default = false,
					description = "flag",
				},
				vertexcolor = {
					is_flag = true,
					type = "bool",
					friendly = "Color",
					default = false,
					description = "flag",
				},
			},
	}
}