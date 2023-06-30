--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 186 2023-02-21T19:10:16Z
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

local ROW_HEIGHT = 16;
local LIST_FULL_HEIGHT = 128;

local MAX_TRADE_SKILL_REAGENTS = 8;
local TRADE_SKILL_TEXT_WIDTH = 270;
local TRADE_SKILL_SKILLUP_TEXT_WIDTH = 30;
local SUB_SKILL_BAR_WIDTH = 60;

ArmoryTradeSkillTypePrefix = {
    optimal      = " [+++] ",
    medium       = " [++] ",
    easy         = " [+] ",
    trivial      = " ",
    header       = " ",
    subheader    = " ",
    nodifficulty = " ",
}

ArmoryTradeSkillTypeColor = {
    optimal      = { r = 1.00, g = 0.50, b = 0.25, font = GameFontNormalLeftOrange };
    medium       = { r = 1.00, g = 1.00, b = 0.00, font = GameFontNormalLeftYellow };
    easy         = { r = 0.25, g = 0.75, b = 0.25, font = GameFontNormalLeftLightGreen };
    trivial      = { r = 0.50, g = 0.50, b = 0.50, font = GameFontNormalLeftGrey };
    header       = { r = 1.00, g = 0.82, b = 0,    font = GameFontNormalLeft };
    subheader    = { r = 1.00, g = 0.82, b = 0,    font = GameFontNormalLeft };
    nodifficulty = { r = 0.96, g = 0.96, b = 0.96, font = GameFontNormalLeftGrey };
};


----------------------------------------------------------
-- TradeSkillFrame Mixin
----------------------------------------------------------

ArmoryTradeSkillFrameMixin = {}

function ArmoryTradeSkillFrameMixin:OnLoad()
    self:SetPortraitToAsset("Interface\\Spellbook\\Spellbook-Icon");
    self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -73);
    self.Inset:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -6, -210);
    self.bottomInset.Bg:SetAtlas("Professions-Recipe-Background", false);

    self.RecipeList:SetRecipeChangedCallback(function(...) self:OnRecipeChanged(...) end);

    self:RegisterEvent("TRADE_SKILL_LIST_UPDATE");
    self:RegisterEvent("TRADE_SKILL_DETAILS_UPDATE");
    self:RegisterEvent("TRADE_SKILL_NAME_UPDATE");

    ArmoryDropDownMenu_Initialize(self.FilterDropDown, function(...) self:InitFilterMenu(...) end, "MENU");
end

local function CanUpdate()
    local professionInfo = C_TradeSkillUI.GetChildProfessionInfo();
    if ( professionInfo.professionID == 0 ) then
        professionInfo = C_TradeSkillUI.GetBaseProfessionInfo();
    end
    return C_TradeSkillUI.IsTradeSkillReady() and professionInfo.professionID;
end

local doUpdate;
function ArmoryTradeSkillFrameMixin:OnEvent(event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( C_TradeSkillUI.IsTradeSkillLinked() or C_TradeSkillUI.IsTradeSkillGuild() or C_TradeSkillUI.IsNPCCrafting() or C_TradeSkillUI.IsRuneforging() ) then
        return;
    end

    if ( not doUpdate ) then
        doUpdate = function() self:Update() end;
    end
    Armory:ExecuteConditional(CanUpdate, doUpdate);
end

function ArmoryTradeSkillFrameMixin:OnShow()
    PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN);
end

function ArmoryTradeSkillFrameMixin:OnHide()
    PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE);
end

function ArmoryTradeSkillFrameMixin:Update()
    local currentSkill = Armory:UpdateTradeSkill();

    if ( Armory.character == Armory.player ) then
        if ( self.lastTradeSkill == currentSkill and self:IsShown() ) then
            self:SetSelectedRecipe(self:GetSelectedRecipe());
        end

        ArmoryFrame_UpdateLineTabs();
    end

    if ( Armory:GetConfigEnableCooldownEvents() ) then
        Armory:Execute(ArmorySocialFrame_UpdateEvents);
    end
end

function ArmoryTradeSkillFrameMixin:SetSelectedRecipe(id)
    self.RecipeList:SetSelectedRecipe(id);
    self:RefreshDisplay();
end

function ArmoryTradeSkillFrameMixin:GetSelectedRecipe()
    return self.RecipeList:GetSelectedRecipe();
end

function ArmoryTradeSkillFrameMixin:RefreshDisplay()
    local numTradeSkills = Armory:GetNumTradeSkills();

    -- If no tradeskills
    if ( numTradeSkills == 0 ) then
        self.ExpandButtonFrame.CollapseAllButton:Disable();
        self.DetailsFrame:Clear()
    else
        self.ExpandButtonFrame.CollapseAllButton:Enable();
    end

    self.SearchBox:Show();

    self.RecipeList:RefreshDisplay();

    self:RefreshSkillTitleAndRank();

    self:RefreshExpandButtonFrame(numTradeSkills);
end

function ArmoryTradeSkillFrameMixin:Refresh()
    self.lastTradeSkill = Armory:GetTradeSkillLine();

    self:ClearFilters();
    self.RecipeList:OnDataSourceChanging();

    ArmoryCloseDropDownMenus();
    ArmoryCloseChildWindows();
    ShowUIPanel(self);

    self:OnDataSourceChanged();

    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
end

function ArmoryTradeSkillFrameMixin:OnDataSourceChanged()
    self:RefreshSkillTitleAndRank();
    self:UpdateLayout();

    self.RecipeList:OnDataSourceChanged();
end

function ArmoryTradeSkillFrameMixin:ClearFilters()
    Armory:SetOnlyShowMakeableRecipes(false);
    Armory:SetOnlyShowSkillUpRecipes(false);
    Armory:SetTradeSkillItemLevelFilter(0, 0);
    Armory:SetTradeSkillItemNameFilter("");
    self.SearchBox:SetText("");

    self:ClearCategoryFilter();

    ArmoryCloseDropDownMenus();

    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
end

function ArmoryTradeSkillFrameMixin:ClearCategoryFilter()
    Armory:SetTradeSkillCategoryFilter(0);
end

function ArmoryTradeSkillFrameMixin:SetCategoryFilter(categoryID)
    self:ClearCategoryFilter();

    if ( categoryID ) then
        Armory:SetTradeSkillCategoryFilter(categoryID);
    end

    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
end

function ArmoryTradeSkillFrameMixin:RefreshSkillTitleAndRank()
    local skillLineName, skillLineRank, skillLineMaxRank, skillLineModifier = Armory:GetTradeSkillLine();
    local color = ArmoryTradeSkillTypeColor[skillType];

    self:SetTitleFormatted(TRADE_SKILL_TITLE, skillLineName);

    -- Set statusbar info
    self.RankFrame:SetStatusBarColor(0.0, 0.0, 1.0, 0.5);
    self.RankFrame.Background:SetVertexColor(0.0, 0.0, 0.75, 0.5);
    self.RankFrame:SetMinMaxValues(0, skillLineMaxRank);
    self.RankFrame:SetValue(skillLineRank);
    if ( skillLineModifier > 0 ) then
        self.RankFrame.SkillRank:SetFormattedText(TRADESKILL_RANK_WITH_MODIFIER, skillLineRank, skillLineModifier, skillLineMaxRank);
    else
        self.RankFrame.SkillRank:SetFormattedText(TRADESKILL_RANK, skillLineRank, skillLineMaxRank);
    end
end

function ArmoryTradeSkillFrameMixin:RefreshExpandButtonFrame(numTradeSkills)

    -- Set the expand/collapse all button texture
    local numHeaders = 0;
    local notExpanded = 0;
    for i = 1, numTradeSkills, 1 do
        local tradeSkillInfo = Armory:GetTradeSkillInfo(i);
        if ( tradeSkillInfo.name and (tradeSkillInfo.type == "header" or tradeSkillInfo.type == "subheader") ) then
            numHeaders = numHeaders + 1;
            if ( tradeSkillInfo.collapsed ) then
                notExpanded = notExpanded + 1;
            end
        end
    end

    -- If all headers are not expanded then show collapse button, otherwise show the expand button
    if ( notExpanded ~= numHeaders ) then
        self.ExpandButtonFrame.CollapseAllButton.isCollapsed = nil;
        self.ExpandButtonFrame.CollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
    else
        self.ExpandButtonFrame.CollapseAllButton.isCollapsed = 1;
        self.ExpandButtonFrame.CollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
    end

    -- If has headers show the expand all button
    if ( numHeaders > 0 ) then
        self.ExpandButtonFrame:Show();
    else
        self.ExpandButtonFrame:Hide();
    end

    self.RecipeList.hasHeaders = numHeaders > 0;
    self.RecipeList:UpdateSkillButtonIndent();
end

function ArmoryTradeSkillFrameMixin:OnRecipeChanged(id)
    self.DetailsFrame:SetSelectedRecipe(self.RecipeList:GetSelectedRecipe());
end

function ArmoryTradeSkillFrameMixin:OnSearchTextChanged(searchBox)
    ArmorySearchBoxTemplate_OnTextChanged(searchBox);

    local text, minLevel, maxLevel = Armory:GetTradeSkillItemFilter(searchBox:GetText());
    local refresh1 = Armory:SetTradeSkillItemNameFilter(text);
    local refresh2 = Armory:SetTradeSkillItemLevelFilter(minLevel, maxLevel);

    if ( refresh1 or refresh2 ) then
        self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
    end
end

function ArmoryTradeSkillFrameMixin:CollapseAllButtonClicked(button)
    if ( button.isCollapsed ) then
        button.isCollapsed = nil;
        Armory:ExpandTradeSkillCategory(0);
    else
        button.isCollapsed = 1;
        Armory:CollapseTradeSkillCategory(0);
    end

    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
end

function ArmoryTradeSkillFrameMixin:InitFilterMenu(dropdown, level)
    local info = ArmoryDropDownMenu_CreateInfo();
    if ( level == 1 ) then
        --[[ Only show makeable recipes ]]--
        info.text = CRAFT_IS_MAKEABLE;
        info.func = function()
            Armory:SetOnlyShowMakeableRecipes(not Armory:GetOnlyShowMakeableRecipes());
            self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
        end;

        info.keepShownOnClick = true;
        info.checked = Armory:GetOnlyShowMakeableRecipes();
        info.isNotRadio = true;
        ArmoryDropDownMenu_AddButton(info, level)

        --[[ Only show recipes that provide skill ups ]]--
        info.text = TRADESKILL_FILTER_HAS_SKILL_UP;
        info.func = function()
            Armory:SetOnlyShowSkillUpRecipes(not Armory:GetOnlyShowSkillUpRecipes());
            self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
        end;
        info.keepShownOnClick = true;
        info.checked = Armory:GetOnlyShowSkillUpRecipes();
        info.isNotRadio = true;
        ArmoryDropDownMenu_AddButton(info, level);

        ArmoryDropDownMenu_AddSpace(level);

        -- [[ Parent categories ]]--
        local categories = Armory:GetTradeSkillCategories();

        for i, categoryInfo in ipairs(categories) do
            info.text = categoryInfo.name;
            info.func = function() self:SetCategoryFilter(categoryInfo.categoryID); end
            info.keepShownOnClick = false;
            info.notCheckable = true;
            info.value = categoryInfo.categoryID;
            ArmoryDropDownMenu_AddButton(info, level);
        end
    end
end

function ArmoryTradeSkillFrameMixin:UpdateLayout()
    if ( self.RecipeList.extended ) then
        self.ExpandButtonFrame:Show();
        self.FilterButton:Show();
        self.FilterDropDown:Show();
    else
        self.ExpandButtonFrame:Hide();
        self.FilterButton:Hide();
        self.FilterDropDown:Hide();
    end
end


----------------------------------------------------------
-- TradeSkillRecipeList Mixin
----------------------------------------------------------

ArmoryTradeSkillRecipeListMixin = {}

function ArmoryTradeSkillRecipeListMixin:OnLoad()
    ArmoryHybridScrollFrame_CreateButtons(self, "ArmoryTradeSkillSkillButtonTemplate", 0, 0);
    self.update = self.RefreshDisplay;
    self.stepSize = ROW_HEIGHT * 2;
end

function ArmoryTradeSkillRecipeListMixin:OnDataSourceChanging()
    self.extended = select(2, Armory:GetNumTradeSkills());
    self:SetSelectedRecipe(nil);
    for i, tradeSkillButton in ipairs(self.buttons) do
        tradeSkillButton:Clear();
    end
    self:Refresh();
end

function ArmoryTradeSkillRecipeListMixin:OnDataSourceChanged()
    self.scrollBar:SetValue(0);
    self.selectedSkill = nil;
    self:UpdateLayout();
    self:Refresh();
end

function ArmoryTradeSkillRecipeListMixin:OnHeaderButtonClicked(categoryButton, categoryInfo)
    local id = categoryButton:GetID();
    if ( categoryInfo.collapsed ) then
        Armory:ExpandTradeSkillCategory(id);
    else
        Armory:CollapseTradeSkillCategory(id);
    end

    self:Refresh();
end

function ArmoryTradeSkillRecipeListMixin:OnRecipeButtonClicked(recipeButton, recipeInfo)
    self:SetSelectedRecipe(recipeButton:GetID());
end

function ArmoryTradeSkillRecipeListMixin:SetSelectedRecipe(id)
    if ( self.selectedSkill ~= id and (not id or id <= Armory:GetNumTradeSkills()) ) then
        self.selectedSkill = id;
        self:RefreshDisplay();
        if ( self.recipeChangedCallback ) then
            self.recipeChangedCallback(id);
        end
        return true;
    end
    return false;
end

function ArmoryTradeSkillRecipeListMixin:GetSelectedRecipe()
    return self.selectedSkill or 1;
end

function ArmoryTradeSkillRecipeListMixin:UpdateFilterBar()
    local filters = nil;
    if ( Armory:GetOnlyShowMakeableRecipes() ) then
        filters = filters or {};
        filters[#filters + 1] = CRAFT_IS_MAKEABLE;
    end

    if ( Armory:GetOnlyShowSkillUpRecipes() ) then
        filters = filters or {};
        filters[#filters + 1] = TRADESKILL_FILTER_HAS_SKILL_UP;
    end

    local categoryFilter = Armory:GetTradeSkillCategoryFilter();
    if ( #categoryFilter > 1 ) then
        local categoryName = categoryFilter[1];
        filters = filters or {};
        filters[#filters + 1] = categoryName;
    end

    if ( filters ) then
        self.FilterBar.Text:SetFormattedText("%s: %s", FILTER, table.concat(filters, PLAYER_LIST_DELIMITER));
    end

    self.filtered = filters ~= nil;

    self:UpdateLayout();
end

function ArmoryTradeSkillRecipeListMixin:RefreshDisplay()
    self:UpdateFilterBar();

    local numTradeSkills = Armory:GetNumTradeSkills();
    local skillOffset = ArmoryHybridScrollFrame_GetOffset(self);

    for i, skillButton in ipairs(self.buttons) do
        local skillIndex = i + skillOffset;

        skillButton = self.buttons[i];
        skillButton:SetID(skillIndex);

        local info = Armory:GetTradeSkillInfo(skillIndex);

        if ( info and info.name and skillIndex <= numTradeSkills ) then
            skillButton:SetUp(info);

            if ( info.type == "recipe" ) then
                skillButton:SetSelected(self:GetSelectedRecipe() == skillIndex);
            end
        else
            skillButton:Clear();
        end
    end

    self:UpdateSkillButtonIndent();

   ArmoryHybridScrollFrame_Update(self, numTradeSkills * ROW_HEIGHT, self:GetHeight());
end

function ArmoryTradeSkillRecipeListMixin:Refresh()
    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
    self:RefreshDisplay();
end

function ArmoryTradeSkillRecipeListMixin:SetRecipeChangedCallback(recipeChangedCallback)
    self.recipeChangedCallback = recipeChangedCallback;
end

function ArmoryTradeSkillRecipeListMixin:UpdateSkillButtonIndent()
    if ( self.hasHeaders ) then
        -- If has headers then move all the names to the right
        for i, skillButton in ipairs(self.buttons) do
            local tradeSkillInfo = skillButton.tradeSkillInfo;
            if ( tradeSkillInfo and tradeSkillInfo.numIndents ~= 0 ) then
                skillButton.Text:SetPoint("TOPLEFT", skillButton, "TOPLEFT", 46, 0);
            else
                skillButton.Text:SetPoint("TOPLEFT", skillButton, "TOPLEFT", 23, 0);
            end
        end
    else
        -- If no headers then move all the names to the left
        for i, skillButton in ipairs(self.buttons) do
            skillButton.Text:SetPoint("TOPLEFT", skillButton, "TOPLEFT", 3, 0);
        end
    end
end

function ArmoryTradeSkillRecipeListMixin:UpdateLayout()
    if ( self.extended ) then
        if ( self.filtered ) then
            self.FilterBar:SetPoint("TOPLEFT", ArmoryTradeSkillFrame.Inset, "TOPLEFT", 8, -4);
            self.FilterBar:Show();

            self:SetHeight(LIST_FULL_HEIGHT - ROW_HEIGHT);
            self:SetPoint("TOPRIGHT", ArmoryTradeSkillFrame.Inset, "TOPRIGHT", -22, -4 - ROW_HEIGHT);
            self.scrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", 1, -14 + ROW_HEIGHT);
        else
            self.FilterBar:Hide();

            self:SetHeight(LIST_FULL_HEIGHT);
            self:SetPoint("TOPRIGHT", ArmoryTradeSkillFrame.Inset, "TOPRIGHT", -22, -4);
            self.scrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", 1, -14);
        end
    else
        self.FilterBar:Hide();
        self:SetHeight(LIST_FULL_HEIGHT);
        self:SetPoint("TOPRIGHT", ArmoryTradeSkillFrame.Inset, "TOPRIGHT", -22, -4 + ROW_HEIGHT - 15);
        self.scrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", 1, -14);
    end
end


----------------------------------------------------------
-- TradeSkillButton Mixin
----------------------------------------------------------

ArmoryTradeSkillButtonMixin = {};

local scanned = {};
local function GetNumAvailable(id)
    local numAvailable = 0;
    table.wipe(scanned);
    if ( Armory:HasInventory() ) then
        for i = 1, Armory:GetTradeSkillNumReagents(id) do
            local reagentLink = Armory:GetTradeSkillReagentItemLink(id, i);
            if ( reagentLink ) then
                local _, _, reagentCount = Armory:GetTradeSkillReagentInfo(id, i);
                if ( reagentCount and reagentCount > 0 ) then
                    table.insert(scanned, floor(Armory:ScanInventory(reagentLink, true) / reagentCount));
                end
            end
        end
        if ( #scanned > 0 ) then
            numAvailable = scanned[1];
            for i = 2, #scanned do
                if ( scanned[i] < numAvailable ) then
                    numAvailable = scanned[i];
                end
            end
        end
    end
    table.wipe(scanned);
    return numAvailable;
end

function ArmoryTradeSkillButtonMixin:SetBaseColor(color)
    self:SetNormalFontObject(color.font);
    self.Text:SetVertexColor(color.r, color.g, color.b);
    self.Count:SetVertexColor(color.r, color.g, color.b);
    self.SkillUps.Text:SetVertexColor(color.r, color.g, color.b);
    self.SkillUps.Icon:SetVertexColor(color.r, color.g, color.b);
    self.SelectedTexture:SetVertexColor(color.r, color.g, color.b)

    self.r = color.r;
    self.g = color.g;
    self.b = color.b;
    self.font = color.font;
end

function ArmoryTradeSkillButtonMixin:SetUp(tradeSkillInfo)
    self.tradeSkillInfo = tradeSkillInfo;

    local textWidth = TRADE_SKILL_TEXT_WIDTH;
    if ( tradeSkillInfo.numIndents > 0 ) then
        textWidth = textWidth - 20;
        self:GetNormalTexture():SetPoint("LEFT", 19, 0);
        self:GetDisabledTexture():SetPoint("LEFT", 19, 0);
        self:GetHighlightTexture():SetPoint("LEFT", 19, 0);
    else
        self:GetNormalTexture():SetPoint("LEFT", -1, 0);
        self:GetDisabledTexture():SetPoint("LEFT", -1, 0);
        self:GetHighlightTexture():SetPoint("LEFT", -1, 0);
    end

    if ( tradeSkillInfo.type == "header" or tradeSkillInfo.type == "subheader" ) then
        self:SetUpHeader(textWidth, tradeSkillInfo);
    else
        self:SetUpRecipe(textWidth, tradeSkillInfo);
    end

    self:Show();
end

function ArmoryTradeSkillButtonMixin:Clear()
    self.isHeader = nil;
    self.isSelected = nil;
    self.categoryID = nil;
    self:Hide();
end

function ArmoryTradeSkillButtonMixin:SetUpHeader(textWidth, tradeSkillInfo)
    self.isHeader = true;
    self.categoryID = tradeSkillInfo.categoryID;
    self.SkillUps:Hide();
    self.LockedIcon:Hide();
    self.StarsFrame:Hide();
    self:SetAlpha(1.0);

    self:SetBaseColor(ArmoryTradeSkillTypeColor[tradeSkillInfo.type]);

    if ( tradeSkillInfo.hasProgressBar ) then
        self.SubSkillRankBar:Show();
        self.SubSkillRankBar:SetMinMaxValues(tradeSkillInfo.skillLineStartingRank, tradeSkillInfo.skillLineMaxLevel);
        self.SubSkillRankBar:SetValue(tradeSkillInfo.skillLineCurrentLevel);
        self.SubSkillRankBar.currentRank = tradeSkillInfo.skillLineCurrentLevel;
        self.SubSkillRankBar.maxRank = tradeSkillInfo.skillLineMaxLevel;

        textWidth = textWidth - SUB_SKILL_BAR_WIDTH;
    else
        self.SubSkillRankBar:Hide();
        self.SubSkillRankBar.currentRank = nil;
        self.SubSkillRankBar.maxRank = nil;
    end

    self.Text:SetWidth(textWidth);
    self:SetText(tradeSkillInfo.name);
    self.Count:SetText("");

    if ( tradeSkillInfo.isEmptyCategory ) then
        self:ClearNormalTexture();
        self.Highlight:SetTexture("")
    else
        if ( tradeSkillInfo.collapsed ) then
            self:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
        else
            self:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
        end
        self.Highlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
    end

    self.SelectedTexture:Hide();
    self:UnlockHighlight()
    self.isSelected = false;
end

function ArmoryTradeSkillButtonMixin:SetUpRecipe(textWidth, tradeSkillInfo)
    self.isHeader = false;
    self.categoryID = nil;
    self.SubSkillRankBar:Hide();

    local usedWidth;
    if ( tradeSkillInfo.numSkillUps > 1 and tradeSkillInfo.difficulty == "optimal" and not tradeSkillInfo.disabled ) then
        self.SkillUps:Show();
        self.SkillUps.Text:SetText(tradeSkillInfo.numSkillUps);
        usedWidth = TRADE_SKILL_SKILLUP_TEXT_WIDTH;
    else
        self.SkillUps:Hide();
        usedWidth = 0;
    end

    -- display a lock icon when the recipe is shown, but unavailable
    if ( tradeSkillInfo.disabled ) then
        self.LockedIcon:Show();
        usedWidth = TRADE_SKILL_SKILLUP_TEXT_WIDTH;
    else
        self.LockedIcon:Hide();
    end

    self:SetBaseColor(ArmoryTradeSkillTypeColor[tradeSkillInfo.difficulty]);

    local skillNamePrefix = ENABLE_COLORBLIND_MODE == "1" and ArmoryTradeSkillTypePrefix[tradeSkillInfo.difficulty] or " ";

    self:ClearNormalTexture();
    self.Highlight:SetTexture("");

    local totalRanks, currentRank = tradeSkillInfo.totalRanks, tradeSkillInfo.currentRank;
    if ( totalRanks and totalRanks > 1 ) then
        usedWidth = usedWidth + self.StarsFrame:GetWidth();
        self.StarsFrame:Show();
        for i, starFrame in ipairs(self.StarsFrame.Stars) do
            starFrame.EarnedStar:SetShown(i <= currentRank);
        end
        if ( self.SkillUps:IsShown() ) then
            self.SkillUps:SetPoint("RIGHT", self.StarsFrame, "LEFT", -2, 0);
            usedWidth = usedWidth + 11;
        end
    else
        self.StarsFrame:Hide();
        if ( self.SkillUps:IsShown() ) then
            self.SkillUps:SetPoint("RIGHT", self, "RIGHT", 3, 0);
        end
    end

    self.Text:SetWidth(0);
    self.Text:SetFormattedText("%s%s", skillNamePrefix, tradeSkillInfo.name);
    local numAvailable = max(tradeSkillInfo.numAvailable, GetNumAvailable(self:GetID()));
    if ( numAvailable == 0 ) then
        self.Count:SetText("");
        textWidth = textWidth - usedWidth;
    else
        self.Count:SetFormattedText("[%d]", numAvailable);

        local nameWidth = self.Text:GetWidth();
        local countWidth = self.Count:GetWidth();

        if ( nameWidth + 2 + countWidth > textWidth - usedWidth ) then
            textWidth = textWidth - 2 - countWidth - usedWidth;
        else
            textWidth = 0;
        end
    end

    self.Text:SetWidth(textWidth);
end

function ArmoryTradeSkillButtonMixin:SetSelected(selected)
    if ( selected ) then
        self.SelectedTexture:Show();

        self.Text:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        self.Count:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

        self.SkillUps.Text:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        self.SkillUps.Icon:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        self:LockHighlight();
        self.isSelected = true;
    else
        self.SelectedTexture:Hide();
        self:UnlockHighlight();
        self.isSelected = false;
    end
end

function ArmoryTradeSkillButtonMixin:OnMouseEnter()
    self.Count:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    self.SkillUps.Icon:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    self.SkillUps.Text:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

    self.Text:SetFontObject(GameFontHighlightLeft);
    self.Text:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    if ( self.SubSkillRankBar.currentRank and self.SubSkillRankBar.maxRank ) then
        self.SubSkillRankBar.Rank:SetFormattedText("%d/%d", self.SubSkillRankBar.currentRank, self.SubSkillRankBar.maxRank);

        self:CreateCompetitionTooltip();
    end
end

function ArmoryTradeSkillButtonMixin:OnMouseLeave()
    if ( not self.isSelected ) then
        self.Count:SetVertexColor(self.r, self.g, self.b);
        self.SkillUps.Icon:SetVertexColor(self.r, self.g, self.b);
        self.SkillUps.Text:SetVertexColor(self.r, self.g, self.b);

        self.Text:SetFontObject(self.font);
        self.Text:SetVertexColor(self.r, self.g, self.b);
    end
    self.SubSkillRankBar.Rank:SetText("");
    self:ClearCompetitionTooltip();
 end

function ArmoryTradeSkillButtonMixin:OnLockIconMouseEnter()
    if ( self.tradeSkillInfo.disabled and self.tradeSkillInfo.disabledReason ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:AddLine(self.tradeSkillInfo.disabledReason, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
        GameTooltip:Show();
    end
end

function ArmoryTradeSkillButtonMixin:CreateCompetitionTooltip()
    local tradeSkill = Armory:GetTradeSkillLine();
    if ( tradeSkill and self.categoryID ) then
        local competition = Armory:GetCompetition(tradeSkill, self.categoryID);

        if ( #competition > 0 ) then
            local index, column, myColumn;

            self.tooltip = Armory.qtip:Acquire("ArmoryCompetitionTooltip", 2);
            self.tooltip:Clear();
            self.tooltip:SetScale(Armory:GetConfigFrameScale());
            self.tooltip:SetFrameLevel(self:GetFrameLevel() + 1);
            self.tooltip:ClearAllPoints();
            self.tooltip:SetClampedToScreen(1);
            self.tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT");

            index, column = self.tooltip:AddLine();
            myColumn = column; index, column = self.tooltip:SetCell(index, myColumn, self:GetText(), GameTooltipHeaderText, "LEFT", 2);

            self.tooltip:AddSeparator(2);
            local maxLevel, currentLevel, result;
            for _, rankInfo in ipairs(competition) do
                if ( rankInfo.currentLevel ) then
                    -- Normalize Values
                    maxLevel = rankInfo.maxLevel - rankInfo.startingRank + 1;
                    currentLevel = rankInfo.currentLevel - rankInfo.startingRank + 1;
                    result = NORMAL_FONT_COLOR_CODE..currentLevel.." / "..maxLevel..FONT_COLOR_CODE_CLOSE;
                else
                    result = UNKNOWN;
                end

                index, column = self.tooltip:AddLine();
                myColumn = column; index, column = self.tooltip:SetCell(index, myColumn, rankInfo.name);
                myColumn = column; index, column = self.tooltip:SetCell(index, myColumn, result, nil, "RIGHT");
            end
            self.tooltip:Show();
        end
    end
end

function ArmoryTradeSkillButtonMixin:ClearCompetitionTooltip()
    if ( self.tooltip ) then
        Armory.qtip:Release(self.tooltip);
        self.tooltip = nil;
    end
end

----------------------------------------------------------
-- TradeSkillDetails Mixin
----------------------------------------------------------

ArmoryTradeSkillDetailsMixin = {}

function ArmoryTradeSkillDetailsMixin:SetSelectedRecipe(id)
    if ( self.selectedRecipe ~= id ) then
        self.selectedRecipe = id;
        self.optionalReagents = {};
        self:Refresh();
    end
end

function ArmoryTradeSkillDetailsMixin:AddContentWidget(widget)
    self.activeContentWidgets[#self.activeContentWidgets + 1] = widget;
end

function ArmoryTradeSkillDetailsMixin:CalculateContentHeight()
    local height = 0;
    local contentTop = self.Contents:GetTop();
    for i, widget in ipairs(self.activeContentWidgets) do
        local bottom = widget:GetBottom();
        if ( bottom ) then
            height = math.max(height, contentTop - bottom);
        end
    end

    return height;
end

local function SetUpReagentButton(reagentButton, reagentName, reagentTexture, requiredReagentCount, playerReagentCount, isOptional, bonusText, optionalReagentQuality)
    reagentName = reagentName or "";
    reagentTexture = reagentTexture or "";

    reagentButton.Icon:SetTexture(reagentTexture);

    if ( isOptional ) then
        reagentButton:SetReagentText(bonusText);
        reagentButton:SetReagentQuality(optionalReagentQuality);
    else
        reagentButton.Name:SetText(reagentName);
    end

    if ( playerReagentCount ) then
        if ( playerReagentCount < requiredReagentCount ) then
            reagentButton.Icon:SetVertexColor(0.5, 0.5, 0.5);
            reagentButton.Name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
        else
            reagentButton.Icon:SetVertexColor(1.0, 1.0, 1.0);
            reagentButton.Name:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        end

        if ( isOptional and requiredReagentCount == 1 ) then
            reagentButton.Count:SetText(playerReagentCount);
        else
            SetItemButtonReagentCount(reagentButton, requiredReagentCount, playerReagentCount);
        end
    else
        reagentButton.Count:SetText(requiredReagentCount);
    end
end

local SPACING_BETWEEN_LINES = 11;
function ArmoryTradeSkillDetailsMixin:RefreshDisplay()
    self.activeContentWidgets = {};

    local recipeInfo = self.selectedRecipe and Armory:GetTradeSkillInfo(self.selectedRecipe);
    if ( recipeInfo and recipeInfo.type == "recipe" ) then
        local categorySkillRank = recipeInfo.categorySkillRank or 0;
        local hasRecipeLeveling = recipeInfo.unlockedRecipeLevel;
        local hasMaxRecipeLevel = hasRecipeLeveling and (recipeInfo.currentRecipeExperience == nil);

        self.Contents.RecipeName:SetText(recipeInfo.name);
        self.recipeID = recipeInfo.recipeID;

        local recipeLink = C_TradeSkillUI.GetRecipeItemLink(recipeInfo.recipeID);
        if ( recipeInfo.productQuality ) then
            local r, g, b = GetItemQualityColor(recipeInfo.productQuality);
            self.Contents.RecipeName:SetTextColor(r, g, b);
        else
            self.Contents.RecipeName:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        end

        SetItemButtonQuality(self.Contents.ResultIcon, recipeInfo.productQuality, recipeLink);
        self:AddContentWidget(self.Contents.RecipeName);

        self.Contents.ResultIcon:SetNormalTexture(recipeInfo.icon);
        Armory:SetItemLink(self.Contents.ResultIcon, Armory:GetTradeSkillItemLink(self.selectedRecipe));

        local minMade, maxMade = Armory:GetTradeSkillNumMade(self.selectedRecipe);
        if ( maxMade > 1 ) then
            if ( minMade == maxMade ) then
                self.Contents.ResultIcon.Count:SetText(minMade);
            else
                self.Contents.ResultIcon.Count:SetFormattedText("%d-%d", minMade, maxMade);
            end
            if ( self.Contents.ResultIcon.Count:GetWidth() > 39 ) then
                self.Contents.ResultIcon.Count:SetFormattedText("~%d", math.floor(Lerp(minMade, maxMade, .5)));
            end
        else
            self.Contents.ResultIcon.Count:SetText("");
        end
        self:AddContentWidget(self.Contents.ResultIcon);

        local totalRanks, currentRank = recipeInfo.totalRanks, recipeInfo.currentRank;
        self.currentRank = currentRank;

        self.Contents.StarsFrame:Hide();
        self.Contents.RecipeLevel:Hide();

        if ( totalRanks and totalRanks > 1 ) then
            for i, starFrame in ipairs(self.Contents.StarsFrame.Stars) do
                starFrame.EarnedStar:SetShown(i <= currentRank);
            end
            self:AddContentWidget(self.Contents.StarsFrame);
            self.Contents.StarsFrame:Show();
        elseif ( hasRecipeLeveling ) then
            local recipeLevelBar = self.Contents.RecipeLevel;
            recipeLevelBar:SetExperience(recipeInfo.currentRecipeExperience, recipeInfo.nextLevelRecipeExperience, recipeInfo.unlockedRecipeLevel);
            self:AddContentWidget(recipeLevelBar);
            recipeLevelBar:Show();
        end

        local recipeDescription = Armory:GetTradeSkillDescription(self.selectedRecipe);
        if ( recipeDescription and #recipeDescription > 0 ) then
            self.Contents.Description:SetText(recipeDescription);
            self.Contents.RequirementLabel:SetPoint("TOPLEFT", self.Contents.Description, "BOTTOMLEFT", 0, -10);
        else
            self.Contents.Description:SetText("");
            self.Contents.RequirementLabel:SetPoint("TOPLEFT", self.Contents.Description, "BOTTOMLEFT", 0, 0);
        end
        self:AddContentWidget(self.Contents.Description);

        local requiredToolsString = Armory:GetTradeSkillTools(self.selectedRecipe);
        if ( requiredToolsString and requiredToolsString ~= "" ) then
            self.Contents.RequirementLabel:Show();
            self.Contents.RequirementText:SetText(requiredToolsString);
            self.Contents.ExperienceLabel:SetPoint("TOP", self.Contents.RequirementText, "BOTTOM", 0, 0);
            self:AddContentWidget(self.Contents.RequirementLabel);
            self:AddContentWidget(self.Contents.RequirementText);
        else
            self.Contents.RequirementLabel:Hide();
            self.Contents.RequirementText:SetText("");
            self.Contents.ExperienceLabel:SetPoint("TOP", self.Contents.RequirementText, "TOP", 0, 0);
        end

        local earnedExperience = recipeInfo.earnedExperience;
        local showEarnedExperience = (earnedExperience ~= nil) and not hasMaxRecipeLevel;
        if ( showEarnedExperience ) then
            self.Contents.ExperienceLabel:Show();
            self.Contents.ExperienceText:SetText(earnedExperience);
            self:AddContentWidget(self.Contents.ExperienceLabel);
            self:AddContentWidget(self.Contents.ExperienceText);
        else
            self.Contents.ExperienceLabel:Hide();
            self.Contents.ExperienceText:SetText("");
        end

        if ( showEarnedExperience ) then
            self.Contents.RecipeCooldown:SetPoint("TOP", self.Contents.ExperienceText, "BOTTOM", 0, -SPACING_BETWEEN_LINES);
        elseif requiredToolsString then
            self.Contents.RecipeCooldown:SetPoint("TOP", self.Contents.RequirementText, "BOTTOM", 0, -SPACING_BETWEEN_LINES);
        else
            self.Contents.RecipeCooldown:SetPoint("TOP", self.Contents.RequirementText, "BOTTOM", 0, 0);
        end

        local cooldown, isDayCooldown, charges, maxCharges = Armory:GetTradeSkillCooldown(self.selectedRecipe);
        self.Contents.ReagentLabel:SetPoint("TOPLEFT", self.Contents.RecipeCooldown, "BOTTOMLEFT", 0, -SPACING_BETWEEN_LINES);
        if ( maxCharges > 0 and (charges > 0 or not cooldown) ) then
            self.Contents.RecipeCooldown:SetFormattedText(TRADESKILL_CHARGES_REMAINING, charges, maxCharges);
            self.Contents.RecipeCooldown:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
            self:AddContentWidget(self.Contents.RecipeCooldown);
        elseif ( recipeInfo.disabled ) then
            self.Contents.RecipeCooldown:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
            self.Contents.RecipeCooldown:SetText(recipeInfo.disabledReason);
            self:AddContentWidget(self.Contents.RecipeCooldown);
        else
            self.Contents.RecipeCooldown:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
            if ( not cooldown ) then
                self.Contents.RecipeCooldown:SetText("");
                self.Contents.ReagentLabel:SetPoint("TOPLEFT", self.Contents.RecipeCooldown, "BOTTOMLEFT", 0, 0);
            elseif ( not isDayCooldown ) then
                self.Contents.RecipeCooldown:SetText(COOLDOWN_REMAINING.." "..SecondsToTime(cooldown));
            elseif ( cooldown > 60 * 60 * 24 ) then    --Cooldown is greater than 1 day.
                self.Contents.RecipeCooldown:SetText(COOLDOWN_REMAINING.." "..SecondsToTime(cooldown, true, false, 1, true));
                self:AddContentWidget(self.Contents.RecipeCooldown);
            else
                self.Contents.RecipeCooldown:SetText(COOLDOWN_EXPIRES_AT_MIDNIGHT);
                self:AddContentWidget(self.Contents.RecipeCooldown);
            end
        end

        local numReagents = Armory:GetTradeSkillNumReagents(self.selectedRecipe);

        if ( numReagents > 0 ) then
            self.Contents.ReagentLabel:Show();
            self:AddContentWidget(self.Contents.ReagentLabel);
        else
            self.Contents.ReagentLabel:Hide();
        end

        for reagentIndex = 1, numReagents do
            local reagentName, reagentTexture, reagentCount, link = Armory:GetTradeSkillReagentInfo(self.selectedRecipe, reagentIndex);
            local playerReagentCount;

            local reagentButton = self.Contents.Reagents[reagentIndex];
            reagentButton.link = link;
            reagentButton.reagentSlotSchematic = {
                reagents = Armory:GetReagents(self.recipeID, reagentIndex)
            };

            if ( Armory:HasInventory() ) then
                -- use count from inventory
                playerReagentCount = Armory:ScanInventory(reagentButton.link, true);
            end

            reagentButton:Show();
            self:AddContentWidget(reagentButton);

            SetUpReagentButton(reagentButton, reagentName, reagentTexture, reagentCount, playerReagentCount);
            Armory:SetItemLink(reagentButton, Armory:GetTradeSkillReagentItemLink(self.selectedRecipe, reagentIndex));
        end

        for reagentIndex = numReagents + 1, #self.Contents.Reagents do
            local reagentButton = self.Contents.Reagents[reagentIndex];
            reagentButton:Hide();
        end

        local optionalReagentSlots = Armory:GetOptionalReagentSlots(self.selectedRecipe);
        self.optionalReagentSlots = optionalReagentSlots;
        local numOptionalReagentSlots = #optionalReagentSlots;
        local hasOptionalReagentSlots = numOptionalReagentSlots > 0;

        self.Contents.OptionalReagentLabel:SetShown(hasOptionalReagentSlots);
        if ( hasOptionalReagentSlots ) then
            if ( numReagents > 0 ) then
                self.Contents.OptionalReagentLabel:SetPoint("TOP", self.Contents.Reagents[numReagents], "BOTTOM", 0, -15)
            else
                self.Contents.OptionalReagentLabel:SetPoint("TOP", self.Contents.ReagentLabel, "TOP");
            end

            self:AddContentWidget(self.Contents.OptionalReagentLabel);
        end

        for optionalReagentIndex, slot in ipairs(optionalReagentSlots) do
            local reagentButton = self.Contents.OptionalReagents[optionalReagentIndex];

            local hasRequiredSkillRank = categorySkillRank >= slot.requiredSkillRank;
            reagentButton:SetLocked(not hasRequiredSkillRank, slot.requiredSkillRank);

            reagentButton.Icon:SetAtlas(hasRequiredSkillRank and "tradeskills-icon-add" or "tradeskills-icon-locked", TextureKitConstants.UseAtlasSize);
            reagentButton.Icon:SetVertexColor(1.0, 1.0, 1.0);
            reagentButton.Count:SetText("");
            reagentButton:SetReagentText(slot.slotText or OPTIONAL_REAGENT_POSTFIX);
            reagentButton:SetReagentColor(hasRequiredSkillRank and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR);
            reagentButton:SetOptions(slot.options);

            reagentButton:Show();
            self:AddContentWidget(reagentButton);
        end

        for optionalReagentIndex = numOptionalReagentSlots + 1, #self.Contents.OptionalReagents do
            local reagentButton = self.Contents.OptionalReagents[optionalReagentIndex];
            reagentButton:Hide();
        end

        self.Contents:SetHeight(self:CalculateContentHeight());
        self.Contents:Show();
        self:Show();
    else
        self:Clear();
    end
end

function ArmoryTradeSkillDetailsMixin:Refresh()
    self:RefreshDisplay();
end

function ArmoryTradeSkillDetailsMixin:Clear()
    self:Hide();
end

function ArmoryTradeSkillDetailsMixin:OnResultClicked(resultButton)
    if ( IsModifiedClick("CHATLINK") and resultButton.link ) then
        HandleModifiedItemClick(resultButton.link);
    end
end

function ArmoryTradeSkillDetailsMixin:OnResultMouseEnter(resultButton)
    if ( self.selectedRecipe ~= 0 ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        Armory:SetTradeSkillItem(self.selectedRecipe);
    end
end

function ArmoryTradeSkillDetailsMixin:OnReagentMouseEnter(reagentButton)
    GameTooltip:SetOwner(reagentButton, "ANCHOR_TOPLEFT");
    Armory:SetTradeSkillItem(self.selectedRecipe, reagentButton.reagentIndex);
end

function ArmoryTradeSkillDetailsMixin:OnReagentClicked(reagentButton)
    if ( IsModifiedClick("CHATLINK") and reagentButton.link ) then
        HandleModifiedItemClick(reagentButton.link);
    end
end

function ArmoryTradeSkillDetailsMixin:OnOptionalReagentMouseEnter(reagentButton)
    GameTooltip:SetOwner(reagentButton, "ANCHOR_TOPLEFT");

    GameTooltip_SetTitle(GameTooltip, EMPTY_OPTIONAL_REAGENT_TOOLTIP_TITLE);

    if ( reagentButton:IsLocked() ) then
        GameTooltip_AddErrorLine(GameTooltip, OPTIONAL_REAGENT_TOOLTIP_SLOT_LOCKED_FORMAT:format(reagentButton:GetLockedSkillRank()));
    end

    local options = reagentButton:GetOptions();
    if ( options ) then
        for i = 1, #options do
            local itemName, _, quality, _, _, _, _, _, _, itemTexture = _G.GetItemInfo(options[i]);
            if ( quality and quality > Enum.ItemQuality.Common and BAG_ITEM_QUALITY_COLORS[quality] ) then
                GameTooltip_AddColoredLine(GameTooltip,  "|T"..itemTexture..":0:0:0:-1|t "..itemName, BAG_ITEM_QUALITY_COLORS[quality])
            elseif ( itemName ) then
                GameTooltip_AddNormalLine(GameTooltip, "|T"..itemTexture..":0:0:0:-1|t "..itemName);
            end
        end
    end

    GameTooltip:Show();
end


----------------------------------------------------------
-- TradeSkillRecipeLevelBar Mixin
----------------------------------------------------------

ArmoryTradeSkillRecipeLevelBarMixin = {}

function ArmoryTradeSkillRecipeLevelBarMixin:OnLoad()
    self.Rank:Hide();
    self:SetStatusBarColor(TRADESKILL_EXPERIENCE_COLOR:GetRGB());
end

function ArmoryTradeSkillRecipeLevelBarMixin:OnEnter()
    self.Rank:Show();

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

    if ( self:IsMaxLevel() ) then
        GameTooltip_SetTitle(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_HIGHEST_RANK, NORMAL_FONT_COLOR);
        GameTooltip_AddColoredLine(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_HIGHEST_RANK_EXPLANATION, GREEN_FONT_COLOR);
    else
        local experiencePercent = math.floor((self.currentExperience / self.maxExperience) * 100);
        GameTooltip_SetTitle(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_RANK_FORMAT:format(self.currentLevel), NORMAL_FONT_COLOR);
        GameTooltip_AddHighlightLine(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_EXPERIENCE_FORMAT:format(self.currentExperience, self.maxExperience, experiencePercent));
        GameTooltip_AddColoredLine(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_LEVELING_FORMAT:format(self.currentLevel + 1), GREEN_FONT_COLOR);
    end

    GameTooltip:Show();
end

function ArmoryTradeSkillRecipeLevelBarMixin:OnLeave()
    self.Rank:Hide();

    GameTooltip_Hide();
end

function ArmoryTradeSkillRecipeLevelBarMixin:SetExperience(currentExperience, maxExperience, currentLevel)
    self.currentExperience = currentExperience;
    self.maxExperience = maxExperience;
    self.currentLevel = currentLevel;

    if ( self:IsMaxLevel() ) then
        self:SetMinMaxValues(0, 1);
        self:SetValue(1);
        self.Rank:SetText(TRADESKILL_RECIPE_LEVEL_MAXIMUM);
    else
        self:SetMinMaxValues(0, maxExperience);
        self:SetValue(currentExperience);
        self.Rank:SetFormattedText(GENERIC_FRACTION_STRING, currentExperience, maxExperience);
    end
end

function ArmoryTradeSkillRecipeLevelBarMixin:IsMaxLevel()
    return self.currentExperience == nil;
end


----------------------------------------------------------
-- OptionalReagentButton Mixin
----------------------------------------------------------

ArmoryOptionalReagentButtonMixin = {}

function ArmoryOptionalReagentButtonMixin:OnLoad()
    self.Name:SetFontObject("GameFontHighlightSmall");
    self.Name:SetMaxLines(3);
    self.Name:ClearAllPoints();
    self.Name:SetPoint("LEFT", self.Icon, "RIGHT", 6, 0);
end

function ArmoryOptionalReagentButtonMixin:SetReagentQuality(quality)
    local itemQualityColor = ITEM_QUALITY_COLORS[quality];
    self.Name:SetTextColor(itemQualityColor.r, itemQualityColor.g, itemQualityColor.b);
    self.IconBorder:Show();
    SetItemButtonQuality(self, quality);
end

function ArmoryOptionalReagentButtonMixin:SetReagentColor(color)
    self.Name:SetTextColor(color:GetRGB());
    self.IconBorder:Hide();
end

function ArmoryOptionalReagentButtonMixin:SetReagentText(name)
    self.Name:SetText(name);
end

function ArmoryOptionalReagentButtonMixin:SetLocked(locked, lockedSkillRank)
    self.locked = locked;
    self.lockedSkillRank = lockedSkillRank;
end

function ArmoryOptionalReagentButtonMixin:IsLocked()
    return self.locked;
end

function ArmoryOptionalReagentButtonMixin:GetLockedSkillRank()
    return self.lockedSkillRank;
end

function ArmoryOptionalReagentButtonMixin:SetOptions(options)
    self.options = options;
end

function ArmoryOptionalReagentButtonMixin:GetOptions(options)
    return self.options;
end

----------------------------------------------------------

function ArmoryTradeSkillFrame_Show()
    ArmoryTradeSkillFrame:Refresh();
end

function ArmoryTradeSkillFrame_Hide()
    HideUIPanel(ArmoryTradeSkillFrame);
end
