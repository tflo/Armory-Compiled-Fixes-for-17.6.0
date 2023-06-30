--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 186 2022-11-20T17:51:25Z
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

ARMORY_REPUTATIONFRAME_FACTIONHEIGHT = 26;

local NUM_FACTIONS_DISPLAYED = 15;
local MAX_REPUTATION_REACTION = 8;

local table = table;
local ipairs = ipairs;
local next = next;
local mod = mod;
local floor = floor;

function ArmoryReputationFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("UPDATE_FACTION");
    self:RegisterEvent("QUEST_LOG_UPDATE");
    self.paragonFramesPool = CreateFramePool("FRAME", self, "ArmoryReputationParagonFrameTemplate");
end

function ArmoryReputationFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        if ( Armory.forceScan or not Armory:FactionsExists() ) then
            Armory:Execute(ArmoryReputationFrame_UpdateFactions);
        end
    else
        Armory:Execute(ArmoryReputationFrame_UpdateFactions);
    end
end

function ArmoryReputationFrame_OnShow(self)
    ArmoryReputationFrame_Update();
end

function ArmoryReputationFrame_UpdateFactions()
    -- UpdateFactions will trigger UPDATE_FACTION
    ArmoryReputationFrame:UnregisterEvent("UPDATE_FACTION");
    Armory:UpdateFactions();
    ArmoryReputationFrame:RegisterEvent("UPDATE_FACTION");
    if ( ArmoryReputationFrame:IsShown() ) then
        ArmoryReputationFrame_Update();
    end
end

function ArmoryReputationFrame_UpdateHeader(show)
    if ( show ) then
        ArmoryReputationFrameFactionLabel:Show();
        ArmoryReputationFrameStandingLabel:Show();
    else
        ArmoryReputationFrameFactionLabel:Hide();
        ArmoryReputationFrameStandingLabel:Hide();
    end
end

function ArmoryReputationFrame_SetRowType(factionRow, isChild, isHeader, hasRep)    --rowType is a binary table of type isHeader, isChild
    local factionRowName = factionRow:GetName()
    local factionBar = _G[factionRowName.."ReputationBar"];
    local factionTitle = _G[factionRowName.."FactionName"];
    local factionButton = _G[factionRowName.."ExpandOrCollapseButton"];
    local factionStanding = _G[factionRowName.."ReputationBarFactionStanding"];
    local factionBackground = _G[factionRowName.."Background"];
    local factionLeftTexture = _G[factionRowName.."ReputationBarLeftTexture"];
    local factionRightTexture = _G[factionRowName.."ReputationBarRightTexture"];
    factionLeftTexture:SetWidth(62);
    factionRightTexture:SetWidth(42);
    factionBar:SetPoint("RIGHT", factionRow, "RIGHT", 0, 0);
    if ( isHeader ) then
        if (isChild) then
            factionRow:SetPoint("LEFT", ArmoryReputationFrame, "LEFT", 29, 0);
        else
            factionRow:SetPoint("LEFT", ArmoryReputationFrame, "LEFT", 10, 0);
        end
        factionButton:SetPoint("LEFT", factionRow, "LEFT", 3, 0);
        factionButton:Show();
        factionTitle:SetPoint("LEFT", factionButton, "RIGHT", 10, 0);
        if ( hasRep ) then
            factionTitle:SetPoint("RIGHT", factionBar, "LEFT", -3, 0);
        else
            factionTitle:SetPoint("RIGHT", factionBar, "RIGHT", -3, 0);
        end

        factionTitle:SetFontObject(GameFontNormalLeft);
        factionBackground:Hide()
        factionLeftTexture:SetHeight(15);
        factionLeftTexture:SetWidth(60);
        factionRightTexture:SetHeight(15);
        factionRightTexture:SetWidth(39);
        factionLeftTexture:SetTexCoord(0.765625, 1.0, 0.046875, 0.28125);
        factionRightTexture:SetTexCoord(0.0, 0.15234375, 0.390625, 0.625);
        factionBar:SetWidth(99);
    else
        if ( isChild ) then
            factionRow:SetPoint("LEFT", ArmoryReputationFrame, "LEFT", 52, 0);
        else
            factionRow:SetPoint("LEFT", ArmoryReputationFrame, "LEFT", 34, 0);
        end

        factionButton:Hide();
        factionTitle:SetPoint("LEFT", factionRow, "LEFT", 10, 0);
        factionTitle:SetPoint("RIGHT", factionBar, "LEFT", -3, 0);
        factionTitle:SetFontObject(GameFontHighlightSmall);
        factionBackground:Show();
        factionLeftTexture:SetHeight(21);
        factionRightTexture:SetHeight(21);
        factionLeftTexture:SetTexCoord(0.7578125, 1.0, 0.0, 0.328125);
        factionRightTexture:SetTexCoord(0.0, 0.1640625, 0.34375, 0.671875);
        factionBar:SetWidth(101)
    end

    if ( (hasRep) or (not isHeader) ) then
        factionStanding:Show();
        factionBar:Show();
        factionBar:GetParent().hasRep = true;
    else
        factionStanding:Hide();
        factionBar:Hide();
        factionBar:GetParent().hasRep = false;
    end
end

function ArmoryReputationFrame_Update()
    ArmoryReputationFrame.paragonFramesPool:ReleaseAll();

    local numFactions = Armory:GetNumFactions();
    local factionIndex, factionRow, factionTitle, factionStanding, factionBar, factionButton, factionBackground;
    local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, isCapped;
    local atWarIndicator, rightBarTexture;

    -- Update scroll frame
    if ( not FauxScrollFrame_Update(ArmoryReputationListScrollFrame, numFactions, NUM_FACTIONS_DISPLAYED, ARMORY_REPUTATIONFRAME_FACTIONHEIGHT ) ) then
        ArmoryReputationListScrollFrameScrollBar:SetValue(0);
    end
    local factionOffset = FauxScrollFrame_GetOffset(ArmoryReputationListScrollFrame);

    local gender = Armory:UnitSex("player");

    local offScreenFudgeFactor = 5;
    local previousBigTextureRows = 0;
    local previousBigTextureRows2 = 0;
    for i = 1, NUM_FACTIONS_DISPLAYED do
        factionIndex = factionOffset + i;
        factionRow = _G["ArmoryReputationBar"..i];
        factionBar = _G["ArmoryReputationBar"..i.."ReputationBar"];
        factionTitle = _G["ArmoryReputationBar"..i.."FactionName"];
        factionButton = _G["ArmoryReputationBar"..i.."ExpandOrCollapseButton"];
        factionStanding = _G["ArmoryReputationBar"..i.."ReputationBarFactionStanding"];
        factionBackground = _G["ArmoryReputationBar"..i.."Background"];
        if ( factionIndex <= numFactions ) then
            name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, isCapped = Armory:GetFactionInfo(factionIndex);
            factionTitle:SetText(name);
            if ( isCollapsed ) then
                factionButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
            else
                factionButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
            end
            factionRow.index = factionIndex;
            factionRow.isCollapsed = isCollapsed;

            local factionStandingtext;

            if ( factionID and Armory:IsFactionParagon(factionID) ) then
                local paragonFrame = ArmoryReputationFrame.paragonFramesPool:Acquire();
                paragonFrame.factionID = factionID;
                paragonFrame.standingID = standingID;
                paragonFrame:SetPoint("RIGHT", factionRow, 11, 0);
                local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon = Armory:GetFactionParagonInfo(factionID);
                paragonFrame.Glow:SetShown(not tooLowLevelForParagon and hasRewardPending);
                paragonFrame.Check:SetShown(not tooLowLevelForParagon and hasRewardPending);
                paragonFrame:Show();
            end

            -- description contains friendship
            if ( description ) then
                factionStandingtext = description;
            else
                factionStandingtext = GetText("FACTION_STANDING_LABEL"..standingID, gender);
            end
            factionStanding:SetText(factionStandingtext);

            -- Normalize values
            barMax = barMax - barMin;
            barValue = barValue - barMin;
            barMin = 0;

            factionRow.standingText = factionStandingtext;
            if ( isCapped ) then
                factionRow.standingProgress = nil;
            else
                factionRow.standingProgress = HIGHLIGHT_FONT_COLOR_CODE.." "..format(REPUTATION_PROGRESS_FORMAT, BreakUpLargeNumbers(barValue), BreakUpLargeNumbers(barMax))..FONT_COLOR_CODE_CLOSE;
            end
            factionBar:SetFillStyle("STANDARD_NO_RANGE_FILL");
            factionBar:SetMinMaxValues(0, barMax);
            factionBar:SetValue(barValue);

            local color = FACTION_BAR_COLORS[standingID];
            if ( factionID and C_Reputation.IsMajorFaction(factionID) ) then
                color = BLUE_FONT_COLOR;
            end
            factionBar:SetStatusBarColor(color.r, color.g, color.b);

            factionBar.BonusIcon:SetShown(hasBonusRepGain);

            ArmoryReputationFrame_SetRowType(factionRow, isChild, isHeader, hasRep);

            factionRow:Show();

            -- Update details if this is the selected faction
            if ( atWarWith ) then
                _G["ArmoryReputationBar"..i.."ReputationBarAtWarHighlight1"]:Show();
                _G["ArmoryReputationBar"..i.."ReputationBarAtWarHighlight2"]:Show();
            else
                _G["ArmoryReputationBar"..i.."ReputationBarAtWarHighlight1"]:Hide();
                _G["ArmoryReputationBar"..i.."ReputationBarAtWarHighlight2"]:Hide();
            end
            if ( factionIndex ~= ArmoryReputationFrame.selectedFaction ) then
                _G["ArmoryReputationBar"..i.."ReputationBarHighlight1"]:Hide();
                _G["ArmoryReputationBar"..i.."ReputationBarHighlight2"]:Hide();
            end
        else
            factionRow:Hide();
        end
    end
end

function ArmoryReputationBar_OnLoad(self)
    local name = self:GetName();
    _G[name.."ReputationBarHighlight1"]:SetPoint("TOPLEFT", self, "TOPLEFT", -2, 4);
    _G[name.."ReputationBarHighlight1"]:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -10, -4);
    _G[name.."ReputationBarAtWarHighlight1"]:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -2);
    _G[name.."ReputationBarAtWarHighlight2"]:SetPoint("TOPRIGHT", self, "TOPRIGHT", -1, -2);
    _G[name.."ReputationBarAtWarHighlight1"]:SetAlpha(0.2);
    _G[name.."ReputationBarAtWarHighlight2"]:SetAlpha(0.2);
    _G[name.."Background"]:SetPoint("TOPRIGHT", name.."ReputationBarLeftTexture", "TOPLEFT", 0, 0);
end

function ArmoryReputationBar_OnClick(self)
    if ( IsModifiedClick("CHATLINK") ) then
        if ( self.hasRep ) then
            local name, standing, standingID, barMin, barMax, barValue = Armory:GetFactionInfo(self.index);
            if ( name ) then
                if ( not standing ) then
                    standing = GetText("FACTION_STANDING_LABEL"..standingID, Armory:UnitSex("player"));
                end
                local text = format(ARMORY_REPUTATION_SUMMARY, name, standing, barValue - barMin, barMax - barMin, barMax - barValue);
                if ( not ChatEdit_InsertLink(text) ) then
                    ChatFrame_OpenChat(text);
                end
            end
        end
    end
end

local standings = {};
function ArmoryReputationBar_OnEnter(self)
    local name = self:GetName();
    local factionName = _G[name.."FactionName"]:GetText();

    if (self.standingProgress) then
      _G[name.."ReputationBarFactionStanding"]:SetText(self.standingProgress);
    end
    _G[name.."ReputationBarHighlight1"]:Show();
    _G[name.."ReputationBarHighlight2"]:Show();

    table.wipe(standings);

    if ( self.hasRep ) then
        local currentProfile = Armory:CurrentProfile();

        for _, profile in ipairs(Armory:GetConnectedProfiles()) do
            Armory:SelectProfile(profile);

            local numFactions = Armory:GetNumFactions();
            local name, description, standingID, barMin, barMax, barValue, factionID;
            local currentValue, threshold, hasRewardPending, value;
            local color;
            for index = 1, Armory:GetNumFactions() do
                name, description, standingID, barMin, barMax, barValue, _, _, _, _, _, _, _, factionID = Armory:GetFactionInfo(index);
                color = NORMAL_FONT_COLOR;
                if ( name and name == factionName ) then
                    if ( not description ) then
                        description = GetText("FACTION_STANDING_LABEL"..standingID, Armory:UnitSex("player"));
                    end

                    if ( factionID and Armory:IsFactionParagon(factionID) ) then
                        currentValue, threshold, _, hasRewardPending = Armory:GetFactionParagonInfo(factionID);
                        if ( currentValue and threshold ) then
                            value = mod(currentValue, threshold);
                            -- show overflow if reward is pending
                            if ( hasRewardPending ) then
                                value = value + threshold;
                                color = RED_FONT_COLOR;
                            end
                            barMin = 0;
                            barMax = threshold;
                            barValue = value;
                        end
                    end

                    name = Armory:GetQualifiedCharacterName();
                    table.insert(standings, {name=name, description=description, barMin=barMin, barMax=barMax, barValue=barValue, color=color});
                    break;
                end
            end
        end
        Armory:SelectProfile(currentProfile);

        table.sort(standings, function(a, b) return a.barValue < b.barValue; end);
    end

    if ( #standings > 0 ) then
        local index, column, myColumn;

        self.tooltip = Armory.qtip:Acquire("ArmoryStandingsTooltip", 3);
        self.tooltip:Clear();
        self.tooltip:SetScale(Armory:GetConfigFrameScale());
        self.tooltip:SetFrameLevel(self:GetFrameLevel() + 1);
        self.tooltip:ClearAllPoints();
        self.tooltip:SetClampedToScreen(1);
        self.tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT");

        index, column = self.tooltip:AddLine();
        myColumn = column; index, column = self.tooltip:SetCell(index, myColumn, factionName, GameTooltipHeaderText, "LEFT", 3);

        self.tooltip:AddSeparator(3);
        local barMax, barValue;
        for _, standing in next, standings do
            -- Normalize Values
            barMax = standing.barMax - standing.barMin;
            barValue = standing.barValue - standing.barMin;

            index, column = self.tooltip:AddLine();
            myColumn = column; index, column = self.tooltip:SetCell(index, myColumn, standing.name);
            myColumn = column; index, column = self.tooltip:SetCell(index, myColumn, standing.description);
            myColumn = column; index, column = self.tooltip:SetCell(index, myColumn, standing.color:WrapTextInColorCode(barValue.." / "..barMax), nil, "RIGHT");
        end
        self.tooltip:Show();

    elseif ( _G[name.."FactionName"]:IsTruncated() ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(factionName, nil, nil, nil, nil, true);
        GameTooltip:Show();

    end
end

function ArmoryReputationBar_OnLeave(self)
    local name = self:GetName();

    _G[name.."ReputationBarFactionStanding"]:SetText(self.standingText);
    if (self.selectedFaction ~= self.index) then
      _G[name.."ReputationBarHighlight1"]:Hide();
      _G[name.."ReputationBarHighlight2"]:Hide();
    end

    if ( self.tooltip ) then
        Armory.qtip:Release(self.tooltip);
        self.tooltip = nil;
    end
    GameTooltip:Hide();
end

function ArmoryReputationParagonFrame_SetupParagonTooltip(frame)
    GameTooltip.owner = frame;
    GameTooltip.factionID = frame.factionID;
    GameTooltip.standingID = frame.standingID;

    local factionName = GetFactionInfoByID(frame.factionID);
    local gender = Armory:UnitSex("player");
    local factionStandingtext = GetText("FACTION_STANDING_LABEL"..frame.standingID, gender);
    local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon = Armory:GetFactionParagonInfo(frame.factionID);

    if ( tooLowLevelForParagon ) then
        GameTooltip_SetTitle(GameTooltip, PARAGON_REPUTATION_TOOLTIP_TEXT_LOW_LEVEL, NORMAL_FONT_COLOR);
    else
        GameTooltip_SetTitle(GameTooltip, factionStandingtext, NORMAL_FONT_COLOR);
        local description = PARAGON_REPUTATION_TOOLTIP_TEXT:format(factionName);
        GameTooltip_AddHighlightLine(GameTooltip, description);
        if ( not hasRewardPending and currentValue and threshold ) then
            local value = mod(currentValue, threshold);
            -- show overflow if reward is pending
            if ( hasRewardPending ) then
                value = value + threshold;
            end
            GameTooltip_ShowProgressBar(GameTooltip, 0, threshold, value, REPUTATION_PROGRESS_FORMAT:format(value, threshold));
        end
        GameTooltip_AddQuestRewardsToTooltip(GameTooltip, rewardQuestID);
    end
    GameTooltip:Show();
end

function ArmoryReputationParagonFrame_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    ArmoryReputationParagonFrame_SetupParagonTooltip(self);
end

function ArmoryReputationParagonFrame_OnLeave(self)
    GameTooltip:Hide();
end

function ArmoryReputationParagonFrame_OnUpdate(self)
    if ( self.Glow:IsShown() ) then
        local alpha;
        local time = GetTime();
        local value = time - floor(time);
        local direction = mod(floor(time), 2);
        if ( direction == 0 ) then
            alpha = value;
        else
            alpha = 1 - value;
        end
        self.Glow:SetAlpha(alpha);
    end
end