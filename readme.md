# Armory: Compiled Fixes for 17.6.0

Fixes to make Armory 17.6.0 work with WoW 10.1

This contains all necessary fixes to make Armory 17.6.0 work with the current WoW 10.1:

- Tradeskill tabs: `ArmoryTradeSkills.lua:912: attempt to index local 'info' (a nil value)`.
- Quest tab: `ArmoryQuestLogFrame.lua:192: attempt to index global 'QUEST_TAG_TCOORDS' (a nil value)`.
- Wrong quest tags in the quests tooltips of the summary sheet ("Completed' instead of "Daily"/"Weekly").
- Missing autofocus for the search box of the Search frame. (This is an improvement, and as such optional.)

I have only included fixes for issues I was experiencing myself. I'm aware that there are posts about other issues, but I guess these are due to interferences with other addons. It would take too much time trying to reduplicate these issues.

As of now and with my usual addon sets, Armory runs completely fine and error-free for me with these fixes.

Except for one thing: under heavy load (i.e. right after login, when all the addons and the client are requesting information from the server), you may get an error when opening any Armory tab. This can be easily avoided by not interacting with Armory during this time. If you don't use many other addons, it's even possible that you'll never have this problem.
