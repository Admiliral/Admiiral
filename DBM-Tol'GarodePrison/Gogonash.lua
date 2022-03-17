local mod	= DBM:NewMod("Gogonash", "DBM-Tol'GarodePrison")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220312000000")
mod:SetCreatureID(84000)
mod:SetUsedIcons(7, 8)
mod:RegisterCombat("combat", 84000)

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_AURA_REMOVED"
)

------------------------------10----------------------------------
local warnLightningofFilth				= mod:NewSpellAnnounce(317549, 2)
local warnMarkofFilth					= mod:NewTargetAnnounce(317544, 2)

local specwarnPrimalHorror				= mod:NewSpecialWarningLookAwayi(317548, nil, nil, nil, 2, 2)
local specWarnMarkofFilthRun			= mod:NewSpecialWarningRun(317544, nil, nil, nil, 1, 2)
local yellMarkofFilth					= mod:NewYell(317544, nil, nil, nil, "YELL") --317158
local yellMarkofFilthFade				= mod:NewShortFadesYell(317544, nil, nil, nil, "YELL")
local specWarnEndlessflameofFilth       = mod:NewSpecialWarningDispel(317540, "MagicDispeller", nil, nil, 1, 2)

local LightningofFilthCast				= mod:NewCastTimer(1, 317549, nil, nil, nil, 2)
local PrimalHorrorCast					= mod:NewCastTimer(1.84, 317548, nil, nil, nil, 2) -- первобытный ужас
local CrushingBlowCast					= mod:NewCastTimer(2.5, 317541, nil, nil, nil, 2) -- Сокрушающий удар
local MarkofFilthBuff					= mod:NewBuffActiveTimer(5, 317544, nil, nil, nil, 2)

local timerLightningofFilth				= mod:NewCDTimer(15, 317549, nil, nil, nil, 3) -- Молния скверны
local timerPrimalHorror					= mod:NewCDTimer(30, 317548, nil, nil, nil, 4, nil, DBM_CORE_IMPORTANT_ICON, nil, 1)
local timerCrushingBlowCast				= mod:NewCDTimer(35, 317541, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerStrikingBlow					= mod:NewCDTimer(10, 317543, nil, "Tank|Healer", nil, 5, nil, DBM_CORE_TANK_ICON)
local timerMarkofFilth					= mod:NewCDTimer(19, 317544, nil, nil, nil, 4, nil, DBM_CORE_IMPORTANT_ICON)
local timerEndlessflameofFilth			= mod:NewCDTimer(18.5, 317540, nil, nil, nil, 4, nil, DBM_CORE_MAGIC_ICON)

mod:AddSetIconOption("SetIconMarkofFilthTargets", 317544, true, true, {7,8})
mod:AddBoolOption("AnnounceMarkofFilth", false)
mod:AddBoolOption("BossHealthFrame", true, "misc")

local MarkTargets = {}
mod.vb.MarkofFilthIcon = 8

function mod:OnCombatStart(delay)
	if mod:IsDifficulty("normal10") then
		timerStrikingBlow:Start(5-delay)
		timerLightningofFilth:Start(8-delay)
		timerMarkofFilth:Start(13-delay)
		timerPrimalHorror:Start(25-delay)
		timerCrushingBlowCast:Start(65-delay)
		if self.Options.BossHealthFrame then
			DBM.BossHealth:Show(L.name)
			DBM.BossHealth:AddBoss(84000, L.name)
		end
	end
end

function mod:OnCombatEnd(wipe)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 317549 then
		warnLightningofFilth:Show()
		LightningofFilthCast:Start()
		timerLightningofFilth:Start()
	elseif spellId == 317548 then
		specwarnPrimalHorror:Show()
		PrimalHorrorCast:Start()
		timerPrimalHorror:Start()
	elseif spellId == 317541 then
		CrushingBlowCast:Start()
		timerCrushingBlowCast:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 317543 then
		timerStrikingBlow:Start()
	elseif spellId == 317540 then
		specWarnEndlessflameofFilth:Show()
		timerEndlessflameofFilth:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 317544 then
		MarkTargets[#MarkTargets + 1] = args.destName
		MarkofFilthBuff:Start()
		if args:IsPlayer() then
			specWarnMarkofFilthRun:Show()
			timerMarkofFilth:Start()
			yellMarkofFilth:Yell()
			yellMarkofFilthFade:Countdown(spellId)
		end
		self:ScheduleMethod(0.1, "SetMarkIcons")
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 317544 then
		if self.Options.SetIconMarkofFilthTargets then
			self:SetIcon(args.destName, 0)
		end
	end
end

do
	local function sort_by_group(v1, v2)
		return DBM:GetRaidSubgroup(UnitName(v1)) < DBM:GetRaidSubgroup(UnitName(v2))
	end
	function mod:SetMarkIcons()
		table.sort(MarkTargets, sort_by_group)
		for i, v in ipairs(MarkTargets) do
			if mod.Options.AnnounceKor then
				if DBM:GetRaidRank() > 0 then
					SendChatMessage(L.MarkofFilthIcon:format(self.vb.MarkofFilthIcon, UnitName(v)), "RAID_WARNING")
				else
					SendChatMessage(L.MarkofFilthIcon:format(self.vb.MarkofFilthIcon, UnitName(v)), "RAID")
				end
			end
			if self.Options.SetIconMarkofFilthTargets then
				self:SetIcon(UnitName(v), self.vb.MarkofFilthIcon)
			end
			self.vb.MarkofFilthIcon = self.vb.MarkofFilthIcon - 1
		end
		if #MarkTargets >= 2 then
			warnMarkofFilth:Show(table.concat(MarkTargets, "<, >"))
			table.wipe(MarkTargets)
			self.vb.MarkofFilthIcon = 8
		end
	end
end