-- helper.lua
-- Contains campaign wide helper functions

function CountAwakeHeroes()
    local count = 0
	local creatures = GetCreatures()
        
    for index, creature in ipairs(creatures) do
		if creature.owner == PLAYER_GOOD and creature.state ~= "CreatureUnconscious" then
            count = count + 1
        end
	end
    PLAYER_GOOD.FLAG0 = count;
end

-- Hides the gem when damaged, deletes it after some turns.
function UpdateFunctionFAKE_GEM(gem)
    if gem.health >= 10000 then
            Game.GemDeleteTurn = 0
    else
        gem.sprite_size = 0
        if Game.GemDeleteTurn == 0 then
            Game.GemDeleteTurn = PLAYER0.GAME_TURN + 90
        end

        if PLAYER0.GAME_TURN >= Game.GemDeleteTurn then
            gem:delete()
            return -1
        end
    end
    return 0
end

function SpawnHorny(location)
    Game.Horny = AddCreatureToLevel(PLAYER6,"EVILLORD",location,10,0,0)
    Game.Horny.party_objective = 5
    Game.Horny.party_target_player = 7
end

