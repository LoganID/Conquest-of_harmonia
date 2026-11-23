-- ********************************************
--
--           Conquest of Harmonia: Rout
--           Map 226 (Also partly done in DKscript, see map00226.txt)
--           Script and Design by Mc. Biggus Dickus 
--
-- ********************************************
function OnGameStart()
    MyHeroParties()
    SpawnGuards()
    SpawnPatrols()
end

-- Define the hero parties that can be spawned
function MyHeroParties()

-- Parties that will defend rooms

    CreateParty("DEFEND")
        AddToParty("DEFEND", "DWARFA"   , 1, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND", "DWARFA"   , 1, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND", "DWARFA"   , 2, 250, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND", "DWARFA"   , 2, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND", "DWARFA"   , 3, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND", "DWARFA"   , 3, 250, "DEFEND_ROOMS", 0)

    CreateParty("DEFEND2")
        AddToParty("DEFEND2", "DWARFA"   , 1, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND2", "DWARFA"   , 1, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND2", "DWARFA"   , 2, 250, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND2", "DWARFA"   , 2, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND2", "DWARFA"   , 3, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND2", "DWARFA"   , 3, 250, "DEFEND_ROOMS", 0)

    CreateParty("DEFEND3")
        AddToParty("DEFEND3", "BARBARIAN", 3, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND3", "BARBARIAN", 3, 250, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND3", "BARBARIAN", 3, 500, "DEFEND_ROOMS", 0)
        AddToParty("DEFEND3", "BARBARIAN", 3, 250, "DEFEND_ROOMS", 0)

end

-- Spawn some hero parties at the start of the map that will defend rooms near their starting locations
function SpawnGuards()
    local defend_party =     AddPartyToLevel(PLAYER_GOOD    ,"DEFEND"            , 9)
    local defend2_party =    AddPartyToLevel(PLAYER_GOOD    ,"DEFEND2"           , 11)   
    local defend3_party =     AddPartyToLevel(PLAYER_GOOD    ,"DEFEND3"           , 10)

    for _, partymember in ipairs(defend_party) do
    partymember.health = 25
    end

    for _, partymember in ipairs(defend3_party) do
    partymember.health = 25
    end
end

-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled

    local FirstRoom = {}
        FirstRoom[1]  =  { stl_x = 106, stl_y = 121 }

    local Middlecircler = {}
        Middlecircler[1]  =      { stl_x = 100, stl_y = 91 }
        Middlecircler[2]  =      { stl_x = 112, stl_y = 91 }
        Middlecircler[3]  =      { stl_x = 112, stl_y = 109 }
        Middlecircler[4]  =      { stl_x = 100, stl_y = 109 }

    local UpRoom = {}
        UpRoom[1]  =  { stl_x = 124, stl_y = 81 }

    local RightRoom = {}
        RightRoom[1]  =  { stl_x = 124, stl_y = 100 }

    local LeftRoom = {}
        LeftRoom[1]  =  { stl_x = 87, stl_y = 100 }

    -- Patrolling parties and individual heroes added to level.

    local PatrolFirst  =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 12, 1, 200)
    local PatrolFirst2 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 12, 1, 200)
    local PatrolFirst3 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 12, 2, 200)
    local PatrolFirst4 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 12, 2, 200)
    local PatrolFirst5 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 12, 3, 200)
    local PatrolFirst6 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 12, 3, 200)


    local PatrolRight  =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 17, 1, 200)
    local PatrolRight2 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 17, 1, 200)
    local PatrolRight3 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 17, 2, 200)
    local PatrolRight4 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 17, 2, 200)
    local PatrolRight5 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 17, 3, 200)
    local PatrolRight6 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 17, 3, 200)

    local PatrolLeft  =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 8, 1, 200)
    local PatrolLeft2 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 8, 1, 200)
    local PatrolLeft3 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 8, 2, 200)
    local PatrolLeft4 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 8, 2, 200)
    local PatrolLeft5 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 8, 3, 200)
    local PatrolLeft6 =    AddCreatureToLevel(PLAYER_GOOD    ,"DWARFA"             , 8, 3, 200)

    local PatrolMiddle  =    AddCreatureToLevel(PLAYER_GOOD    ,"BARBARIAN"             , 13, 1, 200)
    local PatrolMiddle2 =    AddCreatureToLevel(PLAYER_GOOD    ,"BARBARIAN"             ,  3, 1, 200)
    local PatrolMiddle3 =    AddCreatureToLevel(PLAYER_GOOD    ,"BARBARIAN"             , 14, 2, 200)
    local PatrolMiddle4 =    AddCreatureToLevel(PLAYER_GOOD    ,"BARBARIAN"             , 15, 2, 200)

    local PatrolUp  =    AddCreatureToLevel(PLAYER_GOOD    ,"BARBARIAN"             , 16, 2, 200)
    local PatrolUp2 =    AddCreatureToLevel(PLAYER_GOOD    ,"BARBARIAN"             , 16, 2, 200)

    PatrolFirst.health = 25
    PatrolFirst2.health = 25
    PatrolFirst3.health = 50
    PatrolFirst4.health = 25
    PatrolFirst5.health = 25
    PatrolFirst6.health = 25

    PatrolLeft.health = 25
    PatrolLeft2.health = 25
    PatrolLeft3.health = 50
    PatrolLeft4.health = 25
    PatrolLeft5.health = 25
    PatrolLeft6.health = 25

    PatrolMiddle.health = 75
    PatrolMiddle2.health = 75
    PatrolMiddle3.health = 50
    PatrolMiddle4.health = 80

    PatrolUp.health = 25
    PatrolUp2.health = 25

    -- local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"                , 9)

    -- Calling Library function to activate patrols

    -- RegisterPatrol(PatrolPartyRed[1]    , FirstRoom   , 1, "Red Patrol")

    RegisterPatrol(PatrolFirst    , FirstRoom     , 1, "FirstRoom Patrol")
    RegisterPatrol(PatrolFirst2   , FirstRoom     , 1, "FirstRoom Patrol")
    RegisterPatrol(PatrolFirst3   , FirstRoom     , 1, "FirstRoom Patrol")
    RegisterPatrol(PatrolFirst4   , FirstRoom     , 1, "FirstRoom Patrol")
    RegisterPatrol(PatrolFirst5   , FirstRoom     , 1, "FirstRoom Patrol")
    RegisterPatrol(PatrolFirst6   , FirstRoom     , 1, "FirstRoom Patrol")

    RegisterPatrol(PatrolRight    , RightRoom     , 1, "PatrolRight Patrol")
    RegisterPatrol(PatrolRight2   , RightRoom     , 1, "PatrolRight Patrol")
    RegisterPatrol(PatrolRight3   , RightRoom     , 1, "PatrolRight Patrol")
    RegisterPatrol(PatrolRight4   , RightRoom     , 1, "PatrolRight Patrol")
    RegisterPatrol(PatrolRight5   , RightRoom     , 1, "PatrolRight Patrol")
    RegisterPatrol(PatrolRight6   , RightRoom     , 1, "PatrolRight Patrol")

    RegisterPatrol(PatrolLeft    , LeftRoom     , 1, "PatrolLeft Patrol")
    RegisterPatrol(PatrolLeft2   , LeftRoom     , 1, "PatrolLeft Patrol")
    RegisterPatrol(PatrolLeft3   , LeftRoom     , 1, "PatrolLeft Patrol")
    RegisterPatrol(PatrolLeft4   , LeftRoom     , 1, "PatrolLeft Patrol")
    RegisterPatrol(PatrolLeft5   , LeftRoom     , 1, "PatrolLeft Patrol")
    RegisterPatrol(PatrolLeft6   , LeftRoom     , 1, "PatrolLeft Patrol")

    RegisterPatrol(PatrolMiddle    , Middlecircler     , 1, "Middle Patrol")
    RegisterPatrol(PatrolMiddle2   , Middlecircler     , 1, "Middle Patrol")
    RegisterPatrol(PatrolMiddle3   , Middlecircler     , 1, "Middle Patrol")
    RegisterPatrol(PatrolMiddle4   , Middlecircler     , 1, "Middle Patrol")

    RegisterPatrol(PatrolUp    , UpRoom     , 1, "UpRoom Patrol")
    RegisterPatrol(PatrolUp2   , UpRoom     , 1, "UpRoom Patrol")

end