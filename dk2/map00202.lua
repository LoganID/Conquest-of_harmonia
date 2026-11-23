-- ********************************************
--
--           Conquest of Harmonia: Rout
--           Map 226 (Also partly done in DKscript, see map00226.txt)
--           Script and Design by Mc. Biggus Dickus 
--
-- ********************************************
function OnGameStart()
    RegisterTimerEvent(MyHeroParties, 800, false)
    RegisterTimerEvent(SpawnPatrols, 810, false)
end

function StopPatrol()
    Game.patrols = {}
end

-- Define the hero parties that can be spawned
function MyHeroParties()

-- Parties that will patrol the map
    CreateParty("RED")
        AddToParty("RED", "KNIGHT"  , 3, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "THIEF"   , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "THIEF"   , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "WIZARD"  , 2, 250, "ATTACK_DUNGEON_HEART", 0)
end

-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled

    local northernroute = {}
        northernroute[1]  =  { stl_x = 73, stl_y = 22 }
        northernroute[2]  =  { stl_x = 82, stl_y = 22 }


    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"                , 3)


    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , northernroute , 1, "Red Patrol")

end