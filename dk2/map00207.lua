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
    RegisterTimerEvent(SpawnLord, 500, false)
    RegisterTimerEvent(SpawnCRTRS, 305, false)
end

-- Define the hero parties that can be spawned
function MyHeroParties()

-- Parties that will patrol the map
    CreateParty("RED")
        AddToParty("RED", "DWARFA"       , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "DWARFA"       , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "BARBARIAN"    , 1, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("GREEN")
        AddToParty("GREEN", "DWARFA"        , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "BARBARIAN"     , 2, 500, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("WIZARD1")
        AddToParty("WIZARD1", "DWARFA"    , 1, 500, "ATTACK_DUNGEON_HEART", 0)    
        AddToParty("WIZARD1", "DWARFA"    , 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD1", "BARBARIAN", 1, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD1", "BARBARIAN", 1, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD1", "WIZARD"   , 1, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("WIZARD2")
        AddToParty("WIZARD2", "DWARFA"    , 3, 500, "ATTACK_DUNGEON_HEART", 0)    
        AddToParty("WIZARD2", "DWARFA"    , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD2", "BARBARIAN", 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD2", "BARBARIAN", 3, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD2", "WIZARD"   , 3, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("WIZARD3")
        AddToParty("WIZARD3", "DWARFA"    , 2, 500, "ATTACK_DUNGEON_HEART", 0)    
        AddToParty("WIZARD3", "DWARFA"    , 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD3", "BARBARIAN", 2, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD3", "BARBARIAN", 2, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD3", "WIZARD"   , 2, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("WIZARD4")
        AddToParty("WIZARD4", "DWARFA"    , 4, 500, "ATTACK_DUNGEON_HEART", 0)    
        AddToParty("WIZARD4", "DWARFA"    , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD4", "BARBARIAN", 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD4", "BARBARIAN", 4, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD4", "WIZARD"   , 4, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("WIZARD5")
        AddToParty("WIZARD5", "DWARFA"    , 5, 500, "ATTACK_DUNGEON_HEART", 0)    
        AddToParty("WIZARD5", "DWARFA"    , 5, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD5", "BARBARIAN", 5, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD5", "BARBARIAN", 5, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("WIZARD5", "WIZARD"   , 5, 250, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("LORD")
        AddToParty("LORD", "KNIGHT"    , 5, 0, "ATTACK_DUNGEON_HEART", 0)    
        AddToParty("LORD", "DWARFA"    , 5, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("LORD", "BARBARIAN", 5, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("LORD", "BARBARIAN", 5, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("LORD", "BARBARIAN", 5, 250, "ATTACK_DUNGEON_HEART", 0)        
        AddToParty("LORD", "GIANT"   , 5, 250, "ATTACK_DUNGEON_HEART", 0)

end

-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled

    local Lairroute = {}
        Lairroute[1]  =  { stl_x = 97, stl_y = 79 }
        Lairroute[2]  =  { stl_x = 85, stl_y = 79 }

    local westwaterway = {}
        westwaterway[1]  =   { stl_x = 60, stl_y = 95 }
        westwaterway[2]  =   { stl_x = 43, stl_y = 90 }

    local eastside = {}
        eastside[1]  =      { stl_x = 138, stl_y = 91 }
        eastside[2]  =      { stl_x = 138, stl_y = 99 }

    local RouteWiz2 = {}
        RouteWiz2[1]  =      { stl_x = 138, stl_y = 69 }
        RouteWiz2[2]  =      { stl_x = 126, stl_y = 69 }

    local RouteWiz3 = {}
        RouteWiz3[1]  =      { stl_x = 58, stl_y = 82 }
        RouteWiz3[2]  =      { stl_x = 49, stl_y = 73 }

    local RouteWiz4 = {}
        RouteWiz4[1]  =      { stl_x = 52, stl_y = 33 }
        RouteWiz4[2]  =      { stl_x = 42, stl_y = 34 }

    local RouteWiz5 = {}
        RouteWiz5[1]  =      { stl_x = 121, stl_y = 43 }
        RouteWiz5[2]  =      { stl_x = 130, stl_y = 34 }

    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"                , 20)
    local PatrolPartyGreen  =  AddPartyToLevel(PLAYER_GOOD       ,"GREEN"              , 22)
    local PatrolPartyWiz1   =  AddPartyToLevel(PLAYER_GOOD       ,"WIZARD1"            , 1)
    local PatrolPartyWiz2   =  AddPartyToLevel(PLAYER_GOOD       ,"WIZARD2"            , 23)
    local PatrolPartyWiz3   =  AddPartyToLevel(PLAYER_GOOD       ,"WIZARD3"            , 24)
    local PatrolPartyWiz4   =  AddPartyToLevel(PLAYER_GOOD       ,"WIZARD4"            , 4)
    local PatrolPartyWiz5   =  AddPartyToLevel(PLAYER_GOOD       ,"WIZARD5"            , 5)

    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , Lairroute     , 1, "Red Patrol")
    RegisterPatrol(PatrolPartyGreen[1]  , westwaterway  , 1, "Green Patrol")
    RegisterPatrol(PatrolPartyWiz1[1]   , eastside      , 1, "WIZARD1 Patrol")
    RegisterPatrol(PatrolPartyWiz2[1]   , RouteWiz2     , 1, "WIZARD2 Patrol")
    RegisterPatrol(PatrolPartyWiz3[1]   , RouteWiz3     , 1, "WIZARD3 Patrol")
    RegisterPatrol(PatrolPartyWiz4[1]   , RouteWiz4     , 1, "WIZARD4 Patrol")
    RegisterPatrol(PatrolPartyWiz5[1]   , RouteWiz5     , 1, "WIZARD5 Patrol")
end

    -- the Lord AFTER the intro
    -- TODO this party is supposed to stop patrolling after keeper good has 0 wizards anymore from the 5 parties that are spawned in  

function SpawnLord()

    local RouteLord = {}
        RouteLord[1]  =      { stl_x = 97, stl_y = 13 }
        RouteLord[2]  =      { stl_x = 85, stl_y = 13 }

    local PatrolPartyLord   =      AddPartyToLevel(PLAYER_GOOD       ,"LORD"            , 6)

    RegisterPatrol(PatrolPartyLord[1] , RouteLord     , 1, "LORD Patrol")

end

    -- only keeper creatures (spawning in later because otherwise they fight and disturb the intro)


function SpawnCRTRS()
    AddCreatureToLevel(PLAYER0    ,"SALAMANDER"          , 21, 1, 200)
    AddCreatureToLevel(PLAYER0    ,"SALAMANDER"          , 21, 1, 200)
    AddCreatureToLevel(PLAYER0    ,"SALAMANDER"          , 21, 2, 200)
    AddCreatureToLevel(PLAYER0    ,"MISTRESS"            , 21, 1, 200)
    AddCreatureToLevel(PLAYER0    ,"MISTRESS"            , 21, 2, 200)
    AddCreatureToLevel(PLAYER0    ,"TROLL"               , 21, 1, 200)
end

