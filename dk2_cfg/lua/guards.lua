-- guards.lua
-- Standalone guard library. Does not depend on patrols.lua.

function GuardsIsCloseEnough(creature, target)
    return creature.pos.stl_y < target.stl_y + 2 and
           creature.pos.stl_y > target.stl_y - 2 and
           creature.pos.stl_x < target.stl_x + 2 and
           creature.pos.stl_x > target.stl_x - 2
end

function GuardsIsAtExactPosition(creature, target)
    return creature.pos.stl_x == target.stl_x and
           creature.pos.stl_y == target.stl_y
end

function GuardsIsActionableState(state)
    return state == "MoveToPosition" or
           state == "GoodDoingNothing" or
           state == "CreatureDoingNothing" or
           state == "CreatureInCombat" or
           state == "CreatureFollowLeader" or
           state == "CreatureCombatFlee"
end

function GuardsGetNextPotentialLeader(party)
    if party == nil then
        return nil
    end

    for _, member in ipairs(party) do
        if member ~= nil and member:isValid() and
           member.continue_state ~= "CreatureInPrison" and
           GuardsIsActionableState(member.state) then
            return member
        end
    end

    return nil
end

function GuardsStartTimer()
    if Game.guards == nil then
        Game.guards = {}
    end

    if Game.GuardsLibraryTimerInitialized ~= true then
        -- Global callback avoids captured upvalues during serialization.
        RegisterTimerEvent(UpdateGuards, 1, true)
        Game.GuardsLibraryTimerInitialized = true
    end
end

function GuardsUpdateOne(guard)
    local leader = guard.leader

    if leader == nil or not leader:isValid() or
       leader.state == "CreatureUnconscious" or
       leader.continue_state == "CreatureInPrison" then
        local replacement = GuardsGetNextPotentialLeader(guard.party)

        if replacement == nil then
            guard.stopped = true
            return
        end

        guard.leader = replacement
        guard.original_speed = replacement.max_speed
        guard.visit_perfect_positioning = nil
        guard.visit_orientation = nil
        guard.random_turn_countdown = nil
        guard.facing_locked = false
        return
    end

    -- Allow normal combat/flee behavior. Returning to the post starts a new visit.
    if leader.combat_type ~= nil or
       leader.state == "CreatureInCombat" or
       leader.state == "CreatureCombatFlee" then
        leader.max_speed = guard.original_speed
        guard.visit_perfect_positioning = nil
        guard.visit_orientation = nil
        guard.random_turn_countdown = nil
        guard.facing_locked = false
        return
    end

    if leader.state == "CreatureFollowLeader" then
        if leader.model == "TUNNELLER" or leader.model == "IMP" then
            leader.state = "Tunnelling"
        else
            leader.state = "MoveToPosition"
        end
    end

    local target = guard.position
    local closeEnough = GuardsIsCloseEnough(leader, target)

    if closeEnough then
        -- Decide once per return visit: in imperfect mode, a 50/50 chance
        -- determines whether this visit requires the exact subtile.
        if guard.visit_perfect_positioning == nil then
            if guard.perfect_positioning then
                guard.visit_perfect_positioning = true
            else
                guard.visit_perfect_positioning = (math.random(2) == 1)
            end
        end

        local arrived
        if guard.visit_perfect_positioning then
            arrived = GuardsIsAtExactPosition(leader, target)
        else
            arrived = true
        end

        if arrived then
            leader.max_speed = 0

            if not guard.facing_locked then
                if guard.fixed_turn_direction then
                    guard.visit_orientation = guard.orientation
                else
                    guard.visit_orientation = math.random(0, 2047)
                end

                leader.state = "CreatureDoingNothing"
                leader.continue_state = "CreatureDoingNothing"
                -- Set the animation on entering the guard stance. Reapplying it
                -- every timer tick would restart the animation from its first frame.
                leader.anim_sprite = guard.guard_anim
                guard.facing_locked = true

                if guard.random_turn then
                    -- UpdateGuards runs every game turn. This uses the
                    -- existing assumption of 20 turns per second.
                    guard.random_turn_countdown = math.random(20, 100)
                else
                    guard.random_turn_countdown = nil
                end
            end

            if guard.random_turn then
                if guard.random_turn_countdown == nil then
                    guard.random_turn_countdown = math.random(20, 100)
                end

                guard.random_turn_countdown = guard.random_turn_countdown - 1

                if guard.random_turn_countdown <= 0 then
                    guard.visit_orientation = math.random(0, 2047)
                    guard.random_turn_countdown = math.random(20, 100)
                end

                -- Use the creature's turn variable for the random-facing option.
                -- Reapply the stored angle on each update.
                leader.orientation = guard.visit_orientation
            else
                leader.orientation = guard.visit_orientation
            end

            return
        end
    else
        -- Leaving the post area ends this visit. A later return gets fresh choices.
        guard.visit_perfect_positioning = nil
        guard.visit_orientation = nil
        guard.random_turn_countdown = nil
        guard.facing_locked = false
    end

    -- Send the creature to its assigned post or continue its approach.
    leader.max_speed = guard.original_speed
    guard.facing_locked = false

    if leader.state ~= "MoveToPosition" or
       leader.moveto_pos.stl_x ~= target.stl_x or
       leader.moveto_pos.stl_y ~= target.stl_y then
        leader:walk_to(target.stl_x, target.stl_y)
        leader.state = "MoveToPosition"
        leader.continue_state = "CreatureDoingNothing"
    end
end

-- Timer callback: global and upvalue-free for the engine's serializer.
function UpdateGuards()
    if Game.guards == nil then
        return
    end

    for _, guard in ipairs(Game.guards) do
        if not guard.stopped then
            GuardsUpdateOne(guard)
        end
    end
end

-- Death-event callback: global and upvalue-free.
function GuardsOnLeaderDeath(_, triggerData)
    if Game.guards == nil then
        return
    end

    local guard = Game.guards[triggerData.guard_idx]
    if guard == nil then
        return
    end

    local backup = guard.partybackup
    if backup == nil or not backup:isValid() then
        guard.stopped = true
        if triggerData.trigger ~= nil then
            RemoveTrigger(triggerData.trigger)
        end
        return
    end

    local replacement = nil
    if backup.party ~= nil then
        replacement = backup.party[1]
    end
    if replacement == nil then
        replacement = backup
    end

    guard.leader = replacement
    guard.original_speed = replacement.max_speed
    guard.visit_perfect_positioning = nil
    guard.visit_orientation = nil
    guard.random_turn_countdown = nil
    guard.facing_locked = false

    local leaderTrigger = RegisterCreatureDeathEvent(GuardsOnLeaderDeath, replacement)
    leaderTrigger.triggerData.guard_idx = triggerData.guard_idx

    if replacement.party ~= nil and replacement.party[2] ~= nil then
        guard.partybackup = replacement.party[2]

        local backupTrigger = RegisterCreatureDeathEvent(
            GuardsOnBackupDeath,
            guard.partybackup
        )
        backupTrigger.triggerData.guard_idx = triggerData.guard_idx
    else
        guard.partybackup = nil
    end
end

-- Backup death-event callback: global and upvalue-free.
function GuardsOnBackupDeath(_, triggerData)
    if Game.guards == nil then
        return
    end

    local guard = Game.guards[triggerData.guard_idx]
    if guard == nil or triggerData.unit == guard.leader then
        return
    end

    if guard.leader ~= nil and guard.leader.party ~= nil then
        guard.partybackup = guard.leader.party[2]
    else
        guard.partybackup = nil
    end
end

---Assign a creature or party leader to guard one fixed position.
---@param leader Creature
---@param guardPosition table {stl_x = integer, stl_y = integer}
---@param guardOrientation integer facing angle, range 0-2047
---@param guard_name? string optional name for the guard
---@param options? table configuration: guard_anim, fixed_spot, lock_facing, look_around
---@return table guard state
function RegisterGuard(leader, guardPosition, guardOrientation, guard_name, options)
    GuardsStartTimer()

    options = options or {}

    if guard_name == nil then
        guard_name = "Guard " .. tostring(#Game.guards + 1)
    end

    local guardIndex = #Game.guards + 1
    local party = leader.party or { leader }
    local guardAnimation = string.upper(tostring(options.guard_anim or "STAND"))

    local guard = {
        leader = leader,
        position = guardPosition,
        orientation = guardOrientation,
        original_speed = leader.max_speed,
        perfect_positioning = options.fixed_spot == true,
        fixed_turn_direction = options.lock_facing == true,
        random_turn = options.look_around == true,
        guard_anim = guardAnimation,
        visit_perfect_positioning = nil,
        visit_orientation = nil,
        random_turn_countdown = nil,
        facing_locked = false,
        name = guard_name,
        guardId = guardIndex,
        party = party,
        stopped = false
    }

    table.insert(Game.guards, guard)

    local leaderTrigger = RegisterCreatureDeathEvent(GuardsOnLeaderDeath, leader)
    leaderTrigger.triggerData.guard_idx = guardIndex

    if leader.party ~= nil and leader.party[2] ~= nil then
        guard.partybackup = leader.party[2]

        local backupTrigger = RegisterCreatureDeathEvent(
            GuardsOnBackupDeath,
            guard.partybackup
        )
        backupTrigger.triggerData.guard_idx = guardIndex
    end

    leader.state = "MoveToPosition"
    leader.continue_state = "CreatureDoingNothing"

    return guard
end
