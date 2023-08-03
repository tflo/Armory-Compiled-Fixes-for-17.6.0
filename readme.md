# Fork of Armory (WoW addon)

Based on: Armory 17.7.0

This fork, formerly "Armory: Compiled Fixes for 17.6.0", was originally created with and for Armory 17.6.0 (May 2023), which had some serious bugs that hadn't been addressed by the author for quite some time.

With Armory 17.7.0 (July 2023), all the bugs have been fixed by the author ([issue thread](https://legacy.curseforge.com/wow/addons/armory/issues/377)).

Currently, this fork only addresses one issue in Armory 17.7.0.

## Addressed issues

### Prevent stray characters from being inserted into the Search frame edit box

Based on an earlier suggestion, with 17.7.0 the author implemented autofocus for the Search frame edit box.

However, the way it is implemented, any character mapped to the Search frame keybind will be inserted into the editbox of the frame when it is invoked via keybind. This is the case on macOS at least.

The current fix for this is to reapply our 17.6.0 fix[^1] to `../Tools/ArmoryFindFrame.xml`, and discard the change made to `../Tools/ArmoryFindFrame.lua` with 17.7.0.

## Other known issues

There are some other (minor or semi-minor) issues with 17.7.0 that are not addressed in this fork: [Issue thread on CurseForge](https://legacy.curseforge.com/wow/addons/armory/issues?filter-tag=&filter-action=).

[^1]: See the [17.6.0 version of this readme](https://github.com/tflo/Fork-of-Armory/tree/b518eb1985e09581a23a9659d9a018fff85c6f6a) and scroll down to the last diff (change 4).
