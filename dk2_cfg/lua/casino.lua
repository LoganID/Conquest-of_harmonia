-- ============================================================================
--  Casino  (custom room, all logic in Lua)
-- ============================================================================
--
-- How to use this module
--   require("casino")     at the TOP LEVEL of the level script or init.lua
--   CasinoInit()          inside the level script's OnGameStart() or campaign Init's OnCampaignGameStart()
--
-- Companion files (map-local, named after the map that uses them)
--   <map>.terrain.cfg    CASINO / CASINO_WALL slabs (100/101) + CASINO room (17)
--   <map>.slabset.toml   room graphics, copied from the TREASURY slabs
--   <map>.objects.cfg    CASINO_LEVER_HAPPY / CASINO_LEVER_PROFIT (185/186),
--                        the room's own special-box models
--   <map>.crstates.cfg   custom states in engine slots 55 / 56:
--                          CasinoWalking   (en route to a seat)
--                          CasinoGambling  (seated, playing rounds)
--
-- What happens
--   After CASINO_START_DELAY the casinos are active
--   Creatures inside a casino take a seat and gamble every few seconds. They
--   win or lose their own carried gold; the keeper is the house and gains what
--   they lose. Each room runs in one of two modes, switched by a lever in the
--   middle of the room - one of two special-box models, always the one for the
--   mode you can flip TO, so only ever one of the two is visible:
--     HAPPY  - creatures usually win  -> keeper pays, creatures cheer up
--     PROFIT - creatures usually lose -> keeper earns, creatures get annoyed
--   Rarely a round hits the jackpot: gold piles drop and everyone celebrates.
--
--   Winnings stop at the creature's GoldHold. The engine would not enforce that
--   by itself - gold_carried is an int32 that nothing trims, and GoldHold only
--   gates picking piles off the floor - so the cap is applied here. A creature
--   that is full keeps playing and still enjoys its wins, it just stops being
--   paid out - losing is then what frees room to be paid again.
--
--   CASINO_NO_CREATURE_LOSS turns the house generous: the keeper still collects
--   on every loss, but the gold is conjured instead of taken, so the creature
--   keeps its purse and only takes the mood hit. Nothing is staked there, so that
--   mode also skips the buy-in and never sends a penniless creature home.
--
-- Creature attitudes (CASINO_ATTITUDE below)
--   LIKE     walks in on its own, ranked by CASINO_PRIORITY against its jobs
--   NEUTRAL  only plays when dropped in
--   HATE     gets annoyed when dropped in and leaves at once
--   Nobody gambles before owning a lair, however they got there - see
--   CASINO_REQUIRE_LAIR. A creature whose anger has hit the engine ceiling walks
--   out and is not recruited again until something else calms it down.
--
-- Why some things look roundabout
--   * There is no OnDrop event in the engine, so a creature is flagged while it
--     is in the hand and the landing is resolved on the next tick. Reacting to
--     mere presence in the room instead would also grab passers-by.
--   * Room capacity is counted here, not by the engine: add_creature_to_work_room()
--     is only ever called from hardcoded C states, so a creature in a custom
--     state is never counted. The result is handed to the engine through the
--     room's capacity functions - see Casino_Total_Capacity.
--   * Cheering and moaning are real engine states, so the creature leaves
--     CasinoGambling while they run - see CasinoEmote().
-- ============================================================================


-- =====================================================================
--  TUNING
-- =====================================================================
CASINO_DEBUG             = true

CASINO_TICK              = 20    -- main tick period, 1 Hz
CASINO_RECRUIT_EVERY     = 3     -- run the creature sweep only every Nth tick
CASINO_DEEP_EVERY        = 30    -- full object sweep only every Nth tick
CASINO_START_DELAY       = 0   -- 0s: nothing happens before this game turn
CASINO_ROUND_TICKS       = 120   -- ~6s per gambling round

CASINO_STAKE_MIN         = 20
CASINO_STAKE_MAX         = 60 
CASINO_WIN_CHANCE_HAPPY  = 100    -- % chance the creature wins in HAPPY mode
CASINO_WIN_CHANCE_PROFIT = 0      -- % chance the creature wins in PROFIT mode
CASINO_SEED_GOLD         = 40    -- buy-in for a creature that enters with no gold

CASINO_MOOD_STEP         = 500   -- annoyance moved per round
CASINO_HATE_ANNOY        = 400   -- one-shot annoyance when a hater is dropped in
CASINO_BROKE_ANNOY       = 2000   -- annoyance when leaving without money
-- A keeper with an empty treasury cannot pay out wins. Everyone at the tables
-- goes home and no new visitor is recruited for this long, per player.
CASINO_BANKRUPT_PAUSE    = 1200  -- ~60s

CASINO_JACKPOT_CHANCE    = 0.6     -- % per round, fractions allowed (0.1 = one in a thousand)
CASINO_JACKPOT_PILES     = 6
CASINO_JACKPOT_GOLD      = 250   -- gold per dropped pile
CASINO_JACKPOT_MOOD      = 2000  -- annoyance removed from everyone in the room
-- Placeholder, swap for something of your own. 88 is COIN_DROP in sounds.cfg,
-- the sample the computer player uses when it drops coins on the map.
CASINO_JACKPOT_SOUND     = 88
-- How high the coins are spawned so they visibly drop. 256 per subtile;
-- the engine pulls them down on its own because they have a FallAcceleration and
-- are not Immobile (gravity lives in thing_list.c, veloc_push_add.z).
CASINO_JACKPOT_DROP      = 640
CASINO_JACKPOT_COINS     = 6     -- spinning coins raining down per gold pile
-- Quick-message slot for the jackpot box. 256 slots exist and each distinct
-- message needs its own - reusing one drops the message already in it, so pick
-- something no other script on this map uses.
CASINO_MSG_SLOT          = 200

CASINO_EMOTE_CHANCE      = 25    -- % chance of an emote on a normal round
CASINO_EMOTE_TICKS       = 50    -- ~2.5s of cheering or moaning when it happens
CASINO_DANCE_TICKS       = 100   -- ~5s of cheering for everyone on a jackpot
CASINO_LEAVE_COOLDOWN    = 600   -- ~30s before a creature may play again
CASINO_RESERVE_TIMEOUT   = 600   -- ~30s, release a stuck walk reservation
CASINO_MAX_DISTANCE      = 120   -- subtiles (~40 slabs) a creature will walk to gamble
CASINO_WALK_ATTEMPTS     = 3     -- spots tried per room before moving to the next one

CASINO_DEFAULT_MODE      = "HAPPY"   -- mode a freshly built casino starts in

-- Generous house: the keeper is still paid for every loss, but the gold is
-- conjured rather than taken from the creature - it keeps its purse and only
-- takes the mood hit. Wins are paid out normally. The keeper therefore earns the
-- full stake every time instead of only what the creature happened to carry.
-- Since nothing is ever staked in this mode there is also no buy-in, and an empty
-- purse neither stops a creature from playing nor sends it home.
CASINO_NO_CREATURE_LOSS  = false

CASINO_BOX_HAPPY         = 50     -- box_kind, what RegisterSpecialActivatedEvent filters on
CASINO_BOX_PROFIT        = 51

-- Own object models (map00013.objects.cfg), so the casino never collides with
-- other users of the shared SPECBOX_CUSTOM. The lever on show is always the one
-- that switches to the OTHER mode.
CASINO_LEVER_MODEL = {
    [CASINO_BOX_HAPPY]  = "CASINO_LEVER_HAPPY",
    [CASINO_BOX_PROFIT] = "CASINO_LEVER_PROFIT",
}

-- LIKE walks in by itself, HATE storms out, everything else is NEUTRAL.
CASINO_ATTITUDE = {
    ROGUE        = "LIKE", TROLL         = "LIKE", BILE_DEMON   = "LIKE", SKELETON              = "HATE",
    WARLOCK      = "HATE", VAMPIRE       = "HATE", THIEF        = "LIKE", SALAMANDER            = "LIKE",
    GOBLIN       = "LIKE", DARK_ELF      = "LIKE", FIREFFLY     = "LIKE", BLACK_KNIGHT          = "LIKE", 
    DWARFA       = "LIKE", SAMURAI       = "LIKE", BARBARIAN    = "LIKE", MONK                  = "HATE", 
    ARCHER       = "LIKE", WIZARD        = "LIKE", FAIRY        = "LIKE", GIANT                 = "LIKE", 
}

-- A creature never carries more than its model's GoldHold out of the casino.
-- Lua has no getter for creature config, so the values are mirrored here from
-- creatrs/*.cfg (GoldHold). Re-extract if you rebalance those files:
--   for f in creatrs/*.cfg; do ... grep -m1 '^GoldHold' ...; done
CASINO_GOLD_HOLD_DEFAULT = 500
CASINO_GOLD_HOLD = {
    ARCHER          = 250,   AVATAR           = 1000, BARBARIAN    = 1500,
    BILE_DEMON      = 3000,  ROGUE            = 75,   BLACK_KNIGHT = 2000,
    DARK_MISTRESS   = 750,   ANGEL            = 250,  WARLOCK      = 1500,
    GOBLIN          = 1000,  DWARFA           = 500,  FAIRY        = 500,
    FLOATING_SPIRIT = 0,     FIREFLY          = 50,   GHOST        = 1000,
    GIANT           = 2000,  REAPER           = 2500,
    IMP             = 500,   KNIGHT           = 600,  MAIDEN       = 800,
    MONK            = 750,   SAMURAI          = 750,
    SKELETON        = 500,   SORCEROR         = 400,
    SALAMANDER      = 1250,  THIEF            = 1750,
    DARK_ELF        = 500,   TROLL            = 500,  TUNNELLER    = 1500,
    VAMPIRE         = 2500,  WITCH            = 400,  WIZARD       = 500,
}

-- How angry is too angry to gamble, as a multiple of the model's AnnoyLevel.
-- The engine's own steps are: 1x = Angry, 2x = Livid, 3x = the hard ceiling every
-- anger value is clamped to (anger_calculate_creature_is_angry / anger_set_creature_anger_f).
-- 2 is what a player reads as "maxed out", because Livid is the worst face the
-- creature panel ever shows - 3x is a number nothing displays.
CASINO_ANGER_LIMIT = 2

-- Anger threshold per model, mirrored from AnnoyLevel in creatrs/*.cfg for the
-- same reason as GoldHold. Only three values exist in the whole game: 4000 for
-- almost everything, 8000 for BIRD and FLY, and 0 for IMP and FLOATING_SPIRIT,
-- which can never get angry at all 
CASINO_ANNOY_LEVEL_DEFAULT = 4000
CASINO_ANNOY_LEVEL = {
    BIRD = 8000, FLY = 8000,
    IMP = 0, FLOATING_SPIRIT = 0,
}

-- How eagerly a LIKE creature abandons its work for the casino.
--   3  last resort: only creatures that found no job at all (default)
--   2  also pulls creatures off the jobs listed in CASINO_OUTRANKS
--   1  pulls creatures off any job that is interruptible at all
CASINO_PRIORITY   = 3
CASINO_IDLE_TURNS = 60    -- ~3s of continuous idling before the casino tempts them

-- Only creatures that already own a lair gamble at all - both those walking in
-- by themselves and those thrown in by hand. A creature without a bed has more
-- urgent business: newcomers from the portal and anyone freshly dropped into the
-- dungeon head for the lair room first, but while they look for it they sit in
-- exactly the idle states that CASINO_PRIORITY reads as "nothing better to do".
-- This is the proper fix for that; CASINO_START_DELAY only ever papered over it
-- for the creatures already present at map start.
-- models with LairSize 0 in creatrs/*.cfg never get a lair, so they never gamble
CASINO_REQUIRE_LAIR = true

-- Idle states. A creature sitting in one of these has already been run through
-- the engine's whole job chain (assigned -> primary -> secondary) without a hit.
CASINO_IDLE_STATES = {
    CreatureDoingNothing   = true,
    CreatureCannotFindWork = true,
    CreatureDormant        = true,
}

-- Only consulted at CASINO_PRIORITY = 2. Lua cannot read a model's PRIMARYJOBS
-- or SECONDARYJOBS, so which jobs the casino outranks has to be declared here.
CASINO_OUTRANKS = {
    Guarding   = true, AtGuardPostRoom = true,
    Barracking = true, AtBarrackRoom   = true,
    Patrolling = true, PatrolHere      = true,
}


-- =====================================================================
--  STATE  (Game.* survives save/load)
-- =====================================================================
Game.CASINO_MODE     = Game.CASINO_MODE     or {}  -- room_idx -> "HAPPY"|"PROFIT"
Game.CASINO_SEAT     = Game.CASINO_SEAT     or {}  -- idx -> { room_idx, next_round, moving, bought_in }
Game.CASINO_GOING    = Game.CASINO_GOING    or {}  -- idx -> { room_idx, stl_x, stl_y, reserved_at }
Game.CASINO_COOLDOWN = Game.CASINO_COOLDOWN or {}  -- idx -> turn when play is allowed again
Game.CASINO_HELD     = Game.CASINO_HELD     or {}  -- idx -> true while carried in the hand
Game.CASINO_IDLE_SINCE = Game.CASINO_IDLE_SINCE or {}  -- idx -> turn the creature went idle
Game.CASINO_LEVERS   = Game.CASINO_LEVERS   or {}  -- thing idx -> true, every lever we spawned
Game.CASINO_TICKS    = Game.CASINO_TICKS    or 0   -- tick counter, drives the throttles
Game.CASINO_SHUT     = Game.CASINO_SHUT     or {}  -- playerId -> turn the house reopens


function CasinoLog(msg)
    if CASINO_DEBUG then print("[Casino] " .. msg) end
end


-- =====================================================================
--  ANIMATION HOOK
-- =====================================================================
-- Every creature emote in this script goes through here, and nowhere else.
--
-- HAPPY and SAD put the creature into CreatureBeHappy / CreatureMoan, the states
-- the engine itself uses after payday or a refused job. They start the pose and
-- play the mood sound on their own. DANCE is the jackpot version: the same
-- cheer, longer, plus an effect. countdown has to be written too: changing
-- state does not reset it, so the mood would otherwise last for whatever the
-- previous state left in that field.
--
-- A mood state is not CasinoGambling, and when its countdown runs out the engine
-- sends the creature to its idle state rather than back to the table. So for a
-- seated creature the seat is marked with emote_until, the countdown gets a
-- little slack, and CasinoWatchdog puts the creature back to gambling once
-- emote_until comes up.
--
-- A creature without a seat (just sent away, or a bystander on a jackpot) simply
-- gets the mood and is left to the engine afterwards.
function CasinoEmote(cr, kind)
    local state = "CreatureBeHappy"
    local ticks = CASINO_EMOTE_TICKS
    if kind == "SAD" then
        state = "CreatureMoan"
    elseif kind == "DANCE" then
        ticks = CASINO_DANCE_TICKS
        CasinoSpangle(cr, "EFFECT_SPANGLE_MULTICOLOURED")
    end

    local idx  = cr.ThingIndex
    local seat = Game.CASINO_SEAT[idx]
    if seat then
        seat.emote_until = PLAYER0.GAME_TURN + ticks
        -- The watchdog only looks once per CASINO_TICK, so the state has to
        -- outlive emote_until by at least that much.
        ticks = ticks + CASINO_TICK + 5
    elseif Game.CASINO_GOING[idx] or not CasinoCanInterrupt(cr) then
        -- On its way to a table, or busy with something that must not be cut
        -- short (asleep, fighting, in the hand): leave it alone.
        return
    end
    cr.state = state
    cr.countdown = ticks
end

function CasinoSpangle(cr, effect)
    CreateEffectAtPos(effect, cr.pos.stl_x, cr.pos.stl_y, 256)
end

-- Floating number at a plain position, for events that belong to the room
-- rather than to one creature.
function CasinoShowGoldAt(stl_x, stl_y, amount)
    if amount > 0 then
        CreateEffectAtPos("EFFECTELEMENT_PRICE", stl_x, stl_y, amount)
    end
end

-- Win/loss feedback. The floating number cannot carry a sign: draw_engine_number()
-- derives its digits from the integer and stops at the leading non-zero (so no
-- leading 0 is possible), sprites 71-80 are exactly dig0-dig9 with no minus, and
-- a negative value renders nothing at all. The colour is what tells them apart.
function CasinoShowResult(cr, amount, won)
    if amount > 0 then
        -- This effect element reuses the height argument as the number to show.
        CreateEffectAtPos("EFFECTELEMENT_PRICE", cr.pos.stl_x, cr.pos.stl_y, amount)
    end
    if won then
        CasinoSpangle(cr, "EFFECT_COIN_DROP_MINI")
    else
        CasinoSpangle(cr, "EFFECT_SPANGLE_RED")
    end
end


-- =====================================================================
--  HELPERS
-- =====================================================================

-- States we refuse to interrupt for a game of chance.
local CASINO_NO_INTERRUPT = {
    CreatureSleep = true, CreatureEat = true, CreatureBeingDropped = true,
    CreatureCastingPreparation = true, CreatureUnconscious = true,
    InPowerHand = true, Torturing = true,
    CreatureInPrison = true, CreatureArrivedAtPrison = true,
    CreatureInCombat = false, CreatureCombatFlee = true,
    CreatureDoorCombat = false, CreatureObjectCombat = true,
}

function CasinoCanInterrupt(cr)
    if (cr.opponents_count or 0) > 0 then return false end
    -- The real activity hides under MoveToPosition, so check both.
    if CASINO_NO_INTERRUPT[cr.state or ""] then return false end
    if CASINO_NO_INTERRUPT[cr.state_besides_interruptions or ""] then return false end
    return true
end

function CasinoAttitude(cr)
    return CASINO_ATTITUDE[cr.model] or "NEUTRAL"
end

-- Anger sits at its ceiling and gambling will not make it any better. Each of the
-- four reasons is capped separately by the engine, and it is the single highest
-- one that decides the mood, not their sum - so that is what gets compared.
-- Models with AnnoyLevel 0 can never be angry, so they are never furious either.
function CasinoIsFurious(cr)
    local lvl = CASINO_ANNOY_LEVEL[cr.model]
    if lvl == nil then lvl = CASINO_ANNOY_LEVEL_DEFAULT end
    if lvl <= 0 then return false end

    local limit = CASINO_ANGER_LIMIT * lvl
    for _, reason in ipairs({"NOT_PAID", "HUNGRY", "NO_LAIR", "OTHER"}) do
        if (cr:get_annoyance(reason) or 0) >= limit then return true end
    end
    return false
end

-- Settled in enough to think about gambling. cr.lair is the lair totem and comes
-- back nil while the creature has none.
function CasinoHasSettledIn(cr)
    if not CASINO_REQUIRE_LAIR then return true end
    return cr.lair ~= nil
end

function CasinoGoldCap(cr)
    local cap = CASINO_GOLD_HOLD[cr.model]
    if cap == nil then cap = CASINO_GOLD_HOLD_DEFAULT end
    return cap
end

-- What the creature may still take home. The engine never trims gold_carried
-- itself, so the limit has to be enforced here.
function CasinoGoldRoom(cr)
    local left = CasinoGoldCap(cr) - cr.gold_held
    if left < 0 then left = 0 end
    return left
end

function CasinoIsPlayable(cr)
    if not cr or not cr:isValid() then return false end
    if cr.model == "IMP" then return false end
    local t = cr.owner.type
    return t == "Human" or t == "Computer"
end

function CasinoRooms()
    ---@diagnostic disable-next-line: param-type-mismatch
    return GetRoomsOfType("CASINO") or {}
end

-- Only a real keeper runs a casino. Roaming (heroes), Neutral and Inactive owners
-- get no levers, no visitors and no rounds - their rooms are just scenery.
function CasinoRoomIsRun(room)
    local t = room.owner.type
    return t == "Human" or t == "Computer"
end

function CasinoRoomAt(stl_x, stl_y)
    local slab = GetSlab(math.floor(stl_x / 3), math.floor(stl_y / 3))
    if not slab or not slab.room then return nil end
    if slab.room.type ~= "CASINO" then return nil end
    return slab.room
end

-- Slabs divided by two, the same rule the engine uses for its worker rooms.
function CasinoCapacity(room)
    local n = math.floor(#room.slabs / 2)
    if n < 1 then n = 1 end
    return n
end

function CasinoOccupancy(room_idx)
    local n = 0
    for _, seat in pairs(Game.CASINO_SEAT) do
        if seat.room_idx == room_idx then n = n + 1 end
    end
    for _, info in pairs(Game.CASINO_GOING) do
        if info.room_idx == room_idx then n = n + 1 end
    end
    return n
end

function CasinoHasFreeSeat(room)
    return CasinoOccupancy(room.room_idx) < CasinoCapacity(room)
end

-- Capacity functions named in terrain.cfg (TotalCapacity / UsedCapacity of the
-- CASINO room). The engine calls them with the room and expects them to write
-- the result into it. They only mirror the script's own numbers, so the room
-- shows real figures to the engine; who gets a seat is still decided from the
-- seat tables, which are exact at any moment.
--
-- Like the state callbacks these are looked up by name while the cfg is parsed,
-- so they have to be globals at the top level of this file.
function Casino_Total_Capacity(room)
    room.max_capacity = CasinoCapacity(room)
end

-- The engine only asks for this when the room itself changes, not when a
-- creature sits down or leaves, so CasinoTick calls it as well.
function Casino_Used_Capacity(room)
    room.used_capacity = CasinoOccupancy(room.room_idx)
end

function CasinoMode(room_idx)
    return Game.CASINO_MODE[room_idx] or CASINO_DEFAULT_MODE
end

-- The house can only pay out what the keeper actually owns. player.MONEY reads
-- total_money_owned; note that add_gold(-x) silently pays out only part of the
-- sum, or nothing at all, when the treasury is short - and it reports none of
-- that back to Lua (lua_Add_gold_to_player discards the return value). So every
-- payout has to be clamped here, or the casino would hand creatures gold nobody
-- ever paid for.
function CasinoPurse(owner)
    local m = owner.MONEY
    if not m or m < 0 then m = 0 end
    return m
end

function CasinoHouseIsBroke(owner)
    return CasinoPurse(owner) <= 0
end

function CasinoCloseHouse(owner)
    Game.CASINO_SHUT[owner.playerId] = PLAYER0.GAME_TURN + CASINO_BANKRUPT_PAUSE
    CasinoLog("house of player " .. owner.playerId .. " is broke, shut for "
        .. CASINO_BANKRUPT_PAUSE .. " turns")
end

function CasinoHouseIsOpen(owner)
    local reopen = Game.CASINO_SHUT[owner.playerId]
    return (not reopen) or PLAYER0.GAME_TURN >= reopen
end

-- Random walkable subtile inside the room, used as a walk target and for loot.
function CasinoRandomSpot(room)
    local slab = room.slabs[math.random(#room.slabs)]
    return slab.slb_x * 3 + math.random(0, 2), slab.slb_y * 3 + math.random(0, 2)
end

function CasinoRelease(idx)
    Game.CASINO_SEAT[idx]  = nil
    Game.CASINO_GOING[idx] = nil
end

function CasinoSendAway(cr, annoyance)
    local idx = cr.ThingIndex
    CasinoRelease(idx)
    Game.CASINO_COOLDOWN[idx] = PLAYER0.GAME_TURN + CASINO_LEAVE_COOLDOWN
    if annoyance and annoyance > 0 then
        cr:set_annoyance("OTHER", (cr:get_annoyance("OTHER") or 0) + annoyance)
    end
    cr.state = "CreatureDoingNothing"
end

-- Only plain values go into the seat: Game.* is serialised into the savegame,
-- and the owner is re-derived from the room each round anyway.
function CasinoSeat(cr, room)
    local seat = {
        room_idx   = room.room_idx,
        next_round = PLAYER0.GAME_TURN + CASINO_ROUND_TICKS,
    }
    Game.CASINO_GOING[cr.ThingIndex] = nil
    Game.CASINO_IDLE_SINCE[cr.ThingIndex] = nil
    Game.CASINO_SEAT[cr.ThingIndex] = seat
    cr.state = "CasinoGambling"
    -- Face a random way as they settle in, so a full table does not end up as a
    -- row of clones all staring the same direction. Full circle is 2048.
    cr.orientation = math.random(0, 2047)

    return seat
end

-- Handed out once per visit, the moment the creature has reached its spot and
-- its first round timer starts. Only a creature that turns up penniless gets it:
-- gambling never tops anyone up again, run dry at the table and you are out. The
-- leave cooldown gates how often a creature can come back for another.
-- Shown as a bare number, because it is neither a win nor a loss.
function CasinoBuyIn(cr, room)
    -- Nothing to stake when losing costs nothing, so the house keeps its money.
    if CASINO_NO_CREATURE_LOSS then return end
    if cr.gold_held > 0 then return end
    local seed = math.min(CASINO_SEED_GOLD, CasinoGoldRoom(cr), CasinoPurse(room.owner))
    if seed <= 0 then return end
    cr.gold_held = cr.gold_held + seed
    room.owner:add_gold(-seed)
    CasinoShowGoldAt(cr.pos.stl_x, cr.pos.stl_y, seed)
end


-- =====================================================================
--  STATE CALLBACKS  (wired in map.crstates.cfg)
-- =====================================================================

-- CasinoWalking: on the way into a casino. Takes a seat on arrival.
function Casino_Walk_Process(cr)
    local idx  = cr.ThingIndex
    local info = Game.CASINO_GOING[idx]
    if not info then
        cr.state = "CreatureDoingNothing"
        return 0
    end
    -- Any casino will do, not just the one this walk was booked for: the target
    -- may have been merged into another room while the creature was on its way.
    local room = CasinoRoomAt(cr.pos.stl_x, cr.pos.stl_y)
    if room and CasinoRoomIsRun(room) then
        -- Clear GOING before the state change: the engine skips CleanupFunction
        -- for a self-change made from inside a ProcessFunction.
        Game.CASINO_GOING[idx] = nil
        CasinoSeat(cr, room)
        CasinoLog("seated " .. cr.model .. " #" .. idx .. " in room " .. room.room_idx)
    end
    return 0
end

-- Only fires on an external abort (slap, combat, pickup).
function Casino_Walk_Cleanup(cr)
    local idx = cr.ThingIndex
    if not Game.CASINO_GOING[idx] then return end
    Game.CASINO_GOING[idx] = nil
    Game.CASINO_COOLDOWN[idx] = PLAYER0.GAME_TURN + CASINO_LEAVE_COOLDOWN
end

-- CasinoGambling: seated at a table. Settles the creature after each move, hands
-- out the buy-in on the first one, and plays a round whenever the timer comes up.
function Casino_Play_Process(cr)
    local idx  = cr.ThingIndex
    local seat = Game.CASINO_SEAT[idx]
    if not seat then
        cr.state = "CreatureDoingNothing"
        return 0
    end
    if seat.moving then
        -- Arrived at the new spot. Movement is over, so a facing set now sticks,
        -- and the countdown to the next round only starts once settled - walking
        -- must not eat into it.
        seat.moving = nil
        cr.orientation = math.random(0, 2047)
        seat.next_round = PLAYER0.GAME_TURN + CASINO_ROUND_TICKS
    end

    -- Buy-in happens the moment the creature is settled and its first timer
    -- starts, not when that round is later paid out.
    if not seat.bought_in then
        seat.bought_in = true
        local room = CasinoRoomAt(cr.pos.stl_x, cr.pos.stl_y)
        if room then
            CasinoBuyIn(cr, room)
        end
    end

    if PLAYER0.GAME_TURN >= seat.next_round then
        CasinoRound(cr, seat)
    end
    return 0
end

function Casino_Play_Cleanup(cr)
    local idx = cr.ThingIndex
    local seat = Game.CASINO_SEAT[idx]
    if not seat then return end
    -- A walk we started ourselves is a table change, not the creature leaving.
    if seat.moving then return end
    Game.CASINO_SEAT[idx] = nil
    Game.CASINO_COOLDOWN[idx] = PLAYER0.GAME_TURN + CASINO_LEAVE_COOLDOWN
end


-- =====================================================================
--  ONE ROUND OF GAMBLING
-- =====================================================================
function CasinoRound(cr, seat)
    -- Already as angry as the engine allows. No round is going to improve that,
    -- so the creature storms off. No extra annoyance either - there is no room
    -- left for it, the value is at its ceiling.
    if CasinoIsFurious(cr) then
        CasinoSpangle(cr, "EFFECT_SPANGLE_RED")
        CasinoSendAway(cr, 0)
        CasinoEmote(cr, "SAD")
        return
    end

    -- Out of money: no new round is started at all. This is the moment a creature
    -- gives up and walks out - the buy-in only ever covers turning up broke.
    -- Skipped entirely under CASINO_NO_CREATURE_LOSS: nobody stakes anything
    -- there, so an empty purse is no reason to stop playing - and since that mode
    -- also hands out no buy-in, this check would otherwise throw every penniless
    -- creature straight back out on its first round.
    if cr.gold_held <= 0 and not CASINO_NO_CREATURE_LOSS then
        CasinoSpangle(cr, "EFFECT_SPANGLE_RED")
        CasinoSendAway(cr, CASINO_BROKE_ANNOY)
        CasinoEmote(cr, "SAD")
        return
    end

    seat.next_round = PLAYER0.GAME_TURN + CASINO_ROUND_TICKS

    local room = CasinoRoomAt(cr.pos.stl_x, cr.pos.stl_y)
    if not room or not CasinoRoomIsRun(room) then
        -- Wandered off the room somehow, or the room changed hands and is no
        -- longer run by a keeper. The watchdog would catch it, but this is the
        -- cheaper path.
        CasinoSendAway(cr, 0)
        return
    end
    -- Follow the room the creature is actually standing in. Merging two casinos
    -- frees one of the two room structures, so a seat pinned to the old index
    -- would evict everyone who happened to sit in the absorbed half.
    seat.room_idx = room.room_idx

    -- Nothing left to win: the house cannot cover a payout, so the table closes.
    -- Everyone drifts out over the next few rounds and CasinoRankRooms stops
    -- sending anyone new until the keeper has money again.
    if CasinoHouseIsBroke(room.owner) then
        CasinoCloseHouse(room.owner)
        CasinoSpangle(cr, "EFFECT_SPANGLE_RED")
        CasinoSendAway(cr, CASINO_BROKE_ANNOY)
        CasinoEmote(cr, "SAD")
        return
    end

    -- Not while cheering or moaning: walking would replace the mood state on the
    -- spot. CasinoWatchdog sends the creature on once the mood is over.
    if CasinoResolveBet(cr, seat, room) and not seat.emote_until then
        CasinoNextSpot(cr, room, seat)
    end
end

-- Drift to another spot between rounds and take a fresh facing once there, so a
-- busy casino looks like a gambling hall rather than a row of statues. The turn
-- has to wait until the walk is done, otherwise the movement overwrites the angle
-- again - Casino_Play_Process does it on arrival.
function CasinoNextSpot(cr, room, seat)
    local x, y = CasinoRandomSpot(room)
    -- Set before walk_to: should the state change fire Casino_Play_Cleanup, this
    -- is what tells it the creature is relocating, not leaving the table.
    seat.moving = true
    if cr:walk_to(x, y) then
        cr.continue_state = "CasinoGambling"
    else
        seat.moving = nil
        cr.orientation = math.random(0, 2047)
    end
end

-- Plays out one bet. Returns whether the creature stays at the table.
function CasinoResolveBet(cr, seat, room)
    -- Rolled as a float so fractions of a percent work. math.random(100) returns
    -- whole numbers from 1 up, so anything below 1 would simply never hit.
    if math.random() * 100 < CASINO_JACKPOT_CHANCE then
        CasinoJackpot(room)
        return true
    end

    local mode   = CasinoMode(seat.room_idx)
    local chance = CASINO_WIN_CHANCE_PROFIT
    if mode == "HAPPY" then chance = CASINO_WIN_CHANCE_HAPPY end

    local stake = math.random(CASINO_STAKE_MIN, CASINO_STAKE_MAX)
    local owner = room.owner

    if math.random(100) <= chance then
        -- Winnings are capped at the model's GoldHold. A creature that is
        -- already full keeps playing and still enjoys the win, it just cannot
        -- pocket anything more, so no gold changes hands.
        -- Also capped by what the keeper owns, otherwise an empty treasury would
        -- still credit the creature and the casino would mint gold.
        local gain = math.min(stake, CasinoGoldRoom(cr), CasinoPurse(owner))
        if gain > 0 then
            cr.gold_held = cr.gold_held + gain
            owner:add_gold(-gain)
        end
        CasinoShowResult(cr, gain, true)
        cr:set_annoyance("OTHER", math.max(0, (cr:get_annoyance("OTHER") or 0) - CASINO_MOOD_STEP))
        if math.random(100) <= CASINO_EMOTE_CHANCE then CasinoEmote(cr, "HAPPY") end
        return true
    end

    -- The keeper is paid either way. Only who funds it differs: normally the
    -- creature's purse, which is why the stake is capped at what it actually
    -- carries - and CasinoRound has already made sure there is something in it,
    -- since it refuses to start a round for a broke creature. Under
    -- CASINO_NO_CREATURE_LOSS the full stake is conjured instead and the purse is
    -- never touched, which is why an empty one does no harm there.
    local loss = stake
    if not CASINO_NO_CREATURE_LOSS then
        loss = math.min(stake, cr.gold_held)
        cr.gold_held = cr.gold_held - loss
    end
    owner:add_gold(loss)
    cr:set_annoyance("OTHER", (cr:get_annoyance("OTHER") or 0) + CASINO_MOOD_STEP)
    CasinoShowResult(cr, loss, false)
    if math.random(100) <= CASINO_EMOTE_CHANCE then CasinoEmote(cr, "SAD") end
    return true
end

-- Rebuilds the shower of coins the engine plays when you drop gold out of the
-- hand (drop_gold_coins in power_hand.c): a scatter of SPINNCOIN objects tumbling
-- down from above. They clean themselves up - SPINNCOIN starts in the
-- ObSt_BeingDropped state, and object_being_dropped() destroys any coin that
-- lands carrying no gold. Which is all of these, because the property argument
-- of AddObjectToLevelAtPos only fills in gold for GOLD, GOLDL, GOLD_BAG and
-- GOLD_CHEST, and gold_stored is not reachable from Lua at all. So the coins are
-- pure decoration and the real value rides on the pile underneath.
function CasinoDropCoins(stl_x, stl_y, owner)
    for _ = 1, CASINO_JACKPOT_COINS do
        local ob = AddObjectToLevelAtPos("SPINNCOIN", stl_x, stl_y, 0, owner)
        if ob then
            local p = ob.pos
            -- Scatter within half a subtile, like the engine's radius of 127.
            p.val_x = p.val_x + math.random(-127, 127)
            p.val_y = p.val_y + math.random(-127, 127)
            p.val_z = p.val_z + CASINO_JACKPOT_DROP + math.random(0, 128)
            ob.pos = p
        end
    end
end
function CasinoJackpot(room)
    local cx, cy = room.centerpos.stl_x, room.centerpos.stl_y
    for _ = 1, CASINO_JACKPOT_PILES do
        local x, y = CasinoRandomSpot(room)
        AddObjectToLevelAtPos("GOLD", x, y, CASINO_JACKPOT_GOLD, room.owner)
        CasinoDropCoins(x, y, room.owner)
    end

    CreateEffectAtPos("EFFECT_COIN_FOUNTAIN", cx, cy, 0)
    CasinoShowGoldAt(cx, cy, CASINO_JACKPOT_PILES * CASINO_JACKPOT_GOLD)

    local jackpotSounds = {
        "casin001.mp3",
        "casin002.mp3",
        "casin003.mp3",
        "casin004.mp3",
        "casin005.mp3",
        "casin006.mp3",
        "casin007.mp3"
    }

    local randomSound = jackpotSounds[math.random(#jackpotSounds)]
    PlayMessage(room.owner, "SOUND", randomSound)

    -- Information box rather than a chat line: only the owner gets it, and it
    -- zooms to the casino when clicked. DisplayInformation itself is no use here
    -- because it only takes a message id from gtext_***.dat - the Quick* variants
    -- are the free-text ones.

    -- "Jackpot Winner!"
    if room.owner == PLAYER0 then
    RunDKScriptCommand("DISPLAY_INFORMATION(832,CASINO,CASINO_DROP_DOWN)")
    --SetMusic("Jackpot.mp3")
    end
    for _, cr in ipairs(CasinoCreaturesInRoom(room)) do
        cr:set_annoyance("OTHER", math.max(0, (cr:get_annoyance("OTHER") or 0) - CASINO_JACKPOT_MOOD))
        CasinoEmote(cr, "DANCE")
    end

    CasinoLog("JACKPOT in room " .. room.room_idx)
end

-- =====================================================================
--  MODE BOXES
-- =====================================================================
-- The two boxes behave as a single lever in the middle of the room: only the box
-- that switches to the OTHER mode is ever visible, so what you see is what
-- clicking it will do. The engine destroys a special box on click, so the lever
-- is simply re-placed on the next tick.
function CasinoIsLever(ob)
    local m = ob.model
    return m == CASINO_LEVER_MODEL[CASINO_BOX_HAPPY]
        or m == CASINO_LEVER_MODEL[CASINO_BOX_PROFIT]
end

function CasinoBoxesInRoom(room)
    local out = {}
    for _, slab in ipairs(room.slabs) do
        ---@diagnostic disable-next-line: param-type-mismatch
        local things = GetThingsOnSlab(slab.slb_x, slab.slb_y, "OBJECT")
        if things then
            for _, ob in ipairs(things) do
                if ob:isValid() and CasinoIsLever(ob) then
                    out[#out + 1] = ob
                end
            end
        end
    end
    return out
end

-- Fast path for the overwhelmingly common case: the right lever is already
-- sitting in the middle and nothing needs doing. That costs one GetThingsOnSlab
-- instead of one per slab of the room, which for a large casino is the
-- difference between one call a second and twenty.
function CasinoLeverIsInPlace(room, want)
    local center = room.centerpos
    ---@diagnostic disable-next-line: param-type-mismatch
    local things = GetThingsOnSlab(center.slb_x, center.slb_y, "OBJECT")
    if not things then return false end
    for _, ob in ipairs(things) do
        if ob:isValid() and ob.model == CASINO_LEVER_MODEL[want]
           and ob.pos.stl_x == center.stl_x and ob.pos.stl_y == center.stl_y then
            Game.CASINO_LEVERS[ob.ThingIndex] = true
            return true
        end
    end
    return false
end

-- `deep` skips the fast path and re-scans the whole room, which is what clears
-- duplicates sitting away from the centre. Only worth doing occasionally.
function CasinoEnsureLever(room, deep)
    local want = CASINO_BOX_HAPPY
    if CasinoMode(room.room_idx) == "HAPPY" then want = CASINO_BOX_PROFIT end

    if (not deep) and CasinoLeverIsInPlace(room, want) then return end

    -- Keep the first correct lever, remove everything else, so a mode switch or
    -- a stray duplicate always collapses back to exactly one lever.
    local keep = nil
    for _, ob in ipairs(CasinoBoxesInRoom(room)) do
        if (not keep) and ob.model == CASINO_LEVER_MODEL[want] then
            keep = ob
        else
            ob:delete()
        end
    end

    local center = room.centerpos
    if not keep then
        local ob = AddObjectToLevelAtPos(CASINO_LEVER_MODEL[want],
            center.stl_x, center.stl_y, want, room.owner)
        if ob then
            Game.CASINO_LEVERS[ob.ThingIndex] = true
        end
        return
    end

    -- Drag it back to the middle whenever it is off. Mostly this happens because
    -- the room grew or shrank and moved its own centre, not because the lever
    -- went anywhere. Assign the whole position table: thing.pos hands out a fresh
    -- table on every read, so writing keep.pos.stl_x would be thrown away.
    if keep.pos.stl_x ~= center.stl_x or keep.pos.stl_y ~= center.stl_y then
        keep.pos = center
    end
end

function CasinoEnsureBoxes(deep)
    for _, room in ipairs(CasinoRooms()) do
        if CasinoRoomIsRun(room) then
            CasinoEnsureLever(room, deep)
        end
    end
end

-- Sell the room and its lever would otherwise be left sitting on bare ground,
-- still clickable. No object property covers this: EXISTS_ONLY_IN_ROOM is in the
-- config but nothing in the engine ever reads it, and the DESTROYED_ON_ROOM_*
-- flags fire on claiming and on placing a room, not on one going away.
--
-- Only levers this script spawned are checked here, which is a handful of index
-- lookups. Walking GetThingsOfClass("OBJECT") instead builds a fresh Lua table
-- for every object on the whole map and was by far the heaviest thing in the
-- tick - that variant survives as CasinoDeepSweep below, which is also what
-- catches levers this table never knew about.
function CasinoRemoveStrayLevers()
    for idx in pairs(Game.CASINO_LEVERS) do
        local ob = GetThingByIdx(idx)
        if (not ob) or (not ob:isValid()) or (not CasinoIsLever(ob)) then
            -- Gone, or the index got recycled for something else.
            Game.CASINO_LEVERS[idx] = nil
        elseif not CasinoRoomAt(ob.pos.stl_x, ob.pos.stl_y) then
            ob:delete()
            Game.CASINO_LEVERS[idx] = nil
        end
    end
end

-- Safety net for levers this script has no index for: placed by the map editor,
-- or lost if the tracking table ever went out of sync. Deliberately rare.
function CasinoDeepSweep()
    ---@diagnostic disable-next-line: param-type-mismatch
    local objects = GetThingsOfClass("OBJECT")
    if not objects then return end
    for _, ob in ipairs(objects) do
        if ob:isValid() and CasinoIsLever(ob) then
            if CasinoRoomAt(ob.pos.stl_x, ob.pos.stl_y) then
                Game.CASINO_LEVERS[ob.ThingIndex] = true
            else
                ob:delete()
            end
        end
    end
end

-- Room indices get recycled: merging two casinos frees one of the two room
-- structures, and a later room of any kind can be handed that index back. A mode
-- left behind would then silently attach itself to an unrelated casino, so
-- anything that is not a live casino right now is dropped.
function CasinoPruneModes()
    if next(Game.CASINO_MODE) == nil then return end
    local live = {}
    for _, room in ipairs(CasinoRooms()) do
        live[room.room_idx] = true
    end
    for room_idx in pairs(Game.CASINO_MODE) do
        if not live[room_idx] then
            Game.CASINO_MODE[room_idx] = nil
        end
    end
end

-- OnSpecialActivated fires before the crate is destroyed, so its position is
-- still valid here and tells us which room to switch.
function CasinoSetMode(eventData, mode)
    local crate = eventData.Thing
    if not crate or not crate:isValid() then return end
    local room = CasinoRoomAt(crate.pos.stl_x, crate.pos.stl_y)
    if not room then return end
    Game.CASINO_MODE[room.room_idx] = mode
    CasinoLog("room " .. room.room_idx .. " -> mode " .. mode)
end

function CasinoBoxHappy(eventData)  CasinoSetMode(eventData, "HAPPY")  end
function CasinoBoxProfit(eventData) CasinoSetMode(eventData, "PROFIT") end


-- =====================================================================
--  MAIN TICK
-- =====================================================================
function CasinoCreaturesInRoom(room)
    local out = {}
    for _, slab in ipairs(room.slabs) do
        ---@diagnostic disable-next-line: param-type-mismatch
        local things = GetThingsOnSlab(slab.slb_x, slab.slb_y, "CREATURE")
        if things then
            for _, cr in ipairs(things) do
                if CasinoIsPlayable(cr) and not cr.picked_up then
                    out[#out + 1] = cr
                end
            end
        end
    end
    return out
end

-- Release reservations whose creature is gone, was taken out of the room, or
-- never finished walking. Without this a silent engine state change would hold
-- a seat forever and the room would lock up.
function CasinoWatchdog()
    local turn = PLAYER0.GAME_TURN

    for idx, seat in pairs(Game.CASINO_SEAT) do
        local cr = GetThingByIdx(idx)
        ---@cast cr Creature
        if (not cr) or (not cr:isValid()) then
            Game.CASINO_SEAT[idx] = nil
        else
            local room = CasinoRoomAt(cr.pos.stl_x, cr.pos.stl_y)
            -- A seat is only kept while the creature is actually at the table or
            -- walking to another spot in it. Anything else (slapped mid-move, a
            -- silent engine state change) would otherwise hold the seat forever,
            -- because seat.moving suppresses the cleanup path.
            local s = cr.state
            local busy_here = (s == "CasinoGambling") or (s == "MoveToPosition")
            if seat.emote_until then
                -- Cheering or moaning over the last round, see CasinoEmote.
                busy_here = (s == "CreatureBeHappy") or (s == "CreatureMoan")
            end
            if cr.picked_up or (not room) or (not busy_here) then
                Game.CASINO_SEAT[idx] = nil
                Game.CASINO_COOLDOWN[idx] = turn + CASINO_LEAVE_COOLDOWN
            else
                -- Any casino counts, and the seat re-homes itself. Rooms merge by
                -- freeing one of the two structures, so the index a seat was
                -- opened with can simply stop existing.
                seat.room_idx = room.room_idx
                if seat.emote_until and turn >= seat.emote_until then
                    -- Mood is over: back to the table and on to the next spot,
                    -- the way a round without an emote would have gone.
                    seat.emote_until = nil
                    cr.state = "CasinoGambling"
                    CasinoNextSpot(cr, room, seat)
                end
            end
        end
    end

    for idx, info in pairs(Game.CASINO_GOING) do
        local cr = GetThingByIdx(idx)
        ---@cast cr Creature
        local invalid = (not cr) or (not cr:isValid())
        if invalid or (turn - (info.reserved_at or 0)) > CASINO_RESERVE_TIMEOUT then
            Game.CASINO_GOING[idx] = nil
            if not invalid then
                Game.CASINO_COOLDOWN[idx] = turn + CASINO_LEAVE_COOLDOWN
            end
        end
    end
end

-- The engine has no drop event, so a creature is flagged while it sits in the
-- hand and the landing is resolved here on the next tick. Reacting to mere
-- presence instead would also punish creatures that just walk through the room.
function CasinoOnPickUp(eventData)
    local cr = eventData.thing   -- Builtins.lua spells this lowercase
    if not cr or not cr:isValid() then return end
    if not CasinoIsPlayable(cr) then return end
    Game.CASINO_HELD[cr.ThingIndex] = true
end

function CasinoResolveDrops()
    for idx in pairs(Game.CASINO_HELD) do
        local cr = GetThingByIdx(idx)
        ---@cast cr Creature
        if (not cr) or (not cr:isValid()) then
            Game.CASINO_HELD[idx] = nil
        elseif not cr.picked_up then
            Game.CASINO_HELD[idx] = nil
            local room = CasinoRoomAt(cr.pos.stl_x, cr.pos.stl_y)
            if room and CasinoRoomIsRun(room) then
                if CasinoAttitude(cr) == "HATE" then
                    CasinoSpangle(cr, "EFFECT_SPANGLE_RED")
                    CasinoSendAway(cr, CASINO_HATE_ANNOY)
                    CasinoEmote(cr, "SAD")
                elseif CasinoHasSettledIn(cr) and not CasinoIsFurious(cr)
                       and CasinoHouseIsOpen(room.owner)
                       and not CasinoHouseIsBroke(room.owner)
                       and CasinoHasFreeSeat(room) then
                    -- A deliberate drop bypasses the leave cooldown, but nothing
                    -- else: no bed, too angry, or a house that cannot pay all mean
                    -- the creature is left alone and wanders back out. Checking it
                    -- here rather than at the first round saves it walking to a
                    -- table only to storm off again six seconds later.
                    Game.CASINO_COOLDOWN[idx] = nil
                    -- Walk off to pick a spot first instead of gambling on the
                    -- tile they happened to land on. Creatures that come by
                    -- themselves already arrive at a chosen spot.
                    CasinoNextSpot(cr, room, CasinoSeat(cr, room))
                end
            end
        end
    end
end

-- Emulated job-preference rank. The engine's own chain (assigned job -> primary
-- job -> random{lazy sleep, healing sleep, secondary job}, creature_states.c:1891-1930)
-- is hardcoded C and cannot be extended, and Lua sees no job fields at all - not
-- job_assigned, not PRIMARYJOBS, not SECONDARYJOBS. So rank is expressed as what
-- the casino is allowed to pull a creature away from.
--
-- At rank 3 this lands exactly where you want it: a creature only counts as
-- available once the engine has run it through its whole job chain and left it
-- idle, and the idle timer makes sure a brief gap between jobs is not mistaken
-- for unemployment.
function CasinoJobAllows(cr, turn)
    if CASINO_PRIORITY <= 1 then return true end

    local s = cr.state_besides_interruptions or cr.state
    if CASINO_PRIORITY == 2 and CASINO_OUTRANKS[s] then return true end

    local idx = cr.ThingIndex
    if not CASINO_IDLE_STATES[s] then
        Game.CASINO_IDLE_SINCE[idx] = nil
        return false
    end
    if not Game.CASINO_IDLE_SINCE[idx] then
        Game.CASINO_IDLE_SINCE[idx] = turn
        return false
    end
    return (turn - Game.CASINO_IDLE_SINCE[idx]) >= CASINO_IDLE_TURNS
end

-- One pass over the seat tables instead of one per candidate per room, which is
-- what CasinoHasFreeSeat would cost inside the recruiting loop.
function CasinoOccupancyMap()
    local used = {}
    for _, seat in pairs(Game.CASINO_SEAT) do
        used[seat.room_idx] = (used[seat.room_idx] or 0) + 1
    end
    for _, info in pairs(Game.CASINO_GOING) do
        used[info.room_idx] = (used[info.room_idx] or 0) + 1
    end
    return used
end

-- Casinos with a free seat that the creature could plausibly reach, nearest
-- first. Distance both ranks and filters: without a ranking the first room in the
-- engine's list took everyone, which sent creatures hiking past the one next
-- door, and without the cap they would set off across the whole map only for the
-- reservation watchdog to pull them back thirty seconds later.
function CasinoRankRooms(cr, rooms, used)
    local out = {}
    for _, room in ipairs(rooms) do
        -- A keeper who cannot pay attracts nobody: neither while the bankruptcy
        -- pause runs, nor if the treasury happens to be empty right now.
        if room.owner == cr.owner
           and CasinoHouseIsOpen(room.owner) and not CasinoHouseIsBroke(room.owner)
           and (used[room.room_idx] or 0) < CasinoCapacity(room)
        then
            local c = room.centerpos
            local dist = math.abs(cr.pos.stl_x - c.stl_x) + math.abs(cr.pos.stl_y - c.stl_y)
            if dist <= CASINO_MAX_DISTANCE then
                out[#out + 1] = { room = room, dist = dist }
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- Walks the candidates nearest first and returns the room it managed to send the
-- creature to. Several spots are tried per room because walk_to can fail on a
-- single blocked subtile, and the next room is tried when a whole room is
-- unreachable - a locked door on the nearest casino used to stall a creature
-- until the next recruiting pass, over and over.
function CasinoSendTo(cr, rooms, used)
    for _, cand in ipairs(CasinoRankRooms(cr, rooms, used)) do
        for _ = 1, CASINO_WALK_ATTEMPTS do
            local x, y = CasinoRandomSpot(cand.room)
            if cr:walk_to(x, y) then
                cr.continue_state = "CasinoWalking"
                Game.CASINO_GOING[cr.ThingIndex] = {
                    room_idx = cand.room.room_idx, stl_x = x, stl_y = y,
                    reserved_at = PLAYER0.GAME_TURN,
                }
                return cand.room
            end
        end
    end
    return nil
end

-- Creatures that like gambling head over on their own.
function CasinoRecruit()
    local turn = PLAYER0.GAME_TURN
    local rooms = CasinoRooms()
    if #rooms == 0 then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    local creatures = GetThingsOfClass("CREATURE")
    if not creatures then return end

    local used = CasinoOccupancyMap()

    for _, cr in ipairs(creatures) do
        ---@cast cr Creature
        local idx = cr.ThingIndex
        -- Cheap index lookups first: reading .model or .owner crosses into C and
        -- builds a string, so it must not happen for creatures we discard anyway.
        if not Game.CASINO_SEAT[idx] and not Game.CASINO_GOING[idx]
           and (not Game.CASINO_COOLDOWN[idx] or turn >= Game.CASINO_COOLDOWN[idx])
           and CasinoIsPlayable(cr) and CasinoAttitude(cr) == "LIKE"
           and CasinoHasSettledIn(cr) and not CasinoIsFurious(cr)
           and CasinoCanInterrupt(cr) and CasinoJobAllows(cr, turn)
        then
            local room = CasinoSendTo(cr, rooms, used)
            if room then
                -- Book the seat straight away so the next candidate in this same
                -- pass does not get sent to a room that is now full.
                used[room.room_idx] = (used[room.room_idx] or 0) + 1
            end
        end
    end
end

function CasinoTick()
    -- Stay shut for the opening moments of the level, so the casino does not
    -- grab creatures or place its lever while the map is still setting itself up.
    if PLAYER0.GAME_TURN < CASINO_START_DELAY then return end

    Game.CASINO_TICKS = Game.CASINO_TICKS + 1
    local deep = (Game.CASINO_TICKS % CASINO_DEEP_EVERY) == 0

    CasinoPruneModes()
    CasinoRemoveStrayLevers()
    if deep then CasinoDeepSweep() end
    CasinoEnsureBoxes(deep)

    -- These two must stay on every tick: the watchdog frees stuck seats and the
    -- drop handler has to react while the creature is still where you put it.
    CasinoWatchdog()
    CasinoResolveDrops()

    -- Seats change without the engine noticing, so report them once per tick.
    for _, room in ipairs(CasinoRooms()) do
        Casino_Used_Capacity(room)
    end

    -- Recruiting walks every creature on the map, so it runs less often. A few
    -- seconds of delay before an idle creature wanders off to gamble is unnoticeable.
    if (Game.CASINO_TICKS % CASINO_RECRUIT_EVERY) == 0 then
        CasinoRecruit()
    end
end


-- =====================================================================
--  DEBUG
-- =====================================================================
function CasinoChatStatus()
    local rooms = CasinoRooms()
    if #rooms == 0 then
        QuickMessage("No casino on the map")
        return
    end
    for _, room in ipairs(rooms) do
        QuickMessage("Casino #" .. room.room_idx
            .. " mode=" .. CasinoMode(room.room_idx)
            .. " " .. CasinoOccupancy(room.room_idx) .. "/" .. CasinoCapacity(room)
            .. " slabs=" .. #room.slabs
            .. " prio=" .. CASINO_PRIORITY
            .. (CASINO_NO_CREATURE_LOSS and " no-loss" or ""))
    end
end


-- =====================================================================
--  ENTRY POINT  (called from the level script, see map00013.lua)
-- =====================================================================
-- Deliberately NOT OnGameStart: the engine looks that global up by name, so only
-- one definition can exist per level. The level script owns it and calls this.
function CasinoInit()
    ---@diagnostic disable-next-line: param-type-mismatch
    -- The visible lever is always the mode you would switch TO.
    SetBoxTooltip(CASINO_BOX_HAPPY,  "Casino lever: switch to keeping creatures happy")
    SetBoxTooltip(CASINO_BOX_PROFIT, "Casino lever: switch to making money")

    RegisterTimerEvent("CasinoTick", CASINO_TICK, true)
    RegisterSpecialActivatedEvent("CasinoBoxHappy",  CASINO_BOX_HAPPY)
    RegisterSpecialActivatedEvent("CasinoBoxProfit", CASINO_BOX_PROFIT)
    -- Registered unfiltered on purpose: RegisterPickUpEvent's optional filters
    -- compare eventData.Thing, but Builtins.lua fills in eventData.thing.
    RegisterPickUpEvent("CasinoOnPickUp")

    local trig = CreateTrigger("ChatMsg", "CasinoChatStatus", {})
    TriggerAddCondition(trig, function(eventData)
        return eventData.Message == "_CASINO"
    end)

    CasinoLog("setup done, tick=" .. CASINO_TICK .. " round=" .. CASINO_ROUND_TICKS)
end



