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
    SpawnGuards()
end

-- Define the hero parties that can be spawned
function MyHeroParties()

-- Parties that will patrol the map
    CreateParty("RED")
        AddToParty("RED", "GIANT"       , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "SAMURAI"   , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "MONK"        , 2, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "WIZARD"      , 1, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("GREEN")
        AddToParty("GREEN", "THIEF"     , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "THIEF"     , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "SAMURAI" , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "SAMURAI" , 1, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "WIZARD"    , 1, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("YELLOW")
        AddToParty("YELLOW", "THIEF"    , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("YELLOW", "SAMURAI", 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("YELLOW", "SAMURAI", 1, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("YELLOW", "WIZARD"   , 1, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("KNIGHT")
        AddToParty("KNIGHT", "KNIGHT"     , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("KNIGHT", "GIANT"     , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("KNIGHT", "GIANT" , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("KNIGHT", "BARBARIAN" , 2, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("KNIGHT", "BARBARIAN"    , 2, 250, "ATTACK_DUNGEON_HEART", 0)

-- Parties that will defend rooms

    CreateParty("DEFEND2")
        AddToParty("DEFEND2", "THIEF"   , 4, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND2", "THIEF"   , 4, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND2", "THIEF"   , 3, 500, "DEFEND_ROOMS", 0)

    CreateParty("DEFEND3")
        AddToParty("DEFEND3", "BARBARIAN", 3, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND3", "BARBARIAN", 3, 250, "DEFEND_ROOMS", 0)

    CreateParty("DEFEND4")
        AddToParty("DEFEND4", "DWARFA"  , 5, 250, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND4", "DWARFA"  , 4, 500, "DEFEND_ROOMS", 0)
end

-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled
    local guardbridge = {}
        guardbridge[1] =     { stl_x = 178, stl_y = 160 }
        guardbridge[2] =     { stl_x = 178, stl_y = 190 }
        guardbridge[3] =     { stl_x = 115, stl_y = 190 }
        guardbridge[4] =     { stl_x = 115, stl_y = 238 }
        guardbridge[5] =     { stl_x = 115, stl_y = 190 }
        guardbridge[6] =     { stl_x = 178, stl_y = 190 }

    local northernroute = {}
        northernroute[1]  =  { stl_x = 116, stl_y =  95 }
        northernroute[2]  =  { stl_x = 180, stl_y = 153 }

    local westwaterway = {}
        westwaterway[1]  =   { stl_x = 13, stl_y = 145 }
        westwaterway[2]  =   { stl_x = 73, stl_y = 133 }
        westwaterway[3]  =   { stl_x = 52, stl_y = 181 }

    local southside = {}
        southside[1]  =      { stl_x = 10, stl_y = 211 }
        southside[2]  =      { stl_x = 57, stl_y = 242 }

    local KnightRoute = {}
        KnightRoute[1]  =      { stl_x = 58, stl_y = 31 }
        KnightRoute[2]  =      { stl_x = 96, stl_y = 31 }




    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"                , 6)
    local PatrolPartyGreen  =  AddPartyToLevel(PLAYER_GOOD       ,"GREEN"              , 3)
    local PatrolPartyYellow =  AddPartyToLevel(PLAYER_GOOD       ,"YELLOW"             , 7)
    local PatrolPartyKnight =  AddPartyToLevel(PLAYER_GOOD       ,"KNIGHT"             , 8
)
    local PatrolHeroBlue1 =    AddCreatureToLevel(PLAYER_GOOD    ,"SAMURAI"          , 5, 3, 200)
    local PatrolHeroBlue2 =    AddCreatureToLevel(PLAYER_GOOD    ,"SAMURAI"          , 5, 2, 200)
    local PatrolHeroBlue3 =    AddCreatureToLevel(PLAYER_GOOD    ,"WIZARD"             , 5, 1, 200)

    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , northernroute , 1, "Red Patrol")
    RegisterPatrol(PatrolPartyGreen[1]  , westwaterway  , 1, "Green Patrol")
    RegisterPatrol(PatrolPartyYellow[1] , southside     , 1, "Yellow Patrol")
    RegisterPatrol(PatrolPartyKnight[1] , KnightRoute   , 1, "KnightPatrol")

    RegisterPatrol(PatrolHeroBlue1      , guardbridge, 1, "Blue Patrol 1")
    RegisterPatrol(PatrolHeroBlue2      , guardbridge, 2, "Blue Patrol 2")
    RegisterPatrol(PatrolHeroBlue3      , guardbridge, 4, "Blue Patrol 3")
end

-- Spawn some hero parties at the start of the map that will defend rooms near their starting locations
function SpawnGuards()
    AddPartyToLevel(PLAYER_GOOD    ,"DEFEND2"           , 2)
    AddPartyToLevel(PLAYER_GOOD    ,"DEFEND3"           , 3)
    AddPartyToLevel(PLAYER_GOOD    ,"DEFEND4"           , 4)
end