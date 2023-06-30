--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 226 2022-11-19T21:41:37Z
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

ARMORY_OTHER_TABS = {REPUTATION_ABBR, RAID, CURRENCY};

local OTHERFRAME_SUBFRAMES = { "ArmoryReputationFrame", "ArmoryRaidInfoFrame", "ArmoryTokenFrame" };

function ArmoryOtherFrame_ShowSubFrame()
    for index, value in pairs(OTHERFRAME_SUBFRAMES) do
        _G[value]:Hide();
        if ( value == OTHERFRAME_SUBFRAMES[ArmoryPanelTemplates_GetSelectedTab(ArmoryOtherFrame)] ) then
            _G[value]:Show();
        end
    end
end

function ArmoryOtherFrame_OpenSubFrame(id)
    local tab = _G["ArmoryOtherFrameTab"..id];
    if ( tab.enabled == nil or tab.enabled ) then
        if ( not tab:IsVisible() ) then
            ArmoryFrame_OpenFrame(5);
        end
        ArmoryOtherFrameTab_OnClick(tab);
    end
end

function ArmoryOtherFrameTab_OnClick(self)
    ArmoryPanelTemplates_SetTab(ArmoryOtherFrame, self:GetID());
    ArmoryOtherFrame_ShowSubFrame();
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

function ArmoryOtherFrame_OnLoad(self)
    -- update the tabs
    ArmoryPanelTemplates_SetNumTabs(self, #ARMORY_OTHER_TABS);
    ArmoryPanelTemplates_UpdateTabs(self);
    ArmoryPanelTemplates_SetTab(self, 1);
end

function ArmoryOtherFrame_OnShow(self)
    local firstTab, numTabs = ArmoryOtherFrameTab_Update();
    if ( numTabs > 0 ) then
        local currentTab = ArmoryPanelTemplates_GetSelectedTab(self);
        if ( currentTab and _G["ArmoryOtherFrameTab"..currentTab]:IsShown() ) then
            ArmoryPanelTemplates_SetTab(self, currentTab);
        else
            ArmoryPanelTemplates_SetTab(self, firstTab);
        end
        if ( numTabs == 1 ) then
            _G["ArmoryOtherFrameTab"..firstTab]:Hide();
        end

        ArmoryReputationFrame_UpdateHeader(numTabs == 1);
        ArmoryOtherFrame_ShowSubFrame();
    end
end

local function TabAdjust(id, enable, firstTab, numTabs)
    local tab = _G["ArmoryOtherFrameTab"..id];
    local nextTab = _G["ArmoryOtherFrameTab"..(id+1)];
    local frame = _G[OTHERFRAME_SUBFRAMES[id]];
    tab.enabled = enable;
    if ( not enable ) then
        if ( frame:IsVisible() ) then
             frame:Hide();
        end
        tab:Hide();
        if ( nextTab ) then
            nextTab:SetPoint("LEFT", tab, "LEFT", 0, 0);
        end
    else
        tab:Show();
        if ( nextTab ) then
            nextTab:SetPoint("LEFT", tab, "RIGHT", -8, 0); -- -16, 0);
        end
        if ( not firstTab ) then
            firstTab = id;
        end
        numTabs = numTabs + 1;
    end
    return firstTab, numTabs;
end

function ArmoryOtherFrameTab_Update()
    local numTabs = 0;
    local firstTab;

    firstTab, numTabs = TabAdjust(1, Armory:HasReputation(), firstTab, numTabs);
    firstTab, numTabs = TabAdjust(2, Armory:RaidEnabled(), firstTab, numTabs);
    firstTab, numTabs = TabAdjust(3, Armory:HasCurrency(), firstTab, numTabs);

    if ( numTabs > 0 ) then
        local tab;
        local totalTabWidth = 0;
        local tabWidthCache = {};
        for i, tab in ipairs(ArmoryOtherFrame.Tabs) do
            tabWidthCache[i] = 0;
            if ( i <= #ARMORY_OTHER_TABS and tab:IsShown() ) then
                tab:SetText(ARMORY_OTHER_TABS[i]);
                ArmoryPanelTemplates_TabResize(tab, 0);
                tab.Text:SetWidth(0);
                tabWidthCache[i] = ArmoryPanelTemplates_GetTabWidth(tab);
                totalTabWidth = totalTabWidth + tabWidthCache[i];
            else
                tab:Hide();
             end
        end
        ArmoryPanelTemplates_ResizeTabsToFit(ArmoryOtherFrame.Tabs, totalTabWidth, 260, tabWidthCache);

        if ( numTabs == 1 ) then
            _G["ArmoryOtherFrameTab"..firstTab]:Hide();
        end
        ArmoryReputationFrame_UpdateHeader(numTabs == 1);
    end

    return firstTab, numTabs;
end

local tabNames = {};
function ArmoryOtherFrame_TabNames()
    table.wipe(tabNames);
    for i = 1, #ARMORY_OTHER_TABS do
        local tab = _G["ArmoryOtherFrameTab"..i];
        if ( tab.enabled ) then
            table.insert(tabNames, tab:GetText());
        end
    end
    return strjoin(", ", unpack(tabNames));
end