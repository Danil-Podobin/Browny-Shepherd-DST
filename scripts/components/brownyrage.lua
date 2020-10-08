local function oncurrent(self, current)
    if self.inst.player_classified ~= nil then
        assert(current >= 0 and current <= 255, "Player currentbrownyrage out of range: "..tostring(current))
        self.inst.player_classified.currentbrownyrage:set(math.ceil(current))
    end
end

local BrownyRage = Class(function(self, inst)
    self.inst = inst

    --Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("brownyrage")

    self.max = 100
    self.current = 0
    self._old = self.current
	self.rate = 0
	self.sleeprate = -1
    if inst.player_classified ~= nil then
        makereadonly(self, "max")
    end
end,
nil,
{
    current = oncurrent,
})

local function OnTimeEffectTick(inst, self, dt)
	--print("Rage delta", self.rate*dt)
	if inst:HasTag("sleeping") then
		self:DoDelta(self.sleeprate*dt, true)
	else
		self:DoDelta(self.rate*dt, true)
	end
end

function BrownyRage:StartTimeEffect(dt)

    if self.task ~= nil then
		return
    end
	--print("Starting rage time effect")
    self.task = self.inst:DoPeriodicTask(dt, OnTimeEffectTick, nil, self, dt)
end

function BrownyRage:StopTimeEffect()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end


function BrownyRage:DoDelta(delta, overtime)
    local old = self._old
    self.current = math.clamp(self.current + delta, 0, self.max)
    self._old = self.current

    self.inst:PushEvent("brownyragedelta", { oldpercent = old / self.max, newpercent = self.current / self.max, overtime = overtime })

end

function BrownyRage:GetPercent()
    return self.current / self.max
end

function BrownyRage:SetPercent(percent, overtime)
    self.current = self.max * percent
    self:DoDelta(0, overtime)
end

function BrownyRage:OnSave()
    return 
    {
        current = self.current,
    }
end

function BrownyRage:OnLoad(data)
    if data ~= nil and data.current ~= nil and data.current ~= self.current then
        self.current = data.current
		self:DoDelta(0, true)
    end
end

function BrownyRage:GetDebugString()
    return string.format("%2.2f / %2.2f", self.current, self.max)
end

return BrownyRage
