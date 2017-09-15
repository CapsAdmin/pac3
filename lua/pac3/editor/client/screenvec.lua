--[[
Give this function the coordinates of a pixel on your screen, and it will return a unit vector pointing
in the direction that the camera would project that pixel in.

Useful for converting mouse positions to aim vectors for traces.

iScreenX is the x position of your cursor on the screen, in pixels.
iScreenY is the y position of your cursor on the screen, in pixels.
iScreenW is the width of the screen, in pixels.
iScreenH is the height of the screen, in pixels.
angCamRot is the angle your camera is at
fFoV is the Field of View (FOV) of your camera in ___radians___
    Note: This must be nonzero or you will get a divide by zero error.
 ]]
function pace.LPCameraScreenToVector( iScreenX, iScreenY, iScreenW, iScreenH, angCamRot, fFoV )
    --This code works by basically treating the camera like a frustrum of a pyramid.
    --We slice this frustrum at a distance "d" from the camera, where the slice will be a rectangle whose width equals the "4:3" width corresponding to the given screen height.
    local d = 4 * iScreenH / ( 6 * math.tan( 0.5 * fFoV ) ) ;

    --Forward, right, and up vectors (need these to convert from local to world coordinates
    local vForward = angCamRot:Forward();
    local vRight   = angCamRot:Right();
    local vUp      = angCamRot:Up();

    --Then convert vec to proper world coordinates and return it
    return ( d * vForward + ( iScreenX - 0.5 * iScreenW ) * vRight + ( 0.5 * iScreenH - iScreenY ) * vUp ):GetNormalized();
end

--[[
Give this function a vector, pointing from the camera to a position in the world,
and it will return the coordinates of a pixel on your screen - this is where the world position would be projected onto your screen.

Useful for finding where things in the world are on your screen (if they are at all).

vDir is a direction vector pointing from the camera to a position in the world
iScreenW is the width of the screen, in pixels.
iScreenH is the height of the screen, in pixels.
angCamRot is the angle your camera is at
fFoV is the Field of View (FOV) of your camera in ___radians___
    Note: This must be nonzero or you will get a divide by zero error.

Returns x, y, iVisibility.
    x and y are screen coordinates.
    iVisibility will be:
        1 if the point is visible
        0 if the point is in front of the camera, but is not visible
        -1 if the point is behind the camera
]]
function pace.VectorToLPCameraScreen( vDir, iScreenW, iScreenH, angCamRot, fFoV )
    --Same as we did above, we found distance the camera to a rectangular slice of the camera's frustrum, whose width equals the "4:3" width corresponding to the given screen height.
    local d = 4 * iScreenH / ( 6 * math.tan( 0.5 * fFoV ) );
    local fdp = angCamRot:Forward():Dot( vDir );

    --fdp must be nonzero ( in other words, vDir must not be perpendicular to angCamRot:Forward() )
    --or we will get a divide by zero error when calculating vProj below.
    if fdp == 0 then
        return 0, 0, -1
    end

    --Using linear projection, project this vector onto the plane of the slice
    local vProj = ( d / fdp ) * vDir;

    --Dotting the projected vector onto the right and up vectors gives us screen positions relative to the center of the screen.
    --We add half-widths / half-heights to these coordinates to give us screen positions relative to the upper-left corner of the screen.
    --We have to subtract from the "up" instead of adding, since screen coordinates decrease as they go upwards.
    local x = 0.5 * iScreenW + angCamRot:Right():Dot( vProj );
    local y = 0.5 * iScreenH - angCamRot:Up():Dot( vProj );

    --Lastly we have to ensure these screen positions are actually on the screen.
    local iVisibility
    if fdp < 0 then          --Simple check to see if the object is in front of the camera
        iVisibility = -1;
    elseif x < 0  or  x > iScreenW  or  y < 0  or  y > iScreenH then  --We've already determined the object is in front of us, but it may be lurking just outside our field of vision.
        iVisibility = 0;
    else
        iVisibility = 1;
    end

    return x, y, iVisibility;
end

