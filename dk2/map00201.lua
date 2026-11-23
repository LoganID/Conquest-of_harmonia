-- ********************************************
--
--           Conquest of Harmonia: Rout
--           Map 201 (Also partly done in DKscript, see map00226.txt)
--           Script and Design by Mc. Biggus Dickus 
--
-- ********************************************
function OnGameStart()
    MyHeroParties()
    RegisterTimerEvent(SpawnPatrols, 1000, false)
end

-- Define the hero parties that can be spawned
function MyHeroParties()

-- Parties that will patrol the map
    CreateParty("RED")
        AddToParty("RED", "DWARFA"      , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "DWARFA"      , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "DWARFA"      , 1, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "DWARFA"      , 1, 250, "ATTACK_DUNGEON_HEART", 0)

end

-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled
    local guardcastle = {}
        guardcastle[1] =     { stl_x = 40, stl_y = 10 }
        guardcastle[2] =     { stl_x = 40, stl_y = 30 }

    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"                , 4)

    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , guardcastle , 1, "Red Patrol")
end