-- Your character's stats
TUNING.BROWNY_HEALTH = 300
TUNING.BROWNY_HUNGER = 250
TUNING.BROWNY_SANITY = 200

-- Custom starting inventory
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.BROWNY = {
	"brownymace",
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.BROWNY
end
local prefabs = FlattenTree(start_inv, true)

local BROWNY_GRUMPY_RAGE_RATE = 2.5/TUNING.SEG_TIME 
local BROWNY_SUMMER_RAGE_RATE = 0.5/TUNING.SEG_TIME
local BROWNY_GRUMPY_THRESH = 0.5
local BROWNY_BAD_FOOD_RAGE = 10
local BROWNY_DAMAGE_RAGE = 20
local BROWNY_CALM_THRESH = 0.4
local BROWNY_ANGRY_THRESH = 0.8
local BROWNY_CALM_MULT = 1
local BROWNY_MODERATE_MULT = 1.5
local BROWNY_ANGRY_MULT = 2
local BROWNY_KILL_RAGE = -15
local BROWNY_DESTROY_RADIUS = 10
local BROWNY_SUMMER_SANITY_DRAIN = -100/(TUNING.SEG_TIME*2*20)
local BROWNY_INSULATION = 150
local BROWNY_SLEEP_RAGE_PER_TICK = -1
local BROWNY_TAUNT_COOLDOWN = TUNING.TOTAL_DAY_TIME
local BROWNY_TAUNT_RADIUS = 25
local BROWNY_SPEED_MULT = 1.66

local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}

-- Set rage rate
local function updategrumpiness(inst, data)
	local ragerate = 0
	if TheWorld.state.issummer then
		ragerate = ragerate + BROWNY_SUMMER_RAGE_RATE
		inst.components.sanity.dapperness = BROWNY_SUMMER_SANITY_DRAIN
	else
		inst.components.sanity.dapperness = 0
	end
	if inst.components.sanity:GetPercent() <= BROWNY_GRUMPY_THRESH or inst.components.hunger:GetPercent() <= BROWNY_GRUMPY_THRESH then
		ragerate = ragerate + BROWNY_GRUMPY_RAGE_RATE
	end
	
	-- Start rage
	inst.components.brownyrage.rate = ragerate
end

local function DestroyNearestStructure(inst)
	if inst:HasTag("playerghost") then
		return false
	end
	local ent = FindEntity(inst, BROWNY_DESTROY_RADIUS, function(ent) 
	return (ent.components.workable
		and (ent.components.workable.action == ACTIONS.HAMMER 
			or ent.components.workable.action == ACTIONS.MINE 
			or ent.components.workable.action == ACTIONS.CHOP) 
		and ent.components.workable.workleft > 0) 
	or (ent:HasTag("structure") 
		and ent.components.combat 
		and ent.components.health 
		and not ent.components.health:IsDead())
	end)
	
	if ent then
		if ent.components.workable then
			if ent.components.workable.action == ACTIONS.HAMMER then
				ent.components.workable:WorkedBy(inst, 4)
			elseif ent.components.workable.action == ACTIONS.MINE then
				ent.components.workable:WorkedBy(inst, TUNING.MARBLEPILLAR_MINE)
			elseif ent.components.workable.action == ACTIONS.CHOP then
				ent.components.workable:WorkedBy(inst, TUNING.EVERGREEN_CHOPS_TALL)
			end
			return true
		end
		if ent.components.combat then
			ent.components.combat:GetAttacked(inst, 500)
			return true
		end
	end
	return false
end

-- Set damage multiplier based on rage
local function onragedelta(inst, data)
	local damage_mult = BROWNY_CALM_MULT
	local percent = inst.components.brownyrage:GetPercent()
	
	if percent >= BROWNY_ANGRY_THRESH then
		damage_mult = BROWNY_ANGRY_MULT
	elseif percent >= BROWNY_CALM_THRESH then
		damage_mult = BROWNY_MODERATE_MULT
	end
	
	inst.components.combat.damagemultiplier = damage_mult
	
	if inst.destroytask == nil and percent >= 1 then
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_RAGE_FULL"))
		--DestroyNearestStructure(inst)
		inst.destroytask = inst:DoPeriodicTask(2, DestroyNearestStructure)
	elseif inst.destroytask ~= nil and percent < 1 then
		inst.destroytask:Cancel()
		inst.destroytask = nil
	end
end

-- Rage when eating bad food
local function oneat(inst, data)
	if data.food ~= nil and data.food.components.edible ~= nil then
		if data.food.components.edible:GetHealth(inst) < 0 and
			data.food.components.edible:GetSanity(inst) <= 0 and
			not (inst.components.eater ~= nil and
				inst.components.eater.strongstomach and
				data.food:HasTag("monstermeat")) then
			inst.components.brownyrage:DoDelta(BROWNY_BAD_FOOD_RAGE)
		end
	end
end

-- Rage when attacked
local function onattacked(inst, data)
	inst.components.brownyrage:DoDelta(BROWNY_DAMAGE_RAGE)
end

-- Calmed when killing
local function onkilled(inst, data)
	inst.components.brownyrage:DoDelta(BROWNY_KILL_RAGE)
end

-- Calmed when destroying
local function onfinishedwork(inst, data)
	if inst.components.brownyrage:GetPercent() >= 1 or data.action == ACTIONS.HAMMER then
		inst.components.brownyrage:DoDelta(BROWNY_KILL_RAGE)
	end
end


-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when reviving from ghost (optional)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "browny_speed_mod", BROWNY_SPEED_MULT)
	
	inst:WatchWorldState("issummer", updategrumpiness)
    inst:ListenForEvent("hungerdelta", updategrumpiness)
    inst:ListenForEvent("sanitydelta", updategrumpiness)
    inst:ListenForEvent("brownyragedelta", onragedelta)
	inst:ListenForEvent("attacked", onattacked)
	inst:ListenForEvent("oneat", oneat)
    inst:ListenForEvent("killed", onkilled)
    inst:ListenForEvent("finishedwork", onfinishedwork)
	inst.components.brownyrage:StartTimeEffect(1)
end
local function onrespawnfromghost(inst)
	inst.components.brownyrage.current = 50
	inst.components.brownyrage:DoDelta(0, true)
	onbecamehuman(inst)
end

local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
   inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "browny_speed_mod")
   
	inst:StopWatchingWorldState("issummer", updategrumpiness)
	inst:RemoveEventCallback("hungerdelta", updategrumpiness)
	inst:RemoveEventCallback("sanitydelta", updategrumpiness)
    inst:RemoveEventCallback("brownyragedelta", onragedelta)
    inst:RemoveEventCallback("attacked", onattacked)
    inst:RemoveEventCallback("oneat", oneat)
    inst:RemoveEventCallback("killed", onkilled)
    inst:RemoveEventCallback("finishedwork", onfinishedwork)
	
	inst.components.brownyrage:StopTimeEffect()
	inst.components.brownyrage.rate = 0
	inst.components.brownyrage.current = 50
	if inst.destroytask ~= nil then
		inst.destroytask:Cancel()
		inst.destroytask = nil
	end
end

-- When loading or spawning the character
local function onload(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onrespawnfromghost)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
end

local function GetBrownyRage(inst)
    if inst.components.brownyrage ~= nil then
        return inst.components.brownyrage:GetPercent()
    elseif inst.player_classified ~= nil then
        return inst.player_classified.currentbrownyrage:value() * .01
    else
        return 1
    end
end

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst) 
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "browny.tex" )
	inst:AddTag("brownymacebuilder")
    inst:AddTag("brownyrage")
	
    inst.GetBrownyRage = GetBrownyRage 
end
-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
	-- Set starting inventory
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	-- Stats	
	inst.components.health:SetMaxHealth(TUNING.BROWNY_HEALTH)
	inst.components.hunger:SetMax(TUNING.BROWNY_HUNGER)
	inst.components.sanity:SetMax(TUNING.BROWNY_SANITY)
	inst.Transform:SetScale(1.2,1.2,1.2)
	
	-- Insulation
    inst.components.temperature.inherentinsulation = BROWNY_INSULATION
	
	inst:AddComponent("brownytaunter")
	inst.components.brownytaunter.defaultcooldown = BROWNY_TAUNT_COOLDOWN
	inst.components.brownytaunter.tauntradius = BROWNY_TAUNT_RADIUS
	
    inst:AddComponent("brownyrage")
	inst.components.brownyrage.sleeprate = BROWNY_SLEEP_RAGE_PER_TICK
	
	inst.OnLoad = onload
    inst.OnNewSpawn = onload
	
end

return MakePlayerCharacter("browny", prefabs, assets, common_postinit, master_postinit, prefabs)
