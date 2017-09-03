--TODO: Remake from current halo code

local haloex = {}

local render = render
local cam = cam

local lazyload
	local matColor
	local mat_Copy
	local mat_Add
	local mat_Sub
	local rt_Stencil
	local rt_Store

-- loading these only when needed, should not be too costly
lazyload = function()
	lazyload = nil
	matColor	= Material( "model_color" )
	mat_Copy	= Material( "pp/copy" )
	mat_Add	= Material( "pp/add" )
	mat_Sub	= Material( "pp/sub" )
	rt_Stencil	= GetRenderTarget("halo_ex_stencil" .. os.clock(), ScrW()/8, ScrH()/8, true)
	rt_Store		= GetRenderTarget("halo_ex_store" .. os.clock(), ScrW(), ScrH(), true)
end

local List = {}

function haloex.Add( ents, color, blurx, blury, passes, add, ignorez, amount, spherical, shape )

	if add == nil then add = true end
	if ignorez == nil then ignorez = false end

	local t =
	{
		Ents = ents,
		Color = color,
		Hidden = when_hidden,
		BlurX = blurx or 2,
		BlurY = blury or 2,
		DrawPasses = passes or 1,
		Additive = add,
		IgnoreZ = ignorez,
		Amount = amount or 1,
		SphericalSize = spherical or 1,
		Shape = shape or 1,
	}

	table.insert( List, t )

end

function haloex.Render( entry )


	local OldRT = render.GetRenderTarget()

	-- Copy what's currently on the screen to another texture
	render.CopyRenderTargetToTexture( rt_Store )

	-- Clear the colour and the stencils, not the depth
	if ( entry.Additive ) then
		render.Clear( 0, 0, 0, 255, false, true )
	else
		render.Clear( 255, 255, 255, 255, false, true )
	end


	-- FILL STENCIL
	-- Write to the stencil..
	cam.Start3D( EyePos(), EyeAngles() )

		cam.IgnoreZ( entry.IgnoreZ )
		render.OverrideDepthEnable( true, false )									-- Don't write depth

		render.SetStencilEnable( true );
		render.SetStencilFailOperation( STENCILOPERATION_KEEP );
		render.SetStencilZFailOperation( STENCILOPERATION_KEEP );
		render.SetStencilPassOperation( STENCILOPERATION_REPLACE );
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS );
		render.SetStencilWriteMask( 1 );
		render.SetStencilReferenceValue( 1 );

		render.SetBlend( 0 ); -- don't render any colour

		for k, v in pairs( entry.Ents ) do

			if ( !IsValid( v ) ) then continue end

			render.PushFlashlightMode( true )
				if v.pacDrawModel then
					v:pacDrawModel()
				else
					v:DrawModel()
				end
			render.PopFlashlightMode()

		end

	cam.End3D()

	-- FILL COLOUR
	-- Write to the colour buffer
	cam.Start3D( EyePos(), EyeAngles() )

		render.MaterialOverride( matColor )
		cam.IgnoreZ( entry.IgnoreZ )

		render.SetStencilEnable( true );
		render.SetStencilWriteMask( 0 );
		render.SetStencilReferenceValue( 0 );
		render.SetStencilTestMask( 1 );
		render.SetStencilFailOperation( STENCILOPERATION_KEEP );
		render.SetStencilPassOperation( STENCILOPERATION_KEEP );
		render.SetStencilZFailOperation( STENCILOPERATION_KEEP );
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NOTEQUAL );

		for k, v in pairs( entry.Ents ) do

			if ( !IsValid( v ) ) then continue end

			render.SetColorModulation( entry.Color.r/255, entry.Color.g/255, entry.Color.b/255 )
			render.SetBlend( entry.Color.a/255 );

			if v.pacDrawModel then
				v:pacDrawModel()
			else
				v:DrawModel()
			end

		end

		render.MaterialOverride( nil )
		render.SetStencilEnable( false );

	cam.End3D()

	-- BLUR IT
		render.CopyRenderTargetToTexture( rt_Stencil )
		render.OverrideDepthEnable( false, false )
		render.SetStencilEnable( false );
		render.BlurRenderTarget( rt_Stencil, entry.BlurX, entry.BlurY, entry.Amount )

	-- Put our scene back
		render.SetRenderTarget( OldRT )
		render.SetColorModulation( 1, 1, 1 )
		render.SetStencilEnable( false );
		render.OverrideDepthEnable( true, false )
		render.SetBlend( 1 );
		mat_Copy:SetTexture( "$basetexture", rt_Store )
		render.SetMaterial( mat_Copy )
		render.DrawScreenQuad()


	-- DRAW IT TO THE SCEEN

		render.SetStencilEnable( true );
		render.SetStencilWriteMask( 0 );
		render.SetStencilReferenceValue( 0 );
		render.SetStencilTestMask( 1 );
		render.SetStencilFailOperation( STENCILOPERATION_KEEP );
		render.SetStencilPassOperation( STENCILOPERATION_KEEP );
		render.SetStencilZFailOperation( STENCILOPERATION_KEEP );
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL );

		if ( entry.Additive ) then
			mat_Add:SetTexture( "$basetexture", rt_Stencil )
			render.SetMaterial( mat_Add )
		else
			mat_Sub:SetTexture( "$basetexture", rt_Stencil )
			render.SetMaterial( mat_Sub )
		end

		for i=0, entry.DrawPasses do
			local s = entry.SphericalSize
			local n = (i / entry.DrawPasses)
			local x = math.sin(n * math.pi * 2) * s
			local y = math.cos(n * math.pi * 2) * s
			render.DrawScreenQuadEx(
				math.Clamp(x, s * -entry.Shape, s * entry.Shape),
				math.Clamp(y, s * -entry.Shape, s * entry.Shape),
				ScrW(),
				ScrH()
			)
		end

	-- PUT EVERYTHING BACK HOW WE FOUND IT

		render.SetStencilWriteMask( 0 );
		render.SetStencilReferenceValue( 0 );
		render.SetStencilTestMask( 0 );
		render.SetStencilEnable( false )
		render.OverrideDepthEnable( false )
		render.SetBlend( 1 )

		cam.IgnoreZ( false )

end

hook.Add( "PostDrawEffects", "RenderHaloexs", function()

	if not List[1] then return end

	if lazyload then lazyload() end

	for k, v in pairs( List ) do
		haloex.Render( v )
	end

	List = {}

end )

return haloex
