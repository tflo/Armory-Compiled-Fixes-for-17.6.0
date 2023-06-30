--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 245 2023-05-14T11:21:26Z
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
local gearSetItems = {};

ARMORY_SLOTINFO = {
    INVTYPE_2HWEAPON = "MainHandSlot",
    INVTYPE_BODY = "ShirtSlot",
    INVTYPE_CHEST = "ChestSlot",
    INVTYPE_CLOAK = "BackSlot",
    INVTYPE_CROSSBOW = "MainHandSlot",
    INVTYPE_FEET = "FeetSlot",
    INVTYPE_FINGER = "Finger0Slot",
    INVTYPE_FINGER_OTHER = "Finger1Slot",
    INVTYPE_GUN = "MainHandSlot",
    INVTYPE_HAND = "HandsSlot",
    INVTYPE_HEAD = "HeadSlot",
    INVTYPE_HOLDABLE = "SecondaryHandSlot",
    INVTYPE_LEGS = "LegsSlot",
    INVTYPE_NECK = "NeckSlot",
    INVTYPE_RANGED = "MainHandSlot",
    INVTYPE_RANGEDRIGHT = "MainHandSlot",
    --INVTYPE_RELIC = "RangedSlot",
    INVTYPE_ROBE = "ChestSlot",
    INVTYPE_SHIELD = "SecondaryHandSlot",
    INVTYPE_SHOULDER = "ShoulderSlot",
    INVTYPE_TABARD = "TabardSlot",
    INVTYPE_THROWN = "MainHandSlot",
    INVTYPE_TRINKET = "Trinket0Slot",
    INVTYPE_TRINKET_OTHER = "Trinket1Slot",
    INVTYPE_WAIST = "WaistSlot",
    INVTYPE_WEAPON = "MainHandSlot",
    INVTYPE_WEAPON_OTHER = "SecondaryHandSlot",
    INVTYPE_WEAPONMAINHAND = "MainHandSlot",
    INVTYPE_WEAPONOFFHAND = "SecondaryHandSlot",
    INVTYPE_WRIST = "WristSlot",
    INVTYPE_WAND = "MainHandSlot",
};

ARMORY_SLOTID = {
    HeadSlot = 1,
    NeckSlot = 2,
    ShoulderSlot = 3,
    ShirtSlot = 4,
    ChestSlot = 5,
    WaistSlot = 6,
    LegsSlot = 7,
    FeetSlot = 8,
    WristSlot = 9,
    HandsSlot = 10,
    Finger0Slot = 11,
    Finger1Slot = 12,
    Trinket0Slot = 13,
    Trinket1Slot = 14,
    BackSlot = 15,
    MainHandSlot = 16,
    SecondaryHandSlot = 17,
    TabardSlot = 19
};

ARMORY_SLOT = {
    HEADSLOT, -- 1
    NECKSLOT, -- 2
    SHOULDERSLOT, -- 3
    SHIRTSLOT, -- 4
    CHESTSLOT, -- 5
    WAISTSLOT, -- 6
    LEGSSLOT, -- 7
    FEETSLOT, -- 8
    WRISTSLOT, -- 9
    HANDSSLOT, -- 10
    FINGER0SLOT, -- 11
    FINGER1SLOT, -- 12
    TRINKET0SLOT, -- 13
    TRINKET1SLOT, -- 14
    BACKSLOT, -- 15
    MAINHANDSLOT, -- 16
    SECONDARYHANDSLOT, -- 17
    RANGEDSLOT or "", -- 18
    TABARDSLOT  -- 19
};

local ANCHOR_SLOTINFO = {
    RIGHT = {point="TOPLEFT",    relativeTo="TOPRIGHT",   xFactor= 1, yFactor=-1, x= 0, y=6},
    LEFT  = {point="TOPRIGHT",   relativeTo="TOPLEFT",    xFactor=-1, yFactor=-1, x= 0, y=6},
    DOWN  = {point="TOPLEFT",    relativeTo="BOTTOMLEFT", xFactor= 1, yFactor=-1, x=-6, y=0},
    UP    = {point="BOTTOMLEFT", relativeTo="TOPLEFT",    xFactor= 1, yFactor= 1, x=-6, y=0}
};

ARMORY_PAPERDOLL_STATINFO = {

    -- General
    ["HEALTH"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetHealth(statFrame, unit); end
    },
    ["POWER"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetPower(statFrame, unit); end
    },
    ["ALTERNATEMANA"] = {
        -- Only appears for Druids when in shapeshift form
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetAlternateMana(statFrame, unit); end
    },
    ["ITEMLEVEL"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetItemLevel(statFrame, unit); end
    },
    ["MOVESPEED"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetMovementSpeed(statFrame, unit); end
    },
    ["CORRUPTION"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetCorruption(statFrame, unit); end
    },

    -- Base stats
    ["STRENGTH"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetStat(statFrame, unit, LE_UNIT_STAT_STRENGTH); end
    },
    ["AGILITY"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetStat(statFrame, unit, LE_UNIT_STAT_AGILITY); end
    },
    ["INTELLECT"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetStat(statFrame, unit, LE_UNIT_STAT_INTELLECT); end
    },
    ["STAMINA"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetStat(statFrame, unit, LE_UNIT_STAT_STAMINA); end
    },

    -- Enhancements
    ["CRITCHANCE"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetCritChance(statFrame, unit); end
    },
    ["HASTE"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetHaste(statFrame, unit); end
    },
    ["MASTERY"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetMastery(statFrame, unit); end
    },
    ["VERSATILITY"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetVersatility(statFrame, unit); end
    },
    ["LIFESTEAL"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetLifesteal(statFrame, unit); end
    },
    ["AVOIDANCE"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetAvoidance(statFrame, unit); end
    },
    ["SPEED"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetSpeed(statFrame, unit); end
    },

    -- Attack
    ["ATTACK_DAMAGE"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetDamage(statFrame, unit); end
    },
    ["ATTACK_AP"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetAttackPower(statFrame, unit); end
    },
    ["ATTACK_ATTACKSPEED"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetAttackSpeed(statFrame, unit); end
    },
    ["ENERGY_REGEN"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetEnergyRegen(statFrame, unit); end
    },
    ["RUNE_REGEN"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetRuneRegen(statFrame, unit); end
    },
    ["FOCUS_REGEN"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetFocusRegen(statFrame, unit); end
    },

    -- Spell
    ["SPELLPOWER"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetSpellPower(statFrame, unit); end
    },
    ["MANAREGEN"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetManaRegen(statFrame, unit); end
    },

    -- Defense
    ["ARMOR"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetArmor(statFrame, unit); end
    },
    ["DODGE"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetDodge(statFrame, unit); end
    },
    ["PARRY"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetParry(statFrame, unit); end
    },
    ["BLOCK"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetBlock(statFrame, unit); end
    },
    ["STAGGER"] = {
        updateFunc = function(statFrame, unit) ArmoryPaperDollFrame_SetStagger(statFrame, unit); end
    },
};

ARMORY_PAPERDOLL_STATCATEGORIES = {
    ["GENERAL"] = {
        id = 1,
        stats = {
            "HEALTH",
            "ALTERNATEMANA",  -- Druids when in bear/cat form and Mistweaver Monks
            "POWER",
            "ITEMLEVEL",
            "MOVESPEED",
            "CORRUPTION",
        }
    },

    ["ATTRIBUTES"] = {
        id = 2,
        stats = {
            "STRENGTH",
            "AGILITY",
            "INTELLECT",
            "STAMINA",
        }
    },

    ["ENHANCEMENTS"] = {
        id = 7,
        stats = {
            "CRITCHANCE",
            "HASTE",
            "MASTERY",
            "BONUS_ARMOR",
            "LIFESTEAL",
            "VERSATILITY",
            "AVOIDANCE",
            "SPEED",
        }
    },

    ["ATTACK"] = {
        id = 8,
        stats = {
            "ATTACK_DAMAGE",
            "ATTACK_AP",
            "ATTACK_ATTACKSPEED",
            "ENERGY_REGEN",
            "RUNE_REGEN",
            "FOCUS_REGEN",
        }
    },

    ["SPELL"] = {
        id = 5,
        stats = {
            "SPELLPOWER",
            "MANAREGEN",
        }
    },

    ["DEFENSE"] = {
        id = 6,
        stats = {
            "ARMOR",
            "DODGE",
            "PARRY",
            "BLOCK",
            "STAGGER",
        }
    },
};

ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS = {
    "GENERAL",
    "ATTRIBUTES",
    "ENHANCEMENTS",
    "ATTACK",
    "SPELL",
    "DEFENSE",
};

local MAX_ALTERNATE_SLOTS = 3;
local ALTERNATE_SLOT_SIZE = 40;
local NUM_GEARSETS_PER_ROW = 5;

local STRIPE_COLOR = {r=0.9, g=0.9, b=1};

local BreakUpLargeNumbers = BreakUpLargeNumbers;

function ArmoryPaperDollTalentFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_TALENT_UPDATE");
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
end

function ArmoryPaperDollTalentFrame_OnEvent(self, event, ...)
    if ( self:GetParent() == ArmoryPaperDollOverlayFrame ) then
        ArmoryPaperDollFrame_UpdateTalent(1);
    elseif ( Armory:CanHandleEvents() ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateTalent);
    end
end

function ArmoryPaperDollTradeSkillFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("SKILL_LINES_CHANGED");
    self:RegisterEvent("TRIAL_STATUS_UPDATE");
end

function ArmoryPaperDollTradeSkillFrame_OnEvent(self, event, ...)
    if ( self:GetParent() == ArmoryPaperDollOverlayFrame ) then
        ArmoryPaperDollFrame_UpdateSkills(1);
    elseif ( not Armory:CanHandleEvents() ) then
        return
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        if ( Armory.forceScan or not Armory:ProfessionsExists() ) then
            Armory:Execute(ArmoryPaperDollTradeSkillFrame_UpdateSkills);
        end
    elseif ( event == "SKILL_LINES_CHANGED" or event == "TRIAL_STATUS_UPDATE" ) then
        Armory:Execute(ArmoryPaperDollTradeSkillFrame_UpdateSkills);
    end
end

function ArmoryPaperDollTradeSkillFrame_UpdateSkills()
    Armory:UpdateProfessions();
    ArmoryPaperDollFrame_UpdateSkills();
end

function ArmoryPaperDollItemSlotButton_Update(button, itemId)
    local unit = "player";
    local count = 0;
    local link, quality, texture;

    if ( itemId ~= nil ) then
        if ( itemId ~= 0 ) then
            _, link, quality, _, _, _, _, _, _, texture = _G.GetItemInfo(itemId);
        end
        button.itemId = itemId;
    else
        link = Armory:GetInventoryItemLink(unit, button:GetID());
        quality = Armory:GetInventoryItemQuality(unit, button:GetID());
        texture = Armory:GetInventoryItemTexture(unit, button:GetID());
        count = Armory:GetInventoryItemCount(unit, button:GetID());
        button.itemId = nil;
    end

    if ( texture ) then
        SetItemButtonTexture(button, texture);
        SetItemButtonCount(button, count);
        button.hasItem = 1;
    else
        texture = button.backgroundTextureName;
        if ( button.checkRelic and Armory:UnitHasRelicSlot(unit) ) then
            texture = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Relic.blp";
        end
        SetItemButtonTexture(button, texture);
        SetItemButtonCount(button, 0);
        button.hasItem = nil;
    end

    SetItemButtonQuality(button, quality, button.itemId or link);

    Armory:SetInventoryItem("player", button:GetID(), true);
    button.link = link;
end

function ArmoryPaperDollItemSlotButton_OnLoad(self)
    local slotName = self:GetName();
    local id, textureName, checkRelic = GetInventorySlotInfo(strsub(slotName,7));
    self:SetID(id);
    local texture = _G[slotName.."IconTexture"];
    texture:SetTexture(textureName);
    self.backgroundTextureName = textureName;
    self.checkRelic = checkRelic;

    self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
end

function ArmoryPaperDollItemSlotButton_OnEnter(self)
    local hasItem;
    self.anchor = "ANCHOR_RIGHT";
    GameTooltip:SetOwner(self, self.anchor);
    if ( self.itemId == nil ) then
        if ( self:GetID() == 0 or (self:GetID() >= 16 and self:GetID() <= 18) ) then
            ArmoryAlternateSlotFrame_Show(self, "VERTICAL", "DOWN");
        elseif ( self:GetID() ~= 9 and self:GetID() >= 6 and self:GetID() <= 14 ) then
            self.anchor = "ANCHOR_LEFT";
            ArmoryAlternateSlotFrame_Show(self, "HORIZONTAL", "RIGHT");
            if ( ArmoryAlternateSlotFrame:IsShown() ) then
                GameTooltip:SetOwner(ArmoryAlternateSlotFrame, "ANCHOR_RIGHT", -6, -6);
            end
        else
            ArmoryAlternateSlotFrame_Show(self, "HORIZONTAL", "LEFT");
        end
        hasItem = Armory:SetInventoryItem("player", self:GetID());
    elseif ( self.itemId ~= 0 ) then
        local _, link = _G.GetItemInfo(self.itemId);
        Armory:SetInventoryItem("player", self:GetID(), nil, nil, link);
        hasItem = true;
    end
    if ( not hasItem ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        local text = _G[strupper(strsub(self:GetName(), 7))];
        if ( self.checkRelic and Armory:UnitHasRelicSlot("player") ) then
            text = RELICSLOT;
        end
        GameTooltip:SetText(text);
    end
end

function ArmoryPaperDollItemSlotButton_OnClick(self, button)
    if ( self.link ) then
        if ( button == "RightButton" and IsShiftKeyDown() ) then
            ArmoryArtifactFrame:ShowArtifact(self.link);
        elseif ( IsModifiedClick("CHATLINK") ) then
            HandleModifiedItemClick(self.link);
        end
    end
end

function ArmoryAttributesFramePlayerStatDropDown_OnLoad(self)
    ArmoryDropDownMenu_Initialize(self, ArmoryAttributesFramePlayerStatDropDown_Initialize);
    ArmoryDropDownMenu_SetSelectedValue(self, ARMORY_PLAYERSTAT_DROPDOWN_SELECTION);
    ArmoryDropDownMenu_SetWidth(self, 212);
    ArmoryDropDownMenu_JustifyText(self, "LEFT");
end

function ArmoryAttributesFramePlayerStatDropDown_Initialize()
    -- Setup buttons
    local info = ArmoryDropDownMenu_CreateInfo();
    local checked;
    for i = 1, getn(ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS) do
        if ( ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i] == ARMORY_PLAYERSTAT_DROPDOWN_SELECTION ) then
            checked = 1;
        else
            checked = nil;
        end
        info.text = _G["STAT_CATEGORY_"..ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i]];
        info.func = ArmoryAttributesFramePlayerStatDropDown_OnClick;
        info.value = ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i];
        info.checked = checked;
        info.owner = ARMORY_DROPDOWNMENU_OPEN_MENU;
        ArmoryDropDownMenu_AddButton(info);
    end
end

function ArmoryAttributesFramePlayerStatDropDown_OnClick(self)
    ArmoryDropDownMenu_SetSelectedValue(_G[self.owner], self.value);
    ARMORY_PLAYERSTAT_DROPDOWN_SELECTION = self.value;
    ArmoryPaperDollFrame_UpdateStatCategory(self.value);
end

function ArmoryPaperDollFrame_SetLevel()
    local unit = "player";
    local classDisplayName, class = Armory:UnitClass(unit);
    local classColorString = Armory:ClassColor(class, true);
    local level = Armory:UnitLevel(unit);
    local effectiveLevel = Armory:UnitEffectiveLevel(unit);
    if ( effectiveLevel ~= level ) then
        level = EFFECTIVE_LEVEL_FORMAT:format(effectiveLevel, level);
    end
    local text = format(PLAYER_LEVEL_NO_SPEC, level, classColorString, classDisplayName);
    local xp = Armory:GetXP();
    if ( xp ) then
        text = text.." ("..XP.." "..xp..")";
    end
    ArmoryLevelText:SetText(text);
end

function ArmoryPaperDollFrame_SetGuild()
    local guildName, title = Armory:GetGuildInfo("player");
    if ( guildName ) then
        ArmoryGuildText:Show();
        ArmoryGuildText:SetFormattedText(GUILD_TITLE_TEMPLATE, title, guildName);
    else
        ArmoryGuildText:Hide();
    end
end

function ArmoryPaperDollFrame_SetZone()
    local zoneName = Armory:GetZoneText();
    local subzoneName = Armory:GetSubZoneText();
    if ( subzoneName == zoneName ) then
        subzoneName = "";
    end

    -- backwards compatible...
    if ( zoneName ) then
        if ( subzoneName ~= "" ) then
            zoneName = zoneName..", "..subzoneName;
        end
        ArmoryZoneText:Show();
        ArmoryZoneText:SetText(zoneName);
    else
        ArmoryZoneText:Hide();
    end
end

function ArmoryGetEnemyDodgeChance(levelOffset)
    if ( levelOffset < 0 or levelOffset > 3 ) then
        return 0;
    end
    local chance = BASE_ENEMY_DODGE_CHANCE[levelOffset];
    local offhandChance = BASE_ENEMY_DODGE_CHANCE[levelOffset];
    local rangedChance = BASE_ENEMY_DODGE_CHANCE[levelOffset];
    local expertisePct, offhandExpertisePct, rangedExpertisePct = Armory:GetExpertise();
    chance = chance - expertisePct;
    offhandChance = offhandChance - offhandExpertisePct;
    rangedChance = rangedChance - rangedExpertisePct;
    if ( chance < 0 ) then
        chance = 0;
    elseif ( chance > 100 ) then
        chance = 100;
    end
    if ( offhandChance < 0 ) then
        offhandChance = 0;
    elseif ( offhandChance > 100 ) then
        offhandChance = 100;
    end
    if ( rangedChance < 0 ) then
        rangedChance = 0;
    elseif ( rangedChance > 100 ) then
        rangedChance = 100;
    end
    return chance, offhandChance, rangedChance;
end

function ArmoryGetEnemyParryChance(levelOffset)
    if ( levelOffset < 0 or levelOffset > 3 ) then
        return 0;
    end
    local chance = BASE_ENEMY_PARRY_CHANCE[levelOffset];
    local offhandChance = BASE_ENEMY_PARRY_CHANCE[levelOffset];
    local expertisePct, offhandExpertisePct = Armory:GetExpertise();
    local mainhandDodge = BASE_ENEMY_DODGE_CHANCE[levelOffset];
    local offhandDodge = BASE_ENEMY_DODGE_CHANCE[levelOffset];

    expertisePct = expertisePct - mainhandDodge;
    if ( expertisePct < 0 ) then
        expertisePct = 0;
    end
    chance = chance - expertisePct;
    if ( chance < 0 ) then
        chance = 0;
    elseif ( chance > 100 ) then
        chance = 100;
    end

    offhandExpertisePct = offhandExpertisePct - offhandDodge;
    if ( offhandExpertisePct < 0 ) then
        offhandExpertisePct = 0;
    end
    offhandChance = offhandChance - offhandExpertisePct;
    if ( offhandChance < 0 ) then
        offhandChance = 0;
    elseif ( offhandChance > 100 ) then
        offhandChance = 100;
    end
    return chance, offhandChance;
end

function ArmoryPaperDollFrame_SetHealth(statFrame, unit)
    local health = Armory:UnitHealthMax(unit) or 0;
    local healthText = BreakUpLargeNumbers(health);
    PaperDollFrame_SetLabelAndText(statFrame, HEALTH, healthText, false, health);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, HEALTH).." "..healthText..FONT_COLOR_CODE_CLOSE;
    if ( unit == "player" ) then
        statFrame.tooltip2 = STAT_HEALTH_TOOLTIP;
    elseif ( unit == "pet" ) then
        if ( not Armory:UnitHealthMax(unit) ) then
            statFrame:Hide();
            return;
        end
        statFrame.tooltip2 = STAT_HEALTH_PET_TOOLTIP;
    end
    statFrame:Show();
end

function ArmoryPaperDollFrame_SetPower(statFrame, unit)
    local powerType, powerToken = Armory:UnitPowerType(unit);
    local power = Armory:UnitPowerMax(unit) or 0;
    local powerText = BreakUpLargeNumbers(power);
    if ( powerType and powerToken and _G[powerToken] ) then
        PaperDollFrame_SetLabelAndText(statFrame, _G[powerToken], powerText, false, power);
        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, _G[powerToken]).." "..powerText..FONT_COLOR_CODE_CLOSE;
        statFrame.tooltip2 = _G["STAT_"..powerToken.."_TOOLTIP"];
        statFrame:Show();
    else
        statFrame:Hide();
    end
end

function ArmoryPaperDollFrame_SetAlternateMana(statFrame, unit)
    local _, class = Armory:UnitClass(unit);
    if ( class ~= "DRUID" and (class ~= "MONK" or Armory:GetSpecialization() ~= SPEC_MONK_MISTWEAVER) ) then
        statFrame:Hide();
        return;
    end
    local powerType, powerToken = Armory:UnitPowerType(unit);
    if ( powerToken == "MANA" ) then
        statFrame:Hide();
        return;
    end

    local power = Armory:UnitPowerMax(unit, 0);
    local powerText = BreakUpLargeNumbers(power);
    PaperDollFrame_SetLabelAndText(statFrame, MANA, powerText, false, power);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MANA).." "..powerText..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = _G["STAT_MANA_TOOLTIP"];
    statFrame:Show();
end

function ArmoryPaperDollFrame_SetStat(statFrame, unit, statIndex)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local stat, effectiveStat, posBuff, negBuff = Armory:UnitStat(unit, statIndex);

    local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat);
    -- Set the tooltip text
    local statName = _G["SPELL_STAT"..statIndex.."_NAME"];
    local tooltipText = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName).." ";

    if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
        statFrame.tooltip = tooltipText..effectiveStatDisplay..FONT_COLOR_CODE_CLOSE;
    else
        tooltipText = tooltipText..effectiveStatDisplay;
        if ( posBuff > 0 or negBuff < 0 ) then
            tooltipText = tooltipText.." ("..BreakUpLargeNumbers(stat - posBuff - negBuff)..FONT_COLOR_CODE_CLOSE;
        end
        if ( posBuff > 0 ) then
            tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..BreakUpLargeNumbers(posBuff)..FONT_COLOR_CODE_CLOSE;
        end
        if ( negBuff < 0 ) then
            tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..BreakUpLargeNumbers(negBuff)..FONT_COLOR_CODE_CLOSE;
        end
        if ( posBuff > 0 or negBuff < 0 ) then
            tooltipText = tooltipText..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
        end
        statFrame.tooltip = tooltipText;

        -- If there are any negative buffs then show the main number in red even if there are
        -- positive buffs. Otherwise show in green.
        if ( negBuff < 0 and not Armory:GetPVPGearStatRules() ) then
            effectiveStatDisplay = RED_FONT_COLOR_CODE..effectiveStatDisplay..FONT_COLOR_CODE_CLOSE;
        end
    end
    PaperDollFrame_SetLabelAndText(statFrame, statName, effectiveStatDisplay, false, effectiveStat);
    statFrame.tooltip2 = _G["DEFAULT_STAT"..statIndex.."_TOOLTIP"];

    if ( unit == "player" ) then
        local _, unitClass = Armory:UnitClass("player");
        unitClass = strupper(unitClass);

        local primaryStat, spec;
        spec = Armory:GetSpecialization();
        local role = Armory:GetSpecializationRole(spec);
        if ( spec ) then
            primaryStat = select(6, Armory:GetSpecializationInfo(spec, nil, nil, nil, Armory:UnitSex("player")));
        end
        -- Strength
        if ( statIndex == LE_UNIT_STAT_STRENGTH ) then
            local attackPower = Armory:GetAttackPowerForStat(statIndex, effectiveStat);
            if ( Armory:HasAPEffectsSpellPower() ) then
                statFrame.tooltip2 = STAT_TOOLTIP_BONUS_AP_SP;
            end
            if ( not primaryStat or primaryStat == LE_UNIT_STAT_STRENGTH ) then
                statFrame.tooltip2 = format(statFrame.tooltip2, BreakUpLargeNumbers(attackPower));
                if ( role == "TANK" ) then
                    local increasedParryChance = Armory:GetParryChanceFromAttribute() or 0;
                    if ( increasedParryChance > 0 ) then
                        statFrame.tooltip2 = statFrame.tooltip2.."|n|n"..format(CR_PARRY_BASE_STAT_TOOLTIP, increasedParryChance);
                    end
                end
            else
                statFrame.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
            end
        -- Agility
        elseif ( statIndex == LE_UNIT_STAT_AGILITY ) then
            local attackPower = Armory:GetAttackPowerForStat(statIndex, effectiveStat);
               local tooltip = STAT_TOOLTIP_BONUS_AP;
            if ( Armory:HasAPEffectsSpellPower() ) then
                tooltip = STAT_TOOLTIP_BONUS_AP_SP;
            end
            if ( not primaryStat or primaryStat == LE_UNIT_STAT_AGILITY ) then
                statFrame.tooltip2 = format(tooltip, BreakUpLargeNumbers(attackPower));
                if ( role == "TANK" ) then
                    local increasedDodgeChance = Armory:GetDodgeChanceFromAttribute() or 0;
                    if ( increasedDodgeChance > 0 ) then
                        statFrame.tooltip2 = statFrame.tooltip2.."|n|n"..format(CR_DODGE_BASE_STAT_TOOLTIP, increasedDodgeChance);
                    end
                end
            else
                statFrame.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
            end
        -- Stamina
        elseif ( statIndex == LE_UNIT_STAT_STAMINA ) then
            statFrame.tooltip2 = format(statFrame.tooltip2, BreakUpLargeNumbers(((effectiveStat * Armory:UnitHPPerStamina("player"))) * Armory:GetUnitMaxHealthModifier("player")));
        -- Intellect
        elseif ( statIndex == LE_UNIT_STAT_INTELLECT ) then
            if ( Armory:UnitHasMana("player") ) then
                if ( Armory:HasAPEffectsSpellPower() ) then
                    statFrame.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
                else
                    local result, druid = Armory:HasSPEffectsAttackPower();
                    if ( result and druid ) then
                        statFrame.tooltip2 = format(STAT_TOOLTIP_SP_AP_DRUID, max(0, effectiveStat), max(0, effectiveStat));
                    elseif ( result ) then
                        statFrame.tooltip2 = format(STAT_TOOLTIP_BONUS_AP_SP, max(0, effectiveStat));
                    elseif ( not primaryStat or primaryStat == LE_UNIT_STAT_INTELLECT ) then
                        statFrame.tooltip2 = format(statFrame.tooltip2, max(0, effectiveStat));
                    else
                        statFrame.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
                    end
                end
            else
                statFrame.tooltip2 = STAT_NO_BENEFIT_TOOLTIP;
            end
        end
    end
    statFrame:Show();
end

function ArmoryPaperDollFrame_SetArmor(statFrame, unit)
    local baselineArmor, effectiveArmor, armor, bonusArmor = Armory:UnitArmor(unit);
    local level = Armory:UnitEffectiveLevel(unit);

    if ( level and effectiveArmor ) then
        PaperDollFrame_SetLabelAndText(statFrame, STAT_ARMOR, BreakUpLargeNumbers(effectiveArmor), false, effectiveArmor);
        local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, level);
        local armorReductionAgainstTarget = PaperDollFrame_GetArmorReductionAgainstTarget(effectiveArmor);

        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ARMOR).." "..BreakUpLargeNumbers(effectiveArmor)..FONT_COLOR_CODE_CLOSE;
        statFrame.tooltip2 = format(STAT_ARMOR_TOOLTIP, armorReduction);
        if ( armorReductionAgainstTarget ) then
            statFrame.tooltip3 = format(STAT_ARMOR_TARGET_TOOLTIP, armorReductionAgainstTarget);
        else
            statFrame.tooltip3 = nil;
        end
        statFrame:Show();
   else
        statFrame:Hide();
   end
end

function ArmoryPaperDollFrame_SetStagger(statFrame, unit)
    local stagger, staggerAgainstTarget = Armory:GetStaggerPercentage(unit);

    if ( stagger ) then
        PaperDollFrame_SetLabelAndText(statFrame, STAT_STAGGER, BreakUpLargeNumbers(stagger), true, stagger);

        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAGGER).." "..string.format("%.2F%%",stagger)..FONT_COLOR_CODE_CLOSE;
        statFrame.tooltip2 = format(STAT_STAGGER_TOOLTIP, stagger);
        if ( staggerAgainstTarget ) then
            statFrame.tooltip3 = format(STAT_STAGGER_TARGET_TOOLTIP, staggerAgainstTarget);
        else
            statFrame.tooltip3 = nil;
        end

        statFrame:Show();
    else
        statFrame:Hide();
   end
end

function ArmoryPaperDollFrame_SetDodge(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local chance = Armory:GetDodgeChance();
    PaperDollFrame_SetLabelAndText(statFrame, STAT_DODGE, chance, true, chance);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_DODGE_TOOLTIP, Armory:GetCombatRating(CR_DODGE), Armory:GetCombatRatingBonus(CR_DODGE));
    statFrame:Show();
end

function ArmoryPaperDollFrame_SetBlock(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local chance = Armory:GetBlockChance();
    PaperDollFrame_SetLabelAndText(statFrame, STAT_BLOCK, chance, true, chance);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE;

    local shieldBlockArmor = Armory:GetShieldBlock();
    local blockArmorReduction = PaperDollFrame_GetArmorReduction(shieldBlockArmor, Armory:UnitEffectiveLevel(unit));
    local blockArmorReductionAgainstTarget = PaperDollFrame_GetArmorReductionAgainstTarget(shieldBlockArmor);

    statFrame.tooltip2 = CR_BLOCK_TOOLTIP:format(blockArmorReduction);
    if (blockArmorReductionAgainstTarget) then
        statFrame.tooltip3 = format(STAT_BLOCK_TARGET_TOOLTIP, blockArmorReductionAgainstTarget);
    else
        statFrame.tooltip3 = nil;
    end
    statFrame:Show();
end

function ArmoryPaperDollFrame_SetParry(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local chance = Armory:GetParryChance();
    PaperDollFrame_SetLabelAndText(statFrame, STAT_PARRY, chance, true, chance);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, Armory:GetCombatRating(CR_PARRY), Armory:GetCombatRatingBonus(CR_PARRY));
    statFrame:Show();
end

function ArmoryPaperDollFrame_SetResilience(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local resilienceRating = BreakUpLargeNumbers(Armory:GetCombatRating(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN));
    local ratingBonus = Armory:GetCombatRatingBonus(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN);
    local damageReduction = ratingBonus + GetModResilienceDamageReduction();
    PaperDollFrame_SetLabelAndText(statFrame, STAT_RESILIENCE, damageReduction, true, damageReduction);

    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_RESILIENCE).." "..format("%.2F%%", damageReduction)..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = RESILIENCE_TOOLTIP .. format(STAT_RESILIENCE_BASE_TOOLTIP, resilienceRating, ratingBonus);
    statFrame:Show();
end

local function GetAppropriateDamage(unit)
    if ( Armory:IsRangedWeapon() ) then
        local attackTime, minDamage, maxDamage, bonusPos, bonusNeg, percent = Armory:UnitRangedDamage(unit);
        return minDamage, maxDamage, nil, nil, 0, 0, percent;
    else
        return Armory:UnitDamage(unit);
    end
end

function ArmoryPaperDollFrame_SetDamage(statFrame, unit)
    local speed, offhandSpeed = Armory:UnitAttackSpeed(unit);
    local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = GetAppropriateDamage(unit);
    if ( not minDamage or percent == 0 ) then
        statFrame:Hide();
        return;
    end

    -- remove decimal points for display values
    local displayMin = max(floor(minDamage), 1);
    local displayMinLarge = BreakUpLargeNumbers(displayMin);
    local displayMax = max(ceil(maxDamage), 1);
    local displayMaxLarge = BreakUpLargeNumbers(displayMax);

    -- calculate base damage
    minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
    maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

    local baseDamage = (minDamage + maxDamage) * 0.5;
    local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
    local totalBonus = (fullDamage - baseDamage);
    -- set tooltip text with base damage
    local damageTooltip = BreakUpLargeNumbers(max(floor(minDamage), 1)).." - "..BreakUpLargeNumbers(max(ceil(maxDamage), 1));

    local colorPos = "|cff20ff20";
    local colorNeg = "|cffff2020";

    -- epsilon check
    if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
        totalBonus = 0.0;
    end

    local value;
    if ( totalBonus == 0 ) then
        if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
            value = displayMinLarge.." - "..displayMaxLarge;
        else
            value = displayMinLarge.."-"..displayMaxLarge;
        end
    else
        -- set bonus color and display
        local color;
        if ( totalBonus > 0 ) then
            color = colorPos;
        else
            color = colorNeg;
        end
        if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
            value = color..displayMinLarge.." - "..displayMaxLarge.."|r";
        else
            value = color..displayMinLarge.."-"..displayMaxLarge.."|r";
        end
        if ( physicalBonusPos > 0 ) then
            damageTooltip = damageTooltip..colorPos.." +"..physicalBonusPos.."|r";
        end
        if ( physicalBonusNeg < 0 ) then
            damageTooltip = damageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
        end
        if ( percent > 1 ) then
            damageTooltip = damageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
        elseif ( percent < 1 ) then
            damageTooltip = damageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
        end

    end
    PaperDollFrame_SetLabelAndText(statFrame, DAMAGE, value, false, displayMax);
    statFrame.damage = damageTooltip;
    statFrame.attackSpeed = speed;
    statFrame.unit = unit;

    -- If there's an offhand speed then add the offhand info to the tooltip
    if ( offhandSpeed and minOffHandDamage and maxOffHandDamage ) then
        minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
        maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

        local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
        local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
        local offhandDamageTooltip = BreakUpLargeNumbers(max(floor(minOffHandDamage), 1)).." - "..BreakUpLargeNumbers(max(ceil(maxOffHandDamage), 1));
        if ( physicalBonusPos > 0 ) then
            offhandDamageTooltip = offhandDamageTooltip..colorPos.." +"..physicalBonusPos.."|r";
        end
        if ( physicalBonusNeg < 0 ) then
            offhandDamageTooltip = offhandDamageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
        end
        if ( percent > 1 ) then
            offhandDamageTooltip = offhandDamageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
        elseif ( percent < 1 ) then
            offhandDamageTooltip = offhandDamageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
        end
        statFrame.offhandDamage = offhandDamageTooltip;
        statFrame.offhandAttackSpeed = offhandSpeed;
    else
        statFrame.offhandAttackSpeed = nil;
    end

    statFrame:SetScript("OnEnter", CharacterDamageFrame_OnEnter);

    statFrame:Show();
end

function ArmoryPaperDollFrame_SetAttackSpeed(statFrame, unit)
    local meleeHaste = Armory:GetMeleeHaste();
    local speed, offhandSpeed = Armory:UnitAttackSpeed(unit);
    if ( speed ) then
        -- Why format? BreakUpLargeNumbers already uses .2F for fractions.
        -- BreakUpLargeNumbers will fail for European decimal format
        local displaySpeed; --  = format("%.2F", speed);
        if ( offhandSpeed ) then
            offhandSpeed = format("%.2F", offhandSpeed);
        end
        if ( offhandSpeed ) then
            displaySpeed = BreakUpLargeNumbers(speed).." / "..offhandSpeed;
        else
            displaySpeed = BreakUpLargeNumbers(speed);
        end
        PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, displaySpeed, false, speed);

        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED).." "..displaySpeed..FONT_COLOR_CODE_CLOSE;
        statFrame.tooltip2 = format(STAT_ATTACK_SPEED_BASE_TOOLTIP, BreakUpLargeNumbers(meleeHaste));

        statFrame:Show();
    else
        statFrame:Hide();
    end
end

function ArmoryPaperDollFrame_SetAttackPower(statFrame, unit)
    local base, posBuff, negBuff;

    local rangedWeapon = Armory:IsRangedWeapon();

    local tag, tooltip;
    if ( rangedWeapon ) then
        base, posBuff, negBuff = Armory:UnitRangedAttackPower(unit);
        tag, tooltip = RANGED_ATTACK_POWER, RANGED_ATTACK_POWER_TOOLTIP;
    else
         base, posBuff, negBuff = Armory:UnitAttackPower(unit);
         tag, tooltip = MELEE_ATTACK_POWER, MELEE_ATTACK_POWER_TOOLTIP;
    end

    if ( base ) then
        local damageBonus = BreakUpLargeNumbers(max((base + posBuff + negBuff), 0) / ATTACK_POWER_MAGIC_NUMBER);
        local spellPower = 0;
        local value, valueText, tooltipText;
        if ( Armory:GetOverrideAPBySpellPower() ~= nil ) then
            local holySchool = 2;
            -- Start at 2 to skip physical damage
            spellPower = Armory:GetSpellBonusDamage(holySchool);
            for i=(holySchool+1), MAX_SPELL_SCHOOLS do
                spellPower = min(spellPower, Armory:GetSpellBonusDamage(i));
            end
            spellPower = min(spellPower, Armory:GetSpellBonusHealing()) * Armory:GetOverrideAPBySpellPower();

            value = spellPower;
            valueText, tooltipText = ArmoryPaperDollFormatStat(tag, spellPower, 0, 0);
            damageBonus = BreakUpLargeNumbers(spellPower / ATTACK_POWER_MAGIC_NUMBER);
        else
            value = base;
            valueText, tooltipText = ArmoryPaperDollFormatStat(tag, base, posBuff, negBuff);
        end
        PaperDollFrame_SetLabelAndText(statFrame, STAT_ATTACK_POWER, valueText, false, value);
        statFrame.tooltip = tooltipText;

        local effectiveAP = max(0, base + posBuff + negBuff);
        if ( Armory:GetOverrideSpellPowerByAP() ~= nil ) then
            statFrame.tooltip2 = format(MELEE_ATTACK_POWER_SPELL_POWER_TOOLTIP, damageBonus, BreakUpLargeNumbers(effectiveAP * Armory:GetOverrideSpellPowerByAP() + 0.5));
        else
            statFrame.tooltip2 = format(tooltip, damageBonus);
        end

        statFrame:Show();
    else
        statFrame:Hide();
    end
end

function ArmoryPaperDollFrame_SetSpellPower(statFrame, unit)
    local minModifier = 0;

    if ( unit == "player" ) then
        local holySchool = 2;
        -- Start at 2 to skip physical damage
        minModifier = GetSpellBonusDamage(holySchool);

        if ( statFrame.bonusDamage ) then
            table.wipe(statFrame.bonusDamage);
        else
            statFrame.bonusDamage = {};
        end
        statFrame.bonusDamage[holySchool] = minModifier;
        for i = (holySchool + 1), MAX_SPELL_SCHOOLS do
            local bonusDamage = Armory:GetSpellBonusDamage(i);
            minModifier = min(minModifier, bonusDamage);
            statFrame.bonusDamage[i] = bonusDamage;
        end
    elseif ( unit == "pet" ) then
        minModifier = Armory:GetPetSpellBonusDamage();
        statFrame.bonusDamage = nil;
        if ( not minModifier ) then
            statFrame:Hide();
            return;
        end
    end

    PaperDollFrame_SetLabelAndText(statFrame, STAT_SPELLPOWER, BreakUpLargeNumbers(minModifier), false, minModifier);
    statFrame.tooltip = STAT_SPELLPOWER;
    statFrame.tooltip2 = STAT_SPELLPOWER_TOOLTIP;

    statFrame.minModifier = minModifier;
    statFrame.unit = unit;
    statFrame:SetScript("OnEnter", ArmoryCharacterSpellBonusDamage_OnEnter);
    statFrame:Show();
end

function ArmoryPaperDollFrame_SetCritChance(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local rating;
    local spellCrit, rangedCrit, meleeCrit;
    local critChance;

    -- Start at 2 to skip physical damage
    local holySchool = 2;
    local minCrit = Armory:GetSpellCritChance(holySchool);
    statFrame.spellCrit = {};
    statFrame.spellCrit[holySchool] = minCrit;
    local spellCrit;
    for i=(holySchool+1), MAX_SPELL_SCHOOLS do
        spellCrit = Armory:GetSpellCritChance(i);
        minCrit = min(minCrit, spellCrit);
        statFrame.spellCrit[i] = spellCrit;
    end
    spellCrit = minCrit
    rangedCrit = Armory:GetRangedCritChance();
    meleeCrit = Armory:GetCritChance();

    if ( spellCrit >= rangedCrit and spellCrit >= meleeCrit ) then
        critChance = spellCrit;
        rating = CR_CRIT_SPELL;
    elseif ( rangedCrit >= meleeCrit ) then
        critChance = rangedCrit;
        rating = CR_CRIT_RANGED;
    else
        critChance = meleeCrit;
        rating = CR_CRIT_MELEE;
    end

    PaperDollFrame_SetLabelAndText(statFrame, STAT_CRITICAL_STRIKE, critChance, true, critChance);

    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_CRITICAL_STRIKE)..FONT_COLOR_CODE_CLOSE;
    local extraCritChance = Armory:GetCombatRatingBonus(rating);
    local extraCritRating = Armory:GetCombatRating(rating);
    if ( Armory:GetCritChanceProvidesParryEffect() ) then
        statFrame.tooltip2 = format(CR_CRIT_PARRY_RATING_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance, Armory:GetCombatRatingBonusForCombatRatingValue(CR_PARRY, extraCritRating));
    else
        statFrame.tooltip2 = format(CR_CRIT_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance);
    end
    statFrame:Show();
end

function ArmoryPaperDollFrame_SetEnergyRegen(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local powerType, powerToken = Armory:UnitPowerType(unit);
    if ( powerToken ~= "ENERGY" ) then
        statFrame:Hide();
        return;
    end

    local regenRate = Armory:GetPowerRegen();
    local regenRateText = BreakUpLargeNumbers(regenRate);
    PaperDollFrame_SetLabelAndText(statFrame, STAT_ENERGY_REGEN, regenRateText, false, regenRate);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_ENERGY_REGEN).." "..regenRateText..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = STAT_ENERGY_REGEN_TOOLTIP;
    statFrame:Show();
end

function ArmoryPaperDollFrame_SetFocusRegen(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local powerType, powerToken = Armory:UnitPowerType(unit);
    if ( powerToken ~= "FOCUS" ) then
        statFrame:Hide();
        return;
    end

    local regenRate = Armory:GetPowerRegen();
    local regenRateText = BreakUpLargeNumbers(regenRate);
    PaperDollFrame_SetLabelAndText(statFrame, STAT_FOCUS_REGEN, regenRateText, false, regenRate);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_FOCUS_REGEN).." "..regenRateText..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = STAT_FOCUS_REGEN_TOOLTIP;
    statFrame:Show();
end

function ArmoryPaperDollFrame_SetRuneRegen(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local _, class = Armory:UnitClass(unit);
    if ( class ~= "DEATHKNIGHT" ) then
        statFrame:Hide();
        return;
    end

    -- Note: change ArmoryLookup if not 1
    for i = 1, 6 do
        local  _, regenRate = Armory:GetRuneCooldown(i); -- Assuming they are all the same for now
        if ( regenRate ) then
            local regenRateText = format(STAT_RUNE_REGEN_FORMAT, regenRate);
            PaperDollFrame_SetLabelAndText(statFrame, STAT_RUNE_REGEN, regenRateText, false, regenRate);
            statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_RUNE_REGEN).." "..regenRateText..FONT_COLOR_CODE_CLOSE;
            statFrame.tooltip2 = STAT_RUNE_REGEN_TOOLTIP;
            statFrame:Show();
            return;
        end
    end
end

function ArmoryPaperDollFrame_SetHaste(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local haste = Armory:GetHaste();
    local rating = CR_HASTE_MELEE;

    local hasteFormatString;
    if ( haste < 0 and not Armory:GetPVPGearStatRules() ) then
        hasteFormatString = RED_FONT_COLOR_CODE.."%s"..FONT_COLOR_CODE_CLOSE;
    else
        hasteFormatString = "%s";
    end
    PaperDollFrame_SetLabelAndText(statFrame, STAT_HASTE, format(hasteFormatString, format("%d%%", haste + 0.5)), false, haste);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_HASTE)..FONT_COLOR_CODE_CLOSE;

    local _, class = Armory:UnitClass(unit);
    statFrame.tooltip2 = _G["STAT_HASTE_"..class.."_TOOLTIP"];
    if ( not statFrame.tooltip2 ) then
        statFrame.tooltip2 = STAT_HASTE_TOOLTIP;
    end
    statFrame.tooltip2 = statFrame.tooltip2 .. format(STAT_HASTE_BASE_TOOLTIP, BreakUpLargeNumbers(Armory:GetCombatRating(rating)), Armory:GetCombatRatingBonus(rating));

    statFrame:Show();
end

function ArmoryPaperDollFrame_SetManaRegen(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    if ( not Armory:UnitHasMana(unit) ) then
        PaperDollFrame_SetLabelAndText(statFrame, MANA_REGEN, NOT_APPLICABLE, false, 0);
        statFrame.tooltip = nil;
        return;
    end

    local base, combat = Armory:GetManaRegen();
    -- All mana regen stats are displayed as mana/5 sec.
    base = floor(base * 5.0);
    combat = floor(combat * 5.0);
    local baseText = BreakUpLargeNumbers(base);
    local combatText = BreakUpLargeNumbers(combat);

    -- Combat mana regen is most important to the player, so we display it as the main value
    PaperDollFrame_SetLabelAndText(statFrame, MANA_REGEN, combatText, false, combat);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MANA_REGEN) .. " " .. combatText .. FONT_COLOR_CODE_CLOSE;
    -- Base (out of combat) regen is displayed only in the subtext of the tooltip
    statFrame.tooltip2 = format(MANA_REGEN_TOOLTIP, baseText);
    statFrame:Show();
end

function ArmoryMastery_OnEnter(statFrame)
    GameTooltip:SetOwner(statFrame, "ANCHOR_RIGHT");

    local _, class = Armory:UnitClass("player");
    local mastery, bonusCoeff = Armory:GetMasteryEffect();
    local masteryBonus = Armory:GetCombatRatingBonus(CR_MASTERY) * bonusCoeff;

    local primaryTalentTree = Armory:GetSpecialization();
    if ( primaryTalentTree ) then
        local masterySpell, masterySpell2 = Armory:GetSpecializationMasterySpells(primaryTalentTree);
        if ( masterySpell ) then
            GameTooltip:AppendInfo("GetSpellByID", masterySpell);
        end
        if ( masterySpell2 ) then
            GameTooltip:AppendInfoWithSpacer("GetSpellByID", masterySpell2);
        end
        GameTooltip:AddLine(" ");
        GameTooltip:AddLine(format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(Armory:GetCombatRating(CR_MASTERY)), masteryBonus), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
    else
        GameTooltip:AddLine(format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(Armory:GetCombatRating(CR_MASTERY)), masteryBonus), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
        GameTooltip:AddLine(" ");
        GameTooltip:AddLine(STAT_MASTERY_TOOLTIP_NO_TALENT_SPEC, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, true);
    end
    GameTooltip:Show();
end

function ArmoryPaperDollFrame_SetMastery(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local mastery = Armory:GetMasteryEffect();
    PaperDollFrame_SetLabelAndText(statFrame, STAT_MASTERY, mastery, true, mastery);

    statFrame:SetScript("OnEnter", ArmoryMastery_OnEnter);
    statFrame:Show();
end

-- Task 68016: Speed increases run speed
function ArmoryPaperDollFrame_SetSpeed(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local speed = Armory:GetSpeed();
    PaperDollFrame_SetLabelAndText(statFrame, STAT_SPEED, speed, true, speed);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_SPEED) .. " " .. format("%.2F%%", speed) .. FONT_COLOR_CODE_CLOSE;

    statFrame.tooltip2 = format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(Armory:GetCombatRating(CR_SPEED)), Armory:GetCombatRatingBonus(CR_SPEED));

    statFrame:Show();
end

-- Task 68016: Lifesteal returns a portion of all damage done as health
function ArmoryPaperDollFrame_SetLifesteal(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local lifesteal = Armory:GetLifesteal();
    PaperDollFrame_SetLabelAndText(statFrame, STAT_LIFESTEAL, lifesteal, true, lifesteal);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_LIFESTEAL) .. " " .. format("%.2F%%", lifesteal) .. FONT_COLOR_CODE_CLOSE;

    statFrame.tooltip2 = format(CR_LIFESTEAL_TOOLTIP, BreakUpLargeNumbers(Armory:GetCombatRating(CR_LIFESTEAL)), Armory:GetCombatRatingBonus(CR_LIFESTEAL));

    statFrame:Show();
end

-- Task 68016: Avoidance reduces AoE damage taken
function ArmoryPaperDollFrame_SetAvoidance(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local avoidance = Armory:GetAvoidance();
    PaperDollFrame_SetLabelAndText(statFrame, STAT_AVOIDANCE, avoidance, true, avoidance);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_AVOIDANCE) .. " " .. format("%.2F%%", avoidance) .. FONT_COLOR_CODE_CLOSE;

    statFrame.tooltip2 = format(CR_AVOIDANCE_TOOLTIP, BreakUpLargeNumbers(Armory:GetCombatRating(CR_AVOIDANCE)), Armory:GetCombatRatingBonus(CR_AVOIDANCE));

    statFrame:Show();
end

function ArmoryPaperDollFrame_SetVersatility(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local versatility = Armory:GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
    local versatilityDamageBonus = Armory:GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + Armory:GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
    local versatilityDamageTakenReduction = Armory:GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) + Armory:GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN);
    PaperDollFrame_SetLabelAndText(statFrame, STAT_VERSATILITY, versatilityDamageBonus, true, versatilityDamageBonus);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_VERSATILITY)..FONT_COLOR_CODE_CLOSE;

    statFrame.tooltip2 = format(CR_VERSATILITY_TOOLTIP, versatilityDamageBonus, versatilityDamageTakenReduction, BreakUpLargeNumbers(versatility), versatilityDamageBonus, versatilityDamageTakenReduction);

    statFrame:Show();
end

function ArmoryPaperDollFrame_SetItemLevel(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvP = Armory:GetAverageItemLevel();
    local minItemLevel = Armory:GetMinItemLevel();

    local displayItemLevel = math.max(minItemLevel or 0, avgItemLevelEquipped);

    if ( avgItemLevel ) then
        displayItemLevel = floor(displayItemLevel);
        avgItemLevel = floor(avgItemLevel);
        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_AVERAGE_ITEM_LEVEL).." "..avgItemLevel;
        if ( avgItemLevelEquipped ) then
            PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, displayItemLevel, false, displayItemLevel);
            if ( displayItemLevel ~= avgItemLevel ) then
                statFrame.tooltip = statFrame.tooltip .. "  " .. format(STAT_AVERAGE_ITEM_LEVEL_EQUIPPED, avgItemLevelEquipped);
            end
        else
            text:SetText(avgItemLevel);
        end
        statFrame.tooltip = statFrame.tooltip .. FONT_COLOR_CODE_CLOSE;
        statFrame.tooltip2 = STAT_AVERAGE_ITEM_LEVEL_TOOLTIP;

        if ( avgItemLevelPvP and avgItemLevel ~= avgItemLevelPvP ) then
            statFrame.tooltip2 = statFrame.tooltip2.."\n\n"..STAT_AVERAGE_PVP_ITEM_LEVEL:format(avgItemLevelPvP);
        end
    else
        statFrame:Hide();
    end
end

function ArmoryMovementSpeed_OnEnter(statFrame)
    GameTooltip:SetOwner(statFrame, "ANCHOR_RIGHT");
    GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MOVEMENT_SPEED).." "..format("%d%%", statFrame.speed+0.5)..FONT_COLOR_CODE_CLOSE);

    GameTooltip:AddLine(format(STAT_MOVEMENT_GROUND_TOOLTIP, statFrame.runSpeed + 0.5));
    if ( statFrame.unit ~= "pet" ) then
        GameTooltip:AddLine(format(STAT_MOVEMENT_FLIGHT_TOOLTIP, statFrame.flightSpeed + 0.5));
    end
    GameTooltip:AddLine(format(STAT_MOVEMENT_SWIM_TOOLTIP, statFrame.swimSpeed + 0.5));
    GameTooltip:AddLine(" ");
    GameTooltip:AddLine(format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(Armory:GetCombatRating(CR_SPEED)), Armory:GetCombatRatingBonus(CR_SPEED)));
    GameTooltip:Show();

    statFrame.UpdateTooltip = ArmoryMovementSpeed_OnEnter;
end

function ArmoryMovementSpeed_OnUpdate(statFrame, elapsedTime)
    local unit = statFrame.unit;
    local _, runSpeed, flightSpeed, swimSpeed = Armory:GetUnitSpeed(unit);
    local swimming = Armory:IsSwimming(unit);
    local flying = Armory:IsFlying(unit);
    local falling = Armory:IsFalling(unit);
    if ( not runSpeed ) then
        statFrame:Hide();
        return;
    end

    runSpeed = runSpeed / BASE_MOVEMENT_SPEED * 100;
    flightSpeed = flightSpeed / BASE_MOVEMENT_SPEED * 100;

    -- Pets seem to always actually use run speed
    if ( unit == "pet" ) then
        swimSpeed = runSpeed;
    else
        swimSpeed = swimSpeed / BASE_MOVEMENT_SPEED * 100;
    end

    -- Determine whether to display running, flying, or swimming speed
    local speed = runSpeed;
    if ( swimming ) then
        speed = swimSpeed;
    elseif ( flying ) then
        speed = flightSpeed;
    end

    -- Hack so that your speed doesn't appear to change when jumping out of the water
    if ( falling ) then
        if ( statFrame.wasSwimming ) then
            speed = swimSpeed;
        end
    else
        statFrame.wasSwimming = swimming;
    end

    local valueText = format("%d%%", speed + 0.5);
    PaperDollFrame_SetLabelAndText(statFrame, STAT_MOVEMENT_SPEED, valueText, false, speed);
    statFrame.speed = speed;
    statFrame.runSpeed = runSpeed;
    statFrame.flightSpeed = flightSpeed;
    statFrame.swimSpeed = swimSpeed;
end

function ArmoryPaperDollFrame_SetMovementSpeed(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    statFrame.Label:SetText(format(STAT_FORMAT, STAT_MOVEMENT_SPEED));

    statFrame.wasSwimming = nil;
    statFrame.unit = unit;
    ArmoryMovementSpeed_OnUpdate(statFrame);

    statFrame:SetScript("OnEnter", ArmoryMovementSpeed_OnEnter);
end

function ArmoryCorruption_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetMinimumWidth(250);

    local corruption = self.corruption;
    local corruptionResistance = self.corruptionResistance;
    local totalCorruption = math.max(corruption - corruptionResistance, 0);

    local noWrap = false;
    local wrap = true;
    local descriptionXOffset = 10;

    GameTooltip_AddColoredLine(GameTooltip, CORRUPTION_TOOLTIP_TITLE, HIGHLIGHT_FONT_COLOR);
    GameTooltip_AddColoredLine(GameTooltip, CORRUPTION_DESCRIPTION, NORMAL_FONT_COLOR);
    GameTooltip_AddBlankLineToTooltip(GameTooltip);
    GameTooltip_AddColoredDoubleLine(GameTooltip, CORRUPTION_TOOLTIP_LINE, corruption, HIGHLIGHT_FONT_COLOR, HIGHLIGHT_FONT_COLOR, noWrap);
    GameTooltip_AddColoredDoubleLine(GameTooltip, CORRUPTION_RESISTANCE_TOOLTIP_LINE, corruptionResistance, HIGHLIGHT_FONT_COLOR, HIGHLIGHT_FONT_COLOR, noWrap);
    GameTooltip_AddColoredDoubleLine(GameTooltip, TOTAL_CORRUPTION_TOOLTIP_LINE, totalCorruption, CORRUPTION_COLOR, CORRUPTION_COLOR, noWrap);
    GameTooltip_AddBlankLineToTooltip(GameTooltip);

    local corruptionEffects = self.effectInfo;
    table.sort(corruptionEffects, function(a, b) return a.minCorruption < b.minCorruption; end);

    for i = 1, #corruptionEffects do
        local corruptionInfo = corruptionEffects[i];

        if i > 1 then
            GameTooltip_AddBlankLineToTooltip(GameTooltip);
        end

        -- We only show 1 effect above the player's current corruption.
        local lastEffect = (corruptionInfo.minCorruption > totalCorruption);

        GameTooltip_AddColoredLine(GameTooltip, CORRUPTION_EFFECT_HEADER:format(corruptionInfo.name, corruptionInfo.minCorruption), lastEffect and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR, noWrap);
        GameTooltip_AddColoredLine(GameTooltip, corruptionInfo.description, lastEffect and GRAY_FONT_COLOR or CORRUPTION_COLOR, wrap, descriptionXOffset);

        if ( lastEffect ) then
            break;
        end
    end

    GameTooltip:Show();
end

function ArmoryPaperDollFrame_SetCorruption(statFrame, unit)
    if ( unit ~= "player" ) then
        statFrame:Hide();
        return;
    end

    local corruption = Armory:GetCorruption();
    if ( (corruption or 0) == 0 ) then
        statFrame:Hide();
        return;
    end
    local corruptionResistance = Armory:GetCorruptionResistance();
    local totalCorruption = math.max(corruption - corruptionResistance, 0);

    local color = Armory:HexColor(CORRUPTION_COLOR);
    local label = color .. TOTAL_CORRUPTION_TOOLTIP_LINE:gsub(":", "");
    local text = color .. totalCorruption .. FONT_COLOR_CODE_CLOSE;
    PaperDollFrame_SetLabelAndText(statFrame, label, text, false, totalCorruption);

    statFrame.corruption = corruption;
    statFrame.corruptionResistance = corruptionResistance;
    statFrame.effectInfo = Armory:GetNegativeCorruptionEffectInfo();

    statFrame:SetScript("OnEnter", ArmoryCorruption_OnEnter);
    statFrame:Show();
end

function ArmoryCharacterSpellBonusDamage_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, self.tooltip).." "..BreakUpLargeNumbers(self.minModifier)..FONT_COLOR_CODE_CLOSE);

    for i = 2, MAX_SPELL_SCHOOLS do
        if ( self.bonusDamage and self.bonusDamage[i] ~= self.minModifier ) then
            GameTooltip:AddLine(HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, _G["DAMAGE_SCHOOL"..i]).." "..self.bonusDamage[i]..FONT_COLOR_CODE_CLOSE);
            GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..i);
        end
    end

    GameTooltip:AddLine(self.tooltip2);

    if (self.bonusDamage and self.unit == "player") then
        local petStr, damage;
        if ( self.bonusDamage[6] == self.minModifier and self.bonusDamage[3] == self.minModifier ) then
            petStr = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG;
            damage = self.minModifier;
        elseif ( self.bonusDamage[6] > self.bonusDamage[3] ) then
            petStr = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_SHADOW;
            damage = self.bonusDamage[6];
        else
            petStr = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_FIRE;
            damage = self.bonusDamage[3];
        end

        local petBonusAP = Armory:ComputePetBonus("PET_BONUS_SPELLDMG_TO_AP", damage);
        local petBonusDmg = Armory:ComputePetBonus("PET_BONUS_SPELLDMG_TO_SPELLDMG", damage);
        if ( petBonusAP > 0 or petBonusDmg > 0 ) then
            GameTooltip:AddLine(format(petStr, petBonusAP, petBonusDmg), nil, nil, nil, true );
        end
    end
    GameTooltip:Show();
end

function ArmoryPaperDollFormatStat(name, base, posBuff, negBuff)
    local effectiveText = BreakUpLargeNumbers(max(0,base + posBuff + negBuff));
    local text = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT,name).." "..effectiveText;
    if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
        text = text..FONT_COLOR_CODE_CLOSE;
    else
        if ( posBuff > 0 or negBuff < 0 ) then
            text = text.." ("..base..FONT_COLOR_CODE_CLOSE;
        end
        if ( posBuff > 0 ) then
            text = text..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..posBuff..FONT_COLOR_CODE_CLOSE;
        end
        if ( negBuff < 0 ) then
            text = text..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE;
        end
        if ( posBuff > 0 or negBuff < 0 ) then
            text = text..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
        end

        -- if there is a negative buff then show the main number in red, even if there are
        -- positive buffs. Otherwise show the number in green
        if ( negBuff < 0 and not Armory:GetPVPGearStatRules() ) then
            effectiveText = RED_FONT_COLOR_CODE..effectiveText..FONT_COLOR_CODE_CLOSE;
        end
    end
    return effectiveText, text;
end

function ArmoryPaperDollFrame_UpdateStatCategory(category, suffix)
    local overlay = suffix ~= nil;
    if ( not suffix ) then
        suffix = "";
    end

    local categoryInfo = ARMORY_PAPERDOLL_STATCATEGORIES[category];
    if ( not categoryInfo ) then
        return;
    end

    local parentFrame = _G["ArmoryAttributes"..suffix.."Frame"];
    local scrollFrame = _G["ArmoryAttributes"..suffix.."FrameScrollFrame"];
    local categoryFrame = scrollFrame:GetScrollChild();

    parentFrame.Category = category;

    local prevStatFrame = nil;
    local numVisible = 0;
    local totalHeight = 0;
    for index, stat in next, categoryInfo.stats do
        local statFrame = _G["ArmoryAttributes"..suffix.."FramePlayerStat"..numVisible+1];
        if ( not statFrame ) then
            statFrame = CreateFrame("Frame", "ArmoryAttributes"..suffix.."FramePlayerStat"..numVisible+1, categoryFrame, "ArmoryStatTemplate");
            if ( prevStatFrame ) then
                statFrame:SetPoint("TOPLEFT", prevStatFrame, "BOTTOMLEFT", 0, 0);
                statFrame:SetPoint("TOPRIGHT", prevStatFrame, "BOTTOMRIGHT", 0, 0);
            else
                statFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 5, 0);
            end
        end
        local statInfo;
        if ( overlay ) then
            statInfo = PAPERDOLL_STATINFO[stat];
        else
            statInfo = ARMORY_PAPERDOLL_STATINFO[stat];
        end
        if ( statInfo ) then
            statFrame:Show();
            -- Reset tooltip script in case it's been changed
            statFrame:SetScript("OnEnter", PaperDollStatTooltip);
            statFrame.tooltip = nil;
            statFrame.tooltip2 = nil;
            statFrame.UpdateTooltip = nil;
            statFrame:SetScript("OnUpdate", nil);
            statInfo.updateFunc(statFrame, "player");
            if ( statFrame:IsShown() ) then
                numVisible = numVisible + 1;
                totalHeight = totalHeight + statFrame:GetHeight();
                prevStatFrame = statFrame;
                -- Update Tooltip
                if ( GameTooltip:GetOwner() == statFrame ) then
                    statFrame:GetScript("OnEnter")(statFrame);
                end
            end
        end
    end

    if ( category == "GENERAL" and overlay and PersonalGearScore ) then
        local text = PersonalGearScore:GetText();
        if ( text ) then
            local r, g, b = PersonalGearScore:GetTextColor()
            local score = Armory:HexColor(r, g, b)..text:match("(%d+)");
            local statFrame = _G["ArmoryAttributes"..suffix.."FramePlayerStat"..numVisible+1];

            _G[statFrame:GetName().."Label"]:SetText(format(STAT_FORMAT, "GearScore"));
            _G[statFrame:GetName().."StatText"]:SetText(score);

            statFrame:Show();
            statFrame:SetScript("OnEnter", PaperDollStatTooltip);
            statFrame.tooltip = nil;
            statFrame.tooltip2 = nil;

            numVisible = numVisible + 1;
        end
    end

    local scrollbar = scrollFrame.ScrollBar;
    local scrollbarVisible = totalHeight > scrollFrame:GetHeight();
    if ( scrollbarVisible ) then
        scrollbar:Show();
    else
        scrollbar:Hide();
    end

    local index = 1;
    while ( _G["ArmoryAttributes"..suffix.."FramePlayerStat"..index] ) do
        local statFrame = _G["ArmoryAttributes"..suffix.."FramePlayerStat"..index];
        if ( index <= numVisible ) then
            if ( not statFrame.Bg ) then
                statFrame.Bg = statFrame:CreateTexture(statFrame:GetName().."Bg", "BACKGROUND");
                statFrame.Bg:SetPoint("LEFT", parentFrame, "LEFT", 2, 0);
                statFrame.Bg:SetPoint("RIGHT", parentFrame, "RIGHT", -2, 0);
                statFrame.Bg:SetPoint("TOP");
                statFrame.Bg:SetPoint("BOTTOM");
                statFrame.Bg:SetTexture(STRIPE_COLOR.r, STRIPE_COLOR.g, STRIPE_COLOR.b);
                statFrame.Bg:SetAlpha(0.1);
            end
            if ( index % 2 == 0 ) then
                statFrame.Bg:Show();
            else
                statFrame.Bg:Hide();
            end
            if ( scrollbarVisible ) then
                statFrame:SetWidth(parentFrame:GetWidth() - scrollbar:GetWidth() - 10);
            else
                statFrame:SetWidth(parentFrame:GetWidth() - 10);
            end
        else
            statFrame:Hide();
        end
        index = index + 1;
    end
end

function ArmoryInitializePaperDollStats()
    for index, statInfo in next, ARMORY_PAPERDOLL_STATINFO do
        statInfo.updateFunc(ArmoryAttributesFrameDummyStat, "player");
    end
end

function ArmoryPaperDollFrame_SetStatDropDown()
    local _, classFileName = Armory:UnitClass("player");
    classFileName = strupper(classFileName);
    ARMORY_PLAYERSTAT_DROPDOWN_SELECTION = "ATTRIBUTES";
    if ( classFileName == "MAGE" or classFileName == "PRIEST" or classFileName == "WARLOCK" or classFileName == "DRUID" ) then
        ARMORY_PLAYERSTAT_DROPDOWN_SELECTION = "SPELL";
    else
        ARMORY_PLAYERSTAT_DROPDOWN_SELECTION = "ENHANCEMENTS";
    end
end

function ArmoryPaperDollFrame_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED");
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("UNIT_LEVEL");
    self:RegisterEvent("PLAYER_DAMAGE_DONE_MODS");
    self:RegisterEvent("UNIT_ATTACK_POWER");
    self:RegisterEvent("UNIT_RANGEDDAMAGE");
    self:RegisterEvent("UNIT_ATTACK");
    self:RegisterEvent("UNIT_SPELL_HASTE");
    self:RegisterEvent("UNIT_RESISTANCES");
    self:RegisterEvent("UNIT_STATS");
    self:RegisterEvent("UNIT_RANGED_ATTACK_POWER");
    self:RegisterEvent("PLAYER_GUILD_UPDATE");
    self:RegisterEvent("COMBAT_RATING_UPDATE");
    self:RegisterEvent("MASTERY_UPDATE");
    self:RegisterEvent("SPEED_UPDATE");
    self:RegisterEvent("LIFESTEAL_UPDATE");
    self:RegisterEvent("AVOIDANCE_UPDATE");
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    self:RegisterEvent("SOCKET_INFO_UPDATE");
    self:RegisterEvent("ZONE_CHANGED");
    self:RegisterEvent("ZONE_CHANGED_INDOORS");
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA");
    self:RegisterEvent("PLAYER_CONTROL_LOST");
    self:RegisterEvent("PLAYER_CONTROL_GAINED");
    self:RegisterEvent("PLAYER_XP_UPDATE");
    self:RegisterEvent("UPDATE_EXHAUSTION");
    self:RegisterEvent("SKILL_LINES_CHANGED");
    self:RegisterEvent("TRIAL_STATUS_UPDATE");
    self:RegisterEvent("UPDATE_FACTION");
    self:RegisterEvent("EQUIPMENT_SETS_CHANGED");
    self:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE");
    self:RegisterUnitEvent("UNIT_DAMAGE", "player");
    self:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player");
    self:RegisterUnitEvent("UNIT_MAXHEALTH", "player");
    self:RegisterUnitEvent("UNIT_AURA", "player");
    self:RegisterEvent("SPELL_POWER_CHANGED");
    self:RegisterEvent("SPELL_TEXT_UPDATE");

    ARMORY_PLAYERSTAT_DROPDOWN_SELECTION = nil;

    ArmoryPaperDollFrame_UpdateVersion();
end

function ArmoryPaperDollFrame_OnEvent(self, event, unit)
    if ( event == "VARIABLES_LOADED" ) then
        -- Set defaults if no settings for the dropdowns
        if ( not ARMORY_PLAYERSTAT_DROPDOWN_SELECTION ) then
            ArmoryPaperDollFrame_SetStatDropDown();
        end
    elseif ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        -- Wait for data...
        Armory:ExecuteConditional(ArmoryPaperDollFrame_HasData, ArmoryPaperDollFrame_Update);
    end

    if ( unit == "player" ) then
        if ( event == "UNIT_LEVEL" or event == "PLAYER_XP_UPDATE" or event == "UPDATE_EXHAUSTION" ) then
            Armory:Execute(ArmoryPaperDollFrame_SetLevel);
        elseif ( event == "UNIT_DAMAGE" or
                 event == "UNIT_ATTACK_SPEED" or
                 event == "UNIT_RANGEDDAMAGE" or
                 event == "UNIT_ATTACK" or
                 event == "UNIT_STATS" or
                 event == "UNIT_RANGED_ATTACK_POWER" or
                 event == "UNIT_SPELL_HASTE" or
                 event == "UNIT_MAXHEALTH" or
                 event == "UNIT_AURA" or
                 event == "UNIT_RESISTANCES" ) then
            Armory:Execute(ArmoryPaperDollFrame_UpdateStats);
        elseif ( event == "PLAYER_GUILD_UPDATE" ) then
            Armory:Execute(ArmoryPaperDollFrame_SetGuild);
        end
    end

    if ( event == "COMBAT_RATING_UPDATE" or
         event == "MASTERY_UPDATE" or
         event == "SPEED_UPDATE" or
         event == "LIFESTEAL_UPDATE" or
         event == "AVOIDANCE_UPDATE" or
         event == "PLAYER_AVG_ITEM_LEVEL_UPDATE" or
         event == "PLAYER_DAMAGE_DONE_MODS" or
         event == "SPELL_POWER_CHANGED" or
         event == "SPELL_TEXT_UPDATE" ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateStats);
    elseif ( event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" ) then
        Armory:Execute(ArmoryPaperDollFrame_SetZone);
    elseif ( event == "PLAYER_CONTROL_LOST" ) then
        self:UnregisterEvent("ZONE_CHANGED");
        self:UnregisterEvent("ZONE_CHANGED_INDOORS");
    elseif ( event == "PLAYER_CONTROL_GAINED" ) then
        self:RegisterEvent("ZONE_CHANGED");
        self:RegisterEvent("ZONE_CHANGED_INDOORS");
        Armory:Execute(ArmoryPaperDollFrame_SetZone);
    elseif ( (event == "UNIT_LEVEL" and unit == "player") or event == "SKILL_LINES_CHANGED" or event == "TRIAL_STATUS_UPDATE" or event == "UPDATE_FACTION" ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateEquippable);
    elseif ( event == "EQUIPMENT_SETS_CHANGED" ) then
        Armory:Execute(ArmoryGearSets_Update);
    elseif ( event == "PLAYER_EQUIPMENT_CHANGED" or event == "SOCKET_INFO_UPDATE" ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateInventory);
    end
end

function ArmoryPaperDollFrame_HasData()
    local unit = "player";
    return UnitLevel(unit) and UnitRace(unit) and UnitClass(unit);
end

function ArmoryPaperDollFrame_OnShow(self)
    ArmoryPaperDollFrame_Update();
    if ( Armory:GetNumEquipmentSets() > 0 ) then
        ArmoryGearSetToggleButton:Show();
    else
        ArmoryGearSetToggleButton:Hide();
    end
    ArmoryGearSetFrame:Hide();
end

function ArmoryPaperDollFrame_UpdateStats()
    ArmoryInitializePaperDollStats();
    ArmoryPaperDollFrame_UpdateStatCategory(ARMORY_PLAYERSTAT_DROPDOWN_SELECTION);
end

function ArmoryPaperDollFrame_UpdateSlot(frame)
    Armory:SetInventoryItemInfo(frame:GetID());
    ArmoryPaperDollItemSlotButton_Update(frame);
end

function ArmoryPaperDollFrame_UpdateInventory()
    ArmoryPaperDollFrame_UpdateSlot(ArmoryHeadSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryNeckSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryShoulderSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryBackSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryChestSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryShirtSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryTabardSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryWristSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryHandsSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryWaistSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryLegsSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryFeetSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryFinger0Slot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryFinger1Slot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryTrinket0Slot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryTrinket1Slot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryMainHandSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmorySecondaryHandSlot);

    ArmoryPaperDoll_UpdateSockets();
    if ( Armory:GetConfigUseOverlay() ) then
        ArmoryPaperDoll_UpdateSockets(1);
    end

    Armory.hasEquipment = true;
    Armory_EQC_Refresh();
end

function ArmoryPaperDollFrame_UpdateTalent(overlay)
    local specialism, role, parent, currentSpec;

    if ( overlay ) then
        parent = "ArmoryPaperDollTalentOverlay";
        currentSpec = GetSpecialization();
        if ( currentSpec ) then
            _, specialism, _, _, role = GetSpecializationInfo(currentSpec, nil, nil, nil, UnitSex("player"));
        end
    else
        parent = "ArmoryPaperDollTalent";
        currentSpec = Armory:GetSpecialization();
        if ( currentSpec ) then
            _, specialism, _, _, role = Armory:GetSpecializationInfo(currentSpec, nil, nil, nil, Armory:UnitSex("player"));
        end
    end

    if ( role ) then
        _G[parent.."ButtonIcon"]:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
        _G[parent.."ButtonIcon"]:SetTexCoord(GetTexCoordsForRole(role));
    else
        SetPortraitToTexture(_G[parent.."ButtonIcon"], "Interface\\Icons\\Ability_Marksmanship");
    end
    _G[parent.."Text"]:SetText(strupper(specialism or NONE));
end

local function UpdateSkillFrame(skillFrame, values)
    local label = _G[skillFrame:GetName().."Label"];
    local statusbar = _G[skillFrame:GetName().."Bar"];
    local bartext = _G[skillFrame:GetName().."BarText"];
    local icon = _G[skillFrame:GetName().."ButtonIcon"];

    if ( not values ) then
        skillFrame:Hide();
    else
        local skillName, skillRank, skillMaxRank, texture = unpack(values);

        SetPortraitToTexture(icon, texture or Armory:GetProfessionTexture(skillName));
        label:SetText(strupper(skillName));
        statusbar:SetMinMaxValues(0, skillMaxRank);
        statusbar:SetValue(skillRank);
        bartext:SetText(skillRank.." / "..skillMaxRank);
        skillFrame:Show();
    end
end

function ArmoryPaperDollFrame_UpdateSkills(overlay)
    if ( overlay ) then
        local prof1, prof2 = GetProfessions();
        local name, texture, rank, maxRank;
        if ( not (prof1 and prof2) ) then
            UpdateSkillFrame(ArmoryPaperDollTradeSkillOverlayFrame1, nil);
            UpdateSkillFrame(ArmoryPaperDollTradeSkillOverlayFrame2, nil);
        elseif ( prof1 and prof2 ) then
            name, texture, rank, maxRank = GetProfessionInfo(prof1);
            UpdateSkillFrame(ArmoryPaperDollTradeSkillOverlayFrame1, {name, rank, maxRank, texture});
            name, texture, rank, maxRank = GetProfessionInfo(prof2);
            UpdateSkillFrame(ArmoryPaperDollTradeSkillOverlayFrame2, {name, rank, maxRank, texture});
        else
            name, texture, rank, maxRank = GetProfessionInfo(prof1 or prof2);
            UpdateSkillFrame(ArmoryPaperDollTradeSkillOverlayFrame1, {name, rank, maxRank, texture});
            UpdateSkillFrame(ArmoryPaperDollTradeSkillOverlayFrame2, nil);
        end
    else
        local skills = Armory:GetPrimaryTradeSkills();
        if ( #skills == 0 ) then
            UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame1, nil);
            UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame2, nil);
        elseif ( #skills == 1 ) then
            UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame1, skills[1]);
            UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame2, nil);
        else
            UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame1, skills[1]);
            UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame2, skills[2]);
        end
    end
end

function ArmoryPaperDollFrame_Update()
    ArmoryBuffFrame_Update("player");
    ArmoryPaperDollFrame_SetGuild();
    ArmoryPaperDollFrame_SetZone();
    ArmoryPaperDollFrame_SetLevel();
    ArmoryPaperDollFrame_UpdateStats();
    ArmoryPaperDollFrame_UpdateTalent();
    ArmoryPaperDollFrame_UpdateSkills();
    ArmoryPaperDollFrame_UpdateInventory();
    ArmoryGearSets_Update();
end

local alternatives = {};
function ArmoryAlternateSlotFrame_Show(parent, orientation, direction)
    if ( not Armory:GetConfigShowAltEquipment() ) then
        return;
    end

    local frame = ArmoryAlternateSlotFrame;
    local slotName = strsub(parent:GetName(), 7);
    local parentId = Armory:GetUniqueItemId(parent.link)
    local id, link, equipLoc, texture, itemId;
    local numItems = 0;

    table.wipe(alternatives);

    for i = 1, #ArmoryInventoryContainers do
        id = ArmoryInventoryContainers[i];
        if ( id > ARMORY_MAIL_CONTAINER ) then
            for index = 1, Armory:GetContainerNumSlots(id) do
                link = Armory:GetContainerItemLink(id, index);
                if ( link and IsEquippableItem(link) and (Armory:GetContainerItemCanEquip(id, index) or Armory:GetConfigShowUnequippable()) ) then
                    _, _, _, _, _, _, _, _, equipLoc, texture = GetItemInfo(link);
                    if ( ARMORY_SLOTINFO[equipLoc] and ARMORY_SLOTINFO[equipLoc] == slotName ) then
                        itemId = Armory:GetUniqueItemId(link);
                        if ( not alternatives[itemId] and itemId ~= parentId ) then
                            alternatives[itemId] = {link=link, texture=texture};
                            numItems = numItems + 1;
                        end
                    end
                end
            end
        end
    end

    if ( numItems == 0 ) then
        frame:Hide();
        return;
    end

    local length = min(numItems, MAX_ALTERNATE_SLOTS) * ALTERNATE_SLOT_SIZE;
    local xOffset = 12;
    local yOffset = 14;
    if ( direction == "LEFT" and parent:GetLeft() - length + xOffset < 0 ) then
        direction = "RIGHT";
    elseif ( direction == "RIGHT" and parent:GetRight() + length - xOffset > GetScreenWidth() ) then
        direction = "LEFT";
    elseif ( parent:GetBottom() - length + yOffset < 0 ) then
        direction = "UP";
    end
    local anchor = ANCHOR_SLOTINFO[direction];
    local row, column, x, y, button;
    local i = 0;
    for _, item in pairs(alternatives) do
        row = floor(i / MAX_ALTERNATE_SLOTS);
        column = i % MAX_ALTERNATE_SLOTS;
        if ( orientation == "VERTICAL" ) then
            x = row;
            y = column;
        else
            x = column;
            y = row;
        end
        i = i + 1;
        x = (8 + x * ALTERNATE_SLOT_SIZE) * anchor.xFactor;
        y = (8 + y * ALTERNATE_SLOT_SIZE) * anchor.yFactor;

        -- "^Armory.*Slot" pattern used by EQC
        button = _G["ArmoryAlternate"..i.."Slot"];
        if ( not button ) then
            button = CreateFrame("CheckButton", "ArmoryAlternate"..i.."Slot", frame, "ArmoryItemButtonTemplate");
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
            button:SetScript("OnClick", ArmoryAlternateSlotButton_OnClick);
            button:SetScript("OnEnter", ArmoryAlternateSlotButton_OnEnter);
            button:SetScript("OnLeave", ArmoryAlternateSlotButton_OnLeave);
        end
        SetItemButtonTexture(button, item.texture);
        Armory:SetItemLink(button, item.link);
        button.anchor = parent.anchor;
        button:SetID(parent:GetID());
        button:ClearAllPoints();
        button:SetPoint(anchor.point, frame, anchor.point, x, y);
        button:SetFrameLevel(555);--frame:GetParent():GetFrameLevel() + 1);
        button:Show();
    end
    table.wipe(alternatives);

    ArmoryAlternateSlotFrame_HideSlots(numItems + 1);

    frame:ClearAllPoints();
    frame:SetParent(parent);
    frame:SetFrameLevel(parent:GetFrameLevel() + 4);
    frame:SetScale(.85);
    frame:SetPoint(anchor.point, parent, anchor.relativeTo, anchor.x, anchor.y);
    if ( orientation == "VERTICAL" ) then
        frame:SetWidth((row + 1) * ALTERNATE_SLOT_SIZE + xOffset);
        frame:SetHeight(length + yOffset);
    else
        frame:SetWidth(length + xOffset);
        frame:SetHeight((row + 1) * ALTERNATE_SLOT_SIZE + yOffset);
    end
    frame.delay = 0;
    frame:Show();
end

function ArmoryAlternateSlotButton_OnClick(self, button)
    if ( self.link ) then
        if ( button == "RightButton" and IsShiftKeyDown() ) then
            ArmoryArtifactFrame:ShowArtifact(self.link);
        elseif ( IsModifiedClick("CHATLINK") ) then
            HandleModifiedItemClick(self.link);
        end
    end
end

function ArmoryAlternateSlotButton_OnEnter(self)
    GameTooltip:SetOwner(self, self.anchor);
    Armory:SetInventoryItem("player", self:GetID(), false, false, self.link);
end

function ArmoryAlternateSlotButton_OnLeave(self)
    GameTooltip:Hide();
end

function ArmoryAlternateSlotFrame_OnUpdate(self, elapsed)
    local now = time();
    if ( self:IsVisible() and now >= self.delay ) then
        if ( self:IsMouseOver() or self:GetParent():IsMouseOver() ) then
            return;
        end
        self:Hide();
    end
    self.delay = now + 0.5;
end

function ArmoryAlternateSlotFrame_HideSlots(start)
    local i = start or 1;
    while ( _G["ArmoryAlternate"..i.."Slot"] ) do
        _G["ArmoryAlternate"..i.."Slot"]:Hide();
        i = i + 1;
    end
end

function ArmoryPaperDollFrame_UpdateEquippable()
    Armory:UpdateInventoryEquippable();
end

function ArmoryGearSets_Update()
    Armory:UpdateGearSets();
end

function ArmoryPaperDollFrame_UpdateVersion(version)
    local major, minor, rel, lastVersion;
    local myVersion = Armory.version:match("^v?([%d%.]+)")

    if ( myVersion ) then
        ArmoryVersionText:SetText("v"..Armory.version:match("^v?(.+)"));

        if ( not ArmoryPaperDollFrame.lastVersion ) then
            major, minor, rel = strsplit(".", myVersion);
            ArmoryPaperDollFrame.lastVersion = major * 100 + (minor or 0) + (rel or 0) / 100;
        end

        if ( version ) then
            major, minor, rel = strsplit(".", version);
            if ( tonumber(major) ) then
                lastVersion = major * 100 + (minor or 0) + (rel or 0) / 100;
                if ( lastVersion > ArmoryPaperDollFrame.lastVersion ) then
                    ArmoryPaperDollFrame.lastVersion = lastVersion;
                    ArmoryNewVersionText:SetFormattedText("|cffff0000new!|r v|cffffffff%s", version);
                    ArmoryNewVersionText:Show();
                end
            end
        end
    else
        ArmoryVersionText:SetText(RED_FONT_COLOR_CODE..Armory.version..FONT_COLOR_CODE_CLOSE);
    end
end

function ArmoryGearSetFrame_OnLoad(self)
    self.title:SetText(EQUIPMENT_MANAGER);
    self.buttons = {};
    local name = self:GetName();
    local button;
    for i = 1, MAX_EQUIPMENT_SETS_PER_PLAYER do
        button = CreateFrame("CheckButton", "ArmoryGearSetButton" .. i, self, "ArmoryGearSetButtonTemplate");
        if ( i == 1 ) then
            button:SetPoint("TOPLEFT", self, "TOPLEFT", 16, -32);
        elseif ( mod(i, NUM_GEARSETS_PER_ROW) == 1 ) then
            button:SetPoint("TOP", "ArmoryGearSetButton"..(i-NUM_GEARSETS_PER_ROW), "BOTTOM", 0, -10);
        else
            button:SetPoint("LEFT", "ArmoryGearSetButton"..(i-1), "RIGHT", 13, 0);
        end
        button.icon = _G["ArmoryGearSetButton" .. i .. "Icon"];
        button.text = _G["ArmoryGearSetButton" .. i .. "Name"];
        table.insert(self.buttons, button);
    end
end

function ArmoryGearSetFrame_OnShow(self)
    ArmoryFrame:SetAttribute("UIPanelLayout-defined", nil);
    ArmoryGearSetToggleButton:SetButtonState("PUSHED", 1);
    ArmoryGearSetFrame_Update();
    PlaySound(SOUNDKIT.IG_BACKPACK_OPEN);
    ArmoryGearSetFrame:Raise();
end

function ArmoryGearSetFrame_OnHide(self)
    ArmoryFrame:SetAttribute("UIPanelLayout-defined", nil);
    ArmoryGearSetToggleButton:SetButtonState("NORMAL");
    ArmoryPaperDollFrame_UpdateStats();
    PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE);
end

function ArmoryGearSetFrame_Update()
    local numSets = Armory:GetNumEquipmentSets();

    local dialog = ArmoryGearSetFrame;
    local buttons = dialog.buttons;

    local selectedName = dialog.selectedSetName;
    local name, texture, button;
    dialog.selectedSet = nil;
    for i = 1, numSets do
        name, texture = Armory:GetEquipmentSetInfo(i);
        button = buttons[i];
        button:Enable();
        button.name = name;
        button.text:SetText(name);
        button:SetID(i);
        if (texture) then
            button.icon:SetTexture(texture);
        else
            button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
        end
        if ( selectedName and button.name == selectedName ) then
            button:SetChecked(true);
            dialog.selectedSet = button;
        else
            button:SetChecked(false);
        end
    end
    if ( dialog.selectedSet ) then
        ArmoryGearSetFrameEquipSet:Enable();
    else
        ArmoryGearSetFrameEquipSet:Disable();
    end

    for i = numSets + 1, MAX_EQUIPMENT_SETS_PER_PLAYER do
        button = buttons[i];
        button:Disable();
        button:SetChecked(false);
        button.name = nil;
        button.text:SetText("");
        button.icon:SetTexture("");
    end
end

function ArmoryGearSetFrameEquipSet_OnClick(self)
    local selectedSet = ArmoryGearSetFrame.selectedSet;
    if ( selectedSet ) then
        local name = selectedSet.name;
        if ( name and name ~= "" ) then
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
            local items = Armory:GetEquipmentSetItemIDs(selectedSet:GetID(), gearSetItems);
            ArmoryPaperDollItemSlotButton_Update(ArmoryHeadSlot, items[1]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryNeckSlot, items[2]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryShoulderSlot, items[3]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryBackSlot, items[15]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryChestSlot, items[5]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryShirtSlot, items[4]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryTabardSlot, items[19]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryWristSlot, items[9]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryHandsSlot, items[10]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryWaistSlot, items[6]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryLegsSlot, items[7]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryFeetSlot, items[8]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryFinger0Slot, items[11]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryFinger1Slot, items[12]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryTrinket0Slot, items[13]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryTrinket1Slot, items[14]);
            ArmoryPaperDollItemSlotButton_Update(ArmoryMainHandSlot, items[16]);
            ArmoryPaperDollItemSlotButton_Update(ArmorySecondaryHandSlot, items[17]);

            ArmoryPaperDoll_UpdateSockets();
        end
    end
end

function ArmoryGearSetButton_OnClick(self, button, down)
    if ( self.name and self.name ~= "" ) then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
        local dialog = ArmoryGearSetFrame;
        dialog.selectedSetName = self.name;
        ArmoryGearSetFrame_Update();
    else
        self:SetChecked(false);
    end
end

local gearSetLocations = {};
function ArmoryGearSetButton_OnEnter(self)
    if ( self.name and self.name ~= "" ) then
        GameTooltip_SetDefaultAnchor(GameTooltip, self);
        local items = Armory:GetEquipmentSetItemIDs(self:GetID(), gearSetItems);
        local locations = Armory:GetEquipmentSetLocations(self:GetID(), gearSetLocations);
        local locationType;
        local count, equipped, bags, missing = 0, 0, 0, 0;
        for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
            if ( (items[i] or 0) ~= 0 ) then
                locationType = bit.rshift(locations[i], 16);
                if ( locationType == 16 ) then
                    equipped = equipped + 1;
                elseif ( locationType == 48 ) then
                    bags = bags + 1;
                else
                    missing = missing + 1;
                end
                count = count + 1;
            end
        end

        GameTooltip:AddDoubleLine(self.name, format("%d "..ITEMS, count), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        if ( equipped > 0 ) then
            GameTooltip:AddLine(format(ITEMS_EQUIPPED, equipped), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        end
        if ( bags > 0 ) then
            GameTooltip:AddLine(format(ITEMS_IN_INVENTORY, bags), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        end
        if ( missing > 0 ) then
            GameTooltip:AddLine(format(ITEMS_NOT_IN_INVENTORY, missing), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
        end
        GameTooltip:Show();
    end
end

local function AddEmptySockets(frameName, slot, ...)
    local frame, socketType;
    for i = 1, select("#", ...) do
        socketType = select(i, ...);
        if ( socketType == "meta" ) then
            frame = _G[frameName.."Meta"];
        elseif ( socketType == "red" ) then
            frame = _G[frameName.."Red"];
        elseif ( socketType == "blue" ) then
            frame = _G[frameName.."Blue"];
        elseif ( socketType == "yellow" ) then
            frame = _G[frameName.."Yellow"];
        else
            frame = _G[frameName.."Other"];
        end
        frame.Icon:SetVertexColor(0.8, 0.1, 0.1);
        frame.count = frame.count + 1;
        frame.empty = frame.empty + 1;
        table.insert(frame.gems, {slot, RED_FONT_COLOR_CODE..EMPTY..FONT_COLOR_CODE_CLOSE});
    end
end

local socketTypes = { "Red", "Blue", "Yellow", "Meta", "Other" };
local gemColors = {};
function ArmoryPaperDoll_UpdateSockets(overlay)
    local suffix = overlay and "Overlay" or "";
    local frameName = "ArmorySockets"..suffix.."Frame";
    local frame;

    for _, socketType in ipairs(socketTypes) do
        frame = _G[frameName..socketType];
        frame.Icon:SetVertexColor(1.0, 1.0, 1.0);
        frame.count = 0;
        frame.empty = 0;
        frame.tooltip = nil;
        frame.tooltip2 = nil;
        frame.tooltipSubText = nil;
        if ( not frame.gems ) then
            frame.gems = {};
        else
            table.wipe(frame.gems);
        end
    end
    for color in pairs(gemColors) do
        gemColors[color] = 0;
    end

    local unit;
    if ( overlay ) then
        unit = "player";
    end

    local isMetaActive = Armory:IsMetaActive(unit);
    local emptySockets, gemInfo, gemName, gemColor, socketType;
    local link, tooltip, text;
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        if ( slot ~= ARMORY_SLOTID.ShirtSlot and slot ~= ARMORY_SLOTID.TabardSlot ) then
             _, _, _, link, _, _, emptySockets = Armory:GetInventoryItemInfo(slot, unit);

            if ( not link and slot == ARMORY_SLOTID.HeadSlot ) then
                _G[frameName.."Meta"].count = -1;
            end

            if ( Armory:GetItemGemString(link) ) then
                gemInfo = Armory:GetSocketInfo(link);
                for _, socket in ipairs(gemInfo) do
                    if ( socket.link ) then
                        gemName = Armory:GetColorFromLink(socket.link)..socket.gem..FONT_COLOR_CODE_CLOSE;
                        gemColor = (socket.gemColor or UNKNOWN);
                        _, _, socketType = strsplit("-", socket.texture);
                        if ( not socketType ) then
                            socketType = "Other";
                        end
                        frame = _G[frameName..socketType] or _G[frameName.."Other"];
                        frame.count = frame.count + 1;
                        if ( socketType == "Meta" ) then
                            tooltip = Armory:AllocateTooltip();
                            tooltip:SetHyperlink(socket.link);
                            text = Armory:Tooltip2String(tooltip);
                            Armory:ReleaseTooltip(tooltip);
                            for requirement in text:gmatch("(|c%x%x%x%x%x%x%x%x.-|r)") do
                                frame.tooltipSubText = (frame.tooltipSubText and frame.tooltipSubText.."\n" or "")..requirement;
                            end
                        else
                            gemName = gemColor.." : "..gemName;
                            if ( not gemColors[gemColor] ) then
                                gemColors[gemColor] = 1;
                            else
                                gemColors[gemColor] = gemColors[gemColor] + 1;
                            end
                        end
                        table.insert(frame.gems, {ARMORY_SLOT[slot], gemName});
                    end
                end
            end

            if ( emptySockets ) then
                AddEmptySockets(frameName, ARMORY_SLOT[slot], strsplit(":", emptySockets));
            end
        end
    end

    frame = _G[frameName.."Meta"];
    if ( isMetaActive or frame.count == -1 or frame.count + frame.empty == 0 ) then
        frame.Icon:SetVertexColor(1.0, 1.0, 1.0);
    elseif ( frame.empty == 0 ) then
        frame.Icon:SetVertexColor(0.8, 0.1, 0.1);
    end

    for color, count in pairs(gemColors) do
        if ( count > 0 ) then
            frame.tooltip2 = (frame.tooltip2 and frame.tooltip2..", " or "")..format("%s: %d", color, count);
        end
    end

    for _, socketType in ipairs(socketTypes) do
        frame = _G[frameName..socketType];
        if ( frame.count == -1 ) then
            frame.Value:SetText("X");
        else
            frame.Value:SetText(frame.count);
        end
        if ( socketType == "Other" ) then
            frame.tooltip = OTHER;
        else
            frame.tooltip = _G["EMPTY_SOCKET_"..strupper(socketType)];
        end
        if ( frame.count == -1 ) then
            frame.tooltip = frame.tooltip.." "..NOT_APPLICABLE;
        else
            frame.tooltip = frame.tooltip.." "..frame.count;
        end
    end
end

function ArmoryPaperDollSocketTooltip(self)
    if ( self.tooltip ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(self.tooltip, 1.0, 1.0, 1.0);
        if ( self.gems ) then
            for _, gemInfo in ipairs(self.gems) do
                GameTooltip:AddDoubleLine(gemInfo[2], gemInfo[1], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
            end
        end
        if ( self.tooltipSubText ) then
            GameTooltip:AddLine(self.tooltipSubText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        end
        if ( self.tooltip2 ) then
            GameTooltip:AddLine(self.tooltip2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        end
        GameTooltip:Show();
    end
end

----------------------------------------------------------
-- Paper doll overlay
----------------------------------------------------------

local PaperDollFrame_QueuedUpdate_Orig = PaperDollFrame_QueuedUpdate;
function PaperDollFrame_QueuedUpdate(self, ...)
    if ( Armory:GetConfigUseOverlay() ) then
        ArmoryPaperDollOverlayFrame_UpdateStats();
    end
    return PaperDollFrame_QueuedUpdate_Orig(self, ...);
end

local CharacterFrame_Expand_Orig = CharacterFrame_Expand;
function CharacterFrame_Expand(...)
    if ( Armory:GetConfigUseOverlay() ) then
        ArmoryPaperDollOverlayFrame:Show();

        if ( Armory:GetConfigCollapseCharacterFrame() ) then
            return;
        end
    end
    return CharacterFrame_Expand_Orig(...);
end

function ArmoryPaperDollOverlayFrame_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED");
    if ( PlayerTitlePickerFrame ) then -- Removed in Patch 4.1.0
        PlayerTitlePickerFrame:SetFrameLevel(self:GetFrameLevel() + 4);
    end
end

function ArmoryPaperDollOverlayFrame_OnEvent(self, event, ...)
    ArmoryPaperDollOverlayTopFrame_SetStatDropDown();
    ArmoryPaperDollOverlayBottomFrame_SetStatDropDown();
    ArmoryPaperDollCheckButton_Enable(not Armory:GetConfigHideCheckButton());
end

function ArmoryPaperDollOverlayFrame_OnShow(self)
    CharacterModelScene:Hide();
    if ( PawnUI_InventoryPawnButton ) then
        PawnUI_InventoryPawnButton:SetFrameLevel(self:GetFrameLevel() + 1);
    end

    if ( Armory:GetConfigUseMaziel() ) then
        ArmoryPaperDollTalentOverlay:Hide();
        ArmoryPaperDollTradeSkillOverlay:Hide();
        ArmoryAttributesOverlayTopFrame:Show();
        ArmoryAttributesOverlayBottomFrame:ClearAllPoints()
        ArmoryAttributesOverlayBottomFrame:SetPoint("TOPLEFT", ArmoryAttributesOverlayTopFrame, "BOTTOMLEFT", 0, -24);
    else
        ArmoryPaperDollTalentOverlay:Show();
        ArmoryPaperDollTradeSkillOverlay:Show();
        ArmoryAttributesOverlayTopFrame:Hide();
        ArmoryAttributesOverlayBottomFrame:ClearAllPoints()
        ArmoryAttributesOverlayBottomFrame:SetPoint("TOPLEFT", ArmoryPaperDollTradeSkillOverlay, "BOTTOMLEFT", 1, -25);

        ArmoryPaperDollFrame_UpdateTalent(1);
        ArmoryPaperDollFrame_UpdateSkills(1);
    end
    ArmoryPaperDollOverlayFrame_UpdateStats();

    ArmoryPaperDoll_UpdateSockets(1);

    if ( Armory:GetConfigCollapseCharacterFrame() ) then
        CharacterFrame_Collapse();
    end
end

function ArmoryPaperDollOverlayFrame_OnHide(self)
    CharacterModelScene:Show();
    CharacterFrame_Expand();
end

function ArmoryPaperDollOverlayTopFrame_SetStatDropDown()
    if ( not ArmoryLocalSettings.playerStatTopDropdown ) then
        ArmoryLocalSettings.playerStatTopDropdown = "ATTRIBUTES";
    end
    ArmoryDropDownMenu_SetSelectedValue(ArmoryAttributesOverlayTopFramePlayerStatDropDown, ArmoryLocalSettings.playerStatTopDropdown);
end

function ArmoryAttributesOverlayTopFramePlayerStatDropDown_OnLoad(self)
    ArmoryDropDownMenu_SetWidth(self, 182);
    ArmoryDropDownMenu_JustifyText(self, "LEFT");
end

function ArmoryAttributesOverlayTopFramePlayerStatDropDown_OnShow(self)
    ArmoryDropDownMenu_Initialize(self, ArmoryAttributesOverlayTopFramePlayerStatDropDown_Initialize);
    ArmoryDropDownMenu_SetSelectedValue(self, ArmoryLocalSettings.playerStatTopDropdown);
end

function ArmoryAttributesOverlayTopFramePlayerStatDropDown_Initialize()
    -- Setup buttons
    local info = ArmoryDropDownMenu_CreateInfo();
    local checked;
    for i = 1, getn(ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS) do
        if ( ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i] == ArmoryLocalSettings.playerStatTopDropdown ) then
            info.checked = 1;
            checked = 1;
        else
            info.checked = nil;
        end
        info.text = _G["STAT_CATEGORY_"..ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i]];
        info.func = ArmoryAttributesOverlayTopFramePlayerStatDropDown_OnClick;
        info.value = ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i];
        info.owner = ARMORY_DROPDOWNMENU_OPEN_MENU;
        ArmoryDropDownMenu_AddButton(info);
    end
    if ( not checked ) then
        ArmoryLocalSettings.playerStatTopDropdown = nil;
        ArmoryPaperDollOverlayTopFrame_SetStatDropDown();
    end
end

function ArmoryAttributesOverlayTopFramePlayerStatDropDown_OnClick(self)
    ArmoryDropDownMenu_SetSelectedValue(_G[self.owner], self.value);
    ArmoryLocalSettings.playerStatTopDropdown = self.value;
    ArmoryPaperDollFrame_UpdateStatCategory(self.value, "OverlayTop");
end

function ArmoryPaperDollOverlayBottomFrame_SetStatDropDown()
    local _, classFileName = UnitClass("player");
    classFileName = strupper(classFileName);
    if ( not ArmoryLocalSettings.playerStatBottomDropdown ) then
        ArmoryLocalSettings.playerStatBottomDropdown = "ATTRIBUTES";
        if ( classFileName == "MAGE" or classFileName == "PRIEST" or classFileName == "WARLOCK" or classFileName == "DRUID" ) then
            ArmoryLocalSettings.playerStatBottomDropdown = "SPELL";
        else
            ArmoryLocalSettings.playerStatBottomDropdown = "ENHANCEMENTS";
        end
    end
    ArmoryDropDownMenu_SetSelectedValue(ArmoryAttributesOverlayBottomFramePlayerStatDropDown, ArmoryLocalSettings.playerStatBottomDropdown);
end

function ArmoryAttributesOverlayBottomFramePlayerStatDropDown_OnLoad(self)
    ArmoryDropDownMenu_SetWidth(self, 212);
    ArmoryDropDownMenu_JustifyText(self, "LEFT");
end

function ArmoryAttributesOverlayBottomFramePlayerStatDropDown_OnShow(self)
    ArmoryDropDownMenu_Initialize(self, ArmoryAttributesOverlayBottomFramePlayerStatDropDown_Initialize);
    ArmoryDropDownMenu_SetSelectedValue(self, ArmoryLocalSettings.playerStatBottomDropdown);
end

function ArmoryAttributesOverlayBottomFramePlayerStatDropDown_Initialize()
    -- Setup buttons
    local info = ArmoryDropDownMenu_CreateInfo();
    local checked;
    for i = 1, getn(ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS) do
        if ( ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i] == ArmoryLocalSettings.playerStatBottomDropdown ) then
            info.checked = 1;
            checked = 1;
        else
            info.checked = nil;
        end
        info.text = _G["STAT_CATEGORY_"..ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i]];
        info.func = ArmoryAttributesOverlayBottomFramePlayerStatDropDown_OnClick;
        info.value = ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i];
        info.owner = ARMORY_DROPDOWNMENU_OPEN_MENU;
        ArmoryDropDownMenu_AddButton(info);
    end
    if ( not checked ) then
        ArmoryLocalSettings.playerStatBottomDropdown = nil;
        ArmoryPaperDollOverlayBottomFrame_SetStatDropDown();
    end
end

function ArmoryAttributesOverlayBottomFramePlayerStatDropDown_OnClick(self)
    ArmoryDropDownMenu_SetSelectedValue(_G[self.owner], self.value);
    ArmoryLocalSettings.playerStatBottomDropdown = self.value;
    ArmoryPaperDollFrame_UpdateStatCategory(self.value, "OverlayBottom");
end

function ArmoryPaperDollOverlayFrame_UpdateStats()
    ArmoryPaperDollFrame_UpdateStatCategory(ArmoryLocalSettings.playerStatTopDropdown, "OverlayTop");
    ArmoryPaperDollFrame_UpdateStatCategory(ArmoryLocalSettings.playerStatBottomDropdown, "OverlayBottom");
end

function ArmoryPaperDollCheckButton_Enable(enable)
    if ( enable ) then
        ArmoryPaperDollOverlayFrameCheckButton:Show();
    else
        ArmoryPaperDollOverlayFrameCheckButton:Hide();
    end
end