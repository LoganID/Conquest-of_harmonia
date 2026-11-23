function OnGameStart()
    RegisterTimerEvent(Tablelength, 1100, false)
    RegisterTimerEvent(SetupTriggers, 950, false)
    RegisterTimerEvent(MyHeroParties, 900, false)
    RegisterTimerEvent(SpawnPatrols, 1010, false)
    PrinceTookDamage()
    RegisterTimerEvent(InitPrinces, 1020, false)
end

function SetupTriggers()
    CreateParty("PG1")
    AddToParty("PG1", "BALDER"       , 10, 500, "DEFEND_PARTY", 0)  
    AddToParty("PG1", "GIANT"       , 4, 500, "DEFEND_PARTY", 0)
    AddToParty("PG1", "GIANT"       , 4, 250, "DEFEND_PARTY", 0)
    AddToParty("PG1", "GIANT"       , 5, 500, "DEFEND_PARTY", 0)
    AddToParty("PG1", "GIANT"       , 5, 500, "DEFEND_PARTY", 0)

    CreateParty("PG2")
        AddToParty("PG2", "FELIX"       , 10, 500, "DEFEND_PARTY", 0)
        AddToParty("PG2", "GIANT"       , 5, 250, "DEFEND_PARTY", 0)
        AddToParty("PG2", "GIANT"       , 5, 500, "DEFEND_PARTY", 0)
        AddToParty("PG2", "GIANT"       , 5, 500, "DEFEND_PARTY", 0)
        AddToParty("PG2", "GIANT"       , 5, 500, "DEFEND_PARTY", 0)

    CreateParty("PG3")
        AddToParty("PG3", "TRISTAN"       , 10, 500, "DEFEND_PARTY", 0)
        AddToParty("PG3", "GIANT"       , 3, 250, "DEFEND_PARTY", 0)
        AddToParty("PG3", "GIANT"       , 5, 500, "DEFEND_PARTY", 0)
        AddToParty("PG3", "GIANT"       , 5, 500, "DEFEND_PARTY", 0)
        AddToParty("PG3", "GIANT"       , 5, 500, "DEFEND_PARTY", 0)

    Game.PG1 = AddPartyToLevel("PLAYER_GOOD", "PG1", 3)
    Game.PG2 = AddPartyToLevel("PLAYER_GOOD"       ,"PG2"                , 4)
    Game.PG3 = AddPartyToLevel("PLAYER_GOOD"       ,"PG3"                , 5)

    if (Game.PG1 ~= nil and Tablelength(Game.PG1) == 1) then
        -- Prince is the first element in the party
        local prince = Game.PG1[1]
        print(prince.name)
    end

    if (Game.PG2 ~= nil and Tablelength(Game.PG2) == 1) then
        -- Prince is the first element in the party
        local prince = Game.PG2[1]
        print(prince.name)
    end

    if (Game.PG3 ~= nil and Tablelength(Game.PG3) == 1) then
        -- Prince is the first element in the party
        local prince = Game.PG3[1]
        print(prince.name)
    end
end

-- Counts how many entries a table has
function Tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function InitPrinces()
    Game.IsFleeing = false
    RegisterThingDamageEvent(function() PrinceTookDamage(1) end, Game.PG1[1])
    RegisterThingDamageEvent(function() PrinceTookDamage(2) end, Game.PG2[1])
    RegisterThingDamageEvent(function() PrinceTookDamage(3) end, Game.PG3[1])
end

function PrinceTookDamage(princeNumber)
    if not Game.IsFleeing then
        if princeNumber == 1 then
            StopPatrol()
            RegisterTimerEvent(UseSpell, 10, false)
            PlayMessage(PLAYER0,"SPEECH","lvl18spe09.ogg")
	        QuickObjective("I am wounded by the minions of evil. Run, my brothers! Escape my doom and save the Portal Gem.", PLAYER_GOOD)
        elseif princeNumber == 2 then
            StopPatrol()
            RegisterTimerEvent(UseSpell, 10, false)
            PlayMessage(PLAYER0,"SPEECH","lvl18spe09.ogg")
	        QuickObjective("I am wounded by the minions of evil. Run, my brothers! Escape my doom and save the Portal Gem.", PLAYER_GOOD)
        elseif princeNumber == 3 then
            StopPatrol()            
            RegisterTimerEvent(UseSpell, 10, false)
            PlayMessage(PLAYER0,"SPEECH","lvl18spe09.ogg")
	        QuickObjective("I am wounded by the minions of evil. Run, my brothers! Escape my doom and save the Portal Gem.", PLAYER_GOOD)
        end
        Game.IsFleeing = true
    end
end

function UseSpell ()
            UseSpellOnCreature(Game.PG1[1], "SPELL_FEAR",0)
            UseSpellOnCreature(Game.PG2[1], "SPELL_FEAR",0)
            UseSpellOnCreature(Game.PG3[1], "SPELL_FEAR",0)
end

function StopPatrol()
    Game.patrols = {}
end

-- Define the hero parties that can be spawned
function MyHeroParties()

-- Parties that will patrol the map
    CreateParty("RED")
        AddToParty("RED", "GIANT"       , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "GIANT"       , 4, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("RED", "GIANT"       , 5, 500, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("BLUE")
        AddToParty("BLUE", "GIANT"       , 4, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("BLUE", "GIANT"       , 5, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("BLUE", "GIANT"       , 5, 500, "ATTACK_DUNGEON_HEART", 0)

    CreateParty("GREEN")
        AddToParty("GREEN", "GIANT"       , 3, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "GIANT"       , 3, 250, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "GIANT"       , 5, 500, "ATTACK_DUNGEON_HEART", 0)
        AddToParty("GREEN", "GIANT"       , 5, 500, "ATTACK_DUNGEON_HEART", 0)
end


-- Function to define routes, spawn patrolling heroes and initialize their patrolling
function SpawnPatrols()

    -- Define routes to be patrolled

    local Bridgeroute = {}
        Bridgeroute[1]  =  { stl_x = 106, stl_y = 49 }
        Bridgeroute[2]  =  { stl_x = 121, stl_y = 46 }

    local Giants = {}
        Giants[1]  =  { stl_x = 184, stl_y = 40 }
        Giants[2]  =  { stl_x = 193, stl_y = 40 }

    local BossGuards = {}
        BossGuards[1]  =  { stl_x = 148, stl_y = 46 }
        BossGuards[2]  =  { stl_x = 154, stl_y = 39 }

    local RouteP1 = {}
        RouteP1[1]  =  { stl_x = 151, stl_y = 43 }
        RouteP1[2]  =  { stl_x = 202, stl_y = 100 }

    local RouteP2 = {}
        RouteP2[1]  =  { stl_x = 118, stl_y = 178 }
        RouteP2[2]  =  { stl_x = 187, stl_y = 157 }


    local RouteP3 = {}
        RouteP3[1]  =  { stl_x = 169, stl_y = 123 }
        RouteP3[2]  =  { stl_x = 191, stl_y = 70 }
        RouteP3[3]  =  { stl_x = 199, stl_y = 125 }
        RouteP3[4]  =  { stl_x = 184, stl_y = 157 }



    -- Patrolling parties and individual heroes added to level.
    local PatrolPartyRed    =  AddPartyToLevel(PLAYER_GOOD       ,"RED"                , 9)
    local PatrolPartyBlue    =  AddPartyToLevel(PLAYER_GOOD       ,"BLUE"                , 10)
    local PatrolPartyGreen    =  AddPartyToLevel(PLAYER_GOOD       ,"GREEN"                , 7)

    -- Calling Library function to activate patrols
    RegisterPatrol(PatrolPartyRed[1]    , Bridgeroute    , 1, "Red Patrol")
    RegisterPatrol(PatrolPartyBlue[1]    , Giants        , 1, "Red Patrol")
    RegisterPatrol(PatrolPartyGreen[1]    , BossGuards   , 1, "Red Patrol")

    RegisterPatrol(Game.PG1 [1]      , RouteP1, 1, "Blue Patrol 1")
    RegisterPatrol(Game.PG2 [1]      , RouteP2, 2, "Blue Patrol 2")
    RegisterPatrol(Game.PG3 [1]      , RouteP3, 4, "Blue Patrol 3")
end
