================================================================================

Since the Armory author has released a new version (17.7.0), this repo is outdated and obsolete. Related issue thread: https://legacy.curseforge.com/wow/addons/armory/issues/377

================================================================================

# Armory: Compiled Fixes for 17.6.0

These are temporary fixes for the [Armory](https://www.curseforge.com/wow/addons/armory) World of Warcraft Retail addon.

I highly appreciate that Warmexx took the time to update Armory for DF (a massive undertaking due to many, many API changes). At the same time, it pains me to see that Armory does not run properly in 10.1, just because of a few easily fixable things.

## This mod contains fixes to make Armory 17.6.0 work with the current WoW 10.1:

- Tradeskill tabs: `ArmoryTradeSkills.lua:912: attempt to index local 'info' (a nil value)`.
- Quest tab: `ArmoryQuestLogFrame.lua:192: attempt to index global 'QUEST_TAG_TCOORDS' (a nil value)`.
- Wrong quest tags in the quests tooltips of the summary sheet ("Completed" instead of "Daily"/"Weekly").
- Missing autofocus for the search box of the Search frame. (This is an improvement, and as such optional.)

I have only included fixes for issues I was experiencing myself. I'm aware that there are posts about other issues, but I guess these are due to interferences with other addons. It would take too much time trying to reduplicate these issues.

As of now and with my usual addon sets, Armory runs completely fine and error-free _for me_ with these fixes.

Except for one thing:   

Under heavy load, i.e. right after login, when all the addons and the client are requesting information from the server, you may get an error when opening any Armory tab. This can be easily avoided by not interacting with Armory during this time (the first 30 seconds or so after login/reload). If you don't use many other addons, it's even possible that you'll never see this issue.

## Disclaimer

Since I am not familiar with the entire Armory code, it is quite likely that my fixes, or some of them, are suboptimal. Nevertheless, I have tested all the fixes and have been playing with them for some time without any problems.

## To install this mod:

1. Click the green Code button and select "Download ZIP". 
2. Expand the archive.
3. Copy the Armory and ArmoryGuildBank folders to your active AddOns folder, replacing the existing ones.

Alternatively, you can just replace the 4 files (see "The diffs" below) in your Armory folder with the modified ones.

---

## The diffs

As you can see, not big things:

### Change 1 in `../Armory/Core/ArmorySummary.lua`

…fixes the wrong display of the quest tags ("Daily"/"Weekly" is replaced by "Complete") in the Current Quests section of the quest tooltip in the Summary Sheet:

```diff
@@ -475,7 +475,7 @@ local function DisplayQuests(tooltip, characterInfo)
                 color = Armory:HexColor(color);
 
                 myColumn = column; index, column = tooltip:SetCell(index, myColumn, color..questTitleText..FONT_COLOR_CODE_CLOSE);
-                myColumn = column; index, column = tooltip:SetCell(index, myColumn, isHeader and "" or color..(ArmoryQuestLog_GetQuestTag(questID, isComplete, frequency) or "")..FONT_COLOR_CODE_CLOSE);
+                myColumn = column; index, column = tooltip:SetCell(index, myColumn, isHeader and "" or color..(ArmoryQuestLog_GetQuestTag(questID, nil, isComplete, frequency) or "")..FONT_COLOR_CODE_CLOSE);
             end
         end
     end
```

The additional `nil` parameter on position 2 shifts the `isComplete` and `frequency` parameters to their correct positions. Compare the analogous function usage in `ArmoryQuestLogFrame.lua`, around line 204, where the quest tags are displayed correctly.

### Change 2  in `../Armory/Core/ArmoryTradeSkills.lua`

…fixes (better: works around) a nil error with the Tradeskill tabs:

```diff
@@ -909,7 +909,7 @@ function Armory:GetTradeSkillInfo(index)
     end
 
     local QuestionMarkIconFileDataID = 134400;
-    if ( info.icon == QuestionMarkIconFileDataID ) then
+    if ( info and info.icon == QuestionMarkIconFileDataID ) then
         info.icon = self:GetProfessionTexture(self:GetSelectedProfession());
     end
```

### Change 3 in `../Armory/Frames/ArmoryQuestLogFrame.lua`

…is to compensate for recent API changes with icons / textures / atlas (10.1 or 10.0.7, IDK). 

```diff
@@ -189,9 +189,8 @@ function ArmoryQuestLog_Update()
                 questLogTitle:SetText("  "..questLogTitleText);
                 if ( questID and C_CampaignInfo.IsCampaignQuest(questID) ) then
                     local faction = Armory:UnitFactionGroup("player");
-                    local coords = faction == "Horde" and QUEST_TAG_TCOORDS.HORDE or QUEST_TAG_TCOORDS.ALLIANCE;
-                    questLogTitle:SetNormalTexture(QUEST_ICONS_FILE);
-                    questLogTitle:GetNormalTexture():SetTexCoord( unpack(coords) );
+                    local coords = faction == "Horde" and QUEST_TAG_ATLAS.HORDE or QUEST_TAG_ATLAS.ALLIANCE;
+                    questLogTitle:GetNormalTexture():SetAtlas(coords);
                 else
                     questLogTitle:ClearNormalTexture();
                 end
```

### Change 4 in`../Armory/Tools/ArmoryFindFrame.xml`

…is for a more convenient search experience (this is an improvement, not a fix):

```diff
@@ -237,6 +237,9 @@
           <Anchor point="TOPLEFT" x="75" y="-36"/>
         </Anchors>
         <Scripts>
+          <OnShow>
+            C_Timer.After(0, function() self:SetFocus() end)
+          </OnShow>
           <OnEnterPressed inherit="append">
             self:ClearFocus();
             ArmoryFindFrameEditBox_OnEnterPressed(self);
```

We could also set the `autoFocus` attribute of that frame (somewhere else in the code), but the effect of that would be that the letter from the keybind gets inserted into the search field. Hence the C_Timer with 1 frame delay.
