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
    CreateParty("RED")
        AddToParty("RED", "FAIRY"      , 7, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "FAIRY"      , 7, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("WEST")
        AddToParty("WEST", "FAIRY"        , 7, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WEST", "FAIRY"        , 7, 500, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("OST")
        AddToParty("OST", "FAIRY"       , 4, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "FAIRY"       , 7, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "MONK"       , 8, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "MONK"       , 7, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "BARBARIAN"       , 5, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "BARBARIAN"       , 4, 250, "ATTACK_DUNGEON_HEART", 0)
end

-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled

    local Bridgeroute = {}
        Bridgeroute[1]  =  { stl_x = 214, stl_y = 163 }
        Bridgeroute[2]  =  { stl_x = 214, stl_y = 172 }

    local westwaterway = {}
        westwaterway[1]  =   { stl_x = 214, stl_y = 190 }
        westwaterway[2]  =   { stl_x = 214, stl_y = 199 }

    local eastside = {}
        eastside[1]  =      { stl_x = 196, stl_y = 175 }
        eastside[2]  =      { stl_x = 196, stl_y = 187 }

    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"               , 14)
    local PatrolPartyGreen  =  AddPartyToLevel(PLAYER_GOOD       ,"WEST"              , 15)
    local PatrolPartyWiz1   =  AddPartyToLevel(PLAYER_GOOD       ,"OST"               , 16)


    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , Bridgeroute   , 1, "Red Patrol")
    RegisterPatrol(PatrolPartyGreen[1]  , westwaterway  , 1, "WEST Patrol")
    RegisterPatrol(PatrolPartyWiz1[1]   , eastside      , 1, "OST Patrol")

end

