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
end

-- Define the hero parties that can be spawned
function MyHeroParties()

-- Parties that will patrol the map
    CreateParty("RED")
        AddToParty("RED", "BARBARIAN"       , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "BARBARIAN"   , 3, 500, "ATTACK_DUNGEON_HEART", 0)

end

-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled
    local northernroute = {}
        northernroute[1] =     { stl_x = 112, stl_y = 40 }
        northernroute[2] =     { stl_x = 112, stl_y = 43 }
        northernroute[3] =     { stl_x = 103, stl_y = 43 }
        northernroute[4] =     { stl_x = 103, stl_y = 40 }

    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"                , 3)

    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , northernroute , 1, "Red Patrol")
end
