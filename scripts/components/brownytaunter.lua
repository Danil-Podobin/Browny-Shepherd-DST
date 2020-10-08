local TAUNTABLETAGS = {
	"monster", 
	"moose", 
	"frog",
	"tallbird",
	"merm",
	"walrus",
	"killer",
}

local BrownyTaunter = Class(function(self, inst)
    self.inst = inst
	self.cooldown = 0
	self.cantaunt = true
	self.istaunting = false
	self.tauntradius = 25
	self.defaultcooldown = 30
    self.inst:StartUpdatingComponent(self)
end)

function BrownyTaunter:OnUpdate(dt)
	if self.istaunting then return end
	if self.cooldown > dt then
        self.cooldown = self.cooldown - dt
    elseif not self.cantaunt then
		self.cantaunt = true
		self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_TAUNT_READY"))
	end
end

function BrownyTaunter:DoTaunt()
	if self.cantaunt then
		self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_TAUNT"))		
        self.inst:PushEvent("emote", { anim = "emoteXL_angry", soundoverride = "taunt"} )
		self.cantaunt = false
		self.istaunting = true
		self.cooldown = self.defaultcooldown
		self.inst:DoTaskInTime(math.random() * 1, function(inst)
			local tauntedsomething = false
			local x,y,z = self.inst.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x,y,z, SpringCombatMod(self.tauntradius), {"_combat"}, {"INLIMBO", "player"}, TAUNTABLETAGS )
			for k,v in pairs(ents) do 
				if not (v.components.health and v.components.health:IsDead()) and (v.components.combat and v.components.combat.target ~= self.inst) and not(self.inst.components.sanity and self.inst.components.sanity:IsSane() and v:HasTag("shadowcreature")) then
					tauntedsomething = true
					v:DoTaskInTime(math.random() * 1, function(inst)
						v.components.combat:SetTarget(self.inst)
					end)
				end
			end
			if not tauntedsomething then
				self.inst:DoTaskInTime(3, function(inst)
					self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_TAUNT_FAIL"))
					self.cantaunt = true
					self.istaunting = false
				end)
			else
				self.inst:DoTaskInTime(3, function(inst)
					self.istaunting = false
				end)
			end
		end)
	elseif not self.istaunting then
		self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_TAUNT_COOLDOWN"))
	end
end

return BrownyTaunter