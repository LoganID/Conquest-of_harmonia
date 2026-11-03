-- ********************************************
--
--        Crusade
--
-- ********************************************

--
-- Patrol squad positions in the fortress:
--
--                 █████
--                 █   █
--                 █ S8█
--                 █   █
--             ██████ ██████
--             █   █   █   █ 
--    █████    █ S5  S6  S7
--    █   █    █   █   █   █
--    █ S1█  ████████ ███████
--  G1██ █████    █     █   █
--     █ █   █    █     █   █
--        S3         S4     █
--     █ █   █    █     █   █
--  G2██ █████    █     █   █
--    █ S2█  ████████ ███████
--    █   █    █   █   █   █
--    █████    █S9  S10 S11
--             █   █   █   █
--             ██████ ██████
--                 █   █
--                 █S12█
--                 █   █
--                 █████
--

function OnGameStart()
	MyHeroParties()
    SpawnPatrols()
end

function MyHeroParties()
	CreateParty("SQUAD1")
			AddToParty("SQUAD1", "FAIRY", 4, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD1", "FAIRY", 3, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD1", "FAIRY", 3, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD2")
			AddToParty("SQUAD2", "FAIRY", 4, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD2", "FAIRY", 4, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD2", "FAIRY", 2, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD3")
			AddToParty("SQUAD3", "SAMURAI", 5, 100, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD3", "FAIRY", 6, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD3", "FAIRY", 4, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD3", "FAIRY", 4, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD4")
			AddToParty("SQUAD4", "SAMURAI", 6, 100, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD4", "SAMURAI", 4, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD4", "SAMURAI", 4, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD4", "FAIRY", 7, 34, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD4", "FAIRY", 7, 32, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD5")
			AddToParty("SQUAD5", "FAIRY", 4, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD5", "FAIRY", 3, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD5", "FAIRY", 3, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD6")
			AddToParty("SQUAD6", "FAIRY", 7, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD6", "FAIRY", 6, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD7")
			AddToParty("SQUAD7", "FAIRY", 9, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD7", "FAIRY", 7, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD7", "FAIRY", 6, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD8")
			AddToParty("SQUAD8", "FAIRY", 7, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD9")
			AddToParty("SQUAD9", "FAIRY", 5, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD9", "FAIRY", 3, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD9", "FAIRY", 3, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD10")
			AddToParty("SQUAD10", "FAIRY", 8, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD10", "FAIRY", 3, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD11")
			AddToParty("SQUAD11", "FAIRY", 8, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD11", "FAIRY", 7, 0, "ATTACK_DUNGEON_HEART", 0)
			AddToParty("SQUAD11", "FAIRY", 7, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("SQUAD12")
			AddToParty("SQUAD12", "FAIRY", 6, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("GUARD1")
			AddToParty("GUARD1", "BARBARIAN", 5, 0, "ATTACK_DUNGEON_HEART", 0)
	CreateParty("GUARD2")
			AddToParty("GUARD2", "BARBARIAN", 5, 0, "ATTACK_DUNGEON_HEART", 0)
end

function SpawnPatrols()
	local Route1 = {}
			Route1[1] = { stl_x = 118, stl_y = 143 }
			Route1[2] = { stl_x = 118, stl_y = 144 }
	local Route2 = {}
			Route2[1] = { stl_x = 118, stl_y = 164 }
			Route2[2] = { stl_x = 118, stl_y = 165 }
	local Route3 = {}
			Route3[1] = { stl_x = 125, stl_y = 154 }
			Route3[2] = { stl_x = 129, stl_y = 154 }
	local Route4 = {}
			Route4[1] = { stl_x = 154, stl_y = 154 }
			Route4[2] = { stl_x = 160, stl_y = 154 }
	local Route5 = {}
			Route5[1] = { stl_x = 145, stl_y = 139 }
			Route5[2] = { stl_x = 146, stl_y = 139 }
	local Route6 = {}
			Route6[1] = { stl_x = 157, stl_y = 139 }
			Route6[2] = { stl_x = 158, stl_y = 139 }
	local Route7 = {}
			Route7[1] = { stl_x = 169, stl_y = 139 }
			Route7[2] = { stl_x = 170, stl_y = 139 }
	local Route8 = {}
			Route8[1] = { stl_x = 157, stl_y = 127 }
			Route8[2] = { stl_x = 157, stl_y = 128 }
	local Route9 = {}
			Route9[1] = { stl_x = 145, stl_y = 169 }
			Route9[2] = { stl_x = 146, stl_y = 169 }
	local Route10 = {}
			Route10[1] = { stl_x = 157, stl_y = 168 }
			Route10[2] = { stl_x = 157, stl_y = 169 }
	local Route11 = {}
			Route11[1] = { stl_x = 169, stl_y = 169 }
			Route11[2] = { stl_x = 170, stl_y = 169 }
	local Route12 = {}
			Route12[1] = { stl_x = 157, stl_y = 180 }
			Route12[2] = { stl_x = 157, stl_y = 181 }
	local Route13 = {}
			Route13[1] = { stl_x = 108, stl_y = 147 }
			Route13[2] = { stl_x = 108, stl_y = 149 }
	local Route14 = {}
			Route14[1] = { stl_x = 108, stl_y = 159 }
			Route14[2] = { stl_x = 108, stl_y = 161 }

	local PatrolPartySquad1 = AddPartyToLevel(PLAYER_GOOD,"SQUAD1", {stl_x = 118, stl_y = 143})
	local PatrolPartySquad2 = AddPartyToLevel(PLAYER_GOOD,"SQUAD2", {stl_x = 118, stl_y = 164})
	local PatrolPartySquad3 = AddPartyToLevel(PLAYER_GOOD,"SQUAD3", {stl_x = 125, stl_y = 154})
	local PatrolPartySquad4 = AddPartyToLevel(PLAYER_GOOD,"SQUAD4", {stl_x = 154, stl_y = 154})
	local PatrolPartySquad5 = AddPartyToLevel(PLAYER_GOOD,"SQUAD5", {stl_x = 145, stl_y = 139})
	local PatrolPartySquad6 = AddPartyToLevel(PLAYER_GOOD,"SQUAD6", {stl_x = 157, stl_y = 139})
	local PatrolPartySquad7 = AddPartyToLevel(PLAYER_GOOD,"SQUAD7", {stl_x = 169, stl_y = 139})
	local PatrolPartySquad8 = AddPartyToLevel(PLAYER_GOOD,"SQUAD8", {stl_x = 157, stl_y = 127})
	local PatrolPartySquad9 = AddPartyToLevel(PLAYER_GOOD,"SQUAD9", {stl_x = 145, stl_y = 169})
	local PatrolPartySquad10 = AddPartyToLevel(PLAYER_GOOD,"SQUAD10", {stl_x = 157, stl_y = 168})
	local PatrolPartySquad11 = AddPartyToLevel(PLAYER_GOOD,"SQUAD11", {stl_x = 169, stl_y = 169})
	local PatrolPartySquad12 = AddPartyToLevel(PLAYER_GOOD,"SQUAD12", {stl_x = 157, stl_y = 180})
	local PatrolPartyGuard1 = AddPartyToLevel(PLAYER_GOOD,"GUARD1", {stl_x = 108, stl_y = 147})
	local PatrolPartyGuard2 = AddPartyToLevel(PLAYER_GOOD,"GUARD2", {stl_x = 108, stl_y = 159})

	RegisterPatrol(PatrolPartySquad1[1], Route1, 1, "Squad1 Patrol")
	RegisterPatrol(PatrolPartySquad2[1], Route2, 1, "Squad2 Patrol")
	RegisterPatrol(PatrolPartySquad3[1], Route3, 1, "Squad3 Patrol")
	RegisterPatrol(PatrolPartySquad4[1], Route4, 1, "Squad4 Patrol")
	RegisterPatrol(PatrolPartySquad5[1], Route5, 1, "Squad5 Patrol")
	RegisterPatrol(PatrolPartySquad6[1], Route6, 1, "Squad6 Patrol")
	RegisterPatrol(PatrolPartySquad7[1], Route7, 1, "Squad7 Patrol")
	RegisterPatrol(PatrolPartySquad8[1], Route8, 1, "Squad8 Patrol")
	RegisterPatrol(PatrolPartySquad9[1], Route9, 1, "Squad9 Patrol")
	RegisterPatrol(PatrolPartySquad10[1], Route10, 1, "Squad10 Patrol")
	RegisterPatrol(PatrolPartySquad11[1], Route11, 1, "Squad11 Patrol")
	RegisterPatrol(PatrolPartySquad12[1], Route12, 1, "Squad12 Patrol")
	RegisterPatrol(PatrolPartyGuard1[1], Route13, 1, "Guard1 Patrol")
	RegisterPatrol(PatrolPartyGuard2[1], Route14, 1, "Guard2 Patrol")
end

