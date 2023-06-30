# Armory: Compiled Fixes for 17.6.0

Fixes to make Armory 17.6.0 work with WoW 10.1

This contains all necessary fixes to make Armory 17.6.0 work with the current WoW 10.1:

- Tradeskill tabs: `ArmoryTradeSkills.lua:912: attempt to index local 'info' (a nil value)`.
- Quest tab: `ArmoryQuestLogFrame.lua:192: attempt to index global 'QUEST_TAG_TCOORDS' (a nil value)`.
- Wrong quest tags in the quests tooltips of the summary sheet ("Completed' instead of "Daily"/"Weekly").
- Missing autofocus for the search box of the Search frame. (This is an improvement, and as such optional.)

I have only included fixes for issues I was experiencing myself. I'm aware that there posts about other issues, but I guess these are due to interferences with certain other addons.

As of now and with my usual addon sets, Armory runs completely fine and error-free for me with these fixes.

Except one thing: 
Under high load (i.e. immediately after login when all addons and the client are querying infos from the server) it is possible that you get an error when opening whatever Armory tab. 
This can easily avoided by just not interacting with Armory during this time. If you don't use many other addons, it is even possible that you'll never have the issue.
