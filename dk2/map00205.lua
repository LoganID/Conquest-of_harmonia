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
        AddToParty("RED", "BARBARIAN"   , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "BARBARIAN"   , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "WIZARD"      , 2, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "WIZARD"      , 3, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("GREEN")
        AddToParty("GREEN", "BARBARIAN" , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "BARBARIAN" , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "BARBARIAN" , 3, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "WIZARD"    , 3, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("YELLOW")
        AddToParty("YELLOW", "BARBARIAN", 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("YELLOW", "BARBARIAN", 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("YELLOW", "BARBARIAN", 2, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("YELLOW", "WIZARD"   , 2, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("BLUE")
        AddToParty("BLUE", "BARBARIAN", 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("BLUE", "BARBARIAN", 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("BLUE", "BARBARIAN", 2, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("BLUE", "WIZARD"   , 2, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("KNIGHT")
        AddToParty("KNIGHT", "KNIGHT", 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("KNIGHT", "BARBARIAN", 3, 500, "ATTACK_DUNGEON_HEART", 0)
end

-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled

    local northernroute = {}
        northernroute[1]  =  { stl_x = 115, stl_y = 136 }
        northernroute[2]  =  { stl_x = 151, stl_y = 136 }

    local middleway = {}
        middleway[1]  =   { stl_x = 121, stl_y = 160 }
        middleway[2]  =   { stl_x = 148, stl_y = 160 }

    local eastside = {}
        eastside[1]  =      { stl_x = 187, stl_y = 121 }
        eastside[2]  =      { stl_x = 208, stl_y = 121 }
        eastside[3]  =      { stl_x = 208, stl_y = 142 }
        eastside[4]  =      { stl_x = 187, stl_y = 142 }     

    local westside = {}
        westside[1]  =      { stl_x = 49, stl_y = 118 }
        westside[2]  =      { stl_x = 70, stl_y = 118 }
        westside[3]  =      { stl_x = 70, stl_y = 139 }  
        westside[4]  =      { stl_x = 49, stl_y = 139 }         

    local southside = {}
        southside[1]  =   { stl_x = 127, stl_y = 193 }
        southside[2]  =   { stl_x = 139, stl_y = 193 }

    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"                , 12)
    local PatrolPartyGreen  =  AddPartyToLevel(PLAYER_GOOD       ,"GREEN"              , 13)
    local PatrolPartyYellow =  AddPartyToLevel(PLAYER_GOOD       ,"YELLOW"             , 14)
    local PatrolPartyBlue   =  AddPartyToLevel(PLAYER_GOOD       ,"BLUE"               , 15)
    local PatrolPartyKnight =  AddPartyToLevel(PLAYER_GOOD       ,"KNIGHT"             , -5)


    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , northernroute , 1, "Red Patrol")
    RegisterPatrol(PatrolPartyGreen[1]  , middleway  , 1, "Green Patrol")
    RegisterPatrol(PatrolPartyYellow[1] , eastside     , 1, "Yellow Patrol")
    RegisterPatrol(PatrolPartyBlue[1] , westside     , 1, "Blue Patrol")
    RegisterPatrol(PatrolPartyKnight[1] , southside     , 1, "Blue Patrol")


end