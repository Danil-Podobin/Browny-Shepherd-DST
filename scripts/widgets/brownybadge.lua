local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local function OnIsSummer(inst, issummer)
    inst.widget.issummer = issummer
end

local BrownyBadge = Class(Badge, function(self, owner)
    Badge._ctor(self, "browny_meter", owner)
	
    self.sanityarrow = self.underNumber:AddChild(UIAnim())
    self.sanityarrow:GetAnimState():SetBank("sanity_arrow")
    self.sanityarrow:GetAnimState():SetBuild("sanity_arrow")
    self.sanityarrow:SetClickable(false)

    self.inst:WatchWorldState("issummer", OnIsSummer)
    self.issummer = TheWorld.state.issummer
    self.val = 0
    self.arrowdir = nil
    self:StartUpdating()
end)

function BrownyBadge:OnUpdate(dt)
	local anim = "neutral"
	if self.owner:HasTag("sleeping") then
		anim = (self.val > 0 and "arrow_loop_decrease") or "neutral"
	elseif self.owner.replica.hunger:GetPercent() <= 0.5 or self.owner.replica.sanity:GetPercent() <= 0.5 then
		anim = (self.val < 1 and "arrow_loop_increase_more") or "neutral"
	elseif self.issummer then
		anim = (self.val < 1 and "arrow_loop_increase") or "neutral"
	end
    if self.arrowdir ~= anim then
        self.arrowdir = anim
        self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
    end
end

function BrownyBadge:SetPercent(val, max)
    Badge.SetPercent(self, val, max)
    self.val = val
end

return BrownyBadge
