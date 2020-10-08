PrefabFiles = {
	"browny",
	"browny_none",
	"brownymace",
}

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/browny.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/browny.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/browny.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/browny.xml" ),
	
    Asset( "IMAGE", "images/selectscreen_portraits/browny_silho.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/browny_silho.xml" ),

    Asset( "IMAGE", "bigportraits/browny.tex" ),
    Asset( "ATLAS", "bigportraits/browny.xml" ),
	
	Asset( "IMAGE", "images/map_icons/browny.tex" ),
	Asset( "ATLAS", "images/map_icons/browny.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_browny.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_browny.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_ghost_browny.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_ghost_browny.xml" ),
	
	Asset( "IMAGE", "images/avatars/self_inspect_browny.tex" ),
    Asset( "ATLAS", "images/avatars/self_inspect_browny.xml" ),
	
	Asset( "IMAGE", "images/names_browny.tex" ),
    Asset( "ATLAS", "images/names_browny.xml" ),
	
	Asset( "IMAGE", "images/names_gold_browny.tex" ),
    Asset( "ATLAS", "images/names_gold_browny.xml" ),
	
	Asset("SOUNDPACKAGE", "sound/browny.fev"),
    Asset("SOUND", "sound/browny.fsb"),
	
	Asset("ANIM", "anim/browny_meter.zip"),

}

RemapSoundEvent( "dontstarve/characters/browny/death_voice", "browny/characters/browny/death_voice" )
RemapSoundEvent( "dontstarve/characters/browny/hurt", "browny/characters/browny/hurt" )
RemapSoundEvent( "dontstarve/characters/browny/talk_LP", "browny/characters/browny/talk_LP" )
RemapSoundEvent( "dontstarve/characters/browny/emote", "browny/characters/browny/emote" )
RemapSoundEvent( "dontstarve/characters/browny/ghost_LP", "browny/characters/browny/ghost_LP" )
RemapSoundEvent( "dontstarve/characters/browny/yawn", "browny/characters/browny/yawn" )
RemapSoundEvent( "dontstarve/characters/browny/pose", "browny/characters/browny/pose" )
RemapSoundEvent( "dontstarve/characters/browny/taunt", "browny/characters/browny/taunt" )
RemapSoundEvent( "dontstarve/characters/browny/carol", "browny/characters/browny/carol" )

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS

-- The character select screen lines
STRINGS.CHARACTER_TITLES.browny = "The Rage Wolf"
STRINGS.CHARACTER_NAMES.browny = "Browny"
STRINGS.CHARACTER_DESCRIPTIONS.browny = "*Loves winter. Hates summer\n*Uses his anger to his benefit...usually\n*Runs his mouth sometimes"
STRINGS.CHARACTER_QUOTES.browny = "\"Trust me, you don't want to do that.\""
STRINGS.CHARACTER_SURVIVABILITY.browny = "Slim"

-- Custom speech strings
STRINGS.CHARACTERS.BROWNY = require "speech_browny"

-- The character's name as appears in-game 
STRINGS.NAMES.BROWNY = "Browny"
STRINGS.SKIN_NAMES.browny_none = "Browny"

AddMinimapAtlas("images/map_icons/browny.xml")

local skin_modes = {
    { 
        type = "ghost_skin",
        anim_bank = "ghost",
        idle_anim = "idle", 
        scale = 0.75, 
        offset = { 0, -25 } 
    },
}
-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
AddModCharacter("browny", "MALE", skin_modes)

-- Custom items
STRINGS.NAMES.BROWNYMACE = "Squiggles the Mace"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BROWNYMACE = "It's Squiggles!"
STRINGS.RECIPE_DESC.BROWNYMACE = "Browny's mace."

local TECH = GLOBAL.TECH
local RECIPETABS = GLOBAL.RECIPETABS
local brownymace_recipe = AddRecipe("brownymace", { Ingredient("houndstooth", 6), Ingredient("boneshard", 6), Ingredient("nitre", 10)}, RECIPETABS.WAR, TECH.SCIENCE_TWO, nil, nil, nil, nil, "brownymacebuilder", "images/inventoryimages/brownymace.xml" )

-- Put at top of list
brownymace_recipe.sortkey = -8107

-- Custom starting items images on the level select screen
GLOBAL.TUNING.STARTING_ITEM_IMAGE_OVERRIDE.brownymace = {
    atlas = "images/inventoryimages/brownymace.xml",
    image = "brownymace.tex",
}


-- Taunting ability
local function browny_taunt(player)
	if player.components.brownytaunter and not player:HasTag("playerghost") then
		player.components.brownytaunter:DoTaunt()
	end
end
AddModRPCHandler(modname, "browny_taunt", browny_taunt)
GLOBAL.TheInput:AddKeyDownHandler(GetModConfigData("key_taunt", true), function()
    if not GLOBAL.ThePlayer or GLOBAL.ThePlayer.prefab ~= "browny" or GLOBAL.TheFrontEnd:GetActiveScreen() ~= GLOBAL.ThePlayer.HUD then
        return
    end
    
	if GLOBAL.TheNet:GetIsServer() then
		browny_taunt(GLOBAL.ThePlayer)
	else
		SendModRPCToServer(MOD_RPC[modname]["browny_taunt"])
	end
end)

-- Rage meter
local function StatusDisplaysPostInit( self )
	if self.owner:HasTag("brownyrage") then
		local BrownyBadge = require "widgets/brownybadge"
		self.brownymeter = self:AddChild(BrownyBadge(self.owner))

		-- Compatibility with Always On Status mod.
		if GLOBAL.KnownModIndex:IsModEnabled("workshop-376333686") then
			self.brownymeter:SetPosition(-62, -52, 0)
		else
	    	self.brownymeter:SetPosition(-80, -40, 0)
		end
		
		function self:SetBrownyRagePercent(pct)
			self.brownymeter:SetPercent(pct)
		end
		
		function self:BrownyRageDelta(data)
			self:SetBrownyRagePercent(data.newpercent)
			if not data.overtime then
				if data.newpercent > data.oldpercent then
					GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/sanity_down")
					self.brownymeter:PulseRed()
				elseif data.newpercent < data.oldpercent then
					self.brownymeter:PulseGreen()
					GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/sanity_up")
				end
			end
		end
		
		if self.isghostmode then
            self.brownymeter:Hide()
        elseif self.brownymodetask == nil and self.onbrownyragedelta == nil then
            self.onbrownyragedelta = function(owner, data) self:BrownyRageDelta(data) end
            self.inst:ListenForEvent("brownyragedelta", self.onbrownyragedelta, self.owner)
            self:SetBrownyRagePercent(self.owner:GetBrownyRage())
        end
		
		local function OnSetPlayerMode(inst, self)
			self.brownymodetask = nil

			if self.brownymeter ~= nil and self.onbrownyragedelta == nil then
				self.onbrownyragedelta = function(owner, data) self:BrownyRageDelta(data) end
				self.inst:ListenForEvent("brownyragedelta", self.onbrownyragedelta, self.owner)
				self:SetBrownyRagePercent(self.owner:GetBrownyRage())
			end
		end

		local function OnSetGhostMode(inst, self)
			self.brownymodetask = nil
			
			if self.onbrownyragedelta ~= nil then
				self.inst:RemoveEventCallback("brownyragedelta", self.onbrownyragedelta, self.owner)
				self.onbrownyragedelta = nil
			end
		end
	
		local SetGhostMode_prev = self.SetGhostMode
		function self:SetGhostMode(ghostmode)
			SetGhostMode_prev(self, ghostmode)
			--if not self.isghostmode == not ghostmode then --force boolean
			--	return
			--else
			if ghostmode then
				self.brownymeter:Hide()
			else
				self.brownymeter:Show()
			end
			self.brownymodetask = self.inst:DoTaskInTime(0, ghostmode and OnSetGhostMode or OnSetPlayerMode, self)
		end
		
	end

	return self
end

AddClassPostConstruct( "widgets/statusdisplays", StatusDisplaysPostInit)

-- Add rage to player classified
local playerClassifiedPostInit = function(inst)
	local function OnBrownyRageDelta(parent, data)
		if data.overtime then
			parent.player_classified.isbrownyragepulse:set_local(false)
		else
			--Force dirty, we just want to trigger an event on the client
			GLOBAL.SetDirty(parent.player_classified.isbrownyragepulse, true)
		end
	end
	local function OnBrownyRageDirty(inst)
		if inst._parent ~= nil then
			local oldpercent = inst._oldbrownyragepercent
			local percent = inst.currentbrownyrage:value() * .01
			local data =
			{
				oldpercent = oldpercent,
				newpercent = percent,
				overtime = not inst.isbrownyragepulse:value(),
			}
			inst._oldbrownyragepercent = percent
			inst.isbrownyragepulse:set_local(false)
			inst._parent:PushEvent("brownyragedelta", data)
		else
			inst._oldbrownyragepercent = 0
			inst.isbrownyragepulse:set_local(false)
		end
	end
	if GLOBAL.TheWorld.ismastersim then
        inst:ListenForEvent("brownyragedelta", OnBrownyRageDelta, inst._parent)
	else
        inst:ListenForEvent("brownyragedirty", OnBrownyRageDirty)
		if inst._parent ~= nil then
			inst._oldbrownyragepercent = inst.currentbrownyrage:value() * .01
		end
	end
	--Rage variables
    inst._oldbrownyragepercent = 0
    inst.currentbrownyrage = GLOBAL.net_byte(inst.GUID, "brownyrage.current", "brownyragedirty")
    inst.isbrownyragepulse = GLOBAL.net_bool(inst.GUID, "brownyrage.dodeltaovertime", "brownyragedirty")
    inst.currentbrownyrage:set(0)
	if not GLOBAL.TheWorld.ismastersim then
		inst:DoTaskInTime(0, OnBrownyRageDirty)
	end
end
AddPrefabPostInit("player_classified", playerClassifiedPostInit)
