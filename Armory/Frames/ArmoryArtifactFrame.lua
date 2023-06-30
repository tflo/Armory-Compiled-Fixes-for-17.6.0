--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 244 2022-10-30T09:57:47Z
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

local ARTIFACT_POWER_STYLE_RUNE = 1;
local ARTIFACT_POWER_STYLE_MAXED = 2;
local ARTIFACT_POWER_STYLE_CAN_UPGRADE = 3;
local ARTIFACT_POWER_STYLE_PURCHASED = 4;
local ARTIFACT_POWER_STYLE_UNPURCHASED = 5;
local ARTIFACT_POWER_STYLE_UNPURCHASED_LOCKED = 6;

local ARTIFACT_POWER_STYLE_PURCHASED_READ_ONLY = 7;
local ARTIFACT_POWER_STYLE_UNPURCHASED_READ_ONLY = 8;

----------------------------------------------------------
-- ArmoryArtifactFrame Mixin
----------------------------------------------------------

ArmoryArtifactFrameMixin = {};

function ArmoryArtifactFrameMixin:OnLoad()
    self:RegisterEvent("ARTIFACT_UPDATE");
    self:RegisterEvent("ARTIFACT_XP_UPDATE");
    self:RegisterEvent("ARTIFACT_RELIC_INFO_RECEIVED");
    --self:RegisterEvent("ARTIFACT_MAX_RANKS_UPDATE");

    table.insert(UISpecialFrames, "ArmoryArtifactFrame");
end

function ArmoryArtifactFrameMixin:OnShow()
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);

    self:SetScale(Armory:GetConfigFrameScale());

    self:SetupPerArtifactData();
    self:RefreshKnowledgeRanks();
    self.PerksTab:Refresh(true);
end

function ArmoryArtifactFrameMixin:OnHide()
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
end

function ArmoryArtifactFrameMixin:OnEvent(event, ...)
    if ( event == "ARTIFACT_UPDATE" ) then
        Armory:UpdateArtifact();

        local newItem = ...;

        if ( self:IsShown() ) then
            self:RefreshKnowledgeRanks();
            if ( newItem ) then
                self:SetupPerArtifactData();
            end
            self.PerksTab:Refresh(newItem);
        end
    elseif ( event == "ARTIFACT_RELIC_INFO_RECEIVED" ) then
        Armory:UpdateArtifact();
        if ( self:IsShown() ) then
            self.PerksTab:Refresh(false);
        end
    elseif ( event == "ARTIFACT_XP_UPDATE" ) then
        if ( self:IsShown() ) then
            self.PerksTab:Refresh();
        end
    end
end

function ArmoryArtifactFrameMixin:ShowArtifact(link)
    local id = Armory:GetItemId(link);
    if ( id and Armory:IsArtifact(id) ) then
        if ( self:IsShown() ) then
            HideUIPanel(self);
        end
        Armory:SetSelectedArtifact(id);
        ShowUIPanel(self);
    end
end

function ArmoryArtifactFrameMixin:SetupPerArtifactData()
    local _, _, icon = Armory:GetArtifactInfoEx();
    if icon then
        self.ForgeBadgeFrame.ItemIcon:SetTexture(icon);
    end
end

local function MetaPowerTooltipHelper(...)
    local hasAddedAny = false;
    for i = 1, select("#", ...), 3 do
        local spellID, cost, currentRank = select(i, ...);
        local metaPowerDescription = GetSpellDescription(spellID);
        if ( metaPowerDescription ) then
            if ( hasAddedAny ) then
                GameTooltip:AddLine(" ");
            end
            GameTooltip:AddLine(metaPowerDescription, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
            hasAddedAny = true;
        end
    end

    return hasAddedAny;
end

function ArmoryArtifactFrameMixin:RefreshKnowledgeRanks()
    local totalRanks = Armory:GetTotalPurchasedRanks();
    if ( totalRanks > 0 ) then
        self.ForgeBadgeFrame.ForgeLevelLabel:SetText(totalRanks);
        self.ForgeBadgeFrame.ForgeLevelLabel:Show();
        self.ForgeBadgeFrame.ForgeLevelBackground:Show();
        self.ForgeBadgeFrame.ForgeLevelBackgroundBlack:Show();
        self.ForgeLevelFrame:Show();
    else
        self.ForgeBadgeFrame.ForgeLevelLabel:Hide();
        self.ForgeBadgeFrame.ForgeLevelBackground:Hide();
        self.ForgeBadgeFrame.ForgeLevelBackgroundBlack:Hide();
        self.ForgeLevelFrame:Hide();
    end
end

function ArmoryArtifactFrameMixin:OnKnowledgeEnter(knowledgeFrame)
    GameTooltip:SetOwner(knowledgeFrame, "ANCHOR_BOTTOMRIGHT", -25, 27);
    local artifactArtInfo = Armory:GetArtifactArtInfo();
    local color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Artifact];
    GameTooltip:SetText(artifactArtInfo.titleName, color.r, color.g, color.b);

    GameTooltip:AddLine(ARTIFACTS_NUM_PURCHASED_RANKS:format(Armory:GetTotalPurchasedRanks()), HIGHLIGHT_FONT_COLOR:GetRGB());

    local addedAnyMetaPowers = MetaPowerTooltipHelper(Armory:GetMetaPowerInfo());

    GameTooltip:Show();
end


----------------------------------------------------------
-- ArmoryArtifactPerks Mixin
----------------------------------------------------------

ArmoryArtifactPerksMixin = {};

local NUM_CURVED_LINE_SEGEMENTS = 20;
local CURVED_LINE_RADIUS_SCALAR = 0.98;
local CURVED_LINE_THICKNESS = 5;

local TIER2_FORGING_MODEL_SCENE_INFO = StaticModelInfo.CreateModelSceneEntry(55, 382335);            --"SPELLS\\EASTERN_PLAGUELANDS_BEAM_EFFECT.M2";

function ArmoryArtifactPerksMixin:OnLoad()
    self.powerButtonPool = CreateFramePool("BUTTON", self, "ArmoryArtifactPowerButtonTemplate");
end

function ArmoryArtifactPerksMixin:RefreshModel()
    local itemID, altItemID, icon, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID,
        altOnTop, uiCameraID, altHandUICameraID, modelAlpha, modelDesaturation = Armory:GetArtifactInfoEx();

    self.Model.uiCameraID = uiCameraID;
    self.Model.desaturation = modelDesaturation;
    if ( itemAppearanceID ) then
        self.Model:SetItemAppearance(itemAppearanceID);
    else
        self.Model:SetItem(itemID, appearanceModID);
    end

    local backgroundFrontTargetAlpha = 1.0 - (modelAlpha or 1.0);
    self.Model.backgroundFrontTargetAlpha = backgroundFrontTargetAlpha;
    self.Model.BackgroundFront:SetAlpha(backgroundFrontTargetAlpha);

    local baseModelFrameLevel = 505;
    local baseAltModelFrameLevel = 500;
    if ( altOnTop ) then
        baseModelFrameLevel, baseAltModelFrameLevel = baseAltModelFrameLevel, baseModelFrameLevel;
    end

    self.Model:SetFrameLevel(baseModelFrameLevel);

    if ( altItemID and altHandUICameraID ) then
        self.AltModel.uiCameraID = altHandUICameraID;
        self.AltModel.desaturation = modelDesaturation;
        if ( altItemAppearanceID ) then
            self.AltModel:SetItemAppearance(altItemAppearanceID);
        else
            self.AltModel:SetItem(altItemID, appearanceModID);
        end

        self.AltModel:Show();
        self.AltModel:SetFrameLevel(baseAltModelFrameLevel);
    else
        self.AltModel:Hide();
    end
end

function ArmoryArtifactsModelTemplate_OnModelLoaded(self)
    local CUSTOM_ANIMATION_SEQUENCE = 213;
    local animationSequence = self:HasAnimation(CUSTOM_ANIMATION_SEQUENCE) and CUSTOM_ANIMATION_SEQUENCE or 0;

    if ( self.uiCameraID ) then
        Model_ApplyUICamera(self, self.uiCameraID);
    end
    self:SetLight(true, false, 0, 0, 0, .7, 1.0, 1.0, 1.0);
    self:SetViewTranslation(-88, 0);

    self:SetAnimation(animationSequence, 0);

    if C_ArtifactUI.IsArtifactDisabled() then
        self:SetDesaturation(1);
        self:SetParticlesEnabled(false);
        self:SetPaused(true);
    else
        if ( self.useShadowEffect ) then
            self:SetShadowEffect(1);
        else
            self:SetDesaturation(self.desaturation or .5);
        end
    end
end

function ArmoryArtifactPerksMixin:RefreshBackground()
    local artifactArtInfo = Armory:GetArtifactArtInfo();
    if ( artifactArtInfo and artifactArtInfo.textureKit ) then
        self.textureKit = artifactArtInfo.textureKit;

        local bgAtlas = ("%s-BG"):format(artifactArtInfo.textureKit);
        self.BackgroundBack:SetAtlas(bgAtlas);
        local artifactDisabled = C_ArtifactUI.IsArtifactDisabled();
        self.BackgroundBack:SetDesaturated(artifactDisabled);
        self.Model.BackgroundFront:SetAtlas(bgAtlas);
        self.Model.BackgroundFront:SetDesaturated(artifactDisabled);
        self.Tier2ForgingScene.BackgroundMiddle:SetAtlas(bgAtlas);
        self.Tier2ForgingScene.BackgroundMiddle:Show();

        local crestAtlas = ("%s-BG-Rune"):format(artifactArtInfo.textureKit);
        self.CrestFrame.CrestRune1:SetAtlas(crestAtlas, true);
        self.CrestFrame.CrestRune1:SetDesaturated(artifactDisabled);
    else
        self.textureKit = nil;
    end
end

function ArmoryArtifactPerksMixin:AreAllGoldMedalsPurchasedByTier(tier)
    return self.areAllGoldMedalsPurchasedByTier[tier] == nil or self.areAllGoldMedalsPurchasedByTier[tier];
end

function ArmoryArtifactPerksMixin:AreAllPowersPurchasedByTier(tier)
    return self.areAllPowersPurchasedByTier[tier] == nil or self.areAllPowersPurchasedByTier[tier];
end

function ArmoryArtifactPerksMixin:GetStartingPowerButtonByTier(tier)
    return self.startingPowerButtonsByTier[tier];
end

function ArmoryArtifactPerksMixin:GetFinalPowerButtonByTier(tier)
    return self.finalPowerButtonsByTier[tier];
end

function ArmoryArtifactPerksMixin:RefreshPowers(newItem)
    if ( newItem or not self.powerIDToPowerButton ) then
        self.powerButtonPool:ReleaseAll();
        self.powerIDToPowerButton = {};
    end

    local currentTier = Armory:GetArtifactTier();
    self.startingPowerButtonsByTier = {};
    self.finalPowerButtonsByTier = {};
    self.areAllPowersPurchasedByTier = {};
    self.areAllGoldMedalsPurchasedByTier = {};

    local powers = Armory:GetPowers();

    for i, powerID in ipairs(powers) do
        local powerButton = self.powerIDToPowerButton[powerID];

        if ( not powerButton ) then
            powerButton = self.powerButtonPool:Acquire();
            self.powerIDToPowerButton[powerID] = powerButton;

            powerButton:ClearOldData();
        end

        powerButton:SetupButton(powerID, self.BackgroundBack, self.textureKit);
        powerButton.links = {};
        powerButton.owner = self;

        if ( powerButton:IsStart() ) then
            self.startingPowerButtonsByTier[powerButton:GetTier()] = powerButton;
        elseif ( powerButton:IsFinal() ) then
            self.finalPowerButtonsByTier[powerButton:GetTier()] = powerButton;
        elseif ( not powerButton:IsCompletelyPurchased() ) then
            self.areAllPowersPurchasedByTier[powerButton:GetTier()] = false;
            if ( powerButton:IsGoldMedal() ) then
                self.areAllGoldMedalsPurchasedByTier[powerButton:GetTier()] = false;
            end
        end

        local meetsTier = currentTier >= powerButton:GetTier();
        powerButton:SetShown(meetsTier);
        powerButton:SetLinksEnabled(meetsTier and not powerButton:IsFinal());
    end

    self:RefreshPowerTiers();
    self:RefreshDependencies(powers);
    self:RefreshRelics();
end

function ArmoryArtifactPerksMixin:RefreshFinalPowerForTier(tier, isUnlocked)
    local finalTierButton = self:GetFinalPowerButtonByTier(tier);
    if ( finalTierButton ) then
        if ( isUnlocked ) then
            if ( self.wasFinalPowerButtonUnlockedByTier[tier] == false ) then
                self.wasFinalPowerButtonUnlockedByTier[tier] = true;
                finalTierButton:Show();
            end
        else
            finalTierButton:Hide();
            self.wasFinalPowerButtonUnlockedByTier[tier] = false;
        end
    end
end

function ArmoryArtifactPerksMixin:RefreshPowerTiers()
    self:RefreshFinalPowerForTier(1, self:AreAllGoldMedalsPurchasedByTier(1));
    self:RefreshFinalPowerForTier(2, self:AreAllPowersPurchasedByTier(2));

    if ( Armory:GetArtifactTier() >= 2 or Armory:IsMaxedByRulesOrEffect() ) then
        local finalTier2Button = self:GetFinalPowerButtonByTier(2);
        if ( finalTier2Button ) then
            self.CrestFrame:ClearAllPoints();
            self.CrestFrame:SetPoint("CENTER", finalTier2Button, "CENTER");
            self.CrestFrame:Show();

            local forceUpdate = true;

            self.Tier2ForgingScene:Show();
            local forgingEffect = StaticModelInfo.SetupModelScene(self.Tier2ForgingScene, TIER2_FORGING_MODEL_SCENE_INFO, forceUpdate);
            if ( forgingEffect ) then
                forgingEffect:SetAlpha(0.0);
            end
        else
            self.CrestFrame:Hide();
        end
    else
        self.CrestFrame:Hide();
    end
end

function ArmoryArtifactPerksMixin:GetOrCreateDependencyLine(lineIndex)
    local lineContainer = self.DependencyLines and self.DependencyLines[lineIndex];
    if ( lineContainer ) then
        lineContainer:Show();
        return lineContainer;
    end

    lineContainer = CreateFrame("FRAME", nil, self, "ArmoryArtifactDependencyLineTemplate");

    return lineContainer;
end

function ArmoryArtifactPerksMixin:GetOrCreateCurvedDependencyLine(lineIndex)
    local lineContainer = self.CurvedDependencyLines and self.CurvedDependencyLines[lineIndex];
    if ( lineContainer ) then
        lineContainer:Show();
        return lineContainer;
    end

    lineContainer = CreateFrame("FRAME", nil, self, "ArmoryArtifactCurvedDependencyLineTemplate");

    return lineContainer;
end

function ArmoryArtifactPerksMixin:HideUnusedWidgets(widgetTable, numUsed, customHideFunc)
    if ( widgetTable ) then
        for i = numUsed + 1, #widgetTable do
            widgetTable[i]:Hide();
            if ( customHideFunc ) then
                customHideFunc(widgetTable[i]);
            end
        end
    end
end

local function HasPurchasedAnything()
    return Armory:GetTotalPurchasedRanks() > 0 or Armory:IsMaxedByRulesOrEffect();
end

function ArmoryArtifactPerksMixin:Refresh(newItem)
    self.newItem = self.newItem or newItem;

    local artifactItemID = Armory:GetArtifactItemID();
    if ( not artifactItemID or not C_Item.IsItemDataCachedByID(artifactItemID) ) then
        return;
    end

    if ( newItem ) then
        self:HideAllLines();
        self:RefreshBackground();
        self:RefreshModel();
    end

    local hasBoughtAnyPowers = HasPurchasedAnything();
    if ( newItem ) then
        self.hasBoughtAnyPowers = hasBoughtAnyPowers;
        self.wasFinalPowerButtonUnlockedByTier = {};
    elseif ( self.hasBoughtAnyPowers ~= hasBoughtAnyPowers ) then
        self:HideAllLines();

        self.hasBoughtAnyPowers = hasBoughtAnyPowers;
    end

    local finalTier2WasUnlocked = self.wasFinalPowerButtonUnlockedByTier[2];
    self:RefreshPowers(newItem);

    self.TitleContainer:SetPointsRemaining(Armory:GetPointsRemaining());

    self.newItem = nil;

    if ( Armory:GetArtifactTier() == 2 or Armory:IsMaxedByRulesOrEffect() ) then
        self:ShowTier2();
        self.CrestFrame.CrestRune1:SetAlpha(1.0);
        self.Model.BackgroundFront:SetAlpha(self.Model.backgroundFrontTargetAlpha);
        if ( Armory:IsMaxedByRulesOrEffect() ) then
            local finalTier1Button = self:GetFinalPowerButtonByTier(1);
            if ( finalTier1Button ) then
                finalTier1Button:Show();
            end

            local finalTier2Button = self:GetFinalPowerButtonByTier(2);
            if ( finalTier2Button ) then
                finalTier2Button:Show();
            end
        end
    end
end

local LINE_STATE_CONNECTED = 1;
local LINE_STATE_UNLOCKED = 2;
local LINE_STATE_LOCKED = 3;

local function OnUnusedLineHidden(lineContainer)
    lineContainer:SetAlpha(0.0);
end

function ArmoryArtifactPerksMixin:GenerateCurvedLine(startButton, endButton, state, artifactArtInfo)
    local finalTier2Power = self:GetFinalPowerButtonByTier(2);
    if ( not finalTier2Power ) then
        return nil;
    end

    local spline = CreateCatmullRomSpline(2);

    local finalPosition = CreateVector2D(finalTier2Power:GetCenter());
    local startPosition = CreateVector2D(startButton:GetCenter());
    local endPosition = CreateVector2D(endButton:GetCenter());

    local angleOffset = math.atan2(finalPosition.y - startPosition.y, startPosition.x - finalPosition.x);

    local totalAngle = Vector2D_CalculateAngleBetween(endPosition.x - finalPosition.x, endPosition.y - finalPosition.y, startPosition.x - finalPosition.x, startPosition.y - finalPosition.y);
    if ( totalAngle <= 0 ) then
        return;
    end

    local lengthToEdge = Vector2D_GetLength(Vector2D_Subtract(finalPosition.x, finalPosition.y, endPosition.x, endPosition.y));
    lengthToEdge = lengthToEdge * CURVED_LINE_RADIUS_SCALAR;
    -- Catmullrom splines are not quadratic so they cannot perfectly fit a circle, add enough points so that the sampling will produce something close enough to a circle
    -- Keeping this as a spline for now in case we need to connect something non-circular
    local NUM_SLICES = 10;
    local anglePerSlice = totalAngle / (NUM_SLICES - 1);
    for slice = 1, NUM_SLICES do
        local angle = (slice - 1) * anglePerSlice;
        local x = math.cos(angle + angleOffset) * lengthToEdge;
        local y = math.sin(angle + angleOffset) * lengthToEdge;
        spline:AddPoint(x, y);
    end

    local artifactDisabled = C_ArtifactUI.IsArtifactDisabled();
    local previousEndPoint;
    local previousLineContainer;
    for i = 1, NUM_CURVED_LINE_SEGEMENTS do
        self.numUsedCurvedLines = self.numUsedCurvedLines + 1;
        local lineContainer = self:GetOrCreateCurvedDependencyLine(self.numUsedCurvedLines);
        if ( artifactDisabled ) then
            lineContainer:SetConnectedColor(DISABLED_FONT_COLOR);
            lineContainer:SetDisconnectedColor(DISABLED_FONT_COLOR);
        else
            lineContainer:SetConnectedColor(artifactArtInfo.barConnectedColor);
            lineContainer:SetDisconnectedColor(artifactArtInfo.barDisconnectedColor);
        end
        lineContainer:SetEndPoints(finalTier2Power);
        lineContainer:SetState(state);

        local fromPoint = previousEndPoint or CreateVector2D(spline:CalculatePointOnGlobalCurve(0.0));
        local toPoint = CreateVector2D(spline:CalculatePointOnGlobalCurve(i / NUM_CURVED_LINE_SEGEMENTS));

        local delta = toPoint:Clone();
        delta:Subtract(fromPoint);

        local length = delta:GetLength();
        lineContainer:CalculateTiling(length);

        local thickness = CreateVector2D(-delta.y, delta.x);
        thickness:DivideBy(length);

        thickness:ScaleBy(CURVED_LINE_THICKNESS);

        if ( previousLineContainer ) then
            -- We're in the middle or the last piece, connect the start of this to the end of the last

            -- Making these meet by dividing the tangent (miter) would look better, but seems good enough for this scale
            previousLineContainer:SetVertexOffset(UPPER_LEFT_VERTEX, fromPoint.x + thickness.x + 1, -1 - (fromPoint.y + thickness.y));
            previousLineContainer:SetVertexOffset(LOWER_LEFT_VERTEX, fromPoint.x - thickness.x + 1, 1 - (fromPoint.y - thickness.y));

            lineContainer:SetVertexOffset(UPPER_RIGHT_VERTEX, fromPoint.x + thickness.x - 1, -1 - (fromPoint.y + thickness.y));
            lineContainer:SetVertexOffset(LOWER_RIGHT_VERTEX, fromPoint.x - thickness.x - 1, 1 - (fromPoint.y - thickness.y));

            if ( i == NUM_CURVED_LINE_SEGEMENTS ) then
                -- Last piece, just go ahead and just connect the line to the end now
                lineContainer:SetVertexOffset(UPPER_LEFT_VERTEX, toPoint.x + thickness.x + 1, -1 - (toPoint.y + thickness.y));
                lineContainer:SetVertexOffset(LOWER_LEFT_VERTEX, toPoint.x - thickness.x + 1, 1 - (toPoint.y - thickness.y));
            end
        else
            -- First piece, just connect the start
            lineContainer:SetVertexOffset(UPPER_RIGHT_VERTEX, fromPoint.x + thickness.x - 1, -1 - (fromPoint.y + thickness.y));
            lineContainer:SetVertexOffset(LOWER_RIGHT_VERTEX, fromPoint.x - thickness.x - 1, 1 - (fromPoint.y - thickness.y));
        end

        previousLineContainer = lineContainer;
        previousEndPoint = toPoint;
    end

    return previousLineContainer;
end

function ArmoryArtifactPerksMixin:RefreshDependencies(powers)
    self.numUsedLines = 0;
    self.numUsedCurvedLines = 0;

    local artifactDisabled = C_ArtifactUI.IsArtifactDisabled();
    local artifactArtInfo = Armory:GetArtifactArtInfo();
    local lastTier2Power = nil;

    for i, fromPowerID in ipairs(powers) do
        local fromButton = self.powerIDToPowerButton[fromPowerID];
        local fromLinks = Armory:GetPowerLinks(fromPowerID);

        if ( fromLinks ) then
            for j, toPowerID in ipairs(fromLinks) do
                local toButton = self.powerIDToPowerButton[toPowerID];
                if ( self:GetFinalPowerButtonByTier(2) == toButton ) then
                    lastTier2Power = fromButton;
                end
                if ( not fromButton.links[toPowerID] and fromButton:AreLinksEnabled() ) then
                    if ( toButton and not toButton.links[fromPowerID] and toButton:AreLinksEnabled() ) then
                        if ( (not fromButton:GetLinearIndex() or not toButton:GetLinearIndex()) or fromButton:GetLinearIndex() < toButton:GetLinearIndex() ) then
                            local state;
                            if ( (toButton:IsStart() or toButton:ArePrereqsMet()) and (fromButton:IsStart() or fromButton:ArePrereqsMet()) ) then
                                local hasSpentAny = fromButton.hasSpentAny and toButton.hasSpentAny;
                                if ( hasSpentAny or (fromButton:IsActiveForLinks() and toButton:IsCompletelyPurchased()) or (toButton:IsActiveForLinks() and fromButton:IsCompletelyPurchased()) ) then
                                    if ( (fromButton:IsActiveForLinks() and toButton.hasSpentAny) or (toButton:IsActiveForLinks() and fromButton.hasSpentAny) ) then
                                        state = LINE_STATE_CONNECTED;
                                    else
                                        state = LINE_STATE_DISCONNECTED;
                                    end
                                else
                                    state = LINE_STATE_LOCKED;
                                end
                            end

                            if ( fromButton:GetTier() == 2 and toButton:GetTier() == 2 ) then
                                local lineContainer = self:GenerateCurvedLine(fromButton, toButton, state, artifactArtInfo);
                                fromButton.links[toPowerID] = lineContainer;
                                toButton.links[fromPowerID] = lineContainer;
                            else
                                self.numUsedLines = self.numUsedLines + 1;
                                local lineContainer = self:GetOrCreateDependencyLine(self.numUsedLines);
                                if ( artifactDisabled ) then
                                    lineContainer:SetConnectedColor(DISABLED_FONT_COLOR);
                                    lineContainer:SetDisconnectedColor(DISABLED_FONT_COLOR);
                                else
                                    lineContainer:SetConnectedColor(artifactArtInfo.barConnectedColor);
                                    lineContainer:SetDisconnectedColor(artifactArtInfo.barDisconnectedColor);
                                end
                                local fromCenter = CreateVector2D(fromButton:GetCenter());
                                fromCenter:ScaleBy(fromButton:GetEffectiveScale());

                                local toCenter = CreateVector2D(toButton:GetCenter());
                                toCenter:ScaleBy(toButton:GetEffectiveScale());

                                toCenter:Subtract(fromCenter);

                                lineContainer:CalculateTiling(toCenter:GetLength());

                                lineContainer:SetEndPoints(fromButton, toButton);

                                lineContainer:SetState(state);

                                fromButton.links[toPowerID] = lineContainer;
                                toButton.links[fromPowerID] = lineContainer;
                            end
                        end
                    end
                end
            end
        end

        -- Artificially link the starting and last power if they're both purchased to complete the circle
        if ( lastTier2Power and lastTier2Power:IsCompletelyPurchased() and lastTier2Power:HasSpentAny() ) then
            local startingTier2Power = self:GetStartingPowerButtonByTier(2);
            if ( startingTier2Power and startingTier2Power:IsCompletelyPurchased() and not startingTier2Power.links[lastTier2Power:GetPowerID()] ) then
                local lineContainer = self:GenerateCurvedLine(lastTier2Power, startingTier2Power, LINE_STATE_CONNECTED, artifactArtInfo);

                lastTier2Power.links[startingTier2Power:GetPowerID()] = lineContainer;
                startingTier2Power.links[lastTier2Power:GetPowerID()] = lineContainer;
            end
        end
    end

    self:HideUnusedWidgets(self.DependencyLines, self.numUsedLines, OnUnusedLineHidden);
    self:HideUnusedWidgets(self.CurvedDependencyLines, self.numUsedCurvedLines, OnUnusedLineHidden);
end

local function RelicRefreshHelper(self, relicSlotIndex, powersAffected, ...)
    for i = 1, select("#", ...) do
        local powerID = select(i, ...);
        powersAffected[powerID] = true;
        self:AddRelicToPower(powerID, relicSlotIndex);
    end
end

function ArmoryArtifactPerksMixin:RefreshRelics()
    local powersAffected = {};
    for relicSlotIndex = 1, Armory:GetNumRelicSlots() do
        RelicRefreshHelper(self, relicSlotIndex, powersAffected, Armory:GetPowersAffectedByRelic(relicSlotIndex));
    end

    for powerID, button in pairs(self.powerIDToPowerButton) do
        if ( not powersAffected[powerID] ) then
            button:RemoveRelicType();
        end
    end
end

function ArmoryArtifactPerksMixin:AddRelicToPower(powerID, relicSlotIndex)
    local button = self.powerIDToPowerButton[powerID];
    if ( button ) then
        local relicType = Armory:GetRelicSlotType(relicSlotIndex);
        local relicName, relicIcon, _, relicLink = Armory:GetRelicInfo(relicSlotIndex);
        button:ApplyRelicType(relicType, relicLink, self.newItem);
    end
end

local function RelicHighlightHelper(self, highlightEnabled, ...)
    for i = 1, select("#", ...) do
        local powerID = select(i, ...);
        self:SetRelicPowerHighlightEnabled(powerID, highlightEnabled);
    end
end

function ArmoryArtifactPerksMixin:OnRelicSlotMouseEnter(relicSlotIndex)
    RelicHighlightHelper(self, true, Armory:GetPowersAffectedByRelic(relicSlotIndex));
end

function ArmoryArtifactPerksMixin:OnRelicSlotMouseLeave(relicSlotIndex)
    RelicHighlightHelper(self, false, Armory:GetPowersAffectedByRelic(relicSlotIndex));
end

function ArmoryArtifactPerksMixin:SetRelicPowerHighlightEnabled(powerID, highlight, tempRelicType, tempRelicLink)
    local button = self.powerIDToPowerButton[powerID];
    if ( button ) then
        if ( highlight and tempRelicType and tempRelicLink ) then
            button:ApplyTemporaryRelicType(tempRelicType, tempRelicLink);
        else
            button:RemoveTemporaryRelicType();
        end
        button:SetRelicHighlightEnabled(highlight);
    end
end

function ArmoryArtifactPerksMixin:HideAllLines()
    self:HideUnusedWidgets(self.DependencyLines, 0, OnUnusedLineHidden);
end

function ArmoryArtifactPerksMixin:HideTier2()
    for powerID, button in pairs(self.powerIDToPowerButton) do
        if ( button:GetTier() == 2 and button ~= self:GetFinalPowerButtonByTier(2) ) then
            button:Show();
        end
    end

    self.CrestFrame.CrestRune1:Hide();

    if ( self.CurvedDependencyLines ) then
        for i = 1, self.numUsedCurvedLines do
            local lineContainer = self.CurvedDependencyLines[i];
            lineContainer:Hide();
        end
    end
end

function ArmoryArtifactPerksMixin:ShowTier2()
    for powerID, button in pairs(self.powerIDToPowerButton) do
        if ( button:GetTier() == 2 and button ~= self:GetFinalPowerButtonByTier(2) ) then
            button:Show();
        end
    end

    if ( self.CurvedDependencyLines ) then
        for i = 1, self.numUsedCurvedLines do
            local lineContainer = self.CurvedDependencyLines[i];
            lineContainer:Show();
        end
    end

    self.CrestFrame.CrestRune1:Show();
end

----------------------------------------------------------
-- ArmoryArtifactTitleTemplate Mixin
----------------------------------------------------------

ArmoryArtifactTitleTemplateMixin = {};

function ArmoryArtifactTitleTemplateMixin:RefreshTitle()
    local disabledFrame = self:GetParent().DisabledFrame;

    local artifactArtInfo = Armory:GetArtifactArtInfo();
    if ( C_ArtifactUI.IsArtifactDisabled() ) then
        disabledFrame:Show();
        disabledFrame.ArtifactName:SetText(artifactArtInfo.titleName);
        disabledFrame.ArtifactName:SetVertexColor(0.588, 0.557, 0.463);

        if ( artifactArtInfo and artifactArtInfo.textureKit ) then
            local headerAtlas = ("%s-Header"):format(artifactArtInfo.textureKit);
            disabledFrame.Background:SetAtlas(headerAtlas, true);
            disabledFrame.Background:SetDesaturated(true);
            disabledFrame.Background:Show();
        else
            disabledFrame.Background:Hide();
        end

        self.ArtifactName:Hide();
        self.ArtifactPower:Hide();
        self.Background:Hide();
    else
        self.ArtifactName:Show();
        self.ArtifactName:SetText(artifactArtInfo.titleName);
        self.ArtifactName:SetVertexColor(artifactArtInfo.titleColor:GetRGB());
        self.ArtifactPower:Show();

        if ( artifactArtInfo and artifactArtInfo.textureKit ) then
            local headerAtlas = ("%s-Header"):format(artifactArtInfo.textureKit);
            self.Background:SetAtlas(headerAtlas, true);
            self.Background:Show();
        else
            self.Background:Hide();
        end

        disabledFrame:Hide();
    end
end

function ArmoryArtifactTitleTemplateMixin:OnShow()
    self:RefreshTitle();
    self:EvaluateRelics();

    self:RegisterEvent("ARTIFACT_UPDATE");

    if ( C_ArtifactUI.IsArtifactDisabled() ) then
        self.PointsRemainingLabel:Hide();
    else
        self.PointsRemainingLabel:Show();
    end
end

function ArmoryArtifactTitleTemplateMixin:OnHide()
    self:UnregisterEvent("ARTIFACT_UPDATE");
end

function ArmoryArtifactTitleTemplateMixin:OnEvent(event, ...)
    local newItem = ...;
    if ( newItem ) then
        self:RefreshTitle();
    end
    self:EvaluateRelics();
    self:RefreshRelicTooltips();
end

function ArmoryArtifactTitleTemplateMixin:OnRelicSlotMouseEnter(relicSlot)
    if ( relicSlot.lockedReason ) then
        GameTooltip:SetOwner(relicSlot, "ANCHOR_BOTTOMRIGHT", 0, 10);
        local slotName = _G["RELIC_SLOT_TYPE_" .. relicSlot.relicType:upper()];
        if ( slotName ) then
            GameTooltip:SetText(LOCKED_RELIC_TOOLTIP_TITLE:format(slotName), 1, 1, 1);
            if relicSlot.lockedReason == "" then
                GameTooltip:AddLine(LOCKED_RELIC_TOOLTIP_BODY, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
            else
                GameTooltip:AddLine(relicSlot.lockedReason, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
            end
            GameTooltip:Show();
        end
    elseif ( relicSlot.relicLink ) then
        GameTooltip:SetOwner(relicSlot, "ANCHOR_BOTTOMRIGHT", 0, 10);
        GameTooltip:SetHyperlink(relicSlot.relicLink);
        GameTooltip:Show();
    elseif ( relicSlot.relicType ) then
        GameTooltip:SetOwner(relicSlot, "ANCHOR_BOTTOMRIGHT", 0, 10);
        local slotName = _G["RELIC_SLOT_TYPE_" .. relicSlot.relicType:upper()];
        if ( slotName ) then
            GameTooltip:SetText(EMPTY_RELIC_TOOLTIP_TITLE:format(slotName), 1, 1, 1);
            GameTooltip:AddLine(EMPTY_RELIC_TOOLTIP_BODY:format(slotName), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
            GameTooltip:Show();
        end
    end
    self:GetParent():OnRelicSlotMouseEnter(relicSlot.relicSlotIndex);
end

function ArmoryArtifactTitleTemplateMixin:OnRelicSlotMouseLeave(relicSlot)
    GameTooltip_Hide();
    self:GetParent():OnRelicSlotMouseLeave(relicSlot.relicSlotIndex);
end

function ArmoryArtifactTitleTemplateMixin:OnRelicSlotClicked(relicSlot)
    for i = 1, #self.RelicSlots do
        if ( self.RelicSlots[i] == relicSlot ) then
            if ( IsModifiedClick() ) then
                local _, _, _, itemLink = Armory:GetRelicInfo(i);
                HandleModifiedItemClick(itemLink);
            end
            break;
        end
    end
end

function ArmoryArtifactTitleTemplateMixin:RefreshRelicTooltips()
    for i = 1, #self.RelicSlots do
        if ( GameTooltip:IsOwned(self.RelicSlots[i]) ) then
            self.RelicSlots[i]:GetScript("OnEnter")(self.RelicSlots[i]);
            break;
        end
    end
end

function ArmoryArtifactTitleTemplateMixin:EvaluateRelics()
    local numRelicSlots = Armory:GetNumRelicSlots() or 0;

    self:SetHeight(140);

    for i = 1, numRelicSlots do
        local relicSlot = self.RelicSlots[i];

        local relicType = Armory:GetRelicSlotType(i);

        local relicAtlasName = ("Relic-%s-Slot"):format(relicType);
        relicSlot:GetNormalTexture():SetAtlas(relicAtlasName, true);
        relicSlot:GetHighlightTexture():SetAtlas(relicAtlasName, true);
        relicSlot.GlowBorder1:SetAtlas(relicAtlasName, true);
        relicSlot.GlowBorder2:SetAtlas(relicAtlasName, true);
        relicSlot.GlowBorder3:SetAtlas(relicAtlasName, true);
        local lockedReason = Armory:GetRelicLockedReason(i);
        if ( lockedReason ) then
            relicSlot:GetNormalTexture():SetAlpha(.5);
            relicSlot:Disable();
            relicSlot.LockedIcon:Show();
            relicSlot.Icon:SetMask(nil);
            relicSlot.Icon:SetAtlas("Relic-SlotBG", true);
            relicSlot.Glass:Hide();
            relicSlot.relicLink = nil;
        else
            local relicName, relicIcon, relicType, relicLink = Armory:GetRelicInfo(i);

            relicSlot:GetNormalTexture():SetAlpha(1);
            relicSlot:Enable();
            relicSlot.LockedIcon:Hide();
            if ( relicIcon ) then
                relicSlot.Icon:SetSize(34, 34);
                relicSlot.Icon:SetMask(nil);
                relicSlot.Icon:SetTexCoord(0, 1, 0, 1); -- Masks may overwrite our tex coords (even ones set by an atlas), force it back to using the full item icon texture
                relicSlot.Icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask");
                relicSlot.Icon:SetTexture(relicIcon);
                relicSlot.Glass:Show();
            else
                relicSlot.Icon:SetMask(nil);
                relicSlot.Icon:SetAtlas("Relic-SlotBG", true);
                relicSlot.Glass:Hide();
            end
            relicSlot.relicLink = relicLink;
        end

        relicSlot.relicType = relicType;
        relicSlot.relicSlotIndex = i;
        relicSlot.lockedReason = lockedReason;

        relicSlot:ClearAllPoints();
        local PADDING = 0;
        if ( i == 1 ) then
            local offsetX = -(numRelicSlots - 1) * (relicSlot:GetWidth() + PADDING) * .5;
            relicSlot:SetPoint("CENTER", self, "CENTER", offsetX, -6);
        else
            relicSlot:SetPoint("LEFT", self.RelicSlots[i - 1], "RIGHT", PADDING, 0);
        end

        relicSlot:Show();
    end

    for i = numRelicSlots + 1, #self.RelicSlots do
        self.RelicSlots[i]:Hide();
    end
end

function ArmoryArtifactTitleTemplateMixin:SetPointsRemaining(value)
    if ( not C_ArtifactUI.IsArtifactDisabled() ) then
        self.PointsRemainingLabel:SetText(BreakUpLargeNumbers(value));
    end
end


----------------------------------------------------------
-- ArmoryArtifactPowerButton Mixin
----------------------------------------------------------

ArmoryArtifactPowerButtonMixin = {};

function ArmoryArtifactPowerButtonMixin:OnLoad()
    self.LightRune:SetAtlas(self:GenerateRune(), true);
end

function ArmoryArtifactPowerButtonMixin:GenerateRune()
    local NUM_RUNE_TYPES = 11;
    local runeIndex = math.random(1, NUM_RUNE_TYPES);
    return ("Rune-%02d-light"):format(runeIndex);
end

function ArmoryArtifactPowerButtonMixin:OnEnter()
    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetArtifactPowerByID(self:GetPowerID());

        Armory:FilterTooltip(GameTooltip, TOOLTIP_TALENT_RANK, ARTIFACT_POWER_UNLINKED_TOOLTIP);

        self.UpdateTooltip = self.OnEnter;
    end
end

function ArmoryArtifactPowerButtonMixin:OnClick(button)
    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE and IsModifiedClick("CHATLINK") ) then
        local link = Armory:GetPowerHyperlink(self:GetPowerID());
        if ( link ) then
            ChatEdit_InsertLink(link);
        end
    end
end

function ArmoryArtifactPowerButtonMixin:UpdatePowerType()
    self:SetSize(37, 37);
    if ( self.isStart and self.tier == 1 ) then
        self.Icon:SetSize(52, 52);
        self.CircleMask:SetSize(52, 52);
        self.IconBorder:SetAtlas("Artifacts-PerkRing-MainProc", true);
        self.IconBorderDesaturated:SetAtlas("Artifacts-PerkRing-MainProc", true);
    elseif ( self.isFinal and self.tier ~= 1 ) then
        self:SetSize(94, 94);
        self.Icon:SetSize(94, 94);
        self.CircleMask:SetSize(94, 94);
        self.IconBorder:SetAtlas("Artifacts-PerkRing-Final", true);
        self.IconBorderDesaturated:SetAtlas("Artifacts-PerkRing-Final", true);
    elseif ( self.isGoldMedal ) then
        self.Icon:SetSize(50, 50);
        self.CircleMask:SetSize(50, 50);
        self.IconBorder:SetAtlas("Artifacts-PerkRing-GoldMedal", true);
        self.IconBorderDesaturated:SetAtlas("Artifacts-PerkRing-GoldMedal", true);
    else
        self.Icon:SetSize(45, 45);
        self.CircleMask:SetSize(45, 45);
        self.IconBorder:SetAtlas("Artifacts-PerkRing-Small", true);
        self.IconBorderDesaturated:SetAtlas("Artifacts-PerkRing-Small", true);
    end
end

function ArmoryArtifactPowerButtonMixin:SetStyle(style)
    local rankTextColor = CreateColor(0, 0, 0);
    local iconVertexColor = CreateColor(1, 1, 1);
    local iconAlpha = 1;
    local iconBorderAlpha = 1;
    local iconBorderDesaturatedAlpha = 0;

    self.style = style;
    self.IconDesaturated:SetAlpha(1);
    self.IconDesaturated:SetVertexColor(1, 1, 1);
    self.Rank:SetAlpha(1);
    self.RankBorder:SetAlpha(1);
    self.IconBorder:SetVertexColor(1, 1, 1);
    self.LightRune:Hide();

    local artifactDisabled = C_ArtifactUI.IsArtifactDisabled();

    if ( style == ARTIFACT_POWER_STYLE_RUNE ) then
        self.LightRune:Show();
        self.LightRune:SetDesaturated(artifactDisabled);

        iconAlpha = 0;
        iconBorderAlpha = 0;

        self.Rank:SetText(nil);
        self.Rank:SetAlpha(0);
        self.RankBorder:SetAlpha(0);

        self.IconDesaturated:SetAlpha(0);
    elseif ( style == ARTIFACT_POWER_STYLE_MAXED ) then
        self.Rank:SetText(self.currentRank);
        rankTextColor:SetRGB(1, 0.82, 0);
        self.RankBorder:SetAtlas("Artifacts-PointsBox", true);
        self.RankBorder:Show();
    elseif ( style == ARTIFACT_POWER_STYLE_CAN_UPGRADE ) then
        self.Rank:SetText(self.currentRank);
        rankTextColor:SetRGB(0.1, 1, 0.1);
        if ( artifactDisabled ) then
            self.RankBorder:SetAtlas("Artifacts-PointsBox", true);
        else
            self.RankBorder:SetAtlas("Artifacts-PointsBoxGreen", true);
        end
        self.RankBorder:Show();
    elseif ( style == ARTIFACT_POWER_STYLE_PURCHASED or style == ARTIFACT_POWER_STYLE_PURCHASED_READ_ONLY ) then
        self.Rank:SetText(self.currentRank);
        rankTextColor:SetRGB(1, 0.82, 0);
        self.RankBorder:SetAtlas("Artifacts-PointsBox", true);
        self.RankBorder:Show();
    elseif ( style == ARTIFACT_POWER_STYLE_UNPURCHASED ) then
        self.IconBorder:SetVertexColor(.9, .9, .9);
        iconVertexColor:SetRGB(.6, .6, .6);

        self.Rank:SetText(self.currentRank);
        rankTextColor:SetRGB(1, 0.82, 0);
        self.RankBorder:SetAtlas("Artifacts-PointsBox", true);
        self.RankBorder:Show();
    elseif ( style == ARTIFACT_POWER_STYLE_UNPURCHASED_READ_ONLY or style == ARTIFACT_POWER_STYLE_UNPURCHASED_LOCKED ) then
        if ( self.isGoldMedal or self.isStart ) then
            iconVertexColor:SetRGB(.4, .4, .4);
            self.IconBorder:SetVertexColor(.7, .7, .7);
            self.IconDesaturated:SetVertexColor(.4, .4, .4);
            self.RankBorder:Hide();
            self.Rank:SetText(nil);
            iconBorderDesaturatedAlpha = 0.5;
            iconAlpha = .5;
        else
            iconVertexColor:SetRGB(.15, .15, .15);
            self.IconBorder:SetVertexColor(.4, .4, .4);
            self.IconDesaturated:SetVertexColor(.15, .15, .15);
            self.RankBorder:Hide();
            self.Rank:SetText(nil);
            iconAlpha = .2;
        end
    end

    if ( artifactDisabled ) then
        rankTextColor = DISABLED_FONT_COLOR;
        iconAlpha = 0;
        if ( style ~= ARTIFACT_POWER_STYLE_RUNE ) then
            iconBorderDesaturatedAlpha = 1;
        end
        self.IconBorder:Hide();
    else
        self.IconBorder:Show();
    end

    self.Rank:SetTextColor(rankTextColor:GetRGB());
    self.Icon:SetVertexColor(iconVertexColor:GetRGB());
    self.Icon:SetAlpha(iconAlpha);
    self.IconBorder:SetAlpha(iconBorderAlpha);
    self.IconBorderDesaturated:SetAlpha(iconBorderDesaturatedAlpha);
end

function ArmoryArtifactPowerButtonMixin:ApplyTemporaryRelicType(relicType, relicLink)
    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE and self.originalRelicType == nil and self.originalRelicLink == nil ) then
        self.originalRelicType = self.relicType or false;
        self.originalRelicLink = self.relicLink or false;
        self:ApplyRelicType(relicType, relicLink, true);
    end
end

function ArmoryArtifactPowerButtonMixin:RemoveTemporaryRelicType()
    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE and self.originalRelicType ~= nil and self.originalRelicLink ~= nil ) then
        self:ApplyRelicType(self.originalRelicType or nil, self.originalRelicLink or nil, true);

        self.originalRelicType = nil;
        self.originalRelicLink = nil;
    end
end

function ArmoryArtifactPowerButtonMixin:ApplyRelicType(relicType, relicLink)
    if ( self.style == ARTIFACT_POWER_STYLE_RUNE ) then
        -- Runes cannot have relics
        relicType = nil;
        relicLink = nil;
    end

    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE and relicType ) then
        local relicTraitBGAtlas = ("Relic-%s-TraitBG"):format(relicType);
        self.RelicTraitBG:SetAtlas(relicTraitBGAtlas);
        self.RelicTraitBG:Show();

        local relicTraitGlowAtlas = ("Relic-%s-TraitGlow"):format(relicType);
        self.RelicTraitGlow:SetAtlas(relicTraitGlowAtlas);

        local relicTraitGlowRingAtlas = ("Relic-%s-TraitGlowRing"):format(relicType);
        self.RelicTraitGlowRing:SetAtlas(relicTraitGlowRingAtlas);

        local isLarge = self.isStart or self.isGoldMedal;
        local traitSize = isLarge and 120 or 82;
        self.RelicTraitBG:SetSize(traitSize, traitSize);
        self.RelicTraitGlow:SetSize(traitSize, traitSize);

        local ringSize = isLarge and 98 or 82;
        self.RelicTraitGlowRing:SetSize(ringSize, ringSize);

        self:SetRelicHighlightEnabled(false);
    else
        self.RelicTraitBG:Hide();
        self.RelicTraitGlow:Hide();
        self.RelicTraitGlowRing:Hide();
    end
    self.relicType = relicType;
    self.relicLink = relicLink;
end

function ArmoryArtifactPowerButtonMixin:RemoveRelicType()
    self.relicType = nil;
    self.relicLink = nil;
    self.originalRelicType = nil;
    self.originalRelicLink = nil;

    self.RelicTraitBG:Hide();
    self.RelicTraitGlow:Hide();
    self.RelicTraitGlowRing:Hide();
end

local HIGHLIGHT_ALPHA = 1.0;
local NO_HIGHLIGHT_ALPHA = .8;
function ArmoryArtifactPowerButtonMixin:SetRelicHighlightEnabled(enabled)
    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE ) then
        self.RelicTraitGlow:SetShown(enabled);
        self.RelicTraitGlowRing:SetShown(enabled);
        self.RelicTraitBG:SetAlpha(enabled and HIGHLIGHT_ALPHA or NO_HIGHLIGHT_ALPHA);
    end
end

function ArmoryArtifactPowerButtonMixin:GetPowerID()
    return self.powerID;
end

function ArmoryArtifactPowerButtonMixin:GetLinearIndex()
    return self.linearIndex;
end

function ArmoryArtifactPowerButtonMixin:GetTier()
    return self.tier;
end

function ArmoryArtifactPowerButtonMixin:IsStart()
    return self.isStart;
end

function ArmoryArtifactPowerButtonMixin:IsFinal()
    return self.isFinal;
end

function ArmoryArtifactPowerButtonMixin:IsGoldMedal()
    return self.isGoldMedal;
end

function ArmoryArtifactPowerButtonMixin:SetLinksEnabled(enabled)
    self.linksEnabled = enabled;
end

function ArmoryArtifactPowerButtonMixin:AreLinksEnabled()
    return self.linksEnabled;
end

function ArmoryArtifactPowerButtonMixin:HasBonusMaxRanksFromTier()
    return self.numMaxRankBonusFromTier > 0;
end

function ArmoryArtifactPowerButtonMixin:IsCompletelyPurchased()
    return self.isCompletelyPurchased;
end

function ArmoryArtifactPowerButtonMixin:HasSpentAny()
    return self.hasSpentAny;
end

function ArmoryArtifactPowerButtonMixin:ArePrereqsMet()
    return self.prereqsMet;
end

function ArmoryArtifactPowerButtonMixin:IsActiveForLinks()
    return self:IsCompletelyPurchased() or self:HasBonusMaxRanksFromTier();
end

function ArmoryArtifactPowerButtonMixin:GetCurrentRank()
    return self.currentRank;
end

function ArmoryArtifactPowerButtonMixin:IsMaxRank()
    return self.isMaxRank;
end

function ArmoryArtifactPowerButtonMixin:HasRanksFromCurrentTier()
    if ( self.tier == Armory:GetArtifactTier() ) then
        return self.currentRank > 0;
    else
        return self.currentRank > self.maxRank - self.numMaxRankBonusFromTier;
    end
end

function ArmoryArtifactPowerButtonMixin:UpdateIcon()
    if ( self.isFinal and self.tier == 2 ) then
        local finalAtlas = ("%s-FinalIcon"):format(self.textureKit);
        self.Icon:SetAtlas(finalAtlas, true);
        self.IconDesaturated:SetAtlas(finalAtlas, true);
    else
        local name, _, texture = GetSpellInfo(self.spellID);
        self.Icon:SetTexture(texture);
        self.IconDesaturated:SetTexture(texture);
    end
end

function ArmoryArtifactPowerButtonMixin:CalculateDistanceTo(otherPowerButton)
    local cx, cy = self:GetCenter();
    local ocx, ocy = otherPowerButton:GetCenter();
    local dx, dy = ocx - cx, ocy - cy;
    return math.sqrt(dx * dx + dy * dy);
end

function ArmoryArtifactPowerButtonMixin:SetupButton(powerID, anchorRegion, textureKit)
    local powerInfo = Armory:GetPowerInfo(powerID);

    self:ClearAllPoints();
    local xOffset, yOffset = 0, 0;
    if ( powerInfo.offset ) then
        powerInfo.offset:ScaleBy(85);
        xOffset, yOffset = powerInfo.offset:GetXY();
    end
    self:SetPoint("CENTER", anchorRegion, "TOPLEFT", powerInfo.position.x * anchorRegion:GetWidth() + xOffset, -powerInfo.position.y * anchorRegion:GetHeight() - yOffset);

    local totalPurchasedRanks = Armory:GetTotalPurchasedRanks();
    local wasJustUnlocked = powerInfo.prereqsMet and self.prereqsMet == false;
    local wasRespecced = self.currentRank and powerInfo.currentRank < self.currentRank;
    local wasBonusRankJustIncreased = self.bonusRanks and powerInfo.bonusRanks > self.bonusRanks;

    self.powerID = powerID;
    self.spellID = powerInfo.spellID;
    self.currentRank = powerInfo.currentRank;
    self.bonusRanks = powerInfo.bonusRanks;
    self.maxRank = powerInfo.maxRank;
    self.isStart = powerInfo.isStart;
    self.isGoldMedal = powerInfo.isGoldMedal;
    self.isFinal = powerInfo.isFinal;
    self.tier = powerInfo.tier;
    self.textureKit = textureKit;
    self.linearIndex = powerInfo.linearIndex;
    self.numMaxRankBonusFromTier = powerInfo.numMaxRankBonusFromTier;

    self.isCompletelyPurchased = powerInfo.currentRank == powerInfo.maxRank or (self.tier == 1 and self.isStart);
    self.hasSpentAny = powerInfo.currentRank > powerInfo.bonusRanks;
    self.isMaxRank = powerInfo.currentRank == powerInfo.maxRank;
    self.prereqsMet = powerInfo.prereqsMet;
    self.wasBonusRankJustIncreased = wasBonusRankJustIncreased;
    self.cost = powerInfo.cost;

    self:UpdatePowerType();

    self:EvaluateStyle();

    self:UpdateIcon();
end

function ArmoryArtifactPowerButtonMixin:EvaluateStyle()
    if ( not HasPurchasedAnything() and not self.prereqsMet ) then
        self:SetStyle(ARTIFACT_POWER_STYLE_RUNE);
    elseif ( C_ArtifactUI.IsArtifactDisabled() ) then
        if ( self.isMaxRank ) then
            self:SetStyle(ARTIFACT_POWER_STYLE_MAXED);
        elseif ( self.prereqsMet and Armory:GetPointsRemaining() >= self.cost ) then
            self:SetStyle(ARTIFACT_POWER_STYLE_CAN_UPGRADE);
        elseif ( self.currentRank > 0 ) then
            self:SetStyle(ARTIFACT_POWER_STYLE_PURCHASED);
        elseif ( self.prereqsMet ) then
            self:SetStyle(ARTIFACT_POWER_STYLE_UNPURCHASED);
        else
            self:SetStyle(ARTIFACT_POWER_STYLE_UNPURCHASED_LOCKED);
        end
    else
        if ( Armory:GetTotalPurchasedRanks() == 0 and Armory:GetNumObtainedArtifacts() <= 1 ) then
            self:SetStyle(ARTIFACT_POWER_STYLE_RUNE);
        elseif ( Armory:IsPowerKnown(self.powerID) ) then
            self:SetStyle(ARTIFACT_POWER_STYLE_PURCHASED_READ_ONLY);
        else
            self:SetStyle(ARTIFACT_POWER_STYLE_UNPURCHASED_READ_ONLY);
        end
    end
end

function ArmoryArtifactPowerButtonMixin:ClearOldData()
    self.powerID = nil;
    self.spellID = nil;
    self.currentRank = nil;
    self.bonusRanks = nil;
    self.maxRank = nil;
    self.isStart = nil;
    self.isGoldMedal = nil;
    self.isFinal = nil;
    self.cost = nil;
    self.tier = nil;
    self.textureKit = nil;
    self.numMaxRankBonusFromTier = nil;

    self.isCompletelyPurchased = nil;
    self.hasSpentAny = nil;
    self.isMaxRank = nil;
    self.prereqsMet = nil;
    self.wasBonusRankJustIncreased = nil;
    self.linksEnabled = nil;

    self.relicType = nil;
    self.relicLink = nil;
    self.originalRelicType = nil;
    self.originalRelicLink = nil;
end


----------------------------------------------------------
-- ArmoryArtifactLineMixin Mixin
----------------------------------------------------------

ArmoryArtifactLineMixin = {};

ArmoryArtifactLineMixin.LINE_FADE_ANIM_TYPE_CONNECTED = 1;
ArmoryArtifactLineMixin.LINE_FADE_ANIM_TYPE_UNLOCKED = 2;
ArmoryArtifactLineMixin.LINE_FADE_ANIM_TYPE_LOCKED = 3;

function ArmoryArtifactLineMixin:SetState(lineState)
    self.lineState = lineState;
    if ( lineState == LINE_STATE_CONNECTED ) then
        self:SetConnected();
    elseif ( lineState == LINE_STATE_DISCONNECTED ) then
        self:SetDisconnected();
    elseif ( lineState == LINE_STATE_LOCKED ) then
        self:SetLocked();
    end
end

function ArmoryArtifactLineMixin:SetConnected()
    self.Fill:SetVertexColor(self.connectedColor:GetRGB());
    self.FillScroll1:SetVertexColor(self.connectedColor:GetRGB());
    if ( self.FillScroll2 ) then
        self.FillScroll2:SetVertexColor(self.connectedColor:GetRGB());
    end

    self:PlayLineFadeAnim(self.LINE_FADE_ANIM_TYPE_CONNECTED);
end

function ArmoryArtifactLineMixin:SetDisconnected()
    self.Fill:SetVertexColor(self.disconnectedColor:GetRGB());

    self:PlayLineFadeAnim(self.LINE_FADE_ANIM_TYPE_UNLOCKED);
end

function ArmoryArtifactLineMixin:SetLocked()
    self.Fill:SetVertexColor(self.connectedColor:GetRGB());

    self:PlayLineFadeAnim(self.LINE_FADE_ANIM_TYPE_LOCKED);
end

function ArmoryArtifactLineMixin:PlayLineFadeAnim(lineAnimType)
    self.FadeAnim:Finish();

    self.FadeAnim.Background:SetFromAlpha(self.Background:GetAlpha());
    self.FadeAnim.Fill:SetFromAlpha(self.Fill:GetAlpha());
    self.FadeAnim.FillScroll1:SetFromAlpha(self.FillScroll1:GetAlpha());
    if ( self.FillScroll2 ) then
        self.FadeAnim.FillScroll2:SetFromAlpha(self.FillScroll2:GetAlpha());
    end

    local artifactDisabled = C_ArtifactUI.IsArtifactDisabled();
    if ( artifactDisabled ) then
        self.FillScroll1:SetDesaturated(true);
        if ( self.FillScroll2 ) then
            self.FillScroll2:SetDesaturated(true);
        end
    end

    if ( lineAnimType == self.LINE_FADE_ANIM_TYPE_CONNECTED ) then
        if ( artifactDisabled ) then
            self.ScrollAnim:Stop();
        else
            self.ScrollAnim:Play();
        end

        self.FadeAnim.Background:SetToAlpha(0.0);
        self.FadeAnim.Fill:SetToAlpha(1.0);
        self.FadeAnim.FillScroll1:SetToAlpha(1.0);
        if ( self.FillScroll2 ) then
            self.FadeAnim.FillScroll2:SetToAlpha(1.0);
        end
    elseif ( lineAnimType == self.LINE_FADE_ANIM_TYPE_UNLOCKED ) then
        self.ScrollAnim:Stop();

        self.FadeAnim.Background:SetToAlpha(1.0);
        self.FadeAnim.Fill:SetToAlpha(1.0);
        self.FadeAnim.FillScroll1:SetToAlpha(0.0);
        if ( self.FillScroll2 ) then
            self.FadeAnim.FillScroll2:SetToAlpha(0.0);
        end

    elseif ( lineAnimType == self.LINE_FADE_ANIM_TYPE_LOCKED ) then
        self.ScrollAnim:Stop();

        self.FadeAnim.Background:SetToAlpha(0.85);
        self.FadeAnim.Fill:SetToAlpha(0.0);
        self.FadeAnim.FillScroll1:SetToAlpha(0.0);
        if ( self.FillScroll2 ) then
            self.FadeAnim.FillScroll2:SetToAlpha(0.0);
        end
    end
    self.FadeAnim:Play();
end

function ArmoryArtifactLineMixin:SetEndPoints(fromButton, toButton)
    if ( self.IsCurved )  then
        self.Fill:SetSize(2, 2);
        self.Fill:ClearAllPoints();
        self.Fill:SetPoint("CENTER", fromButton);

        self.Background:SetSize(2, 2);
        self.Background:ClearAllPoints();
        self.Background:SetPoint("CENTER", fromButton);

        self.FillScroll1:SetSize(2, 2);
        self.FillScroll1:ClearAllPoints();
        self.FillScroll1:SetPoint("CENTER", fromButton);
    else
        self.Fill:SetStartPoint("CENTER", fromButton);
        self.Fill:SetEndPoint("CENTER", toButton);

        self.Background:SetStartPoint("CENTER", fromButton);
        self.Background:SetEndPoint("CENTER", toButton);

        self.FillScroll1:SetStartPoint("CENTER", fromButton);
        self.FillScroll1:SetEndPoint("CENTER", toButton);

        self.FillScroll2:SetStartPoint("CENTER", fromButton);
        self.FillScroll2:SetEndPoint("CENTER", toButton);
    end
end

function ArmoryArtifactLineMixin:SetConnectedColor(color)
    self.connectedColor = color;
end

function ArmoryArtifactLineMixin:SetDisconnectedColor(color)
    self.disconnectedColor = color;
end

function ArmoryArtifactLineMixin:CalculateTiling(length)
    local TEXTURE_WIDTH = 128;
    local tileAmount = length / TEXTURE_WIDTH;
    self.Fill:SetTexCoord(0, tileAmount, 0, 1);
    self.Background:SetTexCoord(0, tileAmount, 0, 1);
    self.FillScroll1:SetTexCoord(0, tileAmount, 0, 1);
    if ( self.FillScroll2 ) then
        self.FillScroll2:SetTexCoord(0, tileAmount, 0, 1);
    end
end

function ArmoryArtifactLineMixin:SetVertexOffset(vertexIndex, x, y)
    self.Fill:SetVertexOffset(vertexIndex, x, y);
    self.Background:SetVertexOffset(vertexIndex, x, y);
    self.FillScroll1:SetVertexOffset(vertexIndex, x, y);
    if ( self.FillScroll2 ) then
        self.FillScroll2:SetVertexOffset(vertexIndex, x, y);
    end
end

function ArmoryArtifactLineMixin:SetAlpha(alpha)
    self.ScrollAnim:Stop();
    self.FadeAnim:Stop();

    self.Background:SetAlpha(alpha);
    self.Fill:SetAlpha(alpha);
    self.FillScroll1:SetAlpha(alpha);
    if ( self.FillScroll2 ) then
        self.FillScroll2:SetAlpha(alpha);
    end
end
