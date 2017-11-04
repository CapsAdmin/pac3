
local netx = setmetatable({}, {__index = net})

local TYPES_BITS = 4

local TYPE_STRING = 0
local TYPE_NUMBER = 1
local TYPE_ANGLE = 2
local TYPE_VECTOR = 3
local TYPE_BOOL = 4
local TYPE_COLOR = 5
local TYPE_TABLE = 6
local TYPE_ENTITY = 7
local TYPE_NUMBER_UID = 8

local readTable

-- 1.9974 engineers is enough
local function net_ReadVector()
	return Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
end

local function net_WriteVector(vec)
	net.WriteFloat(vec.x)
	net.WriteFloat(vec.y)
	net.WriteFloat(vec.z)
end

local function net_ReadAngle()
	return Angle(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
end

local function net_WriteAngle(ang)
	net.WriteFloat(ang.p)
	net.WriteFloat(ang.y)
	net.WriteFloat(ang.r)
end

local function readTyped()
	local tp = net.ReadUInt(TYPES_BITS)

	if tp == TYPE_STRING then
		return net.ReadString()
	elseif tp == TYPE_NUMBER_UID then
		return tostring(net.ReadUInt(32))
	elseif tp == TYPE_NUMBER then
		return net.ReadInt(32)
	elseif tp == TYPE_ANGLE then
		return net_ReadAngle()
	elseif tp == TYPE_VECTOR then
		return net_ReadVector()
	elseif tp == TYPE_BOOL then
		return net.ReadBool()
	elseif tp == TYPE_COLOR then
		return net.ReadColor()
	elseif tp == TYPE_ENTITY then
		return net.ReadEntity()
	elseif tp == TYPE_TABLE then
		return readTable()
	else
		error('Cannot read type - type is ' .. tp .. '!')
	end
end

local function writeTyped(val, key)
	local tp = type(val)

	if tp == 'string' then
		local tryuid = tonumber(val)

		if tryuid and tryuid > 0 and tryuid < 2 ^ 32 then
			net.WriteUInt(TYPE_NUMBER_UID, TYPES_BITS)
			net.WriteUInt(tryuid, 32)
		else
			net.WriteUInt(TYPE_STRING, TYPES_BITS)
			net.WriteString(val)
		end
	elseif tp == 'number' then
		net.WriteUInt(TYPE_NUMBER, TYPES_BITS)
		net.WriteInt(val, 32)
	elseif tp == 'Angle' then
		net.WriteUInt(TYPE_ANGLE, TYPES_BITS)
		net_WriteAngle(val)
	elseif tp == 'Vector' then
		net.WriteUInt(TYPE_VECTOR, TYPES_BITS)
		net_WriteVector(val)
	elseif tp == 'boolean' then
		net.WriteUInt(TYPE_BOOL, TYPES_BITS)
		net.WriteBool(val)
	elseif tp == 'table' then
		net.WriteUInt(TYPE_COLOR, TYPES_BITS)
		net.WriteColor(val)
	elseif tp == 'Entity' or tp == 'Player' or tp == 'NPC' or tp == 'NextBot' or tp == 'Vehicle' then
		net.WriteUInt(TYPE_ENTITY, TYPES_BITS)
		net.WriteEntity(val)
	else
		error('Unknown type - ' .. tp .. ' (index is ' .. (key or 'unknown') .. ')')
	end
end

local tostring = tostring
local CRC = util.CRC
local crcdatabank = {}

local function writeTable(tab)
	net.WriteUInt(table.Count(tab), 16)

	for key, value in pairs(tab) do
		local i = key

		if type(i) == 'string' then
			i = tonumber(i) or tonumber(CRC(i))
		end

		net.WriteUInt(i, 32)

		if type(value) == 'table' then
			if value.r and value.g and value.b and value.a then
				writeTyped(value, key)
			else
				net.WriteUInt(TYPE_TABLE, TYPES_BITS)
				writeTable(value)
			end
		else
			writeTyped(value, key)
		end
	end
end

do
	local tobank = {
		'ParentUID',
		'self',
		'UniqueID',
		'part',
		'ParentName',
		'AimPartName',
		'ClassName',
		'OwnerName',
		'owner',
		'children',
		'class',
		'player_uid',
		'uid',
		'server_only',

		-- almost all known string indexes
		'3D',
		'ActLand',
		'ActRangeAttack1',
		'AddFrametimeLife',
		'Additive',
		'additive',
		'AddOwnerSpeed',
		'AffectChildren',
		'AffectChildrenOnly',
		'AimDir',
		'AimPart',
		'AimPartName',
		'AimPartUID',
		'Air',
		'AirResistance',
		'albedo',
		'AlignToSurface',
		'allowalphatocoverage',
		'AllowOggWhenMuted',
		'Alpha',
		'alpha',
		'alphatest',
		'AlphaTest',
		'alphatestreference',
		'AlternativeBones',
		'AlternativeRate',
		'AlternativeScaling',
		'ambientocclcolor',
		'ambientoccltexture',
		'AmbientOcclusion',
		'AmbientOcclusionColor',
		'AmbientOcclusionTexture',
		'ambientonly',
		'Amplitude',
		'AngleOffset',
		'Angles',
		'AnimationRate',
		'AnimationType',
		'Arguments',
		'AttackCrouchPrimaryfire',
		'AttackStandPrimaryfire',
		'Attract',
		'AttractMode',
		'AttractRadius',
		'Axis',
		'BaseAlphaEnvMapMask',
		'basealphaenvmapmask',
		'basemapalphaphongmask',
		'BaseTexture',
		'BaseTextureAngle',
		'BaseTextureAngleCenter',
		'BaseTexturePosition',
		'BaseTextureScale',
		'basetexturetransformAngle',
		'basetexturetransformAngleCenter',
		'basetexturetransformPosition',
		'basetexturetransformScale',
		'Bend',
		'BlendMode',
		'BlendTintByBaseAlpha',
		'blendtintbybasealpha',
		'BlendTintColorOverBase',
		'blendtintcoloroverbase',
		'bluramount',
		'BlurFiltering',
		'BlurLength',
		'BlurSpacing',
		'BlurX',
		'BlurY',
		'BodyGroupName',
		'Bone',
		'BoneIndex',
		'BoneMerge',
		'BonePower',
		'Bounce',
		'Box',
		'Brightness',
		'BulletImpact',
		'bumpcompress',
		'bumpframe',
		'bumpmap',
		'BumpMap',
		'bumpstretch',
		'bumptransformAngle',
		'bumptransformAngleCenter',
		'bumptransformPosition',
		'bumptransformScale',
		'CellShade',
		'CenterAttraction',
		'Class',
		'cloakcolortint',
		'CloakColorTint',
		'CloakFactor',
		'cloakfactor',
		'cloakpassenabled',
		'CloakPassEnabled',
		'Code',
		'Collide',
		'CollideWithOwner',
		'Collisions',
		'color',
		'Color',
		'Color1',
		'Color2',
		'color2',
		'ColorTint_Base',
		'ColorTint_Tmp',
		'compress',
		'ConstrainPitch',
		'ConstrainRoll',
		'ConstrainSphere',
		'ConstrainX',
		'ConstrainY',
		'ConstrainYaw',
		'ConstrainZ',
		'corneabumpstrength',
		'corneatexture',
		'CrouchIdle',
		'CrouchSpeed',
		'CrouchWalk',
		'Damage',
		'DamageRadius',
		'DamageType',
		'DampFactor',
		'Damping',
		'Darken',
		'Data',
		'DeathRagdollizeParent',
		'debug',
		'decal',
		'DefaultOnHide',
		'Delay',
		'depthblend',
		'depthblendscale',
		'Detail',
		'detail',
		'detailblendfactor',
		'DetailBlendFactor',
		'detailblendmode',
		'DetailBlendMode',
		'detailframe',
		'DetailScale',
		'detailscale',
		'detailtexturetransformAngle',
		'detailtexturetransformAngleCenter',
		'detailtexturetransformPosition',
		'detailtexturetransformScale',
		'DetailTint',
		'detailtint',
		'DieTime',
		'dilation',
		'distancealpha',
		'DistanceAlpha',
		'distancealphafromdetail',
		'Doppler',
		'DoubleFace',
		'DoubleSided',
		'DrawManual',
		'DrawOrder',
		'DrawPlayerOnDeath',
		'DrawShadow',
		'DrawViewModel',
		'DrawWeapon',
		'dudvmap',
		'Duplicate',
		'Echo',
		'EchoDelay',
		'EchoFeedback',
		'edgesoftnessend',
		'edgesoftnessstart',
		'EditorExpand',
		'Effect',
		'EmissiveBlendBaseTexture',
		'emissiveblendbasetexture',
		'emissiveblendenabled',
		'EmissiveBlendEnabled',
		'EmissiveBlendFlowTexture',
		'emissiveblendflowtexture',
		'EmissiveBlendScrollVector',
		'emissiveblendscrollvector',
		'emissiveblendtexture',
		'EmissiveBlendTexture',
		'EmissiveBlendTint',
		'emissiveblendtint',
		'End',
		'EndAlpha',
		'EndColor',
		'EndLength',
		'EndPoint',
		'EndPointName',
		'EndPointUID',
		'EndSize',
		'entityorigin',
		'EnvMap',
		'envmap',
		'envmapcameraspace',
		'EnvMapContrast',
		'envmapcontrast',
		'envmapframe',
		'envmapmask',
		'EnvMapMask',
		'EnvMapMaskScale',
		'envmapmode',
		'EnvMapMode',
		'envmapsaturation',
		'EnvMapSaturation',
		'envmapsphere',
		'envmaptint',
		'EnvMapTint',
		'Event',
		'ExectueOnWear',
		'Expression',
		'EyeAngles',
		'EyeAnglesLerp',
		'eyeballradius',
		'eyeorigin',
		'EyeTarget',
		'EyeTargetName',
		'EyeTargetUID',
		'fadeoutonsilhouette',
		'FallApartOnDeath',
		'Fallback',
		'FilterFraction',
		'FilterType',
		'FireDelay',
		'FixedSize',
		'flashlightnolambert',
		'flashlighttexture',
		'flashlighttextureframe',
		'flat',
		'fleshbordernoisescale',
		'FleshBorderNoiseScale',
		'FleshBorderSoftness',
		'fleshbordersoftness',
		'fleshbordertexture1d',
		'FleshBorderTexture1D',
		'fleshbordertint',
		'FleshBorderTint',
		'FleshBorderWidth',
		'fleshborderwidth',
		'fleshcubetexture',
		'fleshdebugforcefleshon',
		'FleshDebugForceFleshOn',
		'flesheffectcenterradius1',
		'flesheffectcenterradius2',
		'flesheffectcenterradius3',
		'flesheffectcenterradius4',
		'fleshglobalopacity',
		'FleshGlobalOpacity',
		'fleshglossbrightness',
		'FleshGlossBrightness',
		'fleshinteriorenabled',
		'FleshInteriorEnabled',
		'fleshinteriornoisetexture',
		'FleshInteriorNoiseTexture',
		'fleshinteriortexture',
		'FleshInteriorTexture',
		'fleshnormaltexture',
		'FleshNormalTexture',
		'FleshScrollSpeed',
		'fleshscrollspeed',
		'FleshSubsurfaceTexture',
		'fleshsubsurfacetexture',
		'FleshSubsurfaceTint',
		'fleshsubsurfacetint',
		'Flex',
		'Follow',
		'FollowPart',
		'FollowPartName',
		'FollowPartUID',
		'Font',
		'forcealphawrite',
		'forcerefract',
		'FOV',
		'frame',
		'Frequency',
		'fresnelreflection',
		'Fullbright',
		'Function',
		'gammacolorread',
		'GestureName',
		'glow',
		'glowalpha',
		'glowcolor',
		'glowend',
		'glowstart',
		'glowx',
		'glowy',
		'Gravity',
		'Ground',
		'halflambert',
		'hdrcolorscale',
		'Height',
		'Hide',
		'HideBullets',
		'HideEntity',
		'HideMesh',
		'HidePhysgunBeam',
		'HideRagdollOnDeath',
		'HorizontalFOV',
		'ignore_alpha_modulation',
		'IgnoreOwner',
		'ignorez',
		'InnerAngle',
		'Input',
		'InputDivider',
		'InputMultiplier',
		'intro',
		'InverseKinematics',
		'Invert',
		'InvertHideMesh',
		'invertphongmask',
		'iris',
		'irisframe',
		'irisu',
		'irisv',
		'Jiggle',
		'JiggleAngle',
		'JigglePosition',
		'Jump',
		'Length',
		'LevelOfDetail',
		'LifeTime',
		'LightBlend',
		'Lighting',
		'LightWarpTexture',
		'lightwarptexture',
		'linearwrite',
		'LoadVmt',
		'LocalPlayerOnly',
		'localrefract',
		'localrefractdepth',
		'LocalVelocity',
		'LodOverride',
		'Loop',
		'masked',
		'Mass',
		'Material',
		'MaterialOverride',
		'Materials',
		'Max',
		'MaxAngular',
		'MaxAngularDamp',
		'MaximumRadius',
		'MaxPitch',
		'MaxSpeed',
		'MaxSpeedDamp',
		'Min',
		'MinimumRadius',
		'MinPitch',
		'model',
		'ModelFallback',
		'ModelIndex',
		'MoveChildrenToOrigin',
		'multipass',
		'Multiplier',
		'MuteFootsteps',
		'MuteSounds',
		'Name',
		'NearZ',
		'no_debug_override',
		'no_draw',
		'noalphamod',
		'Noclip',
		'nocull',
		'NoCulling',
		'nodiffusebumplighting',
		'NoDraw',
		'nofog',
		'NoLighting',
		'nolod',
		'NoModel',
		'normalmap',
		'normalmap2',
		'normalmapalphaenvmapmask',
		'NormalMapAlphaEnvMapMask',
		'NoTextureFiltering',
		'NoWorld',
		'NumberParticles',
		'Offset',
		'opaquetexture',
		'Operator',
		'Orthographic',
		'OuterAngle',
		'OuterVolume',
		'OutfitPart',
		'OutfitPartName',
		'OutfitPartUID',
		'Outline',
		'outline',
		'outlinealpha',
		'OutlineAlpha',
		'outlinecolor',
		'OutlineColor',
		'outlineend0',
		'outlineend1',
		'outlinestart0',
		'outlinestart1',
		'Overlapping',
		'Override',
		'OverridePosition',
		'Owner',
		'OwnerCycle',
		'OwnerEntity',
		'OwnerName',
		'OwnerVelocityMultiplier',
		'parallaxstrength',
		'Parent',
		'ParentName',
		'ParentUID',
		'ParticleAngle',
		'ParticleAngleVelocity',
		'Passes',
		'Path',
		'PauseOnHide',
		'Phong',
		'phong',
		'PhongAlbedoTint',
		'phongalbedotint',
		'PhongBoost',
		'phongboost',
		'PhongExponent',
		'phongexponent',
		'phongexponenttexture',
		'PhongExponentTexture',
		'phongfresnelranges',
		'PhongFresnelRanges',
		'phongtint',
		'PhongTint',
		'phongwarptexture',
		'PhongWarpTexture',
		'Physical',
		'PingPongLoop',
		'Pitch',
		'PitchLFOAmount',
		'PitchLFOTime',
		'PlayCount',
		'PlayerAngles',
		'PlayerOwner',
		'PlayOnFootstep',
		'PointA',
		'PointAName',
		'PointAUID',
		'PointB',
		'PointBName',
		'PointBUID',
		'PointC',
		'PointCName',
		'PointCUID',
		'PointD',
		'PointDName',
		'PointDUID',
		'PoseParameter',
		'Position',
		'PositionOffset',
		'PositionSpread',
		'PositionSpread2',
		'Pow',
		'Radius',
		'RandomColor',
		'RandomPitch',
		'RandomRollSpeed',
		'Range',
		'Rate',
		'raytracesphere',
		'receiveflashlight',
		'refractamount',
		'RefractAmount',
		'refracttint',
		'refracttinttexture',
		'refracttinttextureframe',
		'RelativeBones',
		'ReloadCrouch',
		'ReloadStand',
		'RemoveOnCollide',
		'ResetOnHide',
		'ResetVelocitiesOnHide',
		'Resolution',
		'rimlight',
		'Rimlight',
		'rimlightboost',
		'RimlightBoost',
		'rimlightexponent',
		'RimlightExponent',
		'rimmask',
		'RollDelta',
		'RootOwner',
		'Run',
		'RunSpeed',
		'Scale',
		'ScaleChildren',
		'scaleedgesoftnessbasedonscreenres',
		'scaleoutlinesoftnessbasedonscreenres',
		'seamless_base',
		'seamless_detail',
		'seamless_scale',
		'SelfCollision',
		'Selfillum_Envmapmask_Alpha',
		'selfillum_envmapmask_alpha',
		'selfillum',
		'Selfillum',
		'selfillumfresnel',
		'SelfillumFresnel',
		'selfillumfresnelminmaxexp',
		'SelfillumFresnlenMinMaxExp',
		'SelfillumMask',
		'selfillummask',
		'SelfillumTint',
		'selfillumtint',
		'separatedetailuvs',
		'SequenceName',
		'Shadows',
		'Shape',
		'sheenindex',
		'sheenmap',
		'sheenmapmask',
		'sheenmapmaskdirection',
		'sheenmapmaskframe',
		'sheenmapmaskoffsetx',
		'sheenmapmaskoffsety',
		'sheenmapmaskscalex',
		'sheenmapmaskscaley',
		'sheenmaptint',
		'sheenpassenabled',
		'Sitting',
		'Size',
		'SizeX',
		'SizeY',
		'Skin',
		'Sliding',
		'SlotName',
		'SlotWeight',
		'softedges',
		'Sound',
		'SoundLevel',
		'Spacing',
		'SpawnEntity',
		'Speed',
		'Sphere',
		'SphericalSize',
		'Spread',
		'SprintSpeed',
		'SpritePath',
		'srgbtint',
		'StandIdle',
		'Start',
		'StartAlpha',
		'StartColor',
		'StartLength',
		'StartSize',
		'StickEndAlpha',
		'StickEndSize',
		'StickLifetime',
		'StickStartAlpha',
		'StickStartSize',
		'StickToSurface',
		'Sticky',
		'StopOnHide',
		'StopOtherAnimations',
		'StopRadius',
		'Strain',
		'Stretch',
		'stretch',
		'Style',
		'suppress_decals',
		'Swim',
		'SwimIdle',
		'TargetPart',
		'TargetPartName',
		'TargetPartUID',
		'Text',
		'Texture',
		'texture',
		'TextureFilter',
		'TextureFrame',
		'TextureScroll',
		'TextureStretch',
		'TintColor',
		'TrailPath',
		'translucent',
		'Translucent',
		'TranslucentX',
		'UniqueID',
		'URL',
		'use_in_fillrate_mode',
		'UseEndpointOffsets',
		'UseLegacyScale',
		'UseLua',
		'UseParticleTracer',
		'UsePlayerColor',
		'UserData',
		'UseWeaponColor',
		'VariableName',
		'Velocity',
		'VelocityRoughness',
		'vertexalpha',
		'VertexAlpha',
		'vertexalphatest',
		'vertexcolor',
		'vertexcolormodulate',
		'Volume',
		'VolumeLFOAmount',
		'VolumeLFOTime',
		'Walk',
		'WalkSpeed',
		'warpparam',
		'Weapon',
		'WeaponHoldType',
		'Weight',
		'WidthBend',
		'WidthBendSize',
		'wireframe',
		'ZeroEyePitch',
		'znearer',
	}

	for i, val in ipairs(tobank) do
		crcdatabank[CRC(val)] = val
	end
end

local readmeta = {
	__index = function(self, key)
		local val = rawget(self, key)
		if val ~= nil then
			return val
		end

		-- if SERVER then
		-- 	print(key, debug.traceback())
		-- end

		crcdatabank[key] = crcdatabank[key] or CRC(key)
		return rawget(self, crcdatabank[key])
	end
}

function readTable(tab)
	local output = {}
	setmetatable(output, readmeta)
	local amount = net.ReadUInt(16)

	for i = 1, amount do
		local i2 = net.ReadUInt(32)
		local i = tostring(i2)
		local val = readTyped()

		if CLIENT then
			--i = pac.ExtractNetworkID(i) or crcdatabank[i] or (print('Unknown ID ' .. i) or i)
			i = pac.ExtractNetworkID(i) or crcdatabank[i] or i2
		else
			i = crcdatabank[i] or i2
		end

		output[i] = val
	end

	return output
end

function netx.SerializeTable(data)
	local written1 = net.BytesWritten()
	writeTable(data)
	local written2 = net.BytesWritten()

	if written2 >= 65536 then
		return nil, "table too big"
	end

	return written2 - written1
end

function netx.DeserializeTable()
	return readTable()
end

return netx
