
-- Lists all existing coops as tupel {coop, isInit}: 'coop' as thing object and 'isInit' as boolean
Game.CoopsToInit = {}

function UpdateFunctionCOOP(coop)
    if coop.creation_turn == PLAYER0.GAME_TURN - 1 then
        InitializeCoop(coop)
    end
end

function InitializeCoop(coop)
    -- Remove if not in pattern
    if CheckForRemoval(coop) then
        coop:delete()
        return -1
    end
    -- Random rotation
    coop.orientation = math.random(0, 7) * 256
    -- Random offset
    coop.pos = {val_x = coop.pos.val_x + (128 * math.random(-1, 1)),
                val_y = coop.pos.val_y + (128 * math.random(-1, 1)),
                val_z = coop.pos.val_z}
end

function CheckForRemoval(coop)
    -- Checkerboard pattern
    return (coop.pos.slb_x + coop.pos.slb_y) % 2 == 0
end

function UpdateFunctionCHICKEN_GRW(chicken)
    if IsNextToCoop(chicken.pos.slb_x, chicken.pos.slb_y) then
        chicken.pos = PositionOfNextCoop(chicken.pos)
        chicken.sprite_size = 0
    end
end

function UpdateFunctionCHICKEN_STB_WOB_CRK(chicken)
    if IsNextToCoop(chicken.pos.slb_x, chicken.pos.slb_y) then
        chicken.sprite_size = 0
    end
end

function IsNextToCoop(x, y)
    for _, object in ipairs(GetObjectsOnSlab(x, y)) do
        if object.model == "COOP" then
            return true
        end
    end
    return false
end

function PositionOfNextCoop(pos)
    for _, object in ipairs(GetObjectsOnSlab(pos.slb_x, pos.slb_y)) do
        if object.model == "COOP" then
            return object.pos
        end
    end
    return false
end

