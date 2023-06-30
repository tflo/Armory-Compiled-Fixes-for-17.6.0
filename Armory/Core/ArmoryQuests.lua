--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 204 2023-05-14T11:21:00Z
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
local container = "Quests";

local selectedQuestLine = 0;
local questLogFilter = "";

local table = table;
local select = select;
local pairs = pairs;
local ipairs = ipairs;
local tostring = tostring;
local string = string;
local strlower = strlower;
local strtrim = strtrim;
local time = time;

----------------------------------------------------------
-- Quests Internals
----------------------------------------------------------

local questLines = {};
local questCount = 0;
local dirty = true;
local owner = "";

local function ShouldShowHeaderButton(info)
    -- NOTE: Info must refer to a header and it shouldDisplay must have been determined in advance.
    return info.isHeader and info.shouldDisplay;
end

local function ShouldShowQuestButton(info)
    -- If it's not a quest, then it shouldn't show as a quest button
    if ( info.isHeader ) then
        return false;
    end

    -- If it is a quest, but its header is collapsed, then it shouldn't show
    if ( info.header and info.header.isCollapsed ) then
        return false;
    end

    -- Normal rules about quest visibility.
    return not info.isTask and not info.isHidden and (not info.isBounty or info.isComplete);
end

local function ShouldCountAsQuest(info)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( info.isHeader ) then
        return false;
    end

    local id = tostring(info.questID);
    local tagInfo = dbEntry:GetValue(container, id, "Tag");
    local questTagID = tagInfo and tagInfo.tagID;
    if ( questTagID == Enum.QuestTag.Account ) then
        return false;
    end

    return not info.isTask and not info.isHidden and (not info.isBounty or info.isComplete);
end

local function BuildSingleQuestInfo(questLogIndex, questInfoContainer, lastHeader)
    local dbEntry = Armory.selectedDbBaseEntry;
    local title, _, _, isHeader, isCollapsed, isComplete, _, questID, _, _, _, _, isTask, isBounty, _, isHidden, _, _, campaignID, isCalling = dbEntry:GetValue(container, questLogIndex, "Info");
    if ( not title ) then
        return;
    end

    local info =  {
        questLogIndex = questLogIndex,
        title = title,
        isHeader = isHeader,
        isCollapsed = Armory:GetHeaderLineState(container, title),
        questID = questID,
        isTask = isTask,
        isBounty = isBounty,
        isHidden = isHidden,
        isComplete = isComplete and isComplete > 0,
        campaignID = campaignID,
        isCalling = isCalling
    };

    questInfoContainer[questLogIndex] = info;

    -- Precompute whether or not the headers should display so that it's easier to add them later.
    -- We don't care about collapsed states, we only care about the fact that there are any quests
    -- to display under the header.
    -- Caveat: Campaign headers will always display, otherwise they wouldn't be added to the quest log!
    if ( info.isHeader ) then
        lastHeader = info;

        local isCampaign = info.campaignID ~= nil;
        info.shouldDisplay = isCampaign; -- Always display campaign headers, the rest start as hidden
    else
        -- "Intro" Callings go into Campaigns...current move is to not let them display under a calling header, because they will be duplicated
        info.isCalling = info.campaignID == nil and info.isCalling;

        if ( lastHeader and not lastHeader.shouldDisplay ) then
            lastHeader.shouldDisplay = info.isCalling or ShouldShowQuestButton(info);
        end

        -- Make it easy for a quest to look up its header
        info.header = lastHeader;

        if ( info.isCalling and info.header and not info.header.isCampaign ) then
            info.header.isCalling = true;
        end
    end

    return lastHeader;
end

local function BuildQuestInfoContainer()
    local dbEntry = Armory.selectedDbBaseEntry;
    local questInfoContainer = {};

    if ( dbEntry ) then
        local numEntries = dbEntry:GetNumValues(container);
        local lastHeader;

        for questLogIndex = 1, numEntries do
            lastHeader = BuildSingleQuestInfo(questLogIndex, questInfoContainer, lastHeader);
        end
    end

    return questInfoContainer;
end

local function MeetsQuestLogFilter(info)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( questLogFilter == "" ) then
        return true;
    end

    local id = tostring(info.questID);
    local text = info.title.."\t"..dbEntry:GetValue(container, id, "Text");
    local numItems = dbEntry:GetNumValues(container, id, "LeaderBoards");
    for index = 1, numItems do
        text = text.."\t"..(dbEntry:GetValue(container, id, "LeaderBoards", index) or "");
    end
    numItems = dbEntry:GetNumValues(container, id, "Rewards");
    for index = 1, numItems do
        text = text.."\t"..(dbEntry:GetValue(container, id, "Rewards", index) or "");
    end
    local _, name = dbEntry:GetValue(container, id, "RewardSpell");
    if ( name ) then
        text = text.."\t"..name;
    end

    return string.find(strlower(text), strlower(questLogFilter), 1, true);
end

local function GetQuestLines()
    local dbEntry = Armory.selectedDbBaseEntry;

    local infos = BuildQuestInfoContainer();
    local hasItems = (questLogFilter == "");
    local include, text, name;

    table.wipe(questLines);
    questCount = 0;

    for _, info in ipairs(infos) do
        if ( ShouldShowHeaderButton(info) ) then
            table.insert(questLines, info.questLogIndex);
        else
            if ( ShouldCountAsQuest(info) ) then
                questCount = questCount + 1;
            end
            if ( ShouldShowQuestButton(info) and MeetsQuestLogFilter(info) ) then
                hasItems = true;
                table.insert(questLines, info.questLogIndex);
            end
        end
    end

    if ( not hasItems ) then
        table.wipe(questLines);
    end

    dirty = false;
    owner = Armory:SelectedCharacter();

    return questLines;
end

local function GetQuestLineValue(index, key, subkey)
    local dbEntry = Armory.selectedDbBaseEntry;
    local numLines = Armory:GetNumQuestLogEntries();
    if ( dbEntry and index > 0 and index <= numLines ) then
        local questID = select(8, dbEntry:GetValue(container, questLines[index], "Info"));
        if ( subkey ) then
            return dbEntry:GetValue(container, tostring(questID), key, subkey);
        elseif ( key ) then
            return dbEntry:GetValue(container, tostring(questID), key);
        else
            return dbEntry:GetValue(container, questLines[index], "Info");
        end
    end
end

local function UpdateQuestHeaderState(index, isCollapsed)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( dbEntry ) then
        if ( index == 0 ) then
            for i = 1, dbEntry:GetNumValues(container) do
                local name, _, _, isHeader = dbEntry:GetValue(container, i, "Info");
                if ( isHeader ) then
                    Armory:SetHeaderLineState(container, name, isCollapsed);
                end
            end
        else
            local numLines = Armory:GetNumQuestLogEntries();
            if ( index > 0 and index <= numLines ) then
                local name = dbEntry:GetValue(container, questLines[index], "Info");
                Armory:SetHeaderLineState(container, name, isCollapsed);
            end
        end
    end

    dirty = true;
end

----------------------------------------------------------
-- Quests Storage
----------------------------------------------------------

function Armory:QuestsExists()
    local dbEntry = self.playerDbBaseEntry;
    return dbEntry and dbEntry:Contains(container);
end

function Armory:ClearQuests()
    self:ClearModuleData(container);
    dirty = true;
end

local retries = 0;
function Armory:UpdateQuests()
    local dbEntry = self.playerDbBaseEntry;
    if ( not dbEntry ) then
        return;
    end

    if ( not self:IsLocked(container) ) then
        if ( self.ignoreQuestUpdate ) then
            self.ignoreQuestUpdate = false;
            return;
        end

        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        if ( self:HasQuestLog() ) then
            local success, dataMissing;

            local numQuests = 0;
            local currentQuest = C_QuestLog.GetSelectedQuest();

            -- store the complete (expanded) list
            local funcNumLines = C_QuestLog.GetNumQuestLogEntries;
            local funcGetLineInfo = function(index)
                local info = C_QuestLog.GetInfo(index);
                local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent;
                local displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling;
                local difficultyLevel, campaignID, isCalling;
                title = info.title;
                level = info.level;
                suggestedGroup = info.suggestedGroup;
                isHeader = info.isHeader;
                isCollapsed = info.isCollapsed;
                if ( C_QuestLog.IsComplete(info.questID) ) then
                    isComplete = 1;
                elseif ( C_QuestLog.IsFailed(info.questID) ) then
                    isComplete = -1;
                else
                    isComplete = 0;
                end
                frequency = info.frequency;
                questID = info.questID;
                startEvent = info.startEvent;
                displayQuestID = GetCVarBool("displayQuestID");
                isOnMap = info.isOnMap;
                hasLocalPOI = info.hasLocalPOI;
                isTask = info.isTask;
                isBounty = info.isBounty;
                isStory = info.isStory;
                isHidden = info.isHidden;
                isScaling = info.isScaling;
                difficultyLevel = info.difficultyLevel;
                campaignID = info.campaignID;
                isCalling = C_QuestLog.IsQuestCalling(info.questID);
                return title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling, difficultyLevel, campaignID, isCalling;
            end;
            local funcGetLineState = function(index)
                local info = C_QuestLog.GetInfo(index);
                if ( info ) then
                    return info.isHeader, not info.isCollapsed;
                end
            end;
            local funcExpand = _G.ExpandQuestHeader;
            local funcCollapse = _G.CollapseQuestHeader;
            local funcSelect = function(index)
                C_QuestLog.SetSelectedQuest(C_QuestLog.GetInfo(index).questID);
                ProcessQuestLogRewardFactions();
            end;
            local funcAdditionalInfo = function(index)
                numQuests = numQuests + 1;

                local questID = C_QuestLog.GetInfo(index).questID;
                local link = _G.GetQuestLink(questID);
                local id = tostring(questID);
                local info = dbEntry:SelectContainer(container, id);
                info.Link = link;
                info.Text = dbEntry.Save(_G.GetQuestLogQuestText());
                info.Tag = C_QuestLog.GetQuestTagInfo(questID);
                if ( _G.IsCurrentQuestFailed() ) then
                    info.Failed = _G.IsCurrentQuestFailed();
                end
                if ( _G.GetQuestLogTimeLeft() ) then
                    info.TimeLeft = dbEntry.Save(_G.GetQuestLogTimeLeft(), time());
                end
                if ( C_QuestLog.GetRequiredMoney() > 0 ) then
                    info.RequiredMoney = C_QuestLog.GetRequiredMoney();
                end
                if ( _G.GetQuestLogRewardMoney() > 0 ) then
                    info.RewardMoney = _G.GetQuestLogRewardMoney();
                end
                local spellRewards = C_QuestInfoSystem.GetQuestRewardSpells(questID) or {};
                if ( #spellRewards > 0 ) then
                    info.RewardSpells = {};
                    for index, spellID in ipairs(spellRewards) do
                        if ( spellID and spellID > 0 ) then
                            local spellInfo = C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID);
                            local knownSpell = IsSpellKnownOrOverridesKnown(spellID);

                            -- only allow the spell reward if user can learn it
                            if ( spellInfo and spellInfo.texture and not knownSpell and (not spellInfo.isBoostSpell or IsCharacterNewlyBoosted()) and (not spellInfo.garrFollowerID or not C_Garrison.IsFollowerCollected(spellInfo.garrFollowerID)) ) then
                                local knownSpell = _G.IsSpellKnownOrOverridesKnown(spellID);
                                local isFollowerCollected = spellInfo.garrFollowerID and C_Garrison.IsFollowerCollected(spellInfo.garrFollowerID);

                                info.RewardSpells[index] = dbEntry.Save(
                                    spellInfo.texture,
                                    spellInfo.name,
                                    spellInfo.isTradeskill,
                                    spellInfo.isSpellLearned,
                                    spellInfo.hideSpellLearnText,
                                    spellInfo.isBoostSpell,
                                    spellInfo.garrFollowerID,
                                    spellInfo.genericUnlock,
                                    spellID,
                                    knownSpell,
                                    isFollowerCollected,
                                    spellInfo.type
                                );
                            end
                        end
                    end
                end
                if ( _G.GetQuestLogRewardXP() > 0 ) then
                    info.RewardXP = _G.GetQuestLogRewardXP();
                end
                if ( _G.GetQuestLogRewardArtifactXP() ) then
                    info.RewardArtifactXP = dbEntry.Save(_G.GetQuestLogRewardArtifactXP());
                end
                if ( _G.GetQuestLogRewardHonor() ) then
                    info.RewardHonor = _G.GetQuestLogRewardHonor();
                end
                if ( _G.GetQuestLogRewardSkillPoints() ) then
                    info.RewardSkillPoints = dbEntry.Save(_G.GetQuestLogRewardSkillPoints());
                end
                if ( _G.GetQuestLogRewardTitle() ) then
                    info.RewardTitle = _G.GetQuestLogRewardTitle();
                end
                if ( C_QuestLog.GetSuggestedGroupSize(questID) > 0 ) then
                    info.GroupNum = C_QuestLog.GetSuggestedGroupSize(questID);
                end
                if ( _G.GetQuestLogCriteriaSpell() ) then
                    info.CriteriaSpell = dbEntry.Save(_G.GetQuestLogCriteriaSpell());
                end
                if ( _G.GetNumQuestLeaderBoards() > 0 ) then
                    info.LeaderBoards = {};
                    for i = 1, _G.GetNumQuestLeaderBoards() do
                        info.LeaderBoards[i] = dbEntry.Save(_G.GetQuestLogLeaderBoard(i));
                    end
                end
                if ( _G.GetNumQuestLogRewards(questID) > 0 ) then
                    info.Rewards = {};
                    for i = 1, _G.GetNumQuestLogRewards(questID) do
                        local name, texture, numItems, quality, isUsable = _G.GetQuestLogRewardInfo(i, questID);
                        link = _G.GetQuestLogItemLink("reward", i, questID);
                        info.Rewards[i] = dbEntry.Save(name, texture, numItems, quality, isUsable, link);
                        if ( not link ) then
                            dataMissing = true;
                        end
                    end
                end
                if ( _G.GetNumQuestLogChoices(questID) > 0 ) then
                    info.Choices = {};
                    for i = 1, _G.GetNumQuestLogChoices(questID) do
                        local name, texture, numItems, quality, isUsable = _G.GetQuestLogChoiceInfo(i, questID);
                        link = _G.GetQuestLogItemLink("choice", i, questID);
                        info.Choices[i] = dbEntry.Save(name, texture, numItems, quality, isUsable, link);
                        if ( not link ) then
                            dataMissing = true;
                        end
                    end
                end
                if ( _G.GetNumQuestLogRewardCurrencies(questID) > 0 ) then
                    info.Currencies = {};
                    for i = 1, _G.GetNumQuestLogRewardCurrencies(questID) do
                        info.Currencies[i] = dbEntry.Save(_G.GetQuestLogRewardCurrencyInfo(i, questID));
                    end
                end
                return id;
            end;

            -- LightHeaded hooks SelectQuestLogEntry
            local stubbed;
            if ( LightHeaded ) then
                stubbed = LightHeaded.GetCurrentQID;
                LightHeaded.GetCurrentQID = function() return nil; end;
            end

            dbEntry:ClearContainer(container);

            if ( retries < 1 ) then
                -- if expand/collapse has been called a QUEST_LOG_UPDATE event will be fired immediately after the scan has been completed
                success, self.ignoreQuestUpdate = dbEntry:SetExpandableListValues(container, funcNumLines, funcGetLineState, funcGetLineInfo, funcExpand, funcCollapse, funcAdditionalInfo, funcSelect);
                if ( dataMissing or not success ) then
                    retries = retries + 1;
                    self:PrintDebug("Update failed; executing again...", retries);
                    self:ExecuteDelayed(5, function() Armory:UpdateQuests() end);
                else
                    retries = 0;
                end
            else
                retries = 0;
            end

            dbEntry:SetValue(2, container, "NumQuests", numQuests);

            C_QuestLog.SetSelectedQuest(currentQuest);

            if ( stubbed ) then
                LightHeaded.GetCurrentQID = stubbed;
            end
        else
            dbEntry:SetValue(container, nil);
        end

        dirty = dirty or self:IsPlayerSelected();

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Quests Interface
----------------------------------------------------------

function Armory:GetQuestLogIndexByName(name)
    local dbEntry = self.playerDbBaseEntry;
    if ( dbEntry and name ) then
        local count = dbEntry:GetNumValues(container);
        for i = 1, count do
            if ( strtrim(name) == dbEntry:GetValue(container, i, "Info") ) then
                return i;
            end
        end
    end
end

function Armory:GetQuestHeader(index)
    local dbEntry = self.playerDbBaseEntry;
    if ( dbEntry ) then
        for i = index, 1, -1 do
            local title, _, _, isHeader = dbEntry:GetValue(container, i, "Info");
            if ( isHeader ) then
                return title;
            end
        end
    end
    return UNKNOWN;
end

function Armory:IsOnQuest(id)
    local dbEntry = self.selectedDbBaseEntry;
    return dbEntry and dbEntry:Contains(container, id);
end

function Armory:GetNumQuestLogEntries()
    if ( dirty or not self:IsSelectedCharacter(owner) ) then
        GetQuestLines();
    end
    return #questLines, questCount;
end

function Armory:GetQuestLogTitle(index)
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling, difficultyLevel, campaignID, isCalling = GetQuestLineValue(index);
    isCollapsed = self:GetHeaderLineState(container, title);
    return title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling, difficultyLevel, campaignID, isCalling;
end

function Armory:ExpandQuestHeader(index)
    UpdateQuestHeaderState(index, false);
end

function Armory:CollapseQuestHeader(index)
    UpdateQuestHeaderState(index, true);
end

function Armory:GetQuestLink(index)
    return GetQuestLineValue(index, "Link");
end

function Armory:GetQuestLogSelection()
    return selectedQuestLine;
end

function Armory:SelectQuestLogEntry(index)
    selectedQuestLine = index;
end

function Armory:IsCurrentQuestFailed()
    return GetQuestLineValue(selectedQuestLine, "Failed");
end

function Armory:GetQuestLogQuestText()
    return GetQuestLineValue(selectedQuestLine, "Text");
end

function Armory:GetQuestLogTimeLeft()
    local timeLeft, timestamp = GetQuestLineValue(selectedQuestLine, "TimeLeft");

    if ( timeLeft ) then
        timeLeft = timeLeft - (time() - timestamp);
        if ( timeLeft < 0 ) then
            timeLeft = 0;
        end
    end
    return timeLeft;
end

function Armory:GetQuestLogRequiredMoney()
    return GetQuestLineValue(selectedQuestLine, "RequiredMoney") or 0;
end

function Armory:GetQuestLogRewardMoney()
    return GetQuestLineValue(selectedQuestLine, "RewardMoney") or 0;
end

function Armory:GetNumQuestLogRewardSpells()
    local spells = GetQuestLineValue(selectedQuestLine, "RewardSpells");
    if ( spells ) then
        return #spells;
    end
    return 0;
end

function Armory:GetQuestLogRewardSpell(id)
    return GetQuestLineValue(selectedQuestLine, "RewardSpells", id);
end

function Armory:GetQuestLogRewardXP()
    return GetQuestLineValue(selectedQuestLine, "RewardXP") or 0;
end

function Armory:GetQuestLogRewardArtifactXP()
    return GetQuestLineValue(selectedQuestLine, "RewardArtifactXP") or 0;
end

function Armory:GetQuestLogRewardHonor()
    return GetQuestLineValue(selectedQuestLine, "RewardHonor") or 0;
end

function Armory:GetQuestLogRewardSkillPoints()
    return GetQuestLineValue(selectedQuestLine, "RewardSkillPoints");
end

function Armory:GetQuestLogRewardTitle()
    return GetQuestLineValue(selectedQuestLine, "RewardTitle");
end

function Armory:GetQuestLogSpellLink(id)
    local spellId = select(9, self:GetQuestLogRewardSpell(id));
    local link = _G.GetSpellLink(spellId);
    return link;
end

function Armory:GetQuestLogGroupNum()
    return GetQuestLineValue(selectedQuestLine, "GroupNum") or 0;
end

function Armory:GetQuestLogCriteriaSpell()
    return GetQuestLineValue(selectedQuestLine, "CriteriaSpell");
end

function Armory:GetNumQuestLeaderBoards()
    local leaderBoards = GetQuestLineValue(selectedQuestLine, "LeaderBoards");
    if ( leaderBoards ) then
        return #leaderBoards;
    end
    return 0;
end

function Armory:GetQuestLogLeaderBoard(id)
    return GetQuestLineValue(selectedQuestLine, "LeaderBoards", id);
end

function Armory:GetNumQuestLogRewards()
    local rewards = GetQuestLineValue(selectedQuestLine, "Rewards");
    if ( rewards ) then
        return #rewards;
    end
    return 0;
end

function Armory:GetQuestLogRewardInfo(id)
    return GetQuestLineValue(selectedQuestLine, "Rewards", id);
end

function Armory:GetNumQuestLogChoices()
    local choices = GetQuestLineValue(selectedQuestLine, "Choices");
    if ( choices ) then
        return #choices;
    end
    return 0;
end

function Armory:GetQuestLogChoiceInfo(id)
    return GetQuestLineValue(selectedQuestLine, "Choices", id);
end

function Armory:GetNumQuestLogRewardCurrencies()
    local currencies = GetQuestLineValue(selectedQuestLine, "Currencies");
    if ( currencies ) then
        return #currencies;
    end
    return 0;
end

function Armory:GetQuestLogRewardCurrencyInfo(id)
    return GetQuestLineValue(selectedQuestLine, "Currencies", id);
end

function Armory:GetQuestLogItemLink(itemType, id)
    local link;
    if ( itemType == "reward" ) then
        link = select(6, self:GetQuestLogRewardInfo(id));
    elseif ( itemType == "choice" ) then
        link = select(6, self:GetQuestLogChoiceInfo(id));
    end
    return link;
end

function Armory:SetQuestLogFilter(text)
    local refresh = (questLogFilter ~= text);
    questLogFilter = text;
    return refresh;
end

function Armory:GetQuestLogFilter()
    return questLogFilter;
end

function Armory:GetQuestTagInfo(id)
    return GetQuestLineValue(selectedQuestLine, "Tag", id);
end

----------------------------------------------------------
-- Find Methods
----------------------------------------------------------

function Armory:FindQuest(...)
    local dbEntry = self.selectedDbBaseEntry;
    local list = {};

    if ( dbEntry ) then
        local numEntries = dbEntry:GetNumValues(container);
        if ( numEntries ) then
            local name, level, isHeader, link, text, questID;
            for index = 1, numEntries do
                name, level, _, isHeader, _, _, _, questID = dbEntry:GetValue(container, index, "Info");
                if ( not isHeader ) then
                    link = dbEntry:GetValue(container, tostring(questID), "Link");
                    if ( self:GetConfigExtendedSearch() ) then
                        text = self:GetTextFromLink(link);
                    else
                        text = name;
                    end
                    if ( self:FindTextParts(text, ...) ) then
                        name = self:HexColor(ArmoryGetDifficultyColor(level))..name..FONT_COLOR_CODE_CLOSE;
                        table.insert(list, {label=QUEST_LOG, name=name, link=link});
                    end
                end
            end
        end
    end

    return list;
end

function Armory:FindQuestItem(itemList, ...)
    local dbEntry = self.selectedDbBaseEntry;
    local list = itemList or {};

    if ( dbEntry ) then
        local numEntries = dbEntry:GetNumValues(container);
        if ( numEntries ) then
            local questLogTitleText, level, isHeader, questID;
            local text, label, name, link, id;

            for index = 1, numEntries do
                questLogTitleText, level, _, isHeader, _, _, _, questID = dbEntry:GetValue(container, index, "Info");
                if ( not isHeader ) then
                    id = tostring(questID);
                    label = ARMORY_CMD_FIND_QUEST_REWARD.." "..self:HexColor(ArmoryGetDifficultyColor(level))..questLogTitleText..FONT_COLOR_CODE_CLOSE;
                    for _, key in ipairs({"Choices", "Rewards"}) do
                        for i = 1, dbEntry:GetNumValues(container, id, key) do
                            name, _, _, _, _, link = dbEntry:GetValue(container, id, key, i);
                            if ( self:GetConfigExtendedSearch() ) then
                                text = self:GetTextFromLink(link);
                            else
                                text = name;
                            end
                            if ( self:FindTextParts(text, ...) ) then
                                table.insert(list, {label=label, name=name, link=link});
                            end
                        end
                    end
                end
            end
        end
    end

    return list;
end

function Armory:FindQuestSpell(spellList, ...)
    local dbEntry = self.selectedDbBaseEntry;
    local list = spellList or {};

    if ( dbEntry ) then
        local numEntries = dbEntry:GetNumValues(container);
        if ( numEntries ) then
            local questLogTitleText, level, isHeader, questID;
            local text, label, name, link, id;

            for index = 1, numEntries do
                questLogTitleText, level, _, isHeader, _, _, _, questID = dbEntry:GetValue(container, index, "Info");
                if ( not isHeader ) then
                    id = tostring(questID);
                    if ( dbEntry:GetValue(container, id, "RewardSpell") ) then
                        _, name = dbEntry:GetValue(container, id, "RewardSpell");
                        link = dbEntry:GetValue(container, id, "SpellLink");
                        if ( self:GetConfigExtendedSearch() ) then
                            text = self:GetTextFromLink(link);
                        else
                            text = name;
                        end
                        if ( self:FindTextParts(text, ...) ) then
                            label = ARMORY_CMD_FIND_QUEST_REWARD.." "..self:HexColor(ArmoryGetDifficultyColor(level))..questLogTitleText..FONT_COLOR_CODE_CLOSE;
                            table.insert(list, {label=label, name=name, link=link});
                        end
                    end
                end
            end
        end
    end

    return list;
end