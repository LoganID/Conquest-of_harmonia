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
--   Each game is played at one of the room's roulette tables: the creature walks
--   up to it and faces it, bets - which sets the wheel spinning - and hops about
--   while it turns. The result, and the cheering or moaning, comes when it stops.
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
--   * A creature dropped into the casino is seated only once it has landed and
--     the engine has decided what it does - see CasinoTakeDroppedCreature.
--     Reacting to mere presence in the room instead would also grab passers-by.
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
CASINO_ROUND_TICKS       = 40    -- ~2s at the table between two games; each game adds CASINO_SPIN_TICKS

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

-- Roulette tables. They are decoration the room's slab graphics put on its inner
-- slabs, and they only turn while somebody plays (AnimationSpeed 0 in objects.cfg).
CASINO_TABLE_MODEL       = "CASINO_ROULETTE_TABLE"
CASINO_SPIN_TICKS        = 80    -- ~4s the wheel spins for one game
CASINO_SPIN_SPEED        = 90    -- animation speed of a spinning wheel
CASINO_SWITCH_TABLE      = 30    -- % chance to move on to another table after a game
CASINO_HOP_CHANCE        = 6     -- % per turn that a creature waiting on the wheel hops
CASINO_HOP_GAP           = 16    -- turns at least between two hops, so it lands in between
CASINO_HOP_MIN           = 40    -- upward push of a hop - the engine's own range for
CASINO_HOP_MAX           = 120   --   creatures that wait to join a fight

-- Decoration the lever takes the place of on its slab.
CASINO_LEVER_REPLACES = { CASINO_BARREL = true, CASINO_ROULETTE_TABLE = true }

CASINO_SEATS_PER_TABLE   = 4     -- capacity of a casino: this many creatures per roulette table

-- The visible lever. The two special boxes that take the click are invisible
-- (MaximumSize 0 in objects.cfg); what the player sees is a pole decoration on
-- the same spot. Its knob sits on the smiley in HAPPY mode (frame 15 of the
-- lever art) and on the $ in PROFIT mode (frame 1). Flipping it plays one of the
-- two switch animations: SWITCH_PROFIT runs 1 -> 15 and so ends on HAPPY,
-- SWITCH_HAPPY runs 15 -> 1 and ends on PROFIT.
CASINO_POLE_IDLE = "CASINO_POLE_IDLE"
CASINO_POLE_LOOK = {
    HAPPY  = { sprite = "CASINO_LEVER_HAPPY",  switch = "CASINO_POLE_MOVE_PROFIT" },
    PROFIT = { sprite = "CASINO_LEVER_PROFIT", switch = "CASINO_POLE_MOVE_HAPPY"  },
}
CASINO_POLE_MODELS = {
    CASINO_POLE_IDLE = true, CASINO_POLE_MOVE_PROFIT = true, CASINO_POLE_MOVE_HAPPY = true,
}
-- Length of a switch animation: 15 frames at AnimationSpeed 130 is 15 * 256 / 130,
-- just under 30 turns. The idle pole takes over a turn or two early, so the
-- animation never gets to wrap back to its first frame.
CASINO_POLE_SWITCH_TICKS = 22
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
    GOBLIN       = "LIKE", DARK_ELF      = "LIKE", FIREFLY     = "LIKE", BLACK_KNIGHT          = "LIKE", 
    DWARFA       = "LIKE", SAMURAI       = "LIKE", BARBARIAN    = "LIKE", MONK                  = "HATE", 
    ARCHER       = "LIKE", WIZARD        = "LIKE", FAIRY        = "LIKE", GIANT                 = "LIKE",  
    REAPER       = "LIKE",
}

-- A creature never carries more than its model's GoldHold out of the casino.
-- Lua has no getter for creature config, so the values are mirrored here: from
-- dk2_crtr/*.cfg where this campaign overrides a creature, from the base game's
-- creatrs/*.cfg otherwise. Re-extract whenever GoldHold is rebalanced - a value
-- that is too low here means the creature can lose gold but never win any back.
CASINO_GOLD_HOLD_DEFAULT = 500
CASINO_GOLD_HOLD = {
    ANGEL             = 4000,   ARCHER            = 250,    AVATAR            = 1000,
    BALDER            = 600,    BARBARIAN         = 1500,   BILE_DEMON        = 3000,
    BLACK_KNIGHT      = 1500,   BUG               = 300,    DARK_ELF          = 250,
    DARK_MISTRESS     = 750,    DEMONSPAWN        = 250,    DRAGON            = 5000,
    DRUID             = 260,    DWARFA            = 500,    DWARFABONUS       = 500,
    EASTER_CHICKEN    = 400,    EVILLORD          = 0,      FAIRY             = 250,
    FAKELORD          = 600,    FELIX             = 600,    FIREFLY           = 75,
    FLOATING_SPIRIT   = 0,      FLY               = 50,     GEMSTONE_KNIGHT   = 50000,
    GHOST             = 1000,   GIANT             = 1000,   GOBLIN            = 500,
    HELL_HOUND        = 500,    HORNY             = 2500,   IMP               = 1250,
    KNIGHT            = 600,    MAIDEN            = 800,    MISTRESS          = 750,
    MONK              = 750,    ORC               = 600,    REAPER            = 1000,
    ROGUE             = 4000,   SALAMANDER        = 500,    SAMURAI           = 750,
    SKELETON          = 500,    SORCEROR          = 400,    SORCERORBONUS     = 400,
    SPIDER            = 250,    SUMMONED_SKELETON = 500,    TENTACLE          = 500,
    THIEF             = 1750,   TIME_MAGE         = 500,    TRISTAN           = 600,
    TROLL             = 500,    TUNNELLER         = 1500,   VAMPIRE           = 2500,
    WARLOCK           = 400,    WITCH             = 400,    WIZARD            = 500,
}

-- How angry is too angry to gamble, as a multiple of the model's AnnoyLevel.
-- The engine's own steps are: 1x = Angry, 2x = Livid, 3x = the hard ceiling every
-- anger value is clamped to (anger_calculate_creature_is_angry / anger_set_creature_anger_f).
-- 2 is what a player reads as "maxed out", because Livid is the worst face the
-- creature panel ever shows - 3x is a number nothing displays.
CASINO_ANGER_LIMIT = 2

-- Anger threshold per model, mirrored from AnnoyLevel for the same reason as
-- GoldHold. 4000 for almost everything, so only the exceptions are listed; 0
-- means the model can never get angry at all.
CASINO_ANNOY_LEVEL_DEFAULT = 4000
CASINO_ANNOY_LEVEL = {
    EVILLORD = 0, FIREFLY = 7500, FLOATING_SPIRIT = 0, FLY = 8000, HORNY = 0, IMP = 0,
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
CASINO_REQUIRE_LAIR = false

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
Game.CASINO_IDLE_SINCE = Game.CASINO_IDLE_SINCE or {}  -- idx -> turn the creature went idle
Game.CASINO_LEVERS   = Game.CASINO_LEVERS   or {}  -- thing idx -> true, every lever we spawned
Game.CASINO_TICKS    = Game.CASINO_TICKS    or 0   -- tick counter, drives the throttles
Game.CASINO_SHUT     = Game.CASINO_SHUT     or {}  -- playerId -> turn the house reopens
Game.CASINO_SPIN     = Game.CASINO_SPIN     or {}  -- table thing idx -> turn its wheel stops
Game.CASINO_POLE_UNTIL = Game.CASINO_POLE_UNTIL or {}  -- room_idx -> turn its switch animation ends


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
    CreatureInCombat = true, CreatureCombatFlee = true,
    CreatureDoorCombat = true, CreatureObjectCombat = true,
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

-- CASINO_SEATS_PER_TABLE creatures per roulette table in the room.
function CasinoCapacity(room)
    local tables = #CasinoTables(room)
    if tables > 0 then
        return tables * CASINO_SEATS_PER_TABLE
    end
    -- A room too small to have inner slabs has no table: slabs divided by two,
    -- the rule the engine uses for its own worker rooms.
    local n = math.floor(room.slabs_count / 2)
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
        local seat = CasinoSeat(cr, room)
        CasinoLog("seated " .. cr.model .. " #" .. idx .. " in room " .. room.room_idx)
        -- Arrived somewhere in the room; now on to a table.
        CasinoNextSpot(cr, room, seat)
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
    local turn = PLAYER0.GAME_TURN
    if seat.moving then
        -- Arrived at the new spot. Movement is over, so a facing set now sticks,
        -- and the countdown to the next round only starts once settled - walking
        -- must not eat into it.
        seat.moving = nil
        CasinoFaceTable(cr, seat)
        seat.next_round = turn + CASINO_ROUND_TICKS
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

    if seat.spin_until then
        -- Bet is placed, the wheel is turning.
        if turn >= seat.spin_until then
            seat.spin_until = nil
            CasinoStopTable(seat.table)
            CasinoFinishRound(cr, seat)
        else
            CasinoHop(cr, seat, turn)
        end
    elseif turn >= seat.next_round then
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
    -- Place the bet. At a table that means waiting for the wheel to stop;
    -- without one the game is settled on the spot.
    local stop, joined = CasinoSpinTable(seat.table)
    if stop == nil then
        if CasinoResolveBet(cr, seat, room) and not seat.emote_until then
            CasinoNextSpot(cr, room, seat)
        end
    elseif joined then
        seat.spin_until = stop
        CasinoFaceTable(cr, seat)
    else
        -- The wheel is about to stop on someone else's game: bet on the next spin.
        seat.next_round = stop + 1
    end
end

-- The wheel has stopped: now the creature learns how its bet went.
function CasinoFinishRound(cr, seat)
    local room = CasinoRoomAt(cr.pos.stl_x, cr.pos.stl_y)
    if not room or not CasinoRoomIsRun(room) then
        CasinoSendAway(cr, 0)
        return
    end
    seat.room_idx = room.room_idx
    seat.next_round = PLAYER0.GAME_TURN + CASINO_ROUND_TICKS
    if CasinoResolveBet(cr, seat, room) and not seat.emote_until then
        CasinoNextSpot(cr, room, seat)
    end
end

-- =====================================================================
--  ROULETTE TABLES
-- =====================================================================
-- The tables are decoration the room's slab graphics put on its inner slabs
-- (UpdateFunctionTABLE in init.lua thins them out to a checkerboard). Creatures
-- play at them: they walk up to a free subtile next to a table, face it, bet -
-- which sets the wheel spinning - hop about while it turns, and only learn how
-- the bet went once it stops.

-- Tables per room. Kept outside Game on purpose: it rebuilds itself after a
-- load, whenever the room changes size, and on every deep sweep.
CASINO_TABLE_CACHE = {}

function CasinoTables(room)
    local c = CASINO_TABLE_CACHE[room.room_idx]
    local n = room.slabs_count
    local turn = PLAYER0.GAME_TURN
    -- Also rebuilt once it is a second old: the engine may ask for the capacity
    -- while it is still placing the slab graphics, before the tables exist.
    if not c or c.slabs ~= n or turn - c.turn > CASINO_TICK then
        local list = {}
        for _, slab in ipairs(room.slabs) do
            ---@diagnostic disable-next-line: param-type-mismatch
            local things = GetThingsOnSlab(slab.slb_x, slab.slb_y, "OBJECT")
            if things then
                for _, ob in ipairs(things) do
                    if ob:isValid() and ob.model == CASINO_TABLE_MODEL then
                        list[#list + 1] = ob.ThingIndex
                    end
                end
            end
        end
        local changed = not c or #c.list ~= #list
        c = { slabs = n, list = list, turn = turn }
        CASINO_TABLE_CACHE[room.room_idx] = c
        -- The room's own capacity is only recomputed by the engine when the room
        -- changes; tables appear and disappear on their own, so pass it on.
        if changed then
            Casino_Total_Capacity(room)
        end
    end
    return c.list
end

-- The table behind an index, or nil once it is gone or the index was recycled.
function CasinoTable(tidx)
    if not tidx then return nil end
    local t = GetThingByIdx(tidx)
    if t and t:isValid() and t.model == CASINO_TABLE_MODEL then return t end
    return nil
end

-- Turns the creature towards a point. Angles: 0 north, 512 east, 1024 south,
-- 1536 west, 2048 for the full circle.
function CasinoFace(cr, val_x, val_y)
    local p = cr.pos
    local dx, dy = val_x - p.val_x, val_y - p.val_y
    if dx == 0 and dy == 0 then return end
    -- math.atan2 in LuaJIT; Lua 5.3+ merged it into math.atan(y, x).
    local atan2 = math.atan2 or math.atan
    cr.orientation = math.floor(atan2(dx, -dy) * 1024 / math.pi + 0.5) % 2048
end

function CasinoFaceTable(cr, seat)
    local t = CasinoTable(seat.table)
    if t then
        local p = t.pos
        CasinoFace(cr, p.val_x, p.val_y)
    else
        -- No table: a random way, so a crowd does not all stare the same direction.
        cr.orientation = math.random(0, 2047)
    end
end

function CasinoShuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local CASINO_AROUND = { {-1,-1}, {0,-1}, {1,-1}, {-1,0}, {1,0}, {-1,1}, {0,1}, {1,1} }

-- A free subtile right next to a table of this room: one of the eight around the
-- table's own subtile that nobody else seated has as their spot. Tables and
-- spots are tried in random order. Returns stl_x, stl_y and the table, or nil.
function CasinoTableSpot(room, idx)
    local taken = {}
    for other, s in pairs(Game.CASINO_SEAT) do
        if other ~= idx and s.stl_x then
            taken[s.stl_x * 1024 + s.stl_y] = true
        end
    end
    local tables = {}
    for i, tidx in ipairs(CasinoTables(room)) do tables[i] = tidx end
    for _, tidx in ipairs(CasinoShuffle(tables)) do
        local t = CasinoTable(tidx)
        local p = t and t.pos
        local here = p and CasinoRoomAt(p.stl_x, p.stl_y)
        if here and here.room_idx == room.room_idx then
            local around = {}
            for i, d in ipairs(CASINO_AROUND) do around[i] = d end
            for _, d in ipairs(CasinoShuffle(around)) do
                local x, y = p.stl_x + d[1], p.stl_y + d[2]
                if not taken[x * 1024 + y] then return x, y, tidx end
            end
        end
    end
    return nil
end

function CasinoWalkToSpot(cr, seat, x, y)
    -- Set before walk_to: should the state change fire Casino_Play_Cleanup, this
    -- is what tells it the creature is relocating, not leaving the table.
    seat.moving = true
    if cr:walk_to(x, y) then
        cr.continue_state = "CasinoGambling"
        seat.stl_x, seat.stl_y = x, y
        return true
    end
    seat.moving = nil
    return false
end

-- Where the next game is played. Mostly at the same table, sometimes another one
-- (CASINO_SWITCH_TABLE), so a busy casino does not look frozen. A room with no
-- table at all - too small to have inner slabs - plays on a random spot instead.
function CasinoNextSpot(cr, room, seat)
    if CasinoTable(seat.table) and math.random(100) > CASINO_SWITCH_TABLE then
        local p = cr.pos
        if p.stl_x == seat.stl_x and p.stl_y == seat.stl_y then
            CasinoFaceTable(cr, seat)
            seat.next_round = PLAYER0.GAME_TURN + CASINO_ROUND_TICKS
            return
        end
        if CasinoWalkToSpot(cr, seat, seat.stl_x, seat.stl_y) then return end
    end
    for _ = 1, CASINO_WALK_ATTEMPTS do
        local x, y, tidx = CasinoTableSpot(room, cr.ThingIndex)
        if not x then break end
        seat.table = tidx
        if CasinoWalkToSpot(cr, seat, x, y) then return end
    end
    seat.table, seat.stl_x, seat.stl_y = nil, nil, nil
    local x, y = CasinoRandomSpot(room)
    if not CasinoWalkToSpot(cr, seat, x, y) then
        cr.orientation = math.random(0, 2047)
        seat.next_round = PLAYER0.GAME_TURN + CASINO_ROUND_TICKS
    end
end

-- Sets a table's wheel spinning, or lets a creature join a spin already under
-- way - but only during its first half, so nobody bets on a wheel that is about
-- to stop. Returns the turn the wheel stops and whether the bet made it in; nil
-- when there is no table.
function CasinoSpinTable(tidx)
    local t = CasinoTable(tidx)
    if not t then return nil end
    local turn = PLAYER0.GAME_TURN
    local stop = Game.CASINO_SPIN[tidx]
    if stop and stop > turn then
        return stop, (stop - turn) >= CASINO_SPIN_TICKS / 2
    end
    stop = turn + CASINO_SPIN_TICKS
    Game.CASINO_SPIN[tidx] = stop
    t.anim_speed = CASINO_SPIN_SPEED
    return stop, true
end

-- Stops the wheel once its time is up. Every player at the table calls this when
-- its own game ends; a spin that was restarted in the meantime is left running.
function CasinoStopTable(tidx)
    if not tidx then return end
    local stop = Game.CASINO_SPIN[tidx]
    if stop and PLAYER0.GAME_TURN < stop then return end
    Game.CASINO_SPIN[tidx] = nil
    local t = CasinoTable(tidx)
    if t then t.anim_speed = 0 end
end

-- An occasional hop while the wheel turns, the way creatures hop while they wait
-- to join a fight. set_velocity is all Lua has, and it always pushes sideways by
-- the full amount as well (angles_to_vector), so two pushes in opposite
-- directions cancel the sideways part and add up upwards. 512 points straight up.
function CasinoHop(cr, seat, turn)
    if turn < (seat.hop_at or 0) then return end
    if math.random(100) > CASINO_HOP_CHANCE then return end
    local half = math.floor(math.random(CASINO_HOP_MIN, CASINO_HOP_MAX) / 2)
    cr:set_velocity(half, 0, 512)
    cr:set_velocity(half, 1024, 512)
    seat.hop_at = turn + CASINO_HOP_GAP
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
-- The two boxes behave as a single lever in the middle of the room's top row:
-- only the box that switches to the OTHER mode is ever visible, so what you see
-- is what clicking it will do. The engine destroys a special box on click, so
-- the lever is simply re-placed on the next tick.
function CasinoIsLever(ob)
    local m = ob.model
    return m == CASINO_LEVER_MODEL[CASINO_BOX_HAPPY]
        or m == CASINO_LEVER_MODEL[CASINO_BOX_PROFIT]
end

-- Where the lever belongs: the topmost row of the room's slabs, centred on that
-- row. With an even number of slabs in the row the middle is the border between
-- the two middle slabs, so the lever stands exactly there rather than favouring
-- one side. If the row has gaps (an odd-shaped room) and the middle falls into
-- one, the nearest slab of the row is used instead.
-- Returns map coordinates (val), not subtiles, so that border position works.
function CasinoLeverSpot(room)
    local top, row = nil, {}
    for _, slab in ipairs(room.slabs) do
        if top == nil or slab.slb_y < top then
            top, row = slab.slb_y, {}
        end
        if slab.slb_y == top then row[slab.slb_x] = true end
    end
    if top == nil then
        local c = room.centerpos
        return c.val_x, c.val_y
    end

    local lo, hi
    for x in pairs(row) do
        if lo == nil or x < lo then lo = x end
        if hi == nil or x > hi then hi = x end
    end
    local mid = (lo + hi) / 2
    local fits = row[mid] or (row[math.floor(mid)] and row[math.ceil(mid)])
    if not fits then
        local best
        for x in pairs(row) do
            if best == nil or math.abs(x - mid) < math.abs(best - mid)
               or (math.abs(x - mid) == math.abs(best - mid) and x < best) then
                best = x
            end
        end
        mid = best
    end
    -- 768 per slab; the +384 puts the point in the middle of the slab.
    return math.floor(mid * 768 + 384), top * 768 + 384
end

-- The lever is placed at an exact map position, so "in place" allows for a
-- little rounding but not for being knocked onto a neighbouring subtile.
function CasinoLeverAt(ob, val_x, val_y)
    local p = ob.pos
    return math.abs(p.val_x - val_x) <= 16 and math.abs(p.val_y - val_y) <= 16
end

function CasinoIsPole(ob)
    return CASINO_POLE_MODELS[ob.model] == true
end

-- The special boxes and the pole decorations in a room, in one pass.
function CasinoBoxesInRoom(room)
    local out, poles = {}, {}
    for _, slab in ipairs(room.slabs) do
        ---@diagnostic disable-next-line: param-type-mismatch
        local things = GetThingsOnSlab(slab.slb_x, slab.slb_y, "OBJECT")
        if things then
            for _, ob in ipairs(things) do
                if ob:isValid() then
                    if CasinoIsLever(ob) then
                        out[#out + 1] = ob
                    elseif CasinoIsPole(ob) then
                        poles[#poles + 1] = ob
                    end
                end
            end
        end
    end
    return out, poles
end

function CasinoPlaceAt(model, room, val_x, val_y)
    local ob = AddObjectToLevelAtPos(model, math.floor(val_x / 256), math.floor(val_y / 256), 0, room.owner)
    if not ob then return nil end
    ob.pos = { val_x = val_x, val_y = val_y, val_z = ob.pos.val_z }
    Game.CASINO_LEVERS[ob.ThingIndex] = true
    return ob
end

-- Exactly one idle pole on the lever's spot, showing the room's mode. Poles
-- placed by hand in the map editor are taken over: the first one is moved onto
-- the spot, any others go. Left alone while a switch animation is playing.
function CasinoEnsurePole(room, poles, val_x, val_y)
    if (Game.CASINO_POLE_UNTIL[room.room_idx] or 0) > PLAYER0.GAME_TURN then return end
    local keep = nil
    for _, ob in ipairs(poles) do
        if (not keep) and ob.model == CASINO_POLE_IDLE then
            keep = ob
        else
            ob:delete()
        end
    end
    if not keep then
        keep = CasinoPlaceAt(CASINO_POLE_IDLE, room, val_x, val_y)
        if not keep then return end
    elseif not CasinoLeverAt(keep, val_x, val_y) then
        keep.pos = { val_x = val_x, val_y = val_y, val_z = keep.pos.val_z }
    end
    Game.CASINO_LEVERS[keep.ThingIndex] = true
    ---@diagnostic disable-next-line: assign-type-mismatch
    keep.anim_sprite = CASINO_POLE_LOOK[CasinoMode(room.room_idx)].sprite
end

-- The lever was flipped: swap the idle pole for the matching switch animation,
-- and have the idle pole take over again once it has played.
function CasinoFlipPole(room)
    local idx = room.room_idx
    local val_x, val_y = CasinoLeverSpot(room)
    local _, poles = CasinoBoxesInRoom(room)
    for _, ob in ipairs(poles) do ob:delete() end
    if not CasinoPlaceAt(CASINO_POLE_LOOK[CasinoMode(idx)].switch, room, val_x, val_y) then return end
    Game.CASINO_POLE_UNTIL[idx] = PLAYER0.GAME_TURN + CASINO_POLE_SWITCH_TICKS
    local trig = RegisterTimerEvent("CasinoPoleSettle", CASINO_POLE_SWITCH_TICKS, false)
    trig.triggerData.room_idx = idx
end

function CasinoPoleSettle(eventData, triggerData)
    local idx = triggerData.room_idx
    -- Flipped again in the meantime: that newer timer settles it.
    if (Game.CASINO_POLE_UNTIL[idx] or 0) > PLAYER0.GAME_TURN then return end
    Game.CASINO_POLE_UNTIL[idx] = nil
    for _, room in ipairs(CasinoRooms()) do
        if room.room_idx == idx then
            local val_x, val_y = CasinoLeverSpot(room)
            local _, poles = CasinoBoxesInRoom(room)
            CasinoEnsurePole(room, poles, val_x, val_y)
            return
        end
    end
end

-- Fast path for the overwhelmingly common case: the right lever is already
-- sitting in its spot and nothing needs doing. That costs one GetThingsOnSlab
-- instead of one per slab of the room, which for a large casino is the
-- difference between one call a second and twenty.
function CasinoLeverIsInPlace(room, want)
    local val_x, val_y = CasinoLeverSpot(room)
    ---@diagnostic disable-next-line: param-type-mismatch
    local things = GetThingsOnSlab(math.floor(val_x / 768), math.floor(val_y / 768), "OBJECT")
    if not things then return false end
    for _, ob in ipairs(things) do
        if ob:isValid() and ob.model == CASINO_LEVER_MODEL[want]
           and CasinoLeverAt(ob, val_x, val_y) then
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
    local boxes, poles = CasinoBoxesInRoom(room)
    for _, ob in ipairs(boxes) do
        if (not keep) and ob.model == CASINO_LEVER_MODEL[want] then
            keep = ob
        else
            ob:delete()
        end
    end

    local val_x, val_y = CasinoLeverSpot(room)
    if not keep then
        keep = AddObjectToLevelAtPos(CASINO_LEVER_MODEL[want],
            math.floor(val_x / 256), math.floor(val_y / 256), want, room.owner)
        if not keep then return end
        Game.CASINO_LEVERS[keep.ThingIndex] = true
        CasinoLog("room " .. room.room_idx .. " (" .. CasinoMode(room.room_idx)
            .. ") lever placed: " .. CASINO_LEVER_MODEL[want])
    end

    -- Put it exactly on its spot. A new lever needs this because it was spawned
    -- on a subtile centre, an old one whenever the room was built on or sold off
    -- and its top row moved. Assign the whole position table: thing.pos hands out
    -- a fresh table on every read, so writing keep.pos.val_x would be thrown away.
    if not CasinoLeverAt(keep, val_x, val_y) then
        keep.pos = { val_x = val_x, val_y = val_y, val_z = keep.pos.val_z }
    end
    CasinoClearLeverSpot(val_x, val_y)
    CasinoEnsurePole(room, poles, val_x, val_y)
end

-- The lever takes the place of the decoration the room's slab graphics put on
-- its slab: the barrel of the top row's middle slab, or with an even number of
-- slabs the barrels of the two slabs it stands between. The slab graphics may put
-- them back when the room is rebuilt around them, which the deep sweep catches.
function CasinoClearLeverSpot(val_x, val_y)
    local slb_y = math.floor(val_y / 768)
    for slb_x = math.floor((val_x - 384) / 768), math.floor((val_x + 383) / 768) do
        ---@diagnostic disable-next-line: param-type-mismatch
        local things = GetThingsOnSlab(slb_x, slb_y, "OBJECT")
        if things then
            for _, ob in ipairs(things) do
                if ob:isValid() and CASINO_LEVER_REPLACES[ob.model] then
                    ob:delete()
                    CASINO_TABLE_CACHE = {}
                end
            end
        end
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
        if (not ob) or (not ob:isValid()) or not (CasinoIsLever(ob) or CasinoIsPole(ob)) then
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
        elseif ob:isValid() and CasinoIsPole(ob) and CasinoRoomAt(ob.pos.stl_x, ob.pos.stl_y) then
            -- Poles outside a casino may be a mapper's decoration: left alone.
            Game.CASINO_LEVERS[ob.ThingIndex] = true
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
    CasinoFlipPole(room)
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
                    if seat.spin_until then
                        -- Danced through its own game (a jackpot at another
                        -- table): stay put, the result comes once it resumes.
                        CasinoFaceTable(cr, seat)
                    else
                        CasinoNextSpot(cr, room, seat)
                    end
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

-- A creature the keeper dropped has landed, and the engine has already decided
-- what it does there. On landing the engine looks for a fight first - an enemy
-- creature, a heart, or an enemy door on one of the four neighbouring slabs -
-- and only then for a job. A creature it put into a fight is left to it:
-- CasinoCanInterrupt refuses every combat state. The rest, if it landed in a
-- casino, gets a seat.
function CasinoTakeDroppedCreature(cr)
    if not CasinoIsPlayable(cr) then return end
    local room = CasinoRoomAt(cr.pos.stl_x, cr.pos.stl_y)
    if not room or not CasinoRoomIsRun(room) then return end
    if not CasinoCanInterrupt(cr) then return end

    local idx = cr.ThingIndex
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

-- CreatureLanded fires right after the engine's own drop logic, in the same
-- turn, so whatever is set here replaces what the engine chose.
function CasinoOnLanded(eventData)
    local cr = eventData.unit
    if not cr or not cr:isValid() then return end
    CasinoTakeDroppedCreature(cr)
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

    -- Every tick: the watchdog frees seats whose creature has gone elsewhere.
    CasinoWatchdog()

    -- Wheels whose players all left before the game ended.
    local turn = PLAYER0.GAME_TURN
    for tidx, stop in pairs(Game.CASINO_SPIN) do
        if turn >= stop then CasinoStopTable(tidx) end
    end
    if deep then CASINO_TABLE_CACHE = {} end

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
    -- Needs a game build with the CreatureLanded event (KeeperFX PR #5584).
    RegisterCreatureLandedEvent("CasinoOnLanded")

    local trig = CreateTrigger("ChatMsg", "CasinoChatStatus", {})
    TriggerAddCondition(trig, function(eventData)
        return eventData.Message == "_CASINO"
    end)

    CasinoLog("setup done, tick=" .. CASINO_TICK .. " round=" .. CASINO_ROUND_TICKS)
end



