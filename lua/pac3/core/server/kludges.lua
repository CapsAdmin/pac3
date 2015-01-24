hook.Add("PlayerSpawn","pac_flex_part_fix",function(ply)
    --we need to modify the player's flexes serverside at least once,
    --otherwise they will revert after 1 frame clientside
    
    --yeah, I know.
    
    if ply:GetFlexNum() > 0 then ply:SetFlexWeight(1,0) end
    
end)