
--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 237 2022-11-15T18:58:49Z
    URL: http://www.wow-neighbours.com

    License:
        This program is free software; you can redistribute it and/or
        modify it under the terms of the GNU General Public License
        as published by the Free Software Foundation; either version 2
        of the License, or (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program(see GPL.txt); if not, write to the Free Software
        Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

    Note:
        This AddOn's source code is specifically designed to work with
        World of Warcraft's interpreted AddOn system.
        You have an implicit licence to use this AddOn with these facilities
        since that is it's designated purpose as per:
        http://www.fsf.org/licensing/licenses/gpl-faq.html#InterpreterIncompat
--]]

local Armory, _ = Armory, nil;

ArmoryOptionsModulePanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsModulePanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    self.Title:SetText(ARMORY_MODULES_TITLE);
    self.SubText:SetText(ARMORY_MODULES_SUBTEXT);
end

function ArmoryOptionsModulePanelMixin:GetID()
    return ARMORY_MODULES_LABEL;
end


ArmoryOptionsModuleTemplateMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsModuleTemplateMixin:GetKey()
    return nil;
end

function ArmoryOptionsModuleTemplateMixin:GetDefaultValue()
    return true;
end


ArmoryOptionsInventoryModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsInventoryModuleMixin:GetValue()
    return Armory:HasInventory();
end

function ArmoryOptionsInventoryModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:HasInventory(value);
end

function ArmoryOptionsInventoryModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(INVENTORY_TOOLTIP);
end

function ArmoryOptionsInventoryModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        for i = 1, #ArmoryInventoryContainers do
            Armory:SetContainer(ArmoryInventoryContainers[i]);
        end
    else
        Armory:ClearInventory();
    end

    Armory:Close();
end


ArmoryOptionsQuestLogModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsQuestLogModuleMixin:GetValue()
    return Armory:HasQuestLog();
end

function ArmoryOptionsQuestLogModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:HasQuestLog(value);
end

function ArmoryOptionsQuestLogModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(QUESTLOG_BUTTON);
end

function ArmoryOptionsQuestLogModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:UpdateQuests();
    else
        Armory:ClearQuests();
        Armory:ClearQuestHistory();
    end

    Armory:Close();
end


ArmoryOptionsSpellBookModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsSpellBookModuleMixin:GetValue()
    return Armory:HasSpellBook();
end

function ArmoryOptionsSpellBookModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:HasSpellBook(value);
end

function ArmoryOptionsSpellBookModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);

    self:SetLabel(SPELLBOOK_BUTTON);
end

function ArmoryOptionsSpellBookModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:SetSpells();
    else
        Armory:ClearSpells();
    end

    Armory:Close();
end


ArmoryOptionsTradeSkillsModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsTradeSkillsModuleMixin:GetValue()
    return Armory:HasTradeSkills();
end

function ArmoryOptionsTradeSkillsModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:HasTradeSkills(value);
end

function ArmoryOptionsTradeSkillsModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);

    self:SetLabel(TRADE_SKILLS);
end

function ArmoryOptionsTradeSkillsModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:UpdateProfessions();
    else
        Armory:ClearTradeSkills();
    end

    Armory:Close();
end


ArmoryOptionsSocialModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsSocialModuleMixin:GetValue()
    return Armory:HasSocial();
end

function ArmoryOptionsSocialModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:HasSocial(value);
end

function ArmoryOptionsSocialModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(SOCIAL_LABEL);
end

function ArmoryOptionsSocialModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:UpdateFriends();
        Armory:UpdateEvents();
    else
        Armory:ClearFriends();
        Armory:ClearEvents();
    end

    Armory:Close();
end


ArmoryOptionsSharingModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsSharingModuleMixin:GetValue()
    return Armory:HasDataSharing();
end

function ArmoryOptionsSharingModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:HasDataSharing(value);
end

function ArmoryOptionsSharingModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(ARMORY_SHARE_TITLE);
end


ArmoryOptionsPetsModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsPetsModuleMixin:GetValue()
    return Armory:PetsEnabled();
end

function ArmoryOptionsPetsModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:PetsEnabled(value);
end

function ArmoryOptionsPetsModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);

    self:SetLabel(PETS);
end

function ArmoryOptionsPetsModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        if ( HasPetUI() ) then
            ArmoryPetFrame_Update(1);
        end
    else
        Armory:ClearPets();
    end

    Armory:Close();
end


ArmoryOptionsTalentsModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsTalentsModuleMixin:GetValue()
    return Armory:TalentsEnabled();
end

function ArmoryOptionsTalentsModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:TalentsEnabled(value);
end

function ArmoryOptionsTalentsModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(TALENTS);
end

function ArmoryOptionsTalentsModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:SetTalents();
    else
        Armory:ClearTalents();
    end

    Armory:Close();
end


ArmoryOptionsPVPModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsPVPModuleMixin:GetValue()
    return Armory:PVPEnabled();
end

function ArmoryOptionsPVPModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:PVPEnabled(value);
end

function ArmoryOptionsPVPModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(PVP);
end

function ArmoryOptionsPVPModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        --Armory:UpdateArenaTeams();
        Armory:SetHonorTalents();
    else
        --Armory:ClearArenaTeams();
        Armory:ClearHonorTalents();
    end

    Armory:Close();
end


ArmoryOptionsReputationModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsReputationModuleMixin:GetValue()
    return Armory:ReputationEnabled();
end

function ArmoryOptionsReputationModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:ReputationEnabled(value);
end

function ArmoryOptionsReputationModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(REPUTATION);
end

function ArmoryOptionsReputationModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:UpdateFactions();
    else
        Armory:ClearFactions();
    end

    Armory:Close();
end


ArmoryOptionsRaidModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsRaidModuleMixin:GetValue()
    return Armory:RaidEnabled();
end

function ArmoryOptionsRaidModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:RaidEnabled(value);
end

function ArmoryOptionsRaidModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(RAID);
end

function ArmoryOptionsRaidModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:UpdateInstances();
        Armory:UpdateWorldBosses();
    else
        Armory:ClearInstances();
        Armory:ClearRaidFinder();
        Armory:ClearWorldBosses();
    end

    Armory:Close();
end


ArmoryOptionsCurrencyModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsCurrencyModuleMixin:GetValue()
    return Armory:CurrencyEnabled();
end

function ArmoryOptionsCurrencyModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:CurrencyEnabled(value);
end

function ArmoryOptionsCurrencyModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(CURRENCY);
end

function ArmoryOptionsCurrencyModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:UpdateCurrency();
    else
        Armory:ClearCurrency();
    end

    Armory:Close();
end


ArmoryOptionsBuffsModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsBuffsModuleMixin:GetValue()
    return Armory:BuffsEnabled();
end

function ArmoryOptionsBuffsModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:BuffsEnabled(value);
end

function ArmoryOptionsBuffsModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(BUFFOPTIONS_LABEL);
end

function ArmoryOptionsBuffsModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:SetBuffs("player");
        if ( HasPetUI() ) then
            Armory:SetBuffs("pet");
        end
    else
        Armory:ClearBuffs();
    end

    Armory:Close();
end


ArmoryOptionsAchievementsModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsAchievementsModuleMixin:GetValue()
    return Armory:HasAchievements();
end

function ArmoryOptionsAchievementsModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:HasAchievements(value);
end

function ArmoryOptionsAchievementsModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(ACHIEVEMENTS);
end

function ArmoryOptionsAchievementsModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:UpdateAchievements();
    else
        Armory:ClearAchievements();
        Armory:ClearStatistics();
    end

    Armory:Close();
end


ArmoryOptionsStatisticsModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsStatisticsModuleMixin:GetValue()
    return Armory:HasStatistics();
end

function ArmoryOptionsStatisticsModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:HasStatistics(value);
end

function ArmoryOptionsStatisticsModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(STATISTICS);

    self:SetupDependency(self:GetPanel().Achievements);
end

function ArmoryOptionsStatisticsModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( self:GetValue() ) then
        Armory:UpdateAchievements();
    else
        Armory:ClearAchievements();
        Armory:ClearStatistics();
    end

    Armory:Close();
end


ArmoryOptionsArtifactsModuleMixin = CreateFromMixins(ArmoryOptionsModuleTemplateMixin);

function ArmoryOptionsArtifactsModuleMixin:GetValue()
    return Armory:ArtifactsEnabled();
end

function ArmoryOptionsArtifactsModuleMixin:SetValue(value)
    ArmoryOptionsModuleTemplateMixin.SetValue(self, value);
    Armory:ArtifactsEnabled(value);
end

function ArmoryOptionsArtifactsModuleMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetLabel(ARTIFACT_POWER);
end

function ArmoryOptionsArtifactsModuleMixin:OnCommit()
    if ( not self:IsDirty() ) then
        return;
    end

    if ( not self:GetValue() ) then
        Armory:ClearArtifacts();
    end

    Armory:Close();
end
