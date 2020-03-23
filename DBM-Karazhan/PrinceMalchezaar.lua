local mod = DBM:NewMod("Prince", "DBM-Karazhan")
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 172 $"):sub(12, -3))
mod:SetCreatureID(15690)
mod:RegisterCombat("combat", 15690)

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_AURA_APPLIED",
    "UNIT_HEALTH",
	"SPELL_AURA_REMOVED"
)

local warningNovaCast			= mod:NewCastAnnounce(30852, 3)
local timerNovaCD				= mod:NewCDTimer(12, 305425)
local timerFlameCD			    = mod:NewCDTimer(30, 305433)
local specWarnFlame			    = mod:NewSpecialWarningYou(305433)
local warnFlame                 = mod:NewTargetAnnounce(305433, 3)
local timerCurseCD			    = mod:NewCDTimer(30, 305435)

local timerIceSpikeCD			= mod:NewCDTimer(10, 305443)

local timerCallofDeadCD			= mod:NewCDTimer(10, 305447)
local warnCallofDead            = mod:NewTargetAnnounce(305447, 3)
local specWarnCallofDead	    = mod:NewSpecialWarningYou(305447)

local warnNextPhaseSoon         = mod:NewAnnounce("WarnNextPhaseSoon", 1)
local phaseCounter = 1

local flameTargets = {}

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 15690, "Prince Malchezaar")
    if mod:IsDifficulty("normal10") then
    elseif mod:IsDifficulty("heroic10") then
        timerCurseCD:Start(20)
        timerNovaCD:Start()
        phaseCounter = 1
        table.wipe(flameTargets)
    end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 15690, "Prince Malchezaar", wipe)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(305425) then
		warningNovaCast:Show()
		timerNovaCD:Start()
    elseif args:IsSpellID(305443) then
		timerIceSpikeCD:Start()
    elseif args:IsSpellID(305447) then
		timerCallofDeadCD:Start()
        warnCallofDead:Show(args.destName)
        if args:IsPlayer() then
			specWarnCallofDead:Show()
		end
    end
end

function mod:SPELL_AURA_APPLIED(args)
    if args:IsSpellID(305433) then
        if args:IsPlayer() then
            self:PlaySound("impruved")              -- Иммолэйт импрувед!
        end
		timerFlameCD:Start(phaseCounter < 3 and 30 or 10)
        flameTargets[#flameTargets + 1] = args.destName
        if #flameTargets >=2 and phaseCounter < 3 then 
            warnFlame:Show(table.concat(flameTargets, "<, >"))
            table.wipe(flameTargets)
        elseif phaseCounter >= 3 then
            warnFlame:Show(args.destName)
            table.wipe(flameTargets)
        end
		if args:IsPlayer() then
			specWarnFlame:Show()
		end
    elseif args:IsSpellID(305435) then
		timerCurseCD:Start(phaseCounter == 2 and 30 or 20)
        if args:IsPlayer() then
            self:PlaySound("bomb_p")              -- CS 1.6 "bomb has been planted"
        end
	end
end

function mod:SPELL_AURA_REMOVED(args)
    if args:IsSpellID(305435) and args:IsPlayer() then
        self:PlaySound("bomb_d")             -- CS 1.6 "bomb has been defused"
	end
end

function mod:UNIT_HEALTH(uId)
	if phaseCounter == 1 and self:GetUnitCreatureId(uId) == 15690 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.8 then
		phaseCounter = phaseCounter + 1
		warnNextPhaseSoon:Show("2")
        timerFlameCD:Start(20)
        timerCurseCD:Start(20)
    elseif phaseCounter == 2 and self:GetUnitCreatureId(uId) == 15690 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.4 then
		phaseCounter = phaseCounter + 1
		warnNextPhaseSoon:Show(L.FlameWorld)
        timerCurseCD:Cancel()
        timerNovaCD:Cancel()
        timerFlameCD:Start(10)
        self:PlaySound("w_rice")
    elseif phaseCounter == 3 and self:GetUnitCreatureId(uId) == 15690 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.3 then
		phaseCounter = phaseCounter + 1
		warnNextPhaseSoon:Show(L.IceWorld)
        timerFlameCD:Cancel()
        timerIceSpikeCD:Start()
        timerCurseCD:Start(20)
        self:PlaySound("w_rice")
    elseif phaseCounter == 4 and self:GetUnitCreatureId(uId) == 15690 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.2 then
		phaseCounter = phaseCounter + 1
		warnNextPhaseSoon:Show(L.BlackForest)
        timerCurseCD:Cancel()
        timerIceSpikeCD:Cancel()
        timerCallofDeadCD:Start()
        self:PlaySound("w_rice")
    elseif phaseCounter == 5 and self:GetUnitCreatureId(uId) == 15690 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.1 then
		phaseCounter = phaseCounter + 1
		warnNextPhaseSoon:Show(L.LastPhase)
        timerCallofDeadCD:Cancel()
        timerFlameCD:Start()
    end
    
end
