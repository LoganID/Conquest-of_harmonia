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
    RegisterTimerEvent(StopPatrol, 45000, false)
end

function StopPatrol()
    Game.patrols = {}
end

-- Define the hero parties that can be spawned
function MyHeroParties()

-- Parties that will patrol the map
    CreateParty("RED")
        AddToParty("RED", "WIZARD"      , 2, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "WIZARD"      , 3, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "DWARFA"      , 7, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "GIANT"       , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "GIANT"       , 2, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "GIANT"       , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "BARBARIAN"   , 3, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("WEST")
        AddToParty("WEST", "WIZARD"        , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WEST", "WIZARD"        , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WEST", "BARBARIAN"     , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WEST", "THIEF"         , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WEST", "BARBARIAN"     , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WEST", "BARBARIAN"     , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WEST", "KNIGHT"        , 5, 500, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("OST")
        AddToParty("OST", "WIZARD"        , 4, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "WIZARD"        , 4, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "ARCHER"       , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "ARCHER"       , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "ARCHER"       , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "ARCHER"        , 4, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "GIANT"        , 4, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "DWARFA"       , 4, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "DWARFA"       , 4, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "BARBARIAN"    , 6, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "BARBARIAN"    , 6, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("OST", "BARBARIAN"    , 6, 250, "ATTACK_DUNGEON_HEART", 0)
end

-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled

    local Bridgeroute = {}
        Bridgeroute[1]  =  { stl_x = 76, stl_y = 133 }
        Bridgeroute[2]  =  { stl_x = 130, stl_y = 133 }

    local westwaterway = {}
        westwaterway[1]  =   { stl_x = 67, stl_y = 145 }
        westwaterway[2]  =   { stl_x = 67, stl_y = 121 }

    local eastside = {}
        eastside[1]  =      { stl_x = 139, stl_y = 121 }
        eastside[2]  =      { stl_x = 139, stl_y = 145 }

    local leftcircler = {}
        leftcircler[1]  =      { stl_x = 52, stl_y = 127 }
        leftcircler[2]  =      { stl_x = 67, stl_y = 127 }
        leftcircler[3]  =      { stl_x = 67, stl_y = 139 }
        leftcircler[4]  =      { stl_x = 52, stl_y = 139 }

    local rightcircler = {}
        rightcircler[1]  =      { stl_x = 139, stl_y = 127 }
        rightcircler[2]  =      { stl_x = 154, stl_y = 127 }
        rightcircler[3]  =      { stl_x = 154, stl_y = 139 }
        rightcircler[4]  =      { stl_x = 139, stl_y = 139 }

    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"                , 9)
    local PatrolPartyGreen  =  AddPartyToLevel(PLAYER_GOOD       ,"WEST"              , 10)
    local PatrolPartyWiz1   =  AddPartyToLevel(PLAYER_GOOD       ,"OST"               , 35)

    local PatrolHeroleft  =    AddCreatureToLevel(PLAYER_GOOD    ,"ARCHER"             , 36, 5, 200)
    local PatrolHeroleft1 =    AddCreatureToLevel(PLAYER_GOOD    ,"ARCHER"             , 39, 5, 200)
    local PatrolHeroleft2 =    AddCreatureToLevel(PLAYER_GOOD    ,"ARCHER"             , 36, 2, 200)
    local PatrolHeroleft3 =    AddCreatureToLevel(PLAYER_GOOD    ,"ARCHER"             , 39, 6, 200)
    local PatrolHeroleft4 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 36, 5, 200)
    local PatrolHeroleft5 =    AddCreatureToLevel(PLAYER_GOOD    ,"BARBARIAN"          , 39, 3, 200)
    local PatrolHeroleft6 =    AddCreatureToLevel(PLAYER_GOOD    ,"BARBARIAN"          , 36, 3, 200)
    local PatrolHeroleft7 =    AddCreatureToLevel(PLAYER_GOOD    ,"BARBARIAN"          , 39, 3, 200)
    local PatrolHeroleft8 =    AddCreatureToLevel(PLAYER_GOOD    ,"BARBARIAN"          , 36, 4, 200)
    local PatrolHeroleft9 =    AddCreatureToLevel(PLAYER_GOOD    ,"WIZARD"             , 39, 4, 200)
    local PatrolHeroleft10 =   AddCreatureToLevel(PLAYER_GOOD   ,"WIZARD"             , 36, 4, 200)
    local PatrolHeroleft11 =   AddCreatureToLevel(PLAYER_GOOD    ,"THIEF"              , 39, 4, 200)
    local PatrolHeroleft12 =   AddCreatureToLevel(PLAYER_GOOD    ,"KNIGHT"             , 36, 3, 200)

    local PatrolHeroright  =   AddCreatureToLevel(PLAYER_GOOD    ,"ARCHER"             , 37, 4, 200)
    local PatrolHeroright1 =   AddCreatureToLevel(PLAYER_GOOD    ,"ARCHER"             , 38, 4, 200)
    local PatrolHeroright2 =   AddCreatureToLevel(PLAYER_GOOD    ,"ARCHER"             , 37, 4, 200)
    local PatrolHeroright3 =   AddCreatureToLevel(PLAYER_GOOD    ,"ARCHER"             , 38, 4, 200)
    local PatrolHeroright4 =   AddCreatureToLevel(PLAYER_GOOD    ,"WIZARD"             , 37, 4, 200)
    local PatrolHeroright5 =   AddCreatureToLevel(PLAYER_GOOD    ,"WIZARD"             , 38, 8, 200)
    local PatrolHeroright6 =   AddCreatureToLevel(PLAYER_GOOD    ,"GIANT"              , 37, 4, 200)
    local PatrolHeroright7 =   AddCreatureToLevel(PLAYER_GOOD    ,"GIANT"              , 38, 4, 200)
    local PatrolHeroright8 =   AddCreatureToLevel(PLAYER_GOOD    ,"GIANT"              , 37, 4, 200)
    local PatrolHeroright9 =   AddCreatureToLevel(PLAYER_GOOD    ,"KNIGHT"             , 38, 5, 200)
    local PatrolHeroright10 =   AddCreatureToLevel(PLAYER_GOOD   ,"BARBARIAN"          , 37, 6, 200)
    local PatrolHeroright11 =   AddCreatureToLevel(PLAYER_GOOD   ,"BARBARIAN"          , 38, 6, 200)
    local PatrolHeroright12 =   AddCreatureToLevel(PLAYER_GOOD   ,"DWARFA"             , 37, 6, 200)

    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , Bridgeroute   , 1, "Red Patrol")
    RegisterPatrol(PatrolPartyGreen[1]  , westwaterway  , 1, "WEST Patrol")
    RegisterPatrol(PatrolPartyWiz1[1]   , eastside      , 1, "OST Patrol")

    RegisterPatrol(PatrolHeroleft    , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft1   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft2   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft3   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft4   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft5   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft6   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft7   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft8   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft9   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft10   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft11   , leftcircler     , 1, "LEFTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroleft12   , leftcircler     , 1, "LEFTCIRCLE Patrol")

    RegisterPatrol(PatrolHeroright  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright1  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright2  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright3  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright4  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright5  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright6  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright7  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright8  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright9  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright10  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright11  , rightcircler     , 1, "RIGHTCIRCLE Patrol")
    RegisterPatrol(PatrolHeroright12  , rightcircler     , 1, "RIGHTCIRCLE Patrol")


end

