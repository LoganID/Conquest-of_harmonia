-- ********************************************
--
--           Conquest of Harmonia: Rout
--           Map 226 (Also partly done in DKscript, see map00226.txt)
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

    CreateParty("DEFEND")
        AddToParty("DEFEND", "DWARFA"   , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND", "DWARFA"   , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND", "WIZARD"   , 2, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND", "WIZARD"   , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND", "GIANT"    , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND", "GIANT"    , 3, 500, "ATTACK_DUNGEON_HEART", 0)        
        AddToParty("DEFEND", "MONK"     , 2, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("DEFEND2")
        AddToParty("DEFEND2", "MONK"   , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND2", "SAMURAI"   , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND2", "SAMURAI"   , 3, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND2", "SAMURAI"   , 3, 500, "ATTACK_DUNGEON_HEART", 0)

end
-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled

    local northernroute = {}
        northernroute[1]  =  { stl_x = 55, stl_y = 28 }
        northernroute[2]  =  { stl_x = 106, stl_y = 73 }
        northernroute[3]  =  { stl_x = 118, stl_y = 112 }
        northernroute[4]  =  { stl_x = 106, stl_y = 73 }

    local middleway = {}
        middleway[1]  =   { stl_x = 106, stl_y = 100 }
        middleway[2]  =   { stl_x = 130, stl_y = 100 }

    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"DEFEND"                , 4)
    local PatrolPartyGreen  =  AddPartyToLevel(PLAYER_GOOD       ,"DEFEND2"              , 7)


    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , northernroute , 1, "Red Patrol")
    RegisterPatrol(PatrolPartyGreen[1]  , middleway  , 1, "Green Patrol")


end