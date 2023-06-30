# Armory: Compiled Fixes for 17.6.0

I highly appreciate that Warmexx took the time to update Armory for DF (a massive undertaking due to many, many API changes). At the same time, it pains me to see that Armory does not run properly in 10.1, just because of a few easily fixable things.

## This mod contains fixes to make Armory 17.6.0 work with the current WoW 10.1:

- Tradeskill tabs: `ArmoryTradeSkills.lua:912: attempt to index local 'info' (a nil value)`.
- Quest tab: `ArmoryQuestLogFrame.lua:192: attempt to index global 'QUEST_TAG_TCOORDS' (a nil value)`.
- Wrong quest tags in the quests tooltips of the summary sheet ("Completed" instead of "Daily"/"Weekly").
- Missing autofocus for the search box of the Search frame. (This is an improvement, and as such optional.)

I have only included fixes for issues I was experiencing myself. I'm aware that there are posts about other issues, but I guess these are due to interferences with other addons. It would take too much time trying to reduplicate these issues.

As of now and with my usual addon sets, Armory runs completely fine and error-free for me with these fixes.

Except for one thing:   

Under heavy load, i.e. right after login, when all the addons and the client are requesting information from the server, you may get an error when opening any Armory tab. This can be easily avoided just by not interacting with Armory during this time (the first 30 seconds or so after login/reload). If you don't use many other addons, it's even possible that you'll never see this issue.

## Disclaimer

Since I am not familiar with the entire Armory code, it is quite likely that my fixes, or some of them, are suboptimal. Nevertheless, I have tested all the fixes and have been playing with them for some time without any problems.

## To install this mod:

1. Click the green Code button and select "Download ZIP". 
2. Expand the archive.
3. Copy the Armory and ArmoryGuildBank folders to your active AddOns folder, replacing the existing ones.
