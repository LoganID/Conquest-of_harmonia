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
        AddToParty("DEFEND", "ARCHER"   , 4, 500, "ATTACK_DUNGEON_HEART", 0)

        -- Counterclockwie
    CreateParty("DEFEND2")
        AddToParty("DEFEND2", "MONK"   , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND2", "BARBARIAN"   , 5, 500, "ATTACK_DUNGEON_HEART", 0)        
        AddToParty("DEFEND2", "GIANT"   , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND2", "GIANT"   , 3, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND2", "DWARFA"   , 6, 500, "ATTACK_DUNGEON_HEART", 0)


        -- Clockwise
    CreateParty("DEFEND3")
        AddToParty("DEFEND3", "DWARFA"   , 6, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND3", "SAMURAI"   , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND3", "SAMURAI"   , 4, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND3", "WIZARD"   , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("DEFEND3", "BARBARIAN"   , 5, 500, "ATTACK_DUNGEON_HEART", 0)

end
-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled

    local northernroute = {}
        northernroute[1]  =  { stl_x = 109, stl_y = 151 }
        northernroute[2]  =  { stl_x = 133, stl_y = 151 }

    local Clockwise = {}
        Clockwise[1]  =   { stl_x = 91, stl_y = 70 }
        Clockwise[2]  =   { stl_x = 148, stl_y = 73 }
        Clockwise[3]  =   { stl_x = 163, stl_y = 142 }
        Clockwise[4]  =   { stl_x = 79, stl_y = 142 }

    local Counterclockwie = {}
        Counterclockwie[1]  =   { stl_x = 148, stl_y = 73 }
        Counterclockwie[2]  =   { stl_x = 91, stl_y = 70 }     
        Counterclockwie[3]  =   { stl_x = 79, stl_y = 142 }    
        Counterclockwie[4]  =   { stl_x = 163, stl_y = 142 }

    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"DEFEND"                , -1)
    local PatrolPartyGreen  =  AddPartyToLevel(PLAYER_GOOD       ,"DEFEND2"              , 16)
    local PatrolPartyYellow  =  AddPartyToLevel(PLAYER_GOOD       ,"DEFEND3"              , 17)

    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , northernroute , 1, "Red Patrol")
    RegisterPatrol(PatrolPartyGreen[1]  , Clockwise  , 1, "Green Patrol")
    RegisterPatrol(PatrolPartyYellow[1]  , Counterclockwie  , 1, "Yellow Patrol")

end