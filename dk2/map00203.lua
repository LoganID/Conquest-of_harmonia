-- ********************************************
--
--           Conquest of Harmonia: Rout
--           Map 203 (Also partly done in DKscript, see map00226.txt)
--           Script and Design by Mc. Biggus Dickus 
--
-- ********************************************
function OnGameStart()
    MyHeroParties()
    SpawnPatrols()
    SpawnGuards()
end

-- Define the hero parties that can be spawned
function MyHeroParties()

-- Parties that will patrol the map
    CreateParty("RED")
        AddToParty("RED", "BARBARIAN"       , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "BARBARIAN"   , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "KNIGHT"        , 3, 0, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("GUARD1")
        AddToParty("GUARD1", "DWARFA", 1, 0, "ATTACK_DUNGEON_HEART", 0)

end

-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled
    local northernroute = {}
        northernroute[1] =     { stl_x = 67, stl_y = 28 }
        northernroute[2] =     { stl_x = 97, stl_y = 28 }


    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"                , 8)

    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , northernroute , 1, "Red Patrol")
end

function SpawnGuards()
    local Guard1 = AddPartyToLevel(PLAYER_GOOD,"GUARD1", {stl_x = 82, stl_y = 57})
    local Pos1 = { stl_x = 82, stl_y = 57 }
    Guard1[1].health = 10
    RegisterGuard(Guard1[1], Pos1, 2040, "Guard 1", true, true, false)
end
