require "hatchery"
require "patrols"
require "guards"
require "helper"
require "casino"

function OnCampaignGameStart()
    CasinoInit()                                                -- casino code 
    RegisterTimerEvent(CheckForStunDeaths, 1, true)             -- Repeat each frame
    Game.CoopRange = 2                                          -- Coop range in subtiles
    RegisterSlabKindChangeEvent(LavaBecomesBridge, "LAVA", "BRIDGE_FRAME")
end

-- Function that kills all creatures that are close to waking up from stun
function CheckForStunDeaths()
    for _, creature in ipairs(GetThingsOfClass("Creature")) do  -- Get all creatures
        if creature.conscious_back_turns == 1 then              -- If one will wake up next turn
            creature:kill()                                     -- Kill it
        end
    end
end

-- wooden bride and stone bridge behavior

function LavaBecomesBridge(eventData)

    local AiTimer = RegisterTimerEvent(BridgeAi, 10, false)
    AiTimer.triggerData.Slab = eventData.Slab

    local rotTimer = RegisterTimerEvent(BridgeRot, 300, false)
    rotTimer.triggerData.Slab = eventData.Slab

    local burnTimer = RegisterTimerEvent(BridgeBurn, 500, false)
    burnTimer.triggerData.Slab = eventData.Slab

end

-- turning slabs from enemy Keepers to stone after 10 ticks

function BridgeAi(eventData, triggerData)
    
    local slab = triggerData.Slab
    if slab.owner ~= PLAYER0 then
    ChangeSlabType(slab.slb_x, slab.slb_y, "BRIDGE_STONE")
    end
end

-- functions to make the wooden bride functional

function BridgeRot(eventData, triggerData)
    
    local slab = triggerData.Slab
    if slab.kind == "BRIDGE_FRAME" then
    ChangeSlabType(slab.slb_x, slab.slb_y, "BRIDGE_FRAME_BURNED")
    PlayMessage(PLAYER0, "SOUND", 78)
    CreateEffectAtPos("EFFECT_BRIDGEBURN", slab.slb_x* 3 + 1, slab.slb_y* 3 + 1, 1)
    CreateEffectAtPos("EFFECT_SPANGLE_RED", slab.slb_x* 3 + 1, slab.slb_y* 3 + 1, 1)
    end
end

function BridgeBurn(eventData, triggerData)

    local slab = triggerData.Slab
    if slab.kind == "BRIDGE_FRAME_BURNED" then
    ChangeSlabType(slab.slb_x, slab.slb_y, "LAVA")
    CreateEffectAtPos("EFFECT_BRIDGEBURN", slab.slb_x* 3 + 1, slab.slb_y* 3 + 1, 1)
    CreateEffectAtPos("EFFECT_SPANGLE_RED", slab.slb_x* 3 + 1, slab.slb_y* 3 + 1, 1)
    end
end

-- place barricades in a random orientation

-- Lists all existing barricades as tupel {barricades, isInit}: 'barricades' as thing object and 'isInit' as boolean
Game.BarricadesToInit = {}

function UpdateFunctionBARRICADE(barricade)
    if barricade.creation_turn == PLAYER0.GAME_TURN - 1 then
        InitializeBarricade(barricade)
    end
end

function InitializeBarricade(barricade)
    -- Random rotation
    barricade.orientation = math.random(0, 7) * 256
end

-- place fear traps in a south orientation when placed by player 0

-- Lists all existing traps as tupel {traps, isInit}: 'traps' as thing object and 'isInit' as boolean
Game.FearTrapsToInit = {}

function UpdateFunctionFEAR_TRAP(fear_trap)
    if fear_trap.creation_turn == PLAYER0.GAME_TURN - 1 then
        if fear_trap.owner == PLAYER0 then
            InitializeFEAR_TRAP(fear_trap)
        end
    end
    return 1
end

function InitializeFEAR_TRAP(fear_trap)
    -- Random rotation
    fear_trap.orientation = (1536)
end