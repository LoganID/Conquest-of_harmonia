-- guards.lua
-- Used to make creatures stand guard.
-- Standalone library (does not depend on patrols.lua).
--
-- v 1.1 - Bug fix: Imprisoned guards roam now.
--
-- HOW TO USE:
-- Let's create 2 guards to give you a clear picture of how to set this up.
--
-- Example:
--
-- 1. Preparing the guards:
-- CreateParty("GUARD1")
--			AddToParty("GUARD1", "KNIGHT", 2, 0, "ATTACK_DUNGEON_HEART", 0)
-- CreateParty("GUARD2")
--			AddToParty("GUARD2", "TROLL", 5, 0, "ATTACK_DUNGEON_HEART", 0)
--
-- 2. Spawning the guards on the map (where stl_x and stl_y are specific subtile coordinates):
-- local Guard1 = AddPartyToLevel(PLAYER_GOOD,"GUARD1", {stl_x = 109, stl_y = 55})
-- local Guard2 = AddPartyToLevel(PLAYER0,"GUARD2", {stl_x = 155, stl_y = 55})
--
-- 3. Registering the guards. We provide the coordinates where they will hold their position, and define their behavior:
-- RegisterGuard(Guard1[1], {stl_x = 109, stl_y = 55}, 1040, "Gate Guard 1", { guard_anim = "246", fixed_spot = true, lock_facing = true, look_around = true, allow_needs = true, can_pickup = false })
-- RegisterGuard(Guard2[1], {stl_x = 115, stl_y = 55}, 1040, "Gate Guard 2", { fixed_spot = true, lock_facing = true, look_around = false })
--
-- All the parameters break down:
--
-- = Guard1[1] - Should be the "local name" of the party under which our guard was called.
--
-- = {stl_x = 109, stl_y = 55} - Can be the same coordinates used to spawn the guard, or different ones. If different, the guard will walk to the registered coordinates.
--
-- = 1040 - Facing direction. (0-2047). 
--       Up-Left - 1792      Up (North) - 0/2047      Up-Right - 256
--       Left (West) - 1536                           Right (East) - 512 
--       Down-Left - 1280    Down (South) - 1024      Down-Right - 768
--
-- = "Gate Guard 1" - Comment for the map maker to ensure easy identification.
--
-- = guard_anim = "246"
--   All creature animations can be found in "[KeeperFX root directory]/fxdata/creatures" (or your custom directory). 
--   Inside the relevant *.cfg file, find the [sprites] section. 
--   These are the animation numbers you can use. Alternatively, you can use the custom creature's animation number, or its name if it uses one instead.
--   You can use any creature's animation for your guard while he guards.
--   IF NO ANIMATION IS SELECTED: The regular standing animation will be played by default.
--
-- = "fixed_spot = true" - If true, the guard will try to stand exactly where placed, even if forced to leave temporarily. If false, there is a 50-50 chance he will stand on or near the spot.
--
-- = "lock_facing = true" - If true, the guard will only look in the specified direction. If false, he will face a random direction when returning to his post.
--
-- = "look_around = true" - If true, the guard will look around at 1-5 second intervals. This creates a visual effect to make the guard look alive rather than like a statue.
--
-- = "allow_needs = true" - If true, the guard will leave to eat or collect pay when necessary. Designed for creatures assigned to players other than PLAYER_GOOD or neutral.
--
-- = "can_pickup = false" - If false, players cannot pick up this guard (or party). If true (or omitted), the owner can pick them up normally.
--
-- 4. To make a creature stop guarding and roam or perform default actions:
-- You must store the "RegisterGuard" handle inside a variable beforehand:
-- Game.guard17Handle = RegisterGuard(Guard17[1], {stl_x = 73, stl_y = 64}, 1040, "Gate Guard 17", { fixed_spot = true, lock_facing = true, look_around = true, allow_needs = true, can_pickup = false })
-- Then call the unregister command like this:
-- UnregisterGuard(Game.guard17Handle)


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

-- Engine states used while feeding or collecting salary. Check both the
-- current and continuation states because a creature may be moving to a need.
function GuardsIsHandlingNeeds(creature)
    local needStates = {
        CreatureToGarden = true,
        CreatureArrivedAtGarden = true,
        CreatureEatingAtGarden = true,
        CreatureEat = true,
        CreatureWantsSalary = true,
        CreatureTakeSalary = true,
        CreatureWaitAtTreasureRoomDoor = true
    }

    return needStates[creature.state] == true or
           needStates[creature.continue_state] == true
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

-- Apply an explicit animation override. Do not assign an animation when the
-- user omitted guard_anim; in that case, KeeperFX controls the animation normally.
function GuardsApplyAnimation(leader, animation)
    if animation == nil then
        return
    end

    -- Numeric IDs are exposed by the engine as numbers. Avoid reassigning the
    -- same ID unless KeeperFX has changed it since the last guard update.
    local animationId = tonumber(animation)
    if animationId == nil or leader.anim_sprite ~= animationId then
        leader.anim_sprite = animation
    end

    -- A stopped animation cannot advance frames.
    if leader.anim_speed == 0 then
        leader.anim_speed = 128
    end
end

-- Helper to enforce or remove the pickup restriction.
--   can_pickup = true  → hand_blocked_turns = 0 (normal)
--   can_pickup = false → hand_blocked_turns = -1 (infinite block)
function GuardsSetHandRule(creature, can_pickup)
    if creature == nil or not creature:isValid() then
        return
    end
    creature.hand_blocked_turns = can_pickup and 0 or -1
end

function GuardsIsSameCreature(a, b)
    if a == nil or b == nil then
        return false
    end

    if a == b then
        return true
    end

    -- Thing proxies compare by ThingIndex and creation_turn in KeeperFX.
    if a.ThingIndex ~= nil and b.ThingIndex ~= nil then
        return a.ThingIndex == b.ThingIndex and
               a.creation_turn == b.creation_turn
    end

    return false
end

function GuardsTargetMatches(guard, target)
    if guard == target then
        return true
    end

    -- Also accept the guard record returned by RegisterGuard().
    if type(target) == "table" and
       target.guardId ~= nil and
       target.leader ~= nil then
        return target.guardId == guard.guardId
    end

    -- A creature target may be the current leader or any member of its party.
    if GuardsIsSameCreature(guard.leader, target) then
        return true
    end

    if guard.party ~= nil then
        for _, member in ipairs(guard.party) do
            if GuardsIsSameCreature(member, target) then
                return true
            end
        end
    end

    return false
end

function GuardsCanResetToStartState(leader)
    if leader.picked_up or
       leader.state == "CreatureUnconscious" or
       leader.continue_state == "CreatureInPrison" or
       leader.state == "CreatureInPrison" or
       leader.state == "CreatureBeingDropped" or
       leader.continue_state == "CreatureBeingDropped" or
       leader.combat_type ~= nil or
       leader.state == "CreatureInCombat" or
       leader.state == "CreatureCombatFlee" or
       GuardsIsHandlingNeeds(leader) then
        return false
    end

    return true
end

---Stop guarding and return the creature to normal engine behavior.
---Accepts either the creature/current party member or the guard record returned
---by RegisterGuard. Returns true if at least one registration was found.
---@param target Creature|table
---@return boolean unregistered
function UnregisterGuard(target)
    if Game.guards == nil or target == nil then
        return false
    end

    local found = false

    for _, guard in ipairs(Game.guards) do
        if not guard.stopped and GuardsTargetMatches(guard, target) then
            found = true
            guard.stopped = true

            local leader = guard.leader
            if leader ~= nil and leader:isValid() then
                -- Restore normal pickup for the leader.
                GuardsSetHandRule(leader, true)
                leader.max_speed = guard.original_speed

                -- Don't disrupt active combat, needs, pickup/drop, prison, or
                -- unconsciousness. For an idle guard, let KeeperFX choose its
                -- normal start state so its AI can resume.
                if GuardsCanResetToStartState(leader) then
                    leader:set_start_state()
                end
            end

            -- Restore pickup for every party member as well.
            if guard.party ~= nil then
                for _, member in ipairs(guard.party) do
                    if member ~= nil and member:isValid() then
                        GuardsSetHandRule(member, true)
                    end
                end
            end
        end
    end

    return found
end

function GuardsUpdateOne(guard)
    local leader = guard.leader

    if leader == nil or not leader:isValid() or
       leader.state == "CreatureUnconscious" or
       leader.state == "CreatureInPrison" or
       leader.continue_state == "CreatureInPrison" then
        -- The leader is losing its role. Restore the speed it had before it
        -- was frozen at its post, so it can move again if it recovers, is
        -- captured, or is converted.
        if leader ~= nil and leader:isValid() and
           guard.original_speed ~= nil then
            leader.max_speed = guard.original_speed
        end

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
        guard.was_handling_needs = false

        -- Enforce the pickup restriction on the new leader.
        GuardsSetHandRule(replacement, guard.can_pickup)
        return
    end

    -- Let the engine handle food and salary needs. Restore movement speed so
    -- the creature can travel to the relevant room. When the need is complete,
    -- a new guard visit is initialized on the next update.
    if guard.allow_needs and GuardsIsHandlingNeeds(leader) then
        leader.max_speed = guard.original_speed
        guard.facing_locked = false
        guard.was_handling_needs = true
        return
    end

    if guard.was_handling_needs then
        guard.was_handling_needs = false
        guard.facing_locked = false
        guard.visit_orientation = nil
        guard.random_turn_countdown = nil
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
            if guard.allow_needs then
                -- Keep movement available for future food/salary activities.
                leader.max_speed = guard.original_speed
            else
                leader.max_speed = 0
            end

            if not guard.facing_locked then
                if guard.fixed_turn_direction then
                    guard.visit_orientation = guard.orientation
                else
                    guard.visit_orientation = math.random(0, 2047)
                end

                leader.state = "CreatureDoingNothing"
                leader.continue_state = "CreatureDoingNothing"
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

                leader.orientation = guard.visit_orientation
            else
                leader.orientation = guard.visit_orientation
            end

            -- Preserve the existing optional animation override.
            GuardsApplyAnimation(leader, guard.guard_anim)

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
    guard.was_handling_needs = false

    -- Apply the pickup restriction to the new leader.
    GuardsSetHandRule(replacement, guard.can_pickup)

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
---@param options? table configuration: guard_anim, fixed_spot, lock_facing, look_around, allow_needs, can_pickup
---@return table guard state
function RegisterGuard(leader, guardPosition, guardOrientation, guard_name, options)
    GuardsStartTimer()

    options = options or {}

    -- Default to true if the option is missing or nil.
    local can_pickup = options.can_pickup
    if can_pickup == nil then
        can_pickup = true
    end

    if guard_name == nil then
        guard_name = "Guard " .. tostring(#Game.guards + 1)
    end

    local guardIndex = #Game.guards + 1
    local party = leader.party or { leader }

    local guard = {
        leader = leader,
        position = guardPosition,
        orientation = guardOrientation,
        original_speed = leader.max_speed,
        perfect_positioning = options.fixed_spot == true,
        fixed_turn_direction = options.lock_facing == true,
        random_turn = options.look_around == true,
        allow_needs = options.allow_needs == true,
        can_pickup = can_pickup,
        -- nil means use KeeperFX's normal animation behavior.
        -- Numeric IDs can be provided as strings, e.g. "246".
        guard_anim = options.guard_anim,
        visit_perfect_positioning = nil,
        visit_orientation = nil,
        random_turn_countdown = nil,
        facing_locked = false,
        was_handling_needs = false,
        name = guard_name,
        guardId = guardIndex,
        party = party,
        stopped = false
    }

    table.insert(Game.guards, guard)

    -- Apply the pickup restriction to the leader and all party members.
    GuardsSetHandRule(leader, can_pickup)
    for _, member in ipairs(party) do
        if member ~= nil and member:isValid() then
            GuardsSetHandRule(member, can_pickup)
        end
    end

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